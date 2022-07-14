require 'unique_job/util'

module UniqueJob
  class ServerMiddleware
    include Util

    def initialize(redis_options)
      @redis_options = redis_options
    end

    def call(worker, msg, queue, &block)
      perform(worker, msg, &block)
    end
  end
end
