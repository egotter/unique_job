require 'unique_job/logging'
require 'unique_job/job_history'

module UniqueJob
  module Util
    include Logging

    def perform(worker, job, &block)
      if worker.respond_to?(:unique_key)
        unique_key = worker.unique_key(*job['args'])
        logger.debug { "[UniqueJob] Unique key calculated worker=#{job['class']} key=#{unique_key}" }

        if unique?(worker, unique_key)
          yield
        else
          logger.debug { "[UniqueJob] Duplicate job skipped worker=#{job['class']} key=#{unique_key}" }
          perform_callback(worker, :after_skip, job['args'])
          nil
        end
      else
        yield
      end
    end

    def unique?(worker, key)
      if key.nil? || key.to_s.empty?
        logger.warn { "[UniqueJob] Don't check a job with a blank key worker=#{worker.class} key=#{key}" }
        return false
      end

      history = job_history(worker)

      if history.exists?(key)
        false
      else
        history.add(key)
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
