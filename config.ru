require './app'
require './middleware'
require 'rack'
require 'rack/builder'
require 'puma'

use Rack::Session::Cookie, :key => 'rack.session',
							:secret => "secret"
use GameLoader		   
run GameExecuter.new
