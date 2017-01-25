require 'helper'
require 'dr/parse/simple_parser'

describe DR::SimpleParser do
	describe "parse_namevalue" do
		it "parses a simple name value" do
			DR::SimpleParser.parse_namevalue("foo:bar").must_equal([:foo,"bar"])
		end
		it "can let the name be a string" do
			DR::SimpleParser.parse_namevalue("foo:bar",symbolize:false).must_equal(["foo","bar"])
		end
		it "only splits on the first ':'" do
			DR::SimpleParser.parse_namevalue("foo:bar:baz").must_equal([:foo,"bar:baz"])
		end
		it "can change the separation" do
			DR::SimpleParser.parse_namevalue("foo:bar!baz", sep: "!",symbolize:false).must_equal(["foo:bar","baz"])
		end
		it "can set a default" do
			DR::SimpleParser.parse_namevalue("foo", default: 0).must_equal([:foo,0])
		end
		it "If the default is true then support 'no-foo'" do
			DR::SimpleParser.parse_namevalue("no-foo", default: true).must_equal([:foo,false])
		end
		it "can set the default to true" do
			DR::SimpleParser.parse_namevalue("foo", default: true, symbolize:false).must_equal(["foo",true])
		end
	end

	describe "parse_strings" do
		it "can parse several name values" do
			DR::SimpleParser.parse_string("foo:bar,ploum:plim")[:values].must_equal({foo: "bar", ploum: "plim"})
		end
		it "can handle options" do
			DR::SimpleParser.parse_string("name1:value1!option1=ploum!option2=plam!option3,name2:value2!!globalopt1=foo,globalopt2=bar").must_equal({
			values: {name1: "value1", name2: "value2"},
			local_opts: {name1: {option1:"ploum",option2:"plam",option3:true}, name2: {}},
			global_opts: {globalopt1: "foo", globalopt2: "bar"},
			opts: {name1: {option1:"ploum",option2:"plam",option3:true,globalopt1:"foo", globalopt2: "bar"}, name2:{globalopt1: "foo", globalopt2: "bar"}}})
		end
	end
end
