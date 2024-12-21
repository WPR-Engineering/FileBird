# This file is used by Rack-based servers to start the application.

require_relative "config/environment"
require 'rack'
run Rack::Directory.new '.'
run Rails.application
Rails.application.load_server
