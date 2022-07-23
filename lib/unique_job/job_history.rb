require 'unique_job/logging'

module UniqueJob
  class JobHistory
    include Logging

    def initialize(middleware_name, redis)
      @key_prefix = "#{self.class}:#{middleware_name.split('::')[-1]}"
      @redis = redis
    end

    def exists?(v1, v2)
      @redis.exists?(key(v1, v2))
    rescue => e
      logger.warn { "[UniqueJob] Redis#exists? failed v1=#{v1} v2=#{v2} exception=#{e.inspect}" }
      nil
    end

    def add(v1, v2, ttl)
      @redis.setex(key(v1, v2), ttl, true)
    rescue => e
      logger.warn { "[UniqueJob] Redis#setex failed v1=#{v1} v2=#{v2} ttl=#{ttl} exception=#{e.inspect}" }
      nil
    end

    private

    def key(v1, v2)
      "#{@key_prefix}:#{v1}:#{v2}"
    end
  end
end
