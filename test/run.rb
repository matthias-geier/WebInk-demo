#!/usr/bin/env ruby

require 'simple_mmap'
require 'webink/beauty'
require 'test/unit'

config = {
  'db_type' => "sqlite3",
  'db_server' => "./test.sqlite"
}
model_classes = Array.new

Dir.chdir(File.dirname(__FILE__))

require "#{config["db_type"]}"
require 'webink'

models = Dir.new "./models"
models.each do |model|
  load "#{models.path}/#{model}" if model =~ /\.rb$/
  model_classes.push Ink::Model.classname($1) if model =~ /^(.*)\.rb$/
end

begin
  Ink::Database.create config
  db = Ink::Database.database
  db.tables.each do |t|
    db.query "DROP TABLE #{t}"
  end
  model_classes.each do |m|
    m.create.each do |exec|
      begin
        puts exec
        db.query exec
      rescue => ex
        puts ex
      end
    end
  end

  tests = Dir.new "./"
  tests.each do |t|
    load "#{tests.path}/#{t}" if t =~ /^tc_.*\.rb$/
  end
rescue Exception => bang
  puts "SQLError: #{bang}."
  puts bang.backtrace.join("\n")
end
