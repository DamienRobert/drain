module DR
	module Meta
		extend self
		#from http://stackoverflow.com/questions/18551058/better-way-to-turn-a-ruby-class-into-a-module-than-using-refinements
		#See also http://stackoverflow.com/questions/28649472/ruby-refinements-subtleties
		#
		#convert a class into a module using refinements
		#ex: (Class.new { include Meta.refined_module(String) { def length; super+5; end } }).new("foo").length #=> 8
		#This uses the fact that a refining module of klass behaves as if it had
		#klass has his direct ancestor
		def refined_module(klass,&b)
			klass=klass.singleton_class unless Module===klass
			Module.new do
				#including the module rather than just returning it allow us to
				#still be able to use 'using' ('using' does not work directly on
				#refining modules only on the enclosing ones)
				include refine(klass) {
					module_eval(&b) if block_given?
				}
			end
		end

		#find the ancestors of obj, its singleton class, its
		#singleton_singleton_class. To avoid going to infinity, we only add a
		#singleton_class when its ancestors contains new modules we have not
		#seen.
		def all_ancestors(obj)
			obj=obj.singleton_class unless Module===obj
			found=[]
			stack=[obj]
			while !stack.empty? do
				obj=stack.shift
				next if found.include?(obj)
				found<<obj
				stack.push(* obj.ancestors.select {|m| !(stack+found).include?(m)})
				sing=obj.singleton_class
				stack << sing unless sing.ancestors.select {|m| m.class==Module}.reduce(true) {|b,m| b && found.include?(m)}
			end
			return found
		end

		# add extend_ancestors and full_extend to Object
		def extend_object
			include_ancestors=Meta.method(:include_ancestors)
			include_complete=Meta.method(:full_include)
			Object.define_method(:extend_ancestors) do |m|
				include_ancestors.bind(singleton_class).call(m)
			end
			Object.define_method(:full_extend) do |m|
				include_complete.bind(singleton_class).call(m)
			end
		end

		#apply is a 'useless' wrapper to .call, but it also works for UnboundMethod.
		#  See also dr/core_ext that adds 'UnboundMethod#call'
		#=> If we don't want to extend a module with Meta, we can still do
		#Meta.apply(String,method: Meta.instance_method(:include_ancestors),to: self)
		#(note that in 'Meta.apply', the default option to 'to:' is self=Meta,
		#that's why we need to put 'to: self' again)
		def apply(*args,method: nil, to: self, **opts,&block)
			#note, in to self is Meta, except if we include it in another
			#module so that it would make sense
			method=method.unbind if method.class==Method
			case method
			when UnboundMethod
				method=method.bind(to)
			end
			#We cannot call **opts if opts is empty in case of an empty args, cf https://bugs.ruby-lang.org/issues/10708
			if opts.empty?
				method.call(*args,&block)
			else
				method.call(*args,**opts,&block)
			end
		end

		def get_bound_method(obj, method_name, &block)
			obj.singleton_class.send(:define_method,method_name, &block)
			method = obj.method method_name
			obj.singleton_class.send(:remove_method,method_name)
			method
		end

		#Taken from sinatra/base.rb: return an unbound method from a block, with
		#owner the current module
		#Conversely, from a (bound) method, calling to_proc (hence &m) gives a lambda
		#Note: rather than doing 
		#m=get_unbound_method('',&block);m.bind(obj).call(args)
		#one could do obj.instance_exec(args,&block)
		def get_unbound_method(method_name, &block)
			define_method(method_name, &block)
			method = instance_method method_name
			remove_method method_name
			method
		end

		#like get_unbound_method except we pass a strng rather than a block
		def get_unbound_evalmethod(method_name, method_str, args: '')
			module_eval <<-RUBY
				def #{method_name}(#{args})
					#{method_str}
				end
			RUBY
			method = instance_method method_name
			remove_method method_name
			method
		end

	end

	#helping with metaprograming facilities
	#usage: Module Foo; extend DR::MetaModule; include_complete Ploum; end
	module MetaModule
		#When included/extended (according to :hooks, add the following instance
		#and class methods)
		def includes_extends_host_with(instance_module=nil, class_module=nil, hooks: [:included,:extended])
			@_include_module ||= []
			@_extension_module ||= []
			@_include_module << instance_module
			@_extension_module << class_module
			hooks.each do |hook|
				define_singleton_method hook do |base|
					#we use send here because :include is private in Module
					@_include_module.each do |m|
						m=const_get(m) if ! Module===m
						base.send(:include, m)
					end
					@_extension_module.each do |m|
						m=const_get(m) if ! Module===m
						base.extend(m)
					end
				end
			end
		end

		#include_ancestor includes all modules ancestor, so one can do
		#singleton_class.include_ancestors(String) to include the Module ancestors of String into the class
		def include_ancestors(m)
			ancestors=m.respond_to?(:ancestors) ? m.ancestors : m.singleton_class.ancestors
			ancestors.reverse.each do |m|
				include m if m.class==Module
			end
		end

		def include_all_ancestors(obj)
			ancestors=Meta.all_ancestors(obj)
			ancestors.reverse.each do |m|
				include m if m.class==Module
			end
		end

		# module Z
		#		def x; "x"; end
		# end
		# module Enumerable
		#		extend MetaModule
		#		full_include Z
		# end
		# Array.new.x => "x"
		def full_include other
			include other
			if self.class == Module
				this = self
				ObjectSpace.each_object Module do |mod|
					mod.send :include, this if mod < self
				end
			end
		end

		#essentially like define_method, but can pass a Method or an UnboundMethod
		#see also dr/core_ext which add UnboundMethod#to_proc so we could
		#instead use define_method(name,&method) and it would work
		def add_method(name=nil,method)
			name=method.name unless name
			name=name.to_sym
			#if we have a (bound) method, we can convert it to a proc, but the
			#'self' inside it keeps being the 'self' of the original object (even
			#in instance_eval).
			#Since usually we'll want to change the self, it's better to unbind it
			method=method.unbind if method.class==Method
			case method
			when UnboundMethod
				#here the block passed is evaluated using instance_eval, so self is the
				#object calling, not the current module
				define_method name do |*args,&block|
					method.bind(self).call(*args,&block)
				end
			else
				#if method is a block/Proc, this is the same as define_method(name,method)
				define_method(name,&method)
			end
		end

		#add_methods(method1, method2, ...)
		#add_methods({name1: method1, name2: method2, ...})
		#add_methods(aClass, :method_name1, :method_name2)
		#add_methods(aClass, {new_name1: :method_name1, new_name2: :method_name2})
		def add_methods(*args)
			return if args.empty?
			if Module === args.first
				mod=args.shift
				#we include methods from mod, the arguments should be method names
				if args.size == 1 and Hash === args.first
					#we have a hash {new_name => old_name}
					args.first.each do |k,v|
						add_method(k,mod.instance_method(v.to_sym))
					end
				else
					args.each do |m|
						add_method(mod.instance_method(m.to_sym))
					end
				end
			else
				if args.size == 1 and Hash === args.first
					#we have a hash {new_name => method}
					args.first.each do |k,v|
						add_method(k,v)
					end
				else
					args.each do |m|
						add_method(m)
					end
				end
			end
		end
	end

	#DynamicModule.new(:methods_to_include) do ... end
	class DynamicModule < Module
		include MetaModule

		def initialize(*args,&block)
			super #call the block
			add_methods(*args)
		end

	end
end

