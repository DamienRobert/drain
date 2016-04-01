require 'helper'
require 'dr/ruby_ext/core_ext'

describe DR::CoreExt do
	it "Can filter enumerable" do
		[1,2,3,4].filter({odd: [1,3], default: :even}).must_equal({:odd=>[1, 3], :even=>[2, 4]})
	end

	it "Implements Hash#deep_merge" do
		h1 = { x: { y: [4,5,6] }, z: [7,8,9] }
		h2 = { x: { y: [7,8,9] }, z: 'xyz' }
		h1.deep_merge(h2).must_equal({x: {y: [7, 8, 9]}, z: "xyz"})
		h2.deep_merge(h1).must_equal({x: {y: [4, 5, 6]}, z: [7, 8, 9]})
		h1.deep_merge(h2) { |key, old, new| Array(old) + Array(new) }.must_equal({:x=>{:y=>[4, 5, 6, 7, 8, 9]}, :z=>[7, 8, 9, "xyz"]})
	end

	it "Implements Hash#inverse" do
		h={ploum: 2, plim: 2, plam: 3}
		h.inverse.must_equal({2=>[:ploum, :plim], 3=>[:plam]})
	end
end
