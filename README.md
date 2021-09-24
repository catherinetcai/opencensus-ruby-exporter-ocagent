# Ruby OpenCensus Agent Exporter
This library exports OpenCensus data to the OpenCensus Agent.

## This Fork
This is based off of the [Python OC-Agent Exporter](https://github.com/census-instrumentation/opencensus-python/blob/master/contrib/opencensus-ext-ocagent/README.rst) and the [OpenCensus Ruby Exporter Stackdriver](https://github.com/census-ecosystem/opencensus-ruby-exporter-stackdriver). It leverages [Gruf](https://github.com/bigcommerce/gruf) to handle the OpenCensus Agent service calls.

This is devved on Ruby 3.0.

## Usage
In order to make it possible to pull in the generated OpenCensus Protos, I had to fork the OpenCensus-Proto repo and add a [Ruby Gemspec](https://github.com/catherinetcai/opencensus-proto/tree/master/gen-ruby).

```ruby
# In Gemfile

gem 'opencensus'
git 'https://github.com/catherinetcai/opencensus-ruby-exporter-ocagent.git' do
  gem 'opencensus-ocagent'
end
git 'https://github.com/catherinetcai/opencensus-proto.git' do
  gem 'opencensus-proto'
end

# In an initializer - config/initializers/opencensus.rb
OpenCensus.configure do |c|
  c.trace.exporter = OpenCensus::Trace::Exporters::OCAgent.new(service_name: 'your-service-name')
end
```

Now any requests should just be instrumented.

### Versioning

This library follows [Semantic Versioning](http://semver.org/).

It is currently in major version zero (0.y.z), which means that anything may
change at any time, and the public API should not be considered stable.

## Contributing

Contributions to this library are always welcome and highly encouraged.

See the [Contributing Guide](CONTRIBUTING.md) for more information on how to get
started.

Please note that this project is released with a Contributor Code of Conduct. By
participating in this project you agree to abide by its terms. See
[Code of Conduct](CODE_OF_CONDUCT.md) for more information.

## License

This library is licensed under Apache 2.0. Full license text is available in
[LICENSE](LICENSE).
