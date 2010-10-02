# require whatever gems you need for your project
require 'erb'
require 'digest/sha1'
require "#{params[:config]["db_type"]}"
require "webink"

# ######################################################################
# ######################################################################
# Remove webink and add whatever libraries you need, this saves memory.
# Model and Database are attached, and should not be loaded exclusively.
# webink/beauty is not loaded by requiring 'webink'.
# ----------------------------------------------------------------------
#require "webink/controller"
#require "webink/model"
#require "webink/database"
# ######################################################################


# ######################################################################
# ######################################################################
# Loading the Models obviously requires the Model class to be included.
# ----------------------------------------------------------------------
models = Dir.new "./models"
models.each do |model|
  load "#{models.path}/#{model}" if model =~ /\.rb$/
end
# ######################################################################


load "./controllers/#{params[:controller]}.rb"


# ######################################################################
# ######################################################################
# Uncomment this if you do not use the Database library.
# ----------------------------------------------------------------------
Ink::Database.create params[:config]
# ######################################################################


controller = (Ink::Controller.verify params[:controller]).new params
response = (controller.verify params[:module]).call


# ######################################################################
# ######################################################################
# Uncomment this if you do not use the Database library.
# ----------------------------------------------------------------------
Ink::Database.database.close
# ######################################################################
