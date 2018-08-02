require 'helper'
require 'dr/parse/simple_keywords'

describe DR::SimpleKeywordsParser do
	before do
		@hash={
			'FOO' => lambda { |*args|  "FOO: #{args}" },
			'BAR' => lambda { |*args|  "BAR: #{args}" },
		}
	end

	it "Can parse keywords" do
		DR::SimpleKeywordsParser.keywords("FOO(ploum, plam)", @hash).must_equal 'FOO: ["ploum", "plam"]'
	end
end
