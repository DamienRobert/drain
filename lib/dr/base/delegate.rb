module DR
	module Delegator
		extend self
		def delegate_h(klass, var)
			require 'forwardable'
			# put in a Module so that they are easier to distinguish from the
			# 'real' functions
			m=Module.new do
				extend(Forwardable)
				methods=[:[], :[]=, :any?, :assoc, :clear, :compact, :compact!, :delete, :delete_if, :dig, :each, :each_key, :each_pair, :each_value, :empty?, :fetch, :fetch_values, :has_key?, :has_value?, :include?, :index, :invert, :keep_if, :key, :key?, :keys, :length, :member?, :merge, :merge!, :rassoc, :reject, :reject!, :select, :select!, :shift, :size, :slice, :store, :to_a, :to_h, :to_s, :transform_keys, :transform_keys!, :transform_values, :transform_values!, :update, :value?, :values, :values_at]
				include(Enumerable)
				def_delegators var, *methods
			end
			klass.include(m)
		end

		def access_methods(klass, var, *methods)
			methods.each do |k|
				klass.define_method k do
					instance_variable_get(var)[k]
				end
				klass.defined_method :"#{k}=" do |*args|
					instance_variable_get(var).send(:[]=, k, *args)
				end
			end
		end
	end
end
