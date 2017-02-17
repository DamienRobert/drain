module DR
	module Lambda
		extend self
		#standard ruby: col.map(&f) for one variable
		#Here: Lambda.map(f,col1,col2,...) for several variables
		#Other implementation:
		#(shift cols).zip(cols).map {|a| f.call(*a)}
		#but our implementation stops as soon as a collection is empty
		#whereas the zip implementation use the length of the first collection
		#and pads with nil
		def map(f,*cols)
			cols=cols.map(&:each)
			r=[]
			loop do
				r<<f.call(*cols.map(&:next))
			end
			r
		rescue StopIteration
		end

		#like map but return an enumerator
		def enum_map(f,*cols)
			cols=cols.map(&:each)
			Enumerator.new do |y|
				loop do
					y<<f.call(*cols.map(&:next))
				end
			end
		end

		#compose a list of functions
		def compose(*f)
			f.reverse!
			first=f.shift
			return lambda do |*args,&b|
				v=first.call(*args,&b)
				f.reduce(v) {|v,fun| fun.call(v)}
			end
		end
	end
end
