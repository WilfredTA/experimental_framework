require './app'
require './middleware'
require 'rack'
require 'rack/builder'

use Rack::Session::Cookie, :key => 'rack.session',
							:expire_after => 2592000	
use GameLoader		   
run GameExecuter.new
