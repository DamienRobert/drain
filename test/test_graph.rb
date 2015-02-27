require 'helper'
require 'dr/base/graph'

describe DR::Graph do
	before do
		@graph=DR::Graph.new({"foo"=> ["bar","baz"], "bar" => ["baz"], "baz" => "foo"})
	end
	describe "build" do
		it "accepts a Hash" do
			@graph.build({"plim" => "foo"})
		end
	end
end
