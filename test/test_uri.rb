require 'helper'
require 'dr/base/uri'

describe DR::URI::Wrapper do
	before do
		@uri=DR::URI::Wrapper.new(DR::URI::Escape.escape("http://ploum:secret@plam:443/foo bar"))
	end
	it "Wraps an uri element" do
		_(@uri.scheme).must_equal "http"
	end
	it "Auto escapes attribute" do
		_(@uri.path).must_equal "/foo bar"
	end
	it "Auto escape setting elements" do
		@uri.user="ploum plam"
		_(@uri.user).must_equal "ploum plam"
	end
	it "Can convert to a hash" do
		_(@uri.to_h[:user]).must_equal("ploum")
	end
	it "Can convert to json" do
		require 'json'
		_(@uri.to_json).must_equal("{\"uri\":\"http://ploum:secret@plam:443/foo%20bar\",\"scheme\":\"http\",\"userinfo\":\"ploum:secret\",\"host\":\"plam\",\"port\":443,\"path\":\"/foo bar\",\"user\":\"ploum\",\"password\":\"secret\"}")
	end
	it "Can remove password" do
		_(@uri.to_public).must_equal("http://ploum@plam:443/foo%20bar")
	end
	it "Can be merged" do
		_(@uri.soft_merge("foo://plim@").to_s).must_equal("foo://plim:secret@plam:443/foo%20bar")
	end
	it "Can be reverse merged" do
		_(DR::URI::Wrapper.parse("//user@server").reverse_merge(@uri).to_s).must_equal("http://user:secret@server:443/foo%20bar")
	end
end

