module DR
	module Delegator
		def self.delegate_h(klass, var)
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
	end
end
