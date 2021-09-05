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

          def convert_span(span_data)
            return if span_data.nil?

            span_proto = TraceProtos::V1::Span.new(
              name: truncatable_string(span.new),
              kind: span_data.span_kind,
              trace_id: hex_to_bytes(span_data.context.trace_id),
              span_id: hex_to_bytes(span_data.context.span_id),
              parent_span_id: hex_to_bytes(span_data.context.parent_span_id) if span_data.context.parent_span_id,
              start_time: pb_timestamp(span_data.start_time),
              end_time: pb_timestamp(span_data.end_time),
              status: TraceProtos::V1::Status.new(
                code: span_data.status.canonical_code,
                message: span_data.status.description,
              ) if span_data.status,
             child_span_count: Google::Protobuf::UInt32Value.new(value: span_data.child_span_count) if span_data.child_span_count,
            )

            # Set span attributes
            span_data.attributes&.each do |key, value|
              add_pb_attributes(span_proto.attributes, key, value)
            end

            # Set span annotations
            span_data.annotations&.each do |annotation|
              next if annotation.attributes.nil?

              annotation.attributes.each do |key, val|
                ad_pb_attributes(span_proto.attributes, key, val)
              end
            end

            # Set message events
            span_data.message_events&.each do |event|
              # TODO: I don't know if this works
              proto_event = span_proto.time_events.time_event.new()
              proto_event.time = Google::Protobuf::Timestamp.new.from_time(Time.parse(event.timestamp))
              proto_event.type = event.type
              proto_event.id = event.id
              proto_event.uncompressed_size = event.uncompressed_size_bytes
              proto_event.compressed_size = event.compressed_size_bytes
            end

            # Span links
            span_data.links&.each do |link|
              proto_link = span_proto.link.new(trace_id: hex_to_bytes(link.trace_id),
                                               span_id: hex_to_bytes(link.span_id),
                                               type: link.type)
              link.attributes&.attributes&.each do |key, val|
                add_pb_attributes(span_proto.attributes, key, val)
              end
            end

            span_data.context.tracestate&.each do |key, val|
              span_proto.tracestate.entries.new(key: key, val: val)
            end

            span_proto
          end

          def truncatable_string(str, truncated_byte_count = 0)
            TraceProtos::V1::TruncatableString.new(value: str, truncated_byte_count: truncated_byte_count)
          end

          def pb_timestamp(time)
            Google::Protobuf::Timestamp.new.from_time(time)
          end

          def add_pb_attributes(pb_attributes, key, value)
            case value.class
            when TrueClass || FalseClass
              pb_attributes.attribute_map[key].bool_value = value
            when Integer
              pb_attributes.attribute_map[key].int_value = value
            when String
              pb_attributes.attribute_map[key].string_value = value
            when Float
              pb_attributes.attribute_map[key].double_value = value
            else
              pb_attributes.attribute_map[key].string_value = value
            end
          end

          def hex_to_bytes(hex)
            hex.pack("H*").unpack("C*")
          end
        end
      end
    end
  end
end
