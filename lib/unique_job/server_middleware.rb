require 'unique_job/util'

module UniqueJob
  class ServerMiddleware
    include Util

    def initialize(redis_options)
      @redis_options = redis_options
    end

    def call(worker, msg, queue, &block)
      perform_if_unique(worker, msg, &block)
    end
  end
end
