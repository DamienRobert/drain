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

	it "accepts :to_hash" do
		@graph.to_hash.first[1].keys.must_equal [:children, :parents, :attributes]
	end
	
	it "can be converted to a hash" do
		@graph.to_h.must_equal ({"foo"=> ["bar","baz"], "bar" => ["baz"], "baz" => []})
	end

	it "can give a node" do
		@graph["foo"].class.must_equal DR::Node
	end

	it "can give descendants of a node" do
		@graph["foo"].descendants.map(&:to_s).must_equal(["bar", "baz"])
	end

	it "can give ancestors of a node" do
		@graph["baz"].ancestors.map(&:to_s).must_equal(["foo", "bar"])
	end

	it "can show all ancestors of nodes" do
		@graph.ancestors("baz","bar").map(&:to_s).must_equal(["baz", "bar", "foo"])
		@graph.ancestors("baz","bar", ourselves: false).map(&:to_s).must_equal(["foo"])
	end

	it "can show all descendants of nodes" do
		@graph.descendants("foo","bar").map(&:to_s).must_equal(["foo", "bar", "baz"])
		@graph.descendants("foo","bar", ourselves: false).map(&:to_s).must_equal(["baz"])
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
	it "detects unneeded descendants" do
		@graph.unneeded_descendants("foo").map(&:name).must_equal ["foo", "bar", "baz"]
	end

	describe "It works with a cycle" do
		before do
			@graph=DR::Graph.new({"foo"=> ["bar","baz"], "bar" => ["baz"], "baz" => "foo"})
		end

		it "It builds the graph" do
			@graph.nodes.length.must_equal 3
		end
	end

	describe "It works with a lambda to describe the graph" do
		before do
			infos=-> (node) do
				case node
				when "foo"
					return {children: ["bar","baz"]}
				when "bar"
					return {children: ["baz"]}
				when "baz"
					return {children: "foo", attributes: {real: true}}
				end
			end
			@graph=DR::Graph.new(*["foo","bar","baz"],infos: infos)
		end

		it "It builds the graph" do
			@graph.nodes.length.must_equal 3
			@graph.to_h.must_equal({"foo"=>["bar", "baz"], "bar"=>["baz"], "baz"=>["foo"]})
			@graph['baz'].attributes.must_equal(real: true)
		end
	end

	describe "It can be merged with another graph" do
		before do
			@graph2=DR::Graph.new({"foo" => ["bar"], "baz" => ["bar", "qux"]})
		end

		it "Graph2 is well defined" do
			@graph2.nodes.map(&:name).must_equal(%w(foo bar baz qux))
		end

		it "Can be merged in place" do
			@graph | @graph2
			@graph.to_h.must_equal({"foo"=>["bar", "baz"], "bar"=>["baz"], "baz"=>["bar", "qux"], "qux"=>[]})
		end

		it "Can be merged" do
			@graph3 = @graph + @graph2
			@graph.to_h.must_equal({"foo"=>["bar", "baz"], "bar"=>["baz"], "baz"=>[]})
			@graph3.to_h.must_equal({"foo"=>["bar", "baz"], "bar"=>["baz"], "baz"=>["bar", "qux"], "qux"=>[]})
		end
	end
end
