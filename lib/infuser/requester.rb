require 'xmlrpc/client'

module Infuser
  class Requester

    def initialize access_token
      @access_token = access_token
    end

    def get service_call, *args
      reset!
      connection service_call, *args
    end


    private

    def connection service_call, *args
      retry? ? retrying! : raise(Infuser::Error, 'Call failed and retries exhausted.')

      begin
        binding.pry
        logger.info "CALL: #{service_call} at: #{Time.now} args: #{args.inspect} #{options.api_key}"
        result = client.call(service_call, options.api_key, *args)
        connection(service_call, *args) if result.nil?
      rescue Timeout::Error => timeout
        connection(service_call, *args)
      rescue XMLRPC::FaultException => xmlrpc_error
        Infuser::ExceptionHandler.new(xmlrpc_error)
      rescue RuntimeError => e
        e.message.include?('Authorization failed') ? raise(Infuser::ExpiredToken, "Access token is expired or invalid.") : raise
      end

      logger.info "RESULT: #{result.inspect}"
      return result
    end

    def retry?
      retry_count <= options.retry_count
    end

    def retrying!
      @retry_count += 1
    end

    def retry_count
      @retry_count ||= 0
    end

    def reset!
      @retry_count = 0
    end

    def options
      Infuser::Configuration
    end

    def logger
      options.logger
    end

    def access_token
      @access_token || raise(Infuser::ArgumentError, 'You must specify an access token. See documentation.')
    end

    def client
      @client ||= begin
        client = XMLRPC::Client.new3({
          'host'    => 'api.infusionsoft.com',
          'path'    => "/crm/xmlrpc/v1?access_token=#{access_token}",
          'port'    => 443,
          'use_ssl' => true
        })
        client.http_header_extra = { 'User-Agent' => options.user_agent }
        client.http_header_extra = { "accept-encoding" => "identity" }
        client
      end
    end

  end
end
