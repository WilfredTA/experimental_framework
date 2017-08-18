require './app'
require 'rack'
require 'rack/builder'

use Router
run App.new
