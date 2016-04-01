module DR
	module CoreExt
		#[Hash, Array].each {|m| m.include(Enumerable)} #to reinclude
		module Enumerable
			#Ex: [1,2,3,4].filter({odd: [1,3], default: :even})
			#=> {:odd=>[1, 3], :even=>[2, 4]}
			def filter(h)
				invh=h.inverse
				default=h[:default]
				r={}
				each do |el|
					keys=invh.fetch(el,[default])
					keys.each do |key|
						(r[key]||=[]) << el
					end
				end
				return r
			end
		end

		module Hash
			# Returns a new hash with +self+ and +other_hash+ merged recursively.
			#
			#		h1 = { x: { y: [4,5,6] }, z: [7,8,9] }
			#		h2 = { x: { y: [7,8,9] }, z: 'xyz' }
			#
			#		h1.deep_merge(h2) #=> {x: {y: [7, 8, 9]}, z: "xyz"}
			#		h2.deep_merge(h1) #=> {x: {y: [4, 5, 6]}, z: [7, 8, 9]}
			#		h1.deep_merge(h2) { |key, old, new| Array.wrap(old) + Array.wrap(new) }
			#		#=> {:x=>{:y=>[4, 5, 6, 7, 8, 9]}, :z=>[7, 8, 9, "xyz"]}
			#
			#		Adapted from active support
			def deep_merge(other_hash, &block)
				dup.deep_merge!(other_hash, &block)
			end

			# Same as +deep_merge+, but modifies +self+.
			def deep_merge!(other_hash, &block)
				return unless other_hash
				other_hash.each_pair do |k,v|
					tv = self[k]
					case
					when tv.is_a?(Hash) && v.is_a?(Hash)
						self[k] = tv.deep_merge(v, &block)
					when tv.is_a?(Array) && v.is_a?(Array)
						if v.length > 0 && v.first.nil? then
							#hack: if the array begins with nil, we append the new
							#value rather than overwrite it
							v.shift
							self[k] += v
						else
							self[k] = block && tv ? block.call(k, tv, v) : v
						end
					when tv.nil? && v.is_a?(Array)
						#here we still need to remove nil (see above)
						if v.length > 0 && v.first.nil? then
							v.shift
							self[k]=v
						else
							self[k] = block && tv ? block.call(k, tv, v) : v
						end
					else
						self[k] = block && tv ? block.call(k, tv, v) : v
					end
				end
				self
			end

			#from a hash {key: [values]} produce a hash {value: [keys]}
			#there is already Hash#invert using Hash#key which does that, but the difference here is that we flatten Enumerable values
			#h={ploum: 2, plim: 2, plam: 3}
			#h.invert #=> {2=>:plim, 3=>:plam}
			#h.inverse #=> {2=>[:ploum, :plim], 3=>[:plam]}
			def inverse
				r={}
				each_key do |k|
					values=fetch(k)
					values=[values] unless values.respond_to?(:each)
					values.each do |v|
						r[v]||=[]
						r[v]<< k
					end
				end
				return r
			end

			#sort the keys and the values of the hash
			def sort_all
				r=::Hash[self.sort]
				r.each do |k,v|
					r[k]=v.sort
				end
				return r
			end

			#take a key of the form ploum/plam/plim
			#and return self[:ploum][:plam][:plim]
			def keyed_value(key, sep: "/")
				r=self.dup
				return r if key.empty?
				key.split(sep).each do |k|
					k=k.to_sym if r.key?(k.to_sym) && !r.key?(k)
					r=r[k]
				end
				return r
			end

			#from a hash {foo: [:bar, :baz], bar: [:plum, :qux]},
			#then leaf [:foo] returns [:plum, :qux, :baz]
			def leafs(nodes)
				expanded=[] #prevent loops
				r=nodes.dup
				begin
					s,r=r,r.map do |n|
						if key?(n) && !expanded.include?(n)
							expanded << n
							fetch(n)
						else
							n
						end
					end.flatten
				end until s==r
				r
			end
		end

		module Proc
			# Safely call our block, even if the user passed in something of a
			# different arity (lambda case)
			def call_block(*args,**opts)
				if block.arity >= 0
					case block.arity
					when 0
						block.call(**opts)
					else
						block.call(args[0...block.arity],**opts)
					end
				else
					block.call(*args,**opts)
				end
			end
		end

		module UnboundMethod
			#this should be in the stdlib...
			def to_proc
				return lambda do |obj,*args,&b|
					bind(obj).call(*args,&b)
				end
			end
			def call(*args,&b)
				to_proc.call(*args,&b)
			end
		end

		module Proc
			#similar to curry, but pass the provided arguments on the right
			#(a difference to Proc#curry is that we pass the argument directly, not
			#via .call)
			def rcurry(*args,&b)
				return Proc.new do |*a,&b|
					self.call(*a,*args,&b)
				end
			end

			#return self o g
			#f.compose(g).(5,6)
			def compose(g)
				lambda do |*a,&b|
					self.call(g.call(*a,&b))
				end
			end

			#(->(x) {->(y) {x+y}}).uncurry.(2,3) #=> 5
			#(->(x,y) {x+y}).curry.uncurry.(2,3) #=>5
			def uncurry
				lambda do |*a|
					a.reduce(self) {|fun,v| fun.call(v)}
				end
			end
		end

		module Array
			#allows to do things like
			# ["ploum","plam"].map(&[:+,"foo"]) #=> ["ploumfoo", "plamfoo"]
			def to_proc
				ar=self.dup
				method=ar.shift.to_proc
				return method.rcurry(*ar)
			end
		end

		module Object
			#in ruby 2.2, 'Object#itself' only returns self
			def this
				return yield(self) if block_given?
				return self
			end
			#simulate the Maybe monad
			def and_this(&b)
				nil? ? nil : this(&b)
			end
		end
	end

	module CoreRef
		CoreExt.constants.select {|c| c.is_a?(Class)}.each do |c|
			refine const_get("::#{c}") do
				include Module.const_get("CoreExt::#{c}")
			end
		end
	end

	module Recursive
		extend self
		def recursive_constructor(klass)
			return Class.new(klass) do |rklass|
				define_method :initialize do |*args,&b|
					b ? super(*args,&b) : super(*args) { |h,k| h[k] = rklass.new }
				end
			end
		end
	end
	RecursiveHash=Recursive.recursive_constructor(Hash)
	#Arrays don't accept blocks in the same way as Hashs, we need to pass a length parameter, so we can't use DR::RecursiveHash(Array)
end
