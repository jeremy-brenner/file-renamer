$:.push File.expand_path('../lib',__FILE__)

require 'renamer'

Renamer.new(ARGV[0])
