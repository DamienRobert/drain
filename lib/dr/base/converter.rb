module DR
	module Converter
		extend self
		#convert an obj to hash, using 'methods' for the methods attributes
		def to_hash(obj=nil, methods:[], recursive: false, check: false, compact: false)
			return {} if obj.nil?
			obj||=self
			stack=[*obj]
			processed=[]
			klass=stack.first.class
			h={}
			while !stack.empty?
				obj=stack.shift
				next if processed.include?(obj)
				processed << obj
				attributes={}
				methods.each do |m|
					next if check and !obj.respond_to? m
					v=obj.public_send(m)
					attributes[m]=v
					if recursive
						vals=v.kind_of?(Enumerable) ? v.to_a.flatten : [v]
						vals.select! {|v| v.kind_of?(klass)}
						stack.concat(vals)
					end
				end
				attributes=attributes.values.first if compact and attributes.keys.length == 1
				h[obj]=attributes
			end
			h
		end
	end
end
