require './application'

use Rack::Session::Pool
run Sinatra::Application

