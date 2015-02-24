module DR
	module Eruby
		begin
			require 'erubis'
			Erb=::Erubis::Eruby
		rescue LoadError
			require 'erb'
			Erb=::ERB
		end
		def erb_include(template, opt={})
			opt={bind: binding}.merge(opt)
			file=File.expand_path(template)
			Dir.chdir(File.dirname(file)) do |cwd|
				erb = Erb.new(File.read(file))
				#if context is not empty, then we probably want to evaluate
				if opt[:evaluate] or opt[:context]
					r=erb.evaluate(opt[:context])
				else
					r=erb.result(opt[:bind])
				end
				#if using erubis, it is better to invoke the template in <%= =%> than
				#to use chop=true
				r=r.chomp if opt[:chomp]
				return r
			end
		end
	end
end
