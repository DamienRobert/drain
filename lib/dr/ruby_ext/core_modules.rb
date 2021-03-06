module DR
	module CoreExt
		#[Hash, Array].each {|m| m.include(Enumerable)} #to reinclude
		module Enumerable
			#Ex: [1,2,3,4].classify({odd: [1,3], default: :even})
			#=> {:odd=>[1, 3], :even=>[2, 4]}
			def classify(h)
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
			def deep_merge(other_hash, **opts, &block)
				dup.deep_merge!(other_hash, **opts, &block)
			end

			# Same as +deep_merge+, but modifies +self+.
			def deep_merge!(other_hash, append: :auto, &block)
				return self unless other_hash
				other_hash.each_pair do |k,v|
					tv = self[k]
					case
					when tv.is_a?(Hash) && v.is_a?(Hash)
						self[k] = tv.deep_merge(v, &block)
					when tv.is_a?(Array) && v.is_a?(Array)
						if append==:auto and v.length > 0 && v.first.nil? then
							#hack: if the array begins with nil, we append the new
							#value rather than overwrite it
							v.shift
							self[k] += v
						elsif append && append != :auto
							self[k] += v
						else
							self[k] = block && tv ? block.call(k, tv, v) : v
						end
					when tv.nil? && v.is_a?(Array)
						#here we still need to remove nil (see above)
						if append==:auto and v.length > 0 && v.first.nil? then
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

			def reverse_merge(other_hash)
				other_hash.merge(self)
			end
			def reverse_deep_merge(other_hash)
				other_hash.deep_merge(self)
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
				key.to_s.split(sep).each do |k|
					k=k.to_sym if r.key?(k.to_sym) && !r.key?(k)
					r=r[k]
				end
				return r
			end

			#take a key of the form ploum/plam/plim
			#and return self[:ploum][:plam][:plim]=value
			def set_keyed_value(key,value, sep: "/", symbolize: true)
				r=self
				*keys,last=key.to_s.split(sep)
				keys.each do |k|
					k=k.to_sym if (symbolize || r.key?(k.to_sym)) and !r.key?(k)
					r[k]={} unless r.key?(k)
					r=r[k]
				end
				last=last.to_sym if symbolize
				r[last]=value
				self
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

			# Adapted from File activesupport/lib/active_support/core_ext/hash/slice.rb, line 22
			# Note that ruby has Hash#slice, but if the key does not exist, we
			# cannot configure a default
			def slice_with_default(*keys, default: nil)
				keys.each_with_object(::Hash.new) do |k, hash| 
					if has_key?(k) || default == :default_proc
						hash[k] = self[k] 
					else
						hash[k] = default
					end
				end
			end

			def dig_with_default(*args, default: nil)
				r=dig(*args)
				return default if r.nil?
				r
			end

			def has_keys?(*keys, key)
				i=self
				keys.each do |k|
					i.key?(k) or return false
					i=i[k]
				end
				i.key?(key)
			end

			def set_key(*keys, key, value)
				i=self
				keys.each do |k|
					i.key?(k) or i[k]={}
					i=i[k]
				end
				i[key]=value
				# self
			end
			# like set_key, but only set the value if it does not exist
			def add_key(*keys, key, value)
				i=self
				keys.each do |k|
					i.key?(k) or i[k]={}
					i=i[k]
				end
				i.key?(key) or i[key]=value
				# self
				i[key]
			end
			#like add_key, but consider the value is an Array and add to it
			def add_to_key(*keys, key, value, overwrite: false, uniq: true, deep: false)
				i=self
				keys.each do |k|
					i.key?(k) or i[k]={}
					i=i[k]
				end
				if value.is_a?(Hash)
					v=i[key] || {}
					if deep
						overwrite ? v.deep_merge!(value) : v=value.deep_merge(v)
					else
						overwrite ? v.merge!(value) : v=value.merge(v)
					end
				else
					v=i[key] || []
					v += Array(value)
					v.uniq! if uniq
				end
				i[key]=v
				# self
			end

		end

		module UnboundMethod
			#this should be in the stdlib...
			#Note: this is similar to Symbol#to_proc which works like this:
			#  foo=:foo.to_proc; foo.call(obj,*args) #=> obj.method(:foo).call(*args)
			#  => :length.to_proc.call("foo") #=> 3
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
			# Safely call our block, even if the user passed in something of a
			# different arity (lambda case)
			def call_block(*args,**opts)
				if arity >= 0
					case arity
					when 0
						call(**opts)
					else
						call(args[0...arity],**opts)
					end
				else
					call(*args,**opts)
				end
			end

			#similar to curry, but pass the provided arguments on the right
			#(a difference to Proc#curry is that we pass the argument directly, not
			#via .call)
			def rcurry(*args,&b)
				return ::Proc.new do |*a,&b|
					self.call(*a,*args,&b)
				end
			end

			#return self o g
			#f.compose(g).(5,6)
			def compose(g)
				lambda do |*a,&b|
					self.call(*g.call(*a,&b))
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
		# warning, this only works for methods that don't need to call other
		# refined methods
		CoreExt.constants.select {|c| const_get("::#{c}").is_a?(Class)}.each do |c|
			refine const_get("::#{c}") do
				include CoreExt.const_get(c)
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
	#For an individual hash: hash = Hash.new {|h,k| h[k] = h.class.new(&h.default_proc) }
	#Arrays don't accept blocks in the same way as Hashs, we need to pass a length parameter, so we can't use DR::RecursiveHash(Array)
end
