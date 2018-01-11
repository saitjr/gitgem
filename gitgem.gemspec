#!/usr/bin/env ruby
# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "version"

Gem::Specification.new do |s|
  s.name        = 'gitgem'
  s.version     = GitGem::VERSION
  s.date        = '2018-01-10'
  s.summary     = "Install gem from git repo !"
  s.description = "Install gem from git repo !"
  s.authors     = ["saitjr"]
  s.email       = 'tangjr.work@gmail.com'
  s.files       = [Dir.glob("lib/*"), Dir.glob("lib/gitgem/*"), "bin/gitgem"]
  s.homepage    = 'http://rubygems.org/gems/gitgem'
  s.license     = 'MIT'

  s.bindir      = "bin"
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency 'gli', '~> 2.17', '>= 2.17.1'
end
