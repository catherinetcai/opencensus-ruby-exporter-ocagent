# frozen_string_literal: true

# Copyright 2019 OpenCensus Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/protobuf/well_known_types'
require 'gruf'
require 'opencensus/trace/exporters/ocagent/export_request_enumerator'
require 'opencensus/trace/exporters/ocagent/converter'
require 'opencensus/proto/agent/common/v1/common_pb'
require 'opencensus/proto/agent/trace/v1/trace_service_pb'
require 'opencensus/proto/agent/trace/v1/trace_service_services_pb'
require 'concurrent'

module OpenCensus
  ## OpenCensus Trace collects distributed traces
  module Trace
    ## Exporters for OpenCensus Trace
    module Exporters
      # Default OCAgent endpoint
      DEFAULT_ENDPOINT = 'localhost:55678'
      # OCAgent exporter version
      EXPORTER_VERSION = '0.0.1'
      CORE_LIBRARY_VERSION = '0.11.1'

      ## OpenCensus Agent exporter for Trace
      class OCAgent
        attr_reader :client_promise, :endpoint, :node, :service_name

        ## Create an OpenCensusTrace exporter
        #
        # @param [String] :service_name The name of the service to report in traces.
        # @param [optional String] :host_name The host_name of the node.
        # @param [optional String] :endpoint The endpoint to forward the OpenCensus traces.
        # @param [optional Gruf::Client] :client_promise The gRPC client used to export OC traces.
        # @param [optional Integer] :max_queue The max number of API requests that can be queued.
        # @param [optional Integer] :max_threads the max number of threads to process requests.
        def initialize(service_name:, host_name: nil, endpoint: nil, client_promise: nil, max_queue: 1000, max_threads: 1)
          @endpoint = endpoint || DEFAULT_ENDPOINT
          @pool = initialize_pool(max_queue, max_threads)
          @client_promise = client_promise || create_client_promise(@pool, ::OpenCensus::Proto::Agent::Trace::V1::TraceService, @endpoint)
          @service_name = service_name
          @node = get_node(service_name: @service_name, host_name: host_name)
        end

        ## Export spans to OpenCensus synchronously, for now.
        #
        # @param [Array<OpenCensus::Trace::Span>] :spans The captured spans to forward to the trace server.
        #
        def export(spans)
          return if spans.nil? || spans.empty?

          client_promise.execute
          export_promise = client_promise.then do |client|
            client.call(:Export, generate_span_requests(spans).each_item) do |r|
              puts "Received a response: #{r.inspect}"
            end
          end

          export_promise.on_error do |reason|
            puts "Error sending trace because: #{e}"
          end
        rescue ::Gruf::Client::Error => e
          puts("Error: #{e.error.inspect}")
        end

        def generate_span_requests(spans)
          span_protos = spans.map { |span| Converter.new.convert_span(span) }

          ::OpenCensus::Trace::Exporters::OCAgent::ExportRequestEnumerator.new([::OpenCensus::Proto::Agent::Trace::V1::ExportTraceServiceRequest.new(node: node, spans: span_protos)])
        end

        private

        def create_client_promise(pool, service, options)
          Concurrent::Promise.new(executor: pool) do
            ::Gruf::Client.new(
              service: service,
              options: options,
            )
          end
        end

        def initialize_pool(max_threads, max_queue)
          Concurrent::ThreadPoolExecutor.new(
            min_threads: 1,
            max_threads: max_threads,
            max_queue: max_queue,
            fallback_policy: :caller_runs,
            auto_terminate: false,
          )
        end

        def get_node(service_name:, host_name: nil)
          time = Time.current

          OpenCensus::Proto::Agent::Common::V1::Node.new(
            identifier: OpenCensus::Proto::Agent::Common::V1::ProcessIdentifier.new(
              host_name: host_name || Socket.gethostname,
              pid: Process.pid,
              start_timestamp: Converter.new.pb_timestamp(time),
            ),
            library_info: OpenCensus::Proto::Agent::Common::V1::LibraryInfo.new(
              language: OpenCensus::Proto::Agent::Common::V1::LibraryInfo::Language::RUBY,
              exporter_version: EXPORTER_VERSION,
              core_library_version: CORE_LIBRARY_VERSION,
            ),
            service_info: OpenCensus::Proto::Agent::Common::V1::ServiceInfo.new(name: service_name),
          )
        end
      end
    end
  end
end
