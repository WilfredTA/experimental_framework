require './app'
require './middleware'
require 'rack'
require 'rack/builder'

use GameLoader
run GameExecuter.new
