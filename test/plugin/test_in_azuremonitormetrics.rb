require 'fluent/test/helpers'
require 'helper'
require "fluent/test/driver/input"
require "fluent/plugin/in_azuremonitormetrics"

class AzureMonitorMetricsInputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  ### for monitor metrics
  CONFIG_MONITOR_METRICS = %[
    tag azuremonitormetrics
    tenant_id test_tenant_id
    client_id test_client_id
    client_secret test_client_secret

    timespan          300
    interval          PT1M
    resource_uri      /subscriptions/b324c52b-4073-4807-93af-e07d289c093e/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/larryshoebox/blobServices/default/providers/Microsoft.Insights/metrics/BlobCapacity
    aggregation       Average,count
    top               20
    filter            A eq 'a1' and B eq '*'
    resultType       Success
    metricnames      Percentage CPU
    api_version      2018-01-01
    metricnamespace  Microsoft.Storage/storageAccounts/blobServices
    orderby          Average asc  
  ]

  def create_driver_monitor_metrics(conf = CONFIG_MONITOR_METRICS)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::AzureMonitorMetricsInput).configure(conf)
  end

  def setup
    Fluent::Test.setup
  end

  sub_test_case 'configuration' do
    
    test 'configuration parameters for monitor metrics' do
      d = create_driver_monitor_metrics
      assert_equal 'azuremonitormetrics', d.instance.tag
      assert_equal 'test_tenant_id', d.instance.tenant_id
      assert_equal 'test_client_id', d.instance.client_id
      assert_equal 300, d.instance.timespan
      assert_equal 'PT1M', d.instance.interval
      assert_equal '/subscriptions/b324c52b-4073-4807-93af-e07d289c093e/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/larryshoebox/blobServices/default/providers/Microsoft.Insights/metrics/BlobCapacity', d.instance.resource_uri
      assert_equal 'Average,count', d.instance.aggregation
      assert_equal 20, d.instance.top
      assert_equal 'A eq \'a1\' and B eq \'*\'', d.instance.filter
      assert_equal 'Success', d.instance.resultType
      assert_equal 'Percentage CPU', d.instance.metricnames
      assert_equal '2018-01-01', d.instance.api_version
      assert_equal 'Microsoft.Storage/storageAccounts/blobServices', d.instance.metricnamespace
      assert_equal 'Average asc', d.instance.orderby
    end

    test 'configuration query options for monitor metrics' do
      d = create_driver_monitor_metrics
      start_time = Time.now - 1000
      end_time = Time.now
      query_options = d.instance.set_path_options(start_time, end_time, {})
      assert_equal '2018-01-01', query_options[:query_params]['api-version']
      assert_equal 'A eq \'a1\' and B eq \'*\'', query_options[:query_params]['$filter']
      assert_equal 'Average,count', query_options[:query_params]['aggregation']
      assert_equal 'PT1M', query_options[:query_params]['interval']
      assert_equal 20, query_options[:query_params]['top']
      assert_equal 'Success', query_options[:query_params]['resultType']
      assert_equal 'Percentage CPU', query_options[:query_params]['metricnames']
      assert_equal '/subscriptions/b324c52b-4073-4807-93af-e07d289c093e/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/larryshoebox/blobServices/default/providers/Microsoft.Insights/metrics/BlobCapacity', query_options[:skip_encoding_path_params]['resourceUri']
      assert_equal 'Microsoft.Storage/storageAccounts/blobServices', query_options[:query_params]['metricnamespace'] 
      assert_equal 'Average asc', query_options[:query_params]['orderby']
    end
  end
end
