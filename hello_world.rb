require 'redis'
require 'json'

redis = Redis.new(:host => 'localhost', :port => 6379)

redis.set('first_one', 'hello world')

p redis.get('first_one')

redis.set('json_test', [1,2,3].to_json)

p redis.get('json_test')


redis.pipelined do
  redis.set('pipe', 'pipe --')
  redis.incr('incr')
end

p redis.get('incr')

puts <<-EOS
To play with this example use redis-cli from another terminal, like this:

  $ redis-cli publish one hello

Finally force the example to exit sending the 'exit' message with:

  $ redis-cli publish two exit

EOS

trap(:INT){puts 'bye'; exit }

begin
  redis.subscribe(:one, :two) do |on|
    on.subscribe do |channel, subscriptions|
      puts "subscribe to channel ##{channel} (#{subscriptions} subscriptions)"
    end

    on.message do |channel, message|
      puts "##{channel}: #{message}"
      p channel.class.name
      redis.unsubscribe(channel) if message == 'exit'
    end

    on.unsubscribe do |channel, subscriptions|
      puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
    end
  end

rescue Redis::BaseConnectionError => error
  puts "#{error}"
  sleep 1
  retry
end
