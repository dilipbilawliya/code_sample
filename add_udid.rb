# frozen_string_literal: true

module IntegrationWorkflows
  module Kaiterra
    class AddUdid < Workflow
      option :username
      option :password
      option :udid

      Schema = Dry::Schema.Params do
        required(:username).filled(:string)
        required(:password).filled(:string)
        required(:udid).filled(:string)
      end

      API_RESOURCE = RestClient::Resource.new('https://api.kaiterra.com')

      def call
        token = fetch_token
        post(token)
      rescue KaiterraError => e
        Failure.new(e.message)
      end

      private

      def post(token)
        response = API_RESOURCE['/v1/account/me/device'].post(json_post_data, headers(token))
        Success.new JSON.parse(response)
      rescue RestClient::ExceptionWithResponse => e
        Failure.new format_error_from_kaiterra(e.response)
      rescue Timeout::Error,
             Errno::EINVAL,
             Errno::ECONNRESET,
             EOFError,
             SocketError,
             Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError,
             Net::ProtocolError => e # Ruby Http errors
        Failure.new e.message
      end

      def format_error_from_kaiterra(response)
        json = JSON.parse(response)
        if json['error'].present? && json['error']['uuid'].present? && json['error']['uuid'] == 'invalid'
          return I18n.t('integrations.kaiterra.error.invalid_udid')
        end

        I18n.t('integrations.kaiterra.error.cannot_add_device_to_kaiterra')
      rescue StandardError => _e
        I18n.t('integrations.kaiterra.error.cannot_add_device_to_kaiterra')
      end

      def headers(token)
        {
          'Content-Type': 'application/json',
          Authorization:  "Bearer #{token}"
        }
      end

      def json_post_data
        {
          uuid: udid
        }.to_json
      end

      def fetch_token
        result = IntegrationWorkflows::Kaiterra::FetchBearerToken.call(username: username, password: password)
        raise KaiterraError, I18n.t('integrations.kaiterra.error.cannot_add_device_to_kaiterra') if result.failure?

        result.value!['token']
      end
    end
  end
end
