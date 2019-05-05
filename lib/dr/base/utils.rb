module DR
	module Utils
		extend self
		def pretty_print(string, format: nil, pretty: nil)
			case format.to_s
			when "json"
				require 'json'
				return pretty_print(string.to_json, pretty: pretty)
			when "yaml"
				require "yaml"
				return pretty_print(string.to_yaml, pretty: pretty)
			end
			pretty = "color" if pretty == nil #default
			pretty = "pp" if pretty == true
			case pretty.to_s
			when "ap"
				begin
					require 'ap'
					ap string
				rescue LoadError,NameError
					pretty_print(string,pretty:true)
				end
			when "color", "pp_color"
				begin
					require 'pry'
					Pry::ColorPrinter.pp string
				rescue LoadError,NameError
					pretty_print(string,pretty:true)
				end
			when "pp"
				require 'pp'
				pp string
			else
				puts string
			end
		end

		# stolen from active support
		def to_camel_case(s)
			s.sub(/^[a-z\d]*/) { |match| match.capitalize }.
				gsub(/(?:_|(\/))([a-z\d]*)/i) {"#{$1}#{$2.capitalize}"}.
				gsub("/", "::")
		end
		def to_snake_case(s)
			# convert from caml case to snake_case
			s.gsub(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2').
				gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
		end

		def rsplit(s, sep, num=nil)
			if num.nil? or num==0
				s.split(sep)
			else
				components=s.split(sep)
				components+=[nil]*[(num-components.length), 0].max
				a=components[0..(components.length-num)]
				b=components[(components.length-num+1)..(components.length-1)]
				return [a.join(sep), *b]
			end
		end
	end

	# Include this to get less output from pp
	module PPHelper
		# less verbose for pretty_print
		def pretty_print(pp)
			info = respond_to?(:to_pp) ? to_pp : to_s
			pp.object_address_group(self) { pp.text " "+info }
		end

		#since we hide the pp value of self, allow to inspect it
		def export
			r={}
			instance_variables.sort.each do |var|
				r[var]=instance_variable_get(var)
			end
			r
		end
	end
end
