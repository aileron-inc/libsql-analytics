# frozen_string_literal: true

require_relative 'lib/libsql/analytics/version'

Gem::Specification.new do |spec|
  spec.name = 'libsql-analytics'
  spec.version = Libsql::Analytics::VERSION
  spec.authors = ['aileron']
  spec.email = []

  spec.summary = 'Analytics gem for Turso (libSQL) — visit and event tracking with Embedded Replica'
  spec.description = <<~DESC
    A Rails analytics gem inspired by ahoy, built natively for Turso (libSQL).
    Tracks visits and events using Embedded Replica for low-latency local writes
    with automatic sync to Turso Cloud. Uses ULID for primary keys and stores
    query params as both raw string and JSON for flexible querying.
  DESC
  spec.homepage = 'https://github.com/aileron-inc/libsql-analytics'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord-libsql', '>= 0.1'
  spec.add_dependency 'railties', '>= 7.0'
end
