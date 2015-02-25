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
