require 'fluent/plugin/input'
require 'azure_mgmt_monitor'

module Fluent::Plugin
class AzureMonitorMetricsInput < Input
  Fluent::Plugin.register_input("azuremonitormetrics", self)

  config_param :tag, :string
  config_param :tenant_id, :string, :default => nil
  config_param :client_id, :string, :default => nil
  config_param :client_secret, :string, :default => nil, :secret => true

  config_param :timespan, :integer, :default => 300
  config_param :interval, :string, :default => "PT1M"
  config_param :resource_uri, :string, :default => nil
  config_param :aggregation, :string, :default => nil
  config_param :top, :integer, :default => nil
  config_param :filter, :string, :default => nil
  config_param :resultType, :string, :default => nil
  config_param :metricnames, :string, :default => nil
  config_param :api_version, :string, :default => "2018-01-01"
  config_param :metricnamespace, :string, :default => nil
  config_param :orderby, :string, :default => nil

  def configure(conf)
    super
    provider = MsRestAzure::ApplicationTokenProvider.new(@tenant_id, @client_id, @client_secret)
    credentials = MsRest::TokenCredentials.new(provider)
    @client = Azure::Monitor::Mgmt::V2018_01_01::MonitorManagementClient.new(credentials);
  end

  def start
    super
    @watcher = Thread.new(&method(:watch))
  end

  def shutdown
    super
    @watcher.terminate
    @watcher.join
  end

  def set_path_options(start_time, end_time, custom_headers)
    fail ArgumentError, 'start_time is nil' if start_time.nil?

    request_headers = {}
    request_headers['Content-Type'] = 'application/json; charset=utf-8'

    # Set Headers
    request_headers['x-ms-client-request-id'] = SecureRandom.uuid
    request_headers['accept-language'] = @client.accept_language unless @client.accept_language.nil?

    timespanstring = "#{start_time.utc.iso8601}/#{end_time.utc.iso8601}"
    top = @filter.nil? ? nil : @top

    request_url = @client.base_url

    options = {
        middlewares: [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]],
        skip_encoding_path_params: {'resourceUri' => @resource_uri},
        query_params: {'timespan' => timespanstring,'interval' => @interval,'metricnames' => @metricnames,'aggregation' => @aggregation,'top' => top,'orderby' => @orderby,'$filter' => @filter,'resultType' => @resultType,'api-version' => @api_version,'metricnamespace' => @metricnamespace},
        headers: request_headers.merge(custom_headers || {}),
        base_url: request_url
    }
  end

  private

  def watch
    log.debug "azure monitor metrics: watch thread starting"
    @next_fetch_time = Time.now

    until @finished
        start_time = @next_fetch_time - @timespan
        end_time = @next_fetch_time

        log.debug "start time: #{start_time}, end time: #{end_time}"

        monitor_metrics_promise = get_monitor_metrics_async(start_time, end_time)
        monitor_metrics = monitor_metrics_promise.value!

        router.emit(@tag,  Fluent::Engine.now, monitor_metrics.body['value'])
        @next_fetch_time += @timespan
        sleep @timespan
    end
  end

  def get_monitor_metrics_async(start_time, end_time,filter = nil, custom_headers = nil)
    path_template = '{resourceUri}/providers/microsoft.insights/metrics'

    options = set_path_options(start_time, end_time, custom_headers)
    promise = @client.make_request_async(:get, path_template, options)

    promise = promise.then do |result|
      http_response = result.response
      status_code = http_response.status
      response_content = http_response.body
      unless status_code == 200
        error_model = JSON.load(response_content)
        fail MsRest::HttpOperationError.new(result.request, http_response, error_model)
      end
      
      result.request_id = http_response['x-ms-request-id'] unless http_response['x-ms-request-id'].nil?
      result.correlation_request_id = http_response['x-ms-correlation-request-id'] unless http_response['x-ms-correlation-request-id'].nil?
      result.client_request_id = http_response['x-ms-client-request-id'] unless http_response['x-ms-client-request-id'].nil?
      # Deserialize Response
      if status_code == 200
        begin
          result.body = response_content.to_s.empty? ? nil : JSON.load(response_content)
        rescue Exception => e
          fail MsRest::DeserializationError.new('Error occurred in deserializing the response', e.message, e.backtrace, result)
        end
      end
      result
    end
    promise.execute
  end
end
end
