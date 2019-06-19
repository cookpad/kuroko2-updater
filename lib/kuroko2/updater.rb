require "kuroko2/updater/version"
require "kuroko2/updater/whenever"
require "kuroko2/updater/client/definition"
require "logger"

module Kuroko2
  class Updater
    class ValidationError < RuntimeError; end

    def initialize(job_list:, client: Kuroko2::Updater::Client::Definition.new)
      @client = client
      @job_list = job_list
    end

    def run
      validate_job_list

      to_delete.each { |job| client.delete(job) }
      to_create.each { |job| client.create(job) }
      to_update.each { |job| client.update(job) }
    end

    private

      def validate_job_list
        fail ValidationError, ":kuroko2_tags was not set set in the config file" unless tags.any?
        fail ValidationError, ":kuroko2_users was not set in the config file" unless users.any?
        fail ValidationError, "#{duplicated_jobs.join(',')} was specified more than once" if duplicated_jobs.any?
      end

      def duplicated_jobs
        names = desired_jobs.map { |job| job[:name] }
        names.select { |name| names.count(name) > 1 }.uniq
      end

      def to_delete
        existing_jobs.reject do |existing_job|
          desired_jobs.any? do |desired_job|
            desired_job[:name] == existing_job[:name]
          end
        end
      end

      def to_create
        desired_jobs.reject do |desired_job|
          existing_jobs.any? do |existing_job|
            desired_job[:name] == existing_job[:name]
          end
        end
      end

      def to_update
        (desired_jobs - to_create).map do |job|
          job[:id] = id_for(job)
          job
        end
      end

      def id_for(job)
        existing_jobs.find { |existing_job| existing_job[:name] == job[:name] }[:id]
      end

      def existing_jobs
        @_existing_jobs ||= client.list(tags)
      end

      def desired_jobs
        @_desired_jobs ||= job_list.time_and_jobs.flat_map do |time, jobs|
          jobs.map do |job|
            {
              name: job.task,
              script: job.output,
              description: job_description,
              cron: cron(time, job),
              slack_channel: slack_channel,
              user_id: users,
              tags: tags,
              hipchat_notify_finished: notify_finished,
              notify_cancellation: notify_cancellation
            }
          end
        end
      end

      def slack_channel
        job_list.kuroko2_slack_channel
      rescue NoMethodError
        nil
      end

      def job_description
        job_list.kuroko2_job_description
      rescue NoMethodError
        <<~DESC
          This job is managed by an automation tool.

          **Warning DO NOT EDIT**

          Please do not edit this job definition directly.
        DESC
      end

      def notify_finished
        job_list.kuroko2_notify_finished
      rescue NoMethodError
        false
      end

      def notify_cancellation
        job_list.kuroko2_notify_cancellation
      rescue NoMethodError
        true
      end

      def tags
        job_list.kuroko2_tags
      rescue NoMethodError
        []
      end

      def users
        job_list.kuroko2_users
      rescue NoMethodError
        []
      end

      def cron(time, job)
        if job.at
          if job.at.respond_to?(:map)
            job.at.map do |at|
              ::Whenever::Output::Cron.new(time, nil, at).time_in_cron_syntax
            end
          else
            [::Whenever::Output::Cron.new(time, nil, job.at).time_in_cron_syntax]
          end
        else
          [::Whenever::Output::Cron.new(time).time_in_cron_syntax]
        end
      end

      attr_reader :job_list, :client
  end
end
