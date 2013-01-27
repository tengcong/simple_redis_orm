require 'redis'

module MyRedis
  extend self

  def keys_of(key)
    redis_object.keys(key)
  end
  def set_to_redis(key, value)
    redis_object.set(key, value)
  end

  def get_from_redis(key)
    redis_object.get(key)
  end

  def redis_object
    @redis || @redis = Redis.new(:host => 'localhost', :port => 6379)
  end
end

module Orm
  def self.included(base)
    base.extend(ClassMethods)
    super
  end

  attr_accessor :id

  def save
    attributes.each do |k, v|
      MyRedis::set_to_redis(generate_key(k.to_s), v)
    end
  end

  def generate_key(attr)
    "#{self.class.name.downcase}:#{self.id}:#{attr}"
  end

  def attributes
   @attributes
  end

  def add_attributes(k, v)
    @attributes ||= {}
    @attributes[k] = v
  end

  module ClassMethods

    def key(attr)
      attr_name = attr.to_s

      define_method "#{attr.to_s}=".to_sym do |*args|
        instance_variable_set("@#{attr_name}", args[0])
        add_attributes(attr, args[0])
      end

      define_method "#{attr.to_s}".to_sym do |*args|
        instance_variable_get("@#{attr_name}")
      end
    end

    def method_missing(method_name, *args, &blk)
      if(method_name =~ /find_by_(.+)/)
        clazz = self.name.downcase
        ids_collection = key_to_ids(clazz, "#{clazz}:*", $1)
        ids = ids(ids_collection, clazz, $1, args[0])
        package_object(ids, clazz)
      else
        raise Exception.new 'not such method'
      end
    end

    private
    def package_object(ids, clazz)
      values = []
      ids.each do |id|
        ret_val = self.new
        MyRedis.keys_of("#{clazz}:#{id}:*").each do |key|
          attr = key =~ (/#{clazz}:#{id}:(.+)/) && $1
          ret_val.send(attr + '=', MyRedis.get_from_redis("#{clazz}:#{id}:#{attr}"))
          ret_val.id = id
        end
        values << ret_val
      end
      values
    end

    def ids(ids_collection, clazz, attr_name, val)
      ids_collection.select do |id|
        MyRedis.get_from_redis("#{clazz}:#{id}:#{attr_name}") == val
      end
    end

    def key_to_ids(clazz, pattern, attr_name)
      MyRedis.keys_of(pattern).map do |key|
        key =~ /#{clazz}:(.+):(.+)/ && $2 == attr_name; $1
      end.uniq.compact
    end
  end
end

