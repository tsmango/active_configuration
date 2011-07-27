# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{active_configuration}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Thomas Mango"]
  s.date = %q{2011-07-27}
  s.description = %q{A flexible settings system for Rails 3}
  s.email = %q{tsmango@gmail.com}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "app/models/active_configuration/setting.rb",
    "lib/active_configuration.rb",
    "lib/active_configuration/active_record/configuration.rb",
    "lib/active_configuration/base.rb",
    "lib/active_configuration/engine.rb",
    "lib/active_configuration/version.rb",
    "lib/generators/active_configuration/install/install_generator.rb",
    "lib/generators/active_configuration/install/templates/create_settings.rb"
  ]
  s.homepage = %q{http://github.com/tsmango/active_configuration}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{A flexible settings system for Rails 3}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 3.0.0"])
    else
      s.add_dependency(%q<activerecord>, [">= 3.0.0"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 3.0.0"])
  end
end
