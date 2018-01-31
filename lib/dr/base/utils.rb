module DR
	module Utils
		extend self
		def pretty_print(string, format: nil, pretty: false)
			case format.to_s
			when "json"
				require 'json'
				return pretty_print(string.to_json)
			when "yaml"
				require "yaml"
				return pretty_print(string.to_yaml)
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
	end
end
