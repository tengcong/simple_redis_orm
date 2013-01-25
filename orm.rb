require 'redis'
# require 'redis'
#
module MyRedis
  # set_to_redis(, args[0])
  def set_to_redis key, value
    redis_object.set(key, value)
  end

  def get_from_redis key
    redis_object.get(key)
  end

  def redis_object
    @redis || @redis = Redis.new(:host => 'localhost', :port => 6379)
  end
end

module Orm
  def self.included base
    base.extend(ClassMethods)
    super
  end

  def save
    attributes.each do |k, v|
      MyRedis::set_to_redis(generate_key(k.to_s), v)
    end
  end

  def generate_key(attr)
    "#{self.class.name.downcase}:#{attr}"
  end

  def attributes
   @attributes
  end

  def add_attributes k, v
    @attributes ||= {}
    @attributes[k] = v
  end

  module ClassMethods

    def method_missing method_name, *args, &blk
      if(method_name =~ /find_by_(.+)/)
        key = self.name.downcase << ':' << $1
        MyRedis::get_from_redis()
      else
        raise Exception.new 'not such method'
      end
    end

    def key attr
      attr_name = attr.to_s

      define_method "#{attr.to_s}=".to_sym do |*args|
        instance_variable_set("@#{attr_name}", args[0])
        add_attributes(attr, args[0])
      end

      define_method "#{attr.to_s}".to_sym do |*args|
        instance_variable_get("@#{attr_name}")
      end
    end
  end
end

