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
require 'opencensus-proto/proto/agent/trace/v1/common_pb'
require 'opencensus-proto/proto/agent/trace/v1/trace_service_pb'
require 'opencensus-proto/proto/agent/trace/v1/trace_service_services_pb'

module OpenCensus
  ## OpenCensus Trace collects distributed traces
  module Trace
    ## Exporters for OpenCensus Trace
    module Exporters
      # Default OCAgent endpoint
      DEFAULT_ENDPOINT = 'localhost:55678'
      # OCAgent exporter version
      EXPORTER_VERSION = '0.0.1'

      ## OpenCensus Agent exporter for Trace
      class OCAgent
        attr_reader :client, :endpoint, :node, :service_name

        def initialize(service_name:, host_name: nil, endpoint: nil, client: nil)
          @endpoint = endpoint || DEFAULT_ENDPOINT
          @client = client || ::Gruf::Client.new(
            service: ::OpenCensus::Proto::Agent::Trace::V1::TraceService,
            options: { hostname: endpoint },
          )
          @service_name = service_name
          @node = get_node(service_name: service_name, host_name: host_name)
        end

        def emit(span_datas)
          responses = client.call(:Export,
        end

        def export(span_datas)
        end

        def generate_span_requests(span_datas)

        end

        private

        def get_node(service_name:, host_name: nil)
          OpenCensus::Proto::Agent::Common::V1::Node.new(
            identifier: OpenCensus::Proto::Agent::Common::V1::ProcessIdentifier.new(
              host_name: host_name || Socket.gethostname,
              pid: Process.pid,
              start_timestamp: Google::Protobuf::Timestamp.new.from_time(Time.new.utc),
            ),
            library_info: OpenCensus::Proto::Agent::Common::V1::LibraryInfo.new(
              language: OpenCensus::Proto::Agent::Common::V1::LibraryInfo::RUBY,
              exporter_version: EXPORTER_VERSION,
              core_library_version: #TODO,
            ),
            service_info: OpenCensus::Proto::Agent::Common::V1::ServiceInfo.new(name: service_name),
          )
        end

        def translate_to_trace_proto(span_data)
          return if span_data.nil?

          span_proto = OpenCensus::Proto::Trace::V1::Span.new(
            name: OpenCensus::Proto::Trace::V1::TruncatableString,
            kind: span_data.span_kind,
            trace_id: hex_to_bytes(span_data.context.trace_id),
            span_id: hex_to_bytes(span_data.context.span_id),
            parent_span_id: hex_to_bytes(span_data.context.parent_span_id) if span_data.context.parent_span_id,
            start_time: Google::Protobuf::Timestamp.new.from_time(span_data.start_time),
            end_time: Google::Protobuf::Timestamp.new.from_time(span_data.end_time),
            status: OpenCensus::Proto::Trace::V1::Status.new(
              code: span_data.status.canonical_code,
              message: span_data.status.description,
            ) if span_data.status,
           child_span_count: Google::Protobuf::UInt32Value.new(value: span_data.child_span_count) if span_data.child_span_count,
          )

          # Set span attributes
          if span_data.attributes
            span_data.attributes.each do |key, value|
              case value.class
              when TrueClass || FalseClass
                span_proto.attributes.attribute_map[key].bool_value = value
              when Integer
                span_proto.attributes.attribute_map[key].int_value = value
              when String
                span_proto.attributes.attribute_map[key].string_value = value
              when Float
                span_proto.attributes.attribute_map[key].double_value = value
              else
                span_proto.attributes.attribute_map[key].string_value = value
              end
            end
          end

          # Set span annotations
          if span_data.annotations
            span_data.annotations.each do |annotation|
            end
          end
        end

        def hex_to_bytes(hex)
          hex.pack("H*").unpack("C*")
        end
      end
    end
  end
end
