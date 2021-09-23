.PHONY: collector zipkin

# Runs the collector
collector:
	docker run omnition/opencensus-collector:0.1.11 --receive-oc-trace

zipkin:
	docker run -d -p 9411:9411 openzipkin/zipkin
