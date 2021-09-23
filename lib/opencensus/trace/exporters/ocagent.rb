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
require 'opencensus/trace/exporters/ocagent/converter'
require 'opencensus/proto/agent/common/v1/common_pb'
require 'opencensus/proto/agent/trace/v1/trace_service_pb'
require 'opencensus/proto/agent/trace/v1/trace_service_services_pb'

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
        attr_reader :client, :endpoint, :node, :service_name

        ## Create an OpenCensusTrace exporter
        #
        # @param [String] :service_name The name of the service to report in traces.
        # @param [optional String] :host_name The host_name of the node.
        # @param [optional String] :endpoint The endpoint to forward the OpenCensus traces.
        # @param [optional Gruf::Client] :client The gRPC client used to export OC traces.
        # @param [optional Integer] :max_queue The max number of API requests that can be queued.
        # @param [optional Integer] :max_threads the max number of threads to process requests.
        def initialize(service_name:, host_name: nil, endpoint: nil, client: nil, max_queue: 1000, max_threads: 1)
          @endpoint = endpoint || DEFAULT_ENDPOINT
          @client = client || ::Gruf::Client.new(
            service: ::OpenCensus::Proto::Agent::Trace::V1::TraceService,
            options: { hostname: @endpoint },
          )
          @service_name = service_name
          @node = get_node(service_name: @service_name, host_name: host_name)
        end

        ## Export spans to OpenCensus synchronously, for now.
        #
        # @param [Array<OpenCensus::Trace::Span>] :spans The captured spans to forward to the trace server.
        #
        def export(spans)
          responses = client.call(:Export, generate_span_requests(spans)) # This is where the span requests go
          puts("Responses: #{responses}")
        rescue ::Gruf::Client::Error => e
          puts("Error: #{e}")
        end

        def generate_span_requests(spans)
          span_protos = span_datas.map { |span_data| Converter.new(spans) }

          ::OpenCensus::Proto::Agent::Trace::V1::ExportTraceServiceRequest.new(node: node, spans: span_protos)
        end

        private

        def get_node(service_name:, host_name: nil)
          time = Time.current

          OpenCensus::Proto::Agent::Common::V1::Node.new(
            identifier: OpenCensus::Proto::Agent::Common::V1::ProcessIdentifier.new(
              host_name: host_name || Socket.gethostname,
              pid: Process.pid,
              start_timestamp: Google::Protobuf::Timestamp.new(seconds: time.to_i, nanos: time.nsec),
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
