require 'helper'
require 'dr/base/graph'

# This segfaults in ruby-2.2.0, but seems corrected in ruby-2.3-dev
describe DR::Graph do
	before do
		@graph=DR::Graph.new({"foo"=> ["bar","baz"], "bar" => "baz"})
	end

	it "builds the graph" do
		@graph.nodes.length.must_equal 3
	end

	it "accepts :to_a" do
		@graph.to_a.map(&:name).must_equal(["foo", "bar", "baz"])
	end

	it "accepts :to_h" do
		@graph.to_h.first[1].keys == [:children, :parent, :attributes]
	end

	it "can give a hash of children" do
		@graph.to_children.must_equal({"foo"=>["bar", "baz"], "bar"=>["baz"], "baz"=>[]})
	end

	describe "build" do
		it "accepts a Hash" do
			@graph.build({"plim" => "foo"})
		end
	end

	it "detects unneeded nodes" do
		@graph.unneeded("foo","bar").map(&:name).must_equal ["foo","bar"]
		@graph.unneeded("bar").map(&:name).must_equal []
	end

	describe "It works with a cycle" do
		before do
			@graph=DR::Graph.new({"foo"=> ["bar","baz"], "bar" => ["baz"], "baz" => "foo"})
		end

		it "It builds the graph" do
			@graph.nodes.length.must_equal 3
		end
	end
end
