dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'
require 'test/unit'
require 'rubygems'
require 'resque'

#
# make sure we can run redis
#

if !system("which redis-server") || !system("which redis-cli")
  puts '', "** missing redis-server and/or redis-cli"
  puts "** try running `sudo rake install`"
  abort ''
end


#
# start our own redis when the tests start,
# kill it when they end
#

at_exit do
  next if $!

  exit_code = Test::Unit::AutoRunner.run

  puts "Killing test redis server at localhost:9736..."
  `redis-cli -p 9736 shutdown`
  `rm -f #{dir}/dump.rdb`
  exit exit_code
end

puts "Starting redis for testing at localhost:9736..."
`redis-server #{dir}/redis-test.conf`
Resque.redis = 'localhost:9736'
