require_relative 'orm.rb'
module T
  class Test
    include Orm

    key :test
    key :test2
  end
end


t = T::Test.new

# t.test = 'hello_world'
# t.test2 = 'x123xxxxxx'
# t.id = 31133
# t.save

values = T::Test.find_by_test('hello_world')

p values.map(&:attributes)

