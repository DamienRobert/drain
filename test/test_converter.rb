require 'helper'
require 'dr/base/converter'

describe DR::Converter do
	before do
		klass=Class.new do
			attr_accessor :a, :h
			def initialize(a,h)
				@a=a
				@h=h
			end
		end
		@obj1=klass.new(["foo","bar"],{foo: :bar})
		@obj2=klass.new([@obj1],{})
		@obj3=klass.new([],{@obj1 => @obj2})
		@obj3.a << @obj3
	end

	it "Output a hash with the attributes" do
		_(DR::Converter.to_hash(@obj1, methods: [:a,:h])).must_equal({@obj1 => {a: @obj1.a, h: @obj1.h}})
	end

	it ":compact compress the values when there is only one method" do
		_(DR::Converter.to_hash(@obj1, methods: [:a,:h], compact: true)).must_equal({@obj1 => {a: @obj1.a, h: @obj1.h}})
		_(DR::Converter.to_hash(@obj1, methods: [:a], compact: true)).must_equal({@obj1 => @obj1.a})
	end

	it ":check checks that the method exists" do
		_(-> {DR::Converter.to_hash(@obj1, methods: [:none], check: false)}).must_raise NoMethodError
		_(DR::Converter.to_hash(@obj1, methods: [:none], check: true)).must_equal({@obj1 => {}})
	end

	it "accepts a list" do
		_(DR::Converter.to_hash([@obj1,@obj2], methods: [:a,:h])).must_equal({@obj1 => {a: @obj1.a, h: @obj1.h}, @obj2 => {a: @obj2.a, h: @obj2.h}})
	end

	#this test also test that cycles work
	it ":recursive generate the hash on the values" do
		_(DR::Converter.to_hash(@obj3, methods: [:a,:h], recursive: true)).must_equal({@obj1 => {a: @obj1.a, h: @obj1.h}, @obj2 => {a: @obj2.a, h: @obj2.h}, @obj3 => {a: @obj3.a, h: @obj3.h}})
	end

end
