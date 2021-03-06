require 'helper'
require 'dr/ruby_ext/core_modules'

module TestCoreExtRefinements
	using DR::CoreRef
	# TODO make refinements work nicely
end

module TestCoreExt
	require 'dr/ruby_ext/core_ext'
	describe DR::CoreExt do
		describe Enumerable do
			it "Can classify enumerable" do
				_([1,2,3,4].classify({odd: [1,3], default: :even})).must_equal({:odd=>[1, 3], :even=>[2, 4]})
			end
		end

		describe Hash do
			it "Implements Hash#deep_merge" do
				h1 = { x: { y: [4,5,6] }, z: [7,8,9] }
				h2 = { x: { y: [7,8,9] }, z: 'xyz' }
				_(h1.deep_merge(h2)).must_equal({x: {y: [7, 8, 9]}, z: "xyz"})
				_(h2.deep_merge(h1)).must_equal({x: {y: [4, 5, 6]}, z: [7, 8, 9]})
				_(h1.deep_merge(h2) { |key, old, new| Array(old) + Array(new) }).must_equal({:x=>{:y=>[4, 5, 6, 7, 8, 9]}, :z=>[7, 8, 9, "xyz"]})
			end

			it "Hash#deep_merge merge array when they start with nil" do
				h1 = { x: { y: [4,5,6] }, z: [7,8,9] }
				h2 = { x: { y: [nil, 7,8,9] }, z: 'xyz' }
				_(h1.deep_merge(h2)).must_equal({x: {y: [4,5,6,7, 8, 9]}, z: "xyz"})
				_({x: { y: []} }.deep_merge(h2)).must_equal({x: {y: [7, 8, 9]}, z: "xyz"})
				_({z: "foo"}.deep_merge(h2)).must_equal({x: {y: [7, 8, 9]}, z: "xyz"})
			end

			it "Implements Hash#inverse" do
				h={ploum: 2, plim: 2, plam: 3}
				_(h.inverse).must_equal({2=>[:ploum, :plim], 3=>[:plam]})
			end
			
			it "Implements Hash#keyed_value" do
				h = { x: { y: { z: "foo" } } }
				_(h.keyed_value("x/y/z")).must_equal("foo")
			end

			it "Implements Hash#set_keyed_value" do
				h = { x: { y: { z: "foo" } } }
				_(h.set_keyed_value("x/y/z","bar")).must_equal({ x: { y: { z: "bar" } } })
				_(h.set_keyed_value("x/y","bar2")).must_equal({ x: { y: "bar2" } })
				_(h.set_keyed_value("z/y","bar3")).must_equal({ x: { y: "bar2" } , z: {y: "bar3"}})
			end

			it "Implements Hash#leafs" do
				_({foo: [:bar, :baz], bar: [:plum, :qux]}.leafs([:foo])).must_equal([:plum, :qux, :baz])
			end
		end

		describe UnboundMethod do
			it "Can be converted to a proc" do
				m=String.instance_method(:length)
				_(["foo", "ploum"].map(&m)).must_equal([3,5])
			end
			it "Can call" do
				_(String.instance_method(:length).call("foo")).must_equal(3)
			end
		end

		describe Proc do
			# fails due to ruby bug on double splat
			# it "call_block does not worry about arity of lambda" do
			# 	(->(x,y) {x+y}).call_block(1,2,3).must_equal(3)
			# end

			it "Can do rcurry" do
				l=->(x,y) {"#{x}: #{y}"}
				m=l.rcurry("foo")
				_(m.call("bar")).must_equal("bar: foo")
			end

			it "Can compose functions" do
				somme=->(x,y) {x+y}
				carre=->(x) {x*x}
				_(carre.compose(somme).(2,3)).must_equal(25)
			end

			it "Can uncurry functions" do
				_((->(x) {->(y) {x+y}}).uncurry.(2,3)).must_equal(5)
				_((->(x,y) {x+y}).curry.uncurry.(2,3)).must_equal(5)
			end
		end

		describe Array do
			it "Can be converted to proc (providing extra arguments)" do
				_(["ploum","plam"].map(&[:+,"foo"])).must_equal(["ploumfoo", "plamfoo"])
			end
		end

		describe Object do
			it "this can change the object" do
				_("foo".this {|s| s.size}.+(1)).must_equal(4)
			end

			it "and_this emulates the Maybe Monad" do
				_("foo".and_this {|s| s.size}).must_equal(3)
				assert_nil nil.and_this {|s| s.size}
			end
		end

		describe DR::RecursiveHash do
			it "Generates keys when needed" do
				h=DR::RecursiveHash.new
				h[:foo][:bar]=3
				_(h).must_equal({foo: {bar: 3}})
			end
		end
	end
end
