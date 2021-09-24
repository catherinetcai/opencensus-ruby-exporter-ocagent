# frozen_string_literal: true

module OpenCensus
  module Trace
    module Exporters
      class OCAgent
        class ExportRequestEnumerator
          def initialize(spans, delay = 0.5)
            @spans = spans
            @delay = delay
          end

          def each_item
            return enum_for(:each_item) unless block_given?
            @spans.each do |span|
              sleep @delay
              puts "Sending span #{span.inspect}"
              yield span
            end
          end
        end
      end
    end
  end
end

