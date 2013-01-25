require_relative 'orm.rb'
module T
  class Test
    include Orm

    key :test
    key :test2

  end
end


t = T::Test.new

t.test = 'hello_world'
t.test2 = 'xxxxxxx'
# t.save

m = T::Test.find_by_test2('hello_world')
#
# p m.test2



