# coding: utf-8

# Copyright (c) 2024, FusionAuth, All Rights Reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'fusionauth_client'
  spec.version = '1.59.0'
  spec.authors = ['Brian Pontarelli', 'Daniel DeGroff']
  spec.email = %w(brian@fusionauth.io daniel@fusionauth.io)

  spec.summary = %q{The Ruby client library for FusionAuth}
  spec.description = %q{This library contains the Ruby client library that helps you connect your application to FusionAuth.}
  spec.homepage = 'https://github.com/FusionAuth/fusionauth-ruby-client'
  spec.license = 'Apache-2.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # spec.add_development_dependency 'bundler', '~> 1.14'
  # spec.add_development_dependency 'rake', '~> 10.0'
  # spec.add_development_dependency 'minitest', '~> 5.0'
end
