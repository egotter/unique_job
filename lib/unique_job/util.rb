require 'unique_job/logging'
require 'unique_job/job_history'

module UniqueJob
  module Util
    include Logging

    def perform(worker, job, &block)
      if worker.respond_to?(:unique_key)
        key = worker.unique_key(*job['args'])
        logger.debug { "[UniqueJob] Unique key calculated context=#{@context} worker=#{job['class']} key=#{key}" }

        if key.nil? || key.to_s.empty?
          logger.warn { "[UniqueJob] Skip history check context=#{@context} worker=#{job['class']} key=#{key}" }
          yield
        else
          if @history.exists?(job['class'], key)
            logger.info { "[UniqueJob] Duplicate job skipped context=#{@context} worker=#{job['class']} key=#{key}" }
            perform_callback(worker, :after_skip, job['args'])
            nil
          else
            logger.debug { "[UniqueJob] Start job context=#{@context} worker=#{job['class']} key=#{key}" }
            ttl = worker.respond_to?(:unique_in) ? worker.unique_in : 3600
            @history.add(job['class'], key, ttl)
            yield
          end
        end
      else
        yield
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
