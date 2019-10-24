require "faraday"
require "faraday_middleware"
require "active_support/core_ext/hash"

module Kuroko2
  class Updater
    class Client
      class Error < RuntimeError; end
      class Definition
        PATH = "definitions".freeze

        def list(tags = nil)
          response = client.get(PATH) do |req|
            req.params[:tags] = tags if tags
          end
          handle_errors(response)
          response.body.map(&:deep_symbolize_keys)
        end

        def create(params)
          log.info "creating: #{params[:name]}"
          response = client.post(PATH) do |req|
            req.body = params
          end
          handle_errors(response)
          response.body.deep_symbolize_keys
        end

        def update(params)
          params = params.dup
          id = params.delete(:id)
          log.info "updating: #{id} #{params[:name]}"
          response = client.put("#{PATH}/#{id}") do |req|
            req.body = params
          end
          handle_errors(response)
          true
        end

        def delete(params)
          params = params.dup
          id = params.delete(:id)
          log.info "deleting: #{id} #{params[:name]}"
          response = client.delete("#{PATH}/#{id}")
          handle_errors(response)
          true
        end

        private

          def handle_errors(response)
            fail Kuroko2::Updater::Client::Error, response.body["message"] unless response.success?
          end

          def log
            Logger.new(STDERR)
          end

          def client
            @_client ||= Faraday.new(url: ENV.fetch("KUROKO2_API_URL")) do |config|
              config.basic_auth(ENV.fetch("KUROKO2_API_USER"), ENV.fetch("KUROKO2_API_KEY"))
              config.use FaradayMiddleware::EncodeJson
              config.use FaradayMiddleware::ParseJson
              config.adapter Faraday.default_adapter
            end
          end
      end
    end
  end
end
