require 'google/protobuf/well_known_types'
require 'gruf'
require 'opencensus-proto/proto/agent/trace/v1/common_pb'
require 'opencensus-proto/proto/agent/trace/v1/trace_service_pb'
require 'opencensus-proto/proto/agent/trace/v1/trace_service_services_pb'

module OpenCensus
  module Trace
    module Exporters
      class OCAgent
        class Converter
          TraceProtos = ::OpenCensus::Proto::Trace
          AgentProtos = ::OpenCensus::Proto::Agent

          def convert_span
          end
        end
      end
    end
  end
end
