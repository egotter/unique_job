require 'unique_job/util'

module UniqueJob
  class ServerMiddleware
    include Util

    def initialize(redis_options)
      @history = JobHistory.new(self.class.name, Redis.new(redis_options))
      @context = 'Server'
    end

    def call(worker, msg, queue, &block)
      perform(worker, msg, &block)
    end
  end
end
