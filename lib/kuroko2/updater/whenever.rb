require "whenever"

module Kuroko2
  class Updater
    module Whenever
      class ::Whenever::Job
        def task
          @options[:task]
        end

        protected

          # patch whenever not to chomp newlines, as kuroko2 scripts need them
          def process_template(template, options)
            template.gsub(/:\w+/) do |key|
              before_and_after = [$`[-1..-1], $'[0..0]]
              option = options[key.sub(":", "").to_sym] || key

              if before_and_after.all? { |c| c == "'" }
                escape_single_quotes(option)
              elsif before_and_after.all? { |c| c == '"' }
                escape_double_quotes(option)
              else
                option
              end
            end.strip
          end
      end

      class ::Whenever::JobList
        def time_and_jobs
          @jobs.values.reduce({}, :merge)
        end
      end
    end
  end
end
