require "helper"
require 'dr/ruby_ext/meta_ext'
#Module.send :include, DR::Meta

class TestMetaExt < Minitest::Test
	def setup
		@foo=Module.new do
			extend DR::MetaModule
			def foo
				"foo"
			end
		end
		@bar=Module.new do
			def bar
				"bar"
			end
		end
		@baz=Module.new do
			def baz
				"baz"
			end
		end
		@foo.includes_extends_host_with(@bar,@baz)
	end
	def test_includes
		klass=@foo
		test1=Class.new do
			include klass
		end
		test1.new.foo
		test1.new.bar
		test1.baz
	end
	def test_extends
		klass=@foo
		test1=Class.new do
			extend klass
		end
		test1.foo
		test1.new.bar
		test1.baz
	end
end

describe DR::Meta do
	## Does not work anymore in recent rubies (ruby 2.4+)
	# it "Can convert a class to module" do
	# 	(Class.new { include DR::Meta.refined_module(String) { def length; super+5; end } }).new("foo").length.must_equal(8)
	# end

	it "Can show all ancestors" do
		_(DR::Meta.all_ancestors("foo").include?(String.singleton_class)).must_equal(true)
	end

	it "Can generate bound methods" do
		m=DR::Meta.get_bound_method("foo", :bar) do |x|
			self+x
		end
		_(m.call("bar")).must_equal("foobar")
	end

	it "Can apply unbound methods" do
		_(DR::Meta.apply(method: String.instance_method(:length), to: "foo")).must_equal(3)
	end
end
