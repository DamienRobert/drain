module DR
	class Eruby
		module BindingHelper
			extend self
			#complement TOPLEVEL_BINDING
			def empty_binding
				#wraps into anonymous module so that 'def foo' do not pollute namespace
				Module.new do
					#regenerate a new binding
					return binding
				end
			end
			#empty binding (at first) that stays the same and can be shared
			EMPTY_BINDING = empty_binding
			BLANK_OBJECT=Object.new

			# add variables values to a binding; variables is a Hash
			def add_variables(variables, _binding=empty_binding)
				eval variables.collect{|k,v| "#{k} = variables[#{k.inspect}]; "}.join, _binding
				_binding
			end

			#From Tilt/template.rb
			#return a string extracting local_keys from a hash named _context
			def local_extraction(local_keys, context_name: '_context')
				local_keys.map do |k|
					if k.to_s =~ /\A[a-z_][a-zA-Z_0-9]*\z/
						"#{k} = #{context_name}[#{k.inspect}]"
					else
						raise "invalid locals key: #{k.inspect} (keys must be variable names)"
					end
				end.join("\n")+"\n"
			end

		end

		module EngineHelper
			### Stolen from erubis
			## eval(@src) with binding object
			def result(_binding_or_hash=BindingHelper.empty_binding)
				_arg = _binding_or_hash
				if _arg.is_a?(Hash)
					_b=BindingHelper.add_variables(_arg, BindingHelper.empty_binding)
				elsif _arg.is_a?(Binding)
					_b = _arg
				elsif _arg.nil?
					_b = binding
				else
					raise ArgumentError.new("#{self.class.name}#result(): argument should be Binding or Hash but passed #{_arg.class.name} object.")
				end
				return eval(@src, _b, (@filename || '(eruby'))
				#erb.rb:
				#  if @safe_level
				#  proc {
				#		 $SAFE = @safe_level
				#		 eval(@src, b, (@filename || '(erb)'), @lineno)
				#  }.call
			end

			#Note that when the result is not used afterwards via "instance_eval"
			#then the Klass of binding is important when src has 'def foo...'
			#if set, locals should be an array of variable names
			def compile(wrap: :proc, bind: BindingHelper.empty_binding, locals: nil, pre: nil, post: nil, context_name: '_context')
				src=@src
				src=BindingHelper.local_extraction(locals, context_name: context_name)+src if locals
				src=pre+"\n"+src if pre
				src<< post+"\n" if post
				to_eval=case wrap
					when :eval; @src
					when :lambda; "lambda { |#{context_name}| #{src} }"
					when :proc; "Proc.new { |#{context_name}| #{src} }"
					when :module; "Module.new { |#{context_name}| #{src} }"
					when :unbound
						require 'dr/ruby_ext/meta_ext'
						return Meta.get_unbound_evalmethod('eruby', src, args: context_name)
					when :unbound_instance
						require 'dr/ruby_ext/meta_ext'
						return Meta.get_unbound_evalmethod('eruby', <<-RUBY, args: context_name)
							self.instance_eval do
								#{src}
							end
						RUBY
					else src
					end
				return eval(to_eval, bind, "(wrap #{@filename})")
			end

			## by default invoke context.instance_eval(@src)
			def evaluate(_context=Context.new, compile: {}, **opts, &b)
				#I prefer to pass context as a keyword, but we allow to pass it as
				#an argument to respect erubis's api
				_context=opts[:context] if opts.key?(:context)
				#_context = Context.new(_context) if _context.is_a?(Hash)
				vars=opts[:vars]
				compile[:locals]||=vars.keys if vars
				_proc=compile(**compile)
				Eruby.evaluate(_proc, context: _context, **opts, &b)
			end

			## if object is an Class or Module then define instance method to it,
			## else define singleton method to it.
			def def_method(object, method_name, filename=nil)
				m = object.is_a?(Module) ? :module_eval : :instance_eval
				object.__send__(m, "def #{method_name}; #{@src}; end", filename || @filename || '(eruby)')
				#erb.rb: src = self.src.sub(/^(?!#|$)/) {"def #{methodname}\n"} << "\nend\n" #This pattern insert the 'def' after lines with leading comments
			end
		end

		class Template
			include EngineHelper

			def initialize(src, filename: nil)
				if src.respond_to?(:read)
					filename=src unless filename
					src=src.read
				end
				@filename=filename || self.class.inspect
				@src=src
			end

		end

		module ClassHelpers
			def process_ruby(src, src_info: nil, **opts, &b)
				Template.new(src, filename: src_info).evaluate(**opts, &b)
			end

			def evaluate(_proc, context: Context.new, vars: nil, &b)
				#we can only pass the block b when we get an UnboundMethod
				if _proc.is_a?(UnboundMethod)
					if !vars.nil?
						_proc.bind(context).call(vars,&b)
					else
						_proc.bind(context).call(&b)
					end
				elsif _proc.is_a?(String)
					#in this case we cannot pass vars
					warn "Cannot pass variables when _proc is a String" unless vars.nil?
					context.instance_eval(_proc)
				else
					if context.nil?
						if !vars.nil?
							_proc.to_proc.call(vars,&b)
						else
							_proc.to_proc(&b)
						end
					else
						warn "Cannot pass block in context.instance_eval" unless b.nil?
						if !vars.nil?
							context.instance_exec(vars,&_proc)
						else
							context.instance_eval(&_proc)
						end
					end
				end
			end

			def include(template, **opts)
				file=File.expand_path(template)
				Dir.chdir(File.dirname(file)) do |cwd|
					erb = Engine.new(File.read(file))
					#if context is not empty, then we probably want to evaluate
					if opts[:evaluate] or opts[:context]
						r=erb.evaluate(opts[:context])
					else
						bind=opts[:bind]||binding
						r=erb.result(bind)
					end
					#if using erubis, it is better to invoke the template in <%= =%> than
					#to use chomp=true
					r=r.chomp if opts[:chomp]
					return r
				end
			end
		end

		extend ClassHelpers

		begin
			require 'erubi'
			Engine=::Erubi::Engine
		rescue LoadError
			require 'erubis'
			Engine=::Erubis::Eruby
		rescue LoadError
			require 'erb'
			Engine=::ERB
		end
		#prepend so that we have the same implementation
		Engine.__send__(:prepend, EngineHelper)
	end

	## Copy/Pasted from erubis context.rb
	##
	## context object for Engine#evaluate
	##
	## ex.
	##	 template = <<'END'
	##	 Hello <%= @user %>!
	##	 <% for item in @list %>
	##		- <%= item %>
	##	 <% end %>
	##	 END
	##
	##	 context = Erubis::Context.new(:user=>'World', :list=>['a','b','c'])
	##	 # or
	##	 # context = Erubis::Context.new
	##	 # context[:user] = 'World'
	##	 # context[:list] = ['a', 'b', 'c']
	##
	##	 eruby = Erubis::Eruby.new(template)
	##	 print eruby.evaluate(context)
	##
	class Eruby::Context
		include Enumerable

		def initialize(hash=nil)
			hash.each do |name, value|
				self[name] = value
			end if hash
		end

		def [](key)
			return instance_variable_get("@#{key}")
		end

		def []=(key, value)
			return instance_variable_set("@#{key}", value)
		end

		def keys
			return instance_variables.collect { |name| name[1..-1] }
		end

		def each
			instance_variables.each do |name|
				key = name[1..-1]
				value = instance_variable_get(name)
				yield(key, value)
			end
		end

		def to_h
			hash = {}
			self.keys.each { |key| hash[key] = self[key] }
			return hash
		end

		def update(context_or_hash)
			arg = context_or_hash
			if arg.is_a?(Hash)
				arg.each do |key, val|
					self[key] = val
				end
			else
				arg.instance_variables.each do |varname|
					key = varname[1..-1]
					val = arg.instance_variable_get(varname)
					self[key] = val
				end
			end
		end

	end

end
