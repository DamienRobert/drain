require 'helper'
require 'dr/parse/simple_keywords'

describe DR::SimpleKeywordsParser do
	before do
		@parser=DR::SimpleKeywordsParser.new({
			'FOO' => lambda { |*args|  "FOO: #{args}" },
			'BAR' => lambda { |*args|  "BAR: #{args}" },
		})
	end

	it "Can parse keywords" do
		_(@parser.parse("FOO(ploum, plam)")).must_equal 'FOO: ["ploum", "plam"]'
	end

	it "Can preserver spaces" do
		_(@parser.parse("FOO( ploum , plam  )", space: true)).must_equal "FOO: [\" ploum \", \" plam  \"]"
	end

	it "Can change delimiters" do
		_(@parser.parse("FOO[ ploum , plam  ]", delims: '[]')).must_equal "FOO: [\"ploum\", \"plam\"]"
	end

	it "Can have a one caracter delimiter" do
		_(@parser.parse("FOO! ploum , plam  !", delims: '!')).must_equal "FOO: [\"ploum\", \"plam\"]"
	end

	it "Can parse keywords inside keywords" do
		_(@parser.parse("FOO(ploum, BAR( foo, bar ))")).must_equal "FOO: [\"ploum\", \"BAR: [\\\"foo\\\"\", \"\\\"bar\\\"]\"]"
	end

	it "Can add a keyword" do
		@parser.keyword("PLOUM") { |a,b| a.to_i+b.to_i}
		_(@parser.parse("Hello PLOUM(2,3)")).must_equal 'Hello 5'
	end
end
