require './app'
require './middleware'
require 'rack'
require 'rack/builder'

use Router
run App.new
