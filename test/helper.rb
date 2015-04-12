require 'rubygems'
require 'minitest/autorun'
require 'pry-rescue/minitest'
require 'minitest/reporters'
#Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
