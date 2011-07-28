# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "conductor-importer/version"

Gem::Specification.new do |s|
  s.name        = "conductor-importer"
  s.version     = Conductor::Importer::VERSION
  s.authors     = ["Jeremy Friesen"]
  s.email       = ["jeremy.n.friesen@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "conductor-importer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('hpricot', '~> 0.8.4')
  s.add_dependency('activerecord', '~> 3.0.5')
  s.add_dependency('sqlite3', "~> 1.3.3")
  s.add_dependency('rest-client', "~> 1.6.1")
  s.add_dependency('main', "~> 4.6")
  s.add_dependency('json', "~> 1.5.3")
  s.add_dependency('state_machine', "~> 1.0.1")
  s.add_dependency('highline', "~> 1.6.2")

  s.add_development_dependency('ruby-debug', "~> 0.10.4")
end
