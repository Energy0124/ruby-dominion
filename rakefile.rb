task :default => :test

task :test do
  $:.push File.dirname(__FILE__) + '/test'
  
  require 'test_cards'
  require 'test_game'
end