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


lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "opencensus/ocagent/version"

Gem::Specification.new do |spec|
  spec.name =        "opencensus-ocagent"
  spec.version =     OpenCensus::OCAgent::VERSION
  spec.authors =     ["Daniel Azuma"]
  spec.email =       ["dazuma@google.com"]

  spec.summary =     "OpenCensus Agent exporter"
  spec.description = "OpenCensus Agent exporter"
  spec.homepage =    "https://github.com/census-ecosystem/opencensus-ruby-exporter-ocagent"
  spec.license =     "Apache-2.0"

  spec.files = ::Dir.glob("lib/**/*.rb") +
               ::Dir.glob("*.md") +
               ["AUTHORS", "LICENSE", ".yardopts"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.3.0"

  spec.add_dependency "gruf", "~> 2.9.1"
  spec.add_dependency "opencensus", "~> 0.4.0"
  spec.add_dependency "ruby-protobuf", "~> 3.10.4"

  spec.add_development_dependency "bundler", ">= 1.17", "< 3.0"
  spec.add_development_dependency "faraday", "~> 1.7"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-focus", "~> 1.1"
  spec.add_development_dependency "minitest-rg", "~> 5.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "redcarpet", "~> 3.4"
  spec.add_development_dependency "rubocop", "~> 1.20"
  spec.add_development_dependency "toys", "~> 0.12"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "yard-doctest", "~> 0.1.6"
end
