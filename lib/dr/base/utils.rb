module DR
	module Utils
		extend self
		def pretty_print(string, format: nil, pretty: false)
			case format.to_s
			when "json"
				require 'json'
				return pretty_print(string.to_json, pretty: pretty)
			when "yaml"
				require "yaml"
				return pretty_print(string.to_yaml, pretty: pretty)
			end
			if pretty.to_s=="color"
				begin
					require 'ap'
					ap string
				rescue LoadError,NameError
					pretty_print(string,pretty:true)
				end
			elsif pretty
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
	end
end
