require './app'
require './middleware'
require 'rack'
require 'rack/builder'


run App.new
