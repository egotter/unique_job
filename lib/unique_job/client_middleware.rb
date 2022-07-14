require 'unique_job/util'

module UniqueJob
  class ClientMiddleware
    include Util

    def initialize(redis_options)
      @redis_options = redis_options
    end

    def call(worker_str, job, queue, redis_pool, &block)
      if job.has_key?('at')
        # perform_in or perform_at
        yield
      else
        if worker_str.class == String
          worker = worker_str.constantize.new # Sidekiq < 6
        else
          worker = worker_str.new
        end
        perform(worker, job, &block)
      end
    end
  end
end
