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

          def initialize_clone
            @stack_trace_hash_ids = {}
          end

          def convert_span(span_data)
            return if span_data.nil?

            TraceProtos::V1::Span.new(
              name: truncatable_string(span.name),
              kind: span_data.span_kind,
              trace_id: hex_to_bytes(span_data.context.trace_id),
              span_id: hex_to_bytes(span_data.context.span_id),
              parent_span_id: span_data.context.parent_span_id ? hex_to_bytes(span_data.context.parent_span_id) : "",
              start_time: pb_timestamp(span_data.start_time),
              end_time: pb_timestamp(span_data.end_time),
              status: pb_status(span_data.status),
              child_span_count: Google::Protobuf::UInt32Value.new(value: span_data.child_span_count) if span_data.child_span_count,
              attributes: convert_attributes(span_data.attributes, span_data.dropped_attributes_count),
              stack_trace: convert_stack_trace(span_data.stack_trace,
                                               span_data.dropped_frames_count,
                                               span_data.stack_trace_hash_id),
              time_events: convert_time_events(span_data.time_events,
                                               span_data.dropped_annotations_count,
                                               span_data.dropped_message_events_count),
              links: convert_links(span_data.links, span_data.dropped_links_count),
              same_process_as_parent_span: Google::Protobuf::BoolValue.new(value: span_data.same_process_as_parent_span) if span_data.same_process_as_parent_span,
            )
          end

          def truncatable_string(str, truncated_byte_count = 0)
            TraceProtos::V1::TruncatableString.new(value: str, truncated_byte_count: truncated_byte_count)
          end

          def pb_timestamp(time)
            Google::Protobuf::Timestamp.new.from_time(time)
          end

          def pb_status(status)
            return if status.nil?

            TraceProtos::V1::Status.new(
              code: status.canonical_code,
              message: status.description
            )
          end

          def convert_attributes(attributes, dropped_attributes_count)
            attribute_map = {}

            attributes.each do |key, val|
              attribute_map[key] = convert_attribute_value(val)
            end
            TraceProtos::V1::Span::Attributes.new(
              attribute_map: attribute_map,
              dropped_attributes_count: dropped_attributes_count
            )
          end

          def convert_attribute_value(value)
            case value
            when OpenCensus::Trace::TruncatableString
              TraceProtos::V1::AttributeValue.new(string_value: truncatable_string(value))
            when TrueClass || FalseClass
              TraceProtos::V1::AttributeValue.new(bool_value: value)
            when Integer
              TraceProtos::V1::AttributeValue.new(int_value: value)
            else
              puts("Can't handle value type: #{value}")
            end
          end

          def convert_stack_trace(stack_trace, dropped_frames_count, stack_trace_hash_id)
            # If the hash id already exists, then just return
            if @stack_trace_hash_ids[stack_trace_hash_id]
              return TraceProtos::V1::StackTrace.new(stack_trace_hash_id: stack_trace_hash_id)
            end

            # Otherwise, construct
            @stack_trace_hash_ids[stack_trace_hash_id] = true
            frame_protos = stack_trace.map { |frame| convert_stack_frame(frame) }
            frames_proto = TraceProtos::V1::StackTrace::StackFrames.new(
              frame: frame_protos,
              dropped_frames_count: dropped_frames_count
            )

            TraceProtos::V1::StackTrace.new(stack_frames: frames_proto, stack_trace_hash_id: stack_trace_hash_id)
          end

           # https://ruby-doc.org/core-2.5.0/Thread/Backtrace/Location.html
          def convert_stack_frame(frame)
            TraceProtos::V1::StackTrace::StackFrame.new(
              function_name: truncatable_string(frame.label),
              file_name: truncatable_string(frame.path),
              line_number: frame.lineno
            )
          end


          def convert_time_events(events, dropped_annotations_count, dropped_message_events_count)
            event_protos = events.map do |event|
              case event
              when OpenCensus::Trace::Annotation
                convert_annotation(event)
              when OpenCensus::Trace::MessageEvent
              else
                nil
              end
            end.compact

            TraceProtos::Span::TimeEvents.new(
              time_event: event_protos,
              dropped_annotations_count: dropped_annotations_count,
              dropped_message_events_count: dropped_message_events_count
            )
          end

          def convert_link(link)
            TraceProtos::V1::Span::Link.new(
              trace_id: link.trace_id,
              span_id: link.span_id,
              type: link.type,
              attributes: convert_attributes(link.attributes, link.dropped_attributes_count)
            )
          end

          def convert_annotation(annotation)
            proto = TraceProtos::V1::Span::TimeEvent::Annotation.new(
              description: trunctable_string(annotation.description),
              attributes: convert_attributes(annotation.attributes)
            )

            TraceProtos::V1::Span::TimeEvent::Annotation.new
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
