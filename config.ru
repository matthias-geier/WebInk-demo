require 'erb'
require 'digest/sha1'
#require 'webink'
require './webink/beauty.rb'
require './webink/controller.rb'
require './webink/model.rb'
require './webink/database.rb'

run Ink::Beauty.new
