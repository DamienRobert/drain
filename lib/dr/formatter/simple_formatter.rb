module DR
	module Formatter
		extend self
		def localize(msg, lang: :en, **_opts)
			case msg
			when Hash
				msg[lang].to_s
			else
				msg.to_s
			end
		end

	end
end
