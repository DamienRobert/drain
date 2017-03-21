module DR
	class Eruby
		#complement TOPLEVEL_BINDING
		EMPTY_BINDING = binding

		module ClassHelpers
			#process some ruby code
			#run '_src' in its own execution context
			#instead of binding(), binding: TOPLEVEL_BINDING may be useful to not
			#pollute the source
			def process_ruby(_src, src_info: nil, context: nil, eval_binding: binding, wrap: :proc, variables: nil)
				#stolen from Erubis
				if _src.respond_to?(:read)
					src_info=_src unless src_info
					_src=_src.read
				end
				to_eval=case wrap
					#todo: a lambda with local parameters to simulate local
					#variables, cf Tilt
					when :eval; _src
					when :lambda; "lambda { |_context| #{_src} }"
					when :proc; "Proc.new { |_context| #{_src} }"
					when :module; "Module.new { |_context| #{_src} }"
					end
				_proc=eval(to_eval, eval_binding, "(process_ruby #{src_info})")
				unless context.nil?
					#I don't think there is much value [*] to wrap _src into _proc,
					#instance_eval("_src") and instance_eval(&_proc) seems to have
					#the same effect on binding
					#[*] apart from passing _context to _src, but we have 'self' already
					#- it allows also to set up block local $SAFE level
					#- and we can use break while this is not possible with a string
					context.instance_eval(&_proc)
				else
					_proc
				end
			end

			def eruby_include(template, opt={})
				file=File.expand_path(template)
				Dir.chdir(File.dirname(file)) do |cwd|
					erb = Engine.new(File.read(file))
					#if context is not empty, then we probably want to evaluate
					if opt[:evaluate] or opt[:context]
						r=erb.evaluate(opt[:context])
					else
						bind=opt[:bind]||binding
						r=erb.result(bind)
					end
					#if using erubis, it is better to invoke the template in <%= =%> than
					#to use chomp=true
					r=r.chomp if opt[:chomp]
					return r
				end
			end

			# add variables values to a binding; variables is a Hash
			def add_variables(variables, _binding=TOPLEVEL_BINDING)
				eval _arg.collect{|k,v| "#{k} = _arg[#{k.inspect}]; "}.join, _binding
				_binding
			end
		end
		extend ClassHelpers

		module EngineHelper
			### Stolen from erubis
			## eval(@src) with binding object
			def result(_binding_or_hash=TOPLEVEL_BINDING)
				_arg = _binding_or_hash
				if _arg.is_a?(Hash)
					_b=self.class.add_variables(_arg, binding)
				elsif _arg.is_a?(Binding)
					_b = _arg
				elsif _arg.nil?
					_b = binding
				else
					raise ArgumentError.new("#{self.class.name}#result(): argument should be Binding or Hash but passed #{_arg.class.name} object.")
				end
				return eval(@src, _b, (@filename || '(erubis'))
				#erb.rb:
				#  if @safe_level
				#  proc {
				#    $SAFE = @safe_level
				#    eval(@src, b, (@filename || '(erb)'), @lineno)
				#  }.call
			end

			## invoke context.instance_eval(@src)
			def evaluate(_context=Context.new)
				_context = Context.new(_context) if _context.is_a?(Hash)
				#return _context.instance_eval(@src, @filename || '(erubis)')
				#@_proc ||= eval("proc { #{@src} }", Erubis::EMPTY_BINDING, @filename || '(erubis)')
				_proc ||= eval("proc { #{@src} }", binding(), @filename || '(eruby)')
				return _context.instance_eval(&_proc)
			end

			## if object is an Class or Module then define instance method to it,
			## else define singleton method to it.
			def def_method(object, method_name, filename=nil)
				m = object.is_a?(Module) ? :module_eval : :instance_eval
				object.__send__(m, "def #{method_name}; #{@src}; end", filename || @filename || '(erubis)')
				#erb.rb: src = self.src.sub(/^(?!#|$)/) {"def #{methodname}\n"} << "\nend\n" #This pattern insert the 'def' after lines with leading comments
			end
		end

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

		def to_hash
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
