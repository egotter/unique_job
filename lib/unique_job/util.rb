require 'unique_job/logging'
require 'unique_job/job_history'

module UniqueJob
  module Util
    include Logging

    def perform_if_unique(worker, args, &block)
      if worker.respond_to?(:unique_key)
        unique_key = worker.unique_key(*args)
        logger.debug { "[UniqueJob] Calculate unique key worker=#{worker.class} key=#{unique_key}" }

        if unique_key.nil? || unique_key.to_s.empty?
          logger.warn { "[UniqueJob] Don't check a job with a blank key worker=#{worker.class} key=#{unique_key}" }
          yield
        elsif check_uniqueness(worker, unique_key.to_s)
          yield
        else
          logger.debug { "[UniqueJob] Duplicate job skipped worker=#{worker.class} key=#{unique_key}" }
          perform_callback(worker, :after_skip, args)
          nil
        end
      else
        yield
      end
    end

    def check_uniqueness(worker, unique_key)
      history = job_history(worker)

      if history.exists?(unique_key)
        false
      else
        history.add(unique_key)
        true
      end
    end

    def job_history(worker)
      ttl = worker.respond_to?(:unique_in) ? worker.unique_in : 3600
      JobHistory.redis_options = @redis_options
      JobHistory.new(worker.class, self.class, ttl)
    end

    def truncate(text, length: 100)
      if text.length > length
        text.slice(0, length)
      else
        text
      end
    end

    def perform_callback(worker, callback_name, args)
      if worker.respond_to?(callback_name)
        parameters = worker.method(callback_name).parameters

        begin
          if parameters.empty?
            worker.send(callback_name)
          else
            worker.send(callback_name, *args)
          end
        rescue ArgumentError => e
          raise ArgumentError.new("[UniqueJob] Invalid parameters callback=#{callback_name}")
        end
      end
    end
  end
end
