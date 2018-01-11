#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'optparse'
require 'fileutils'

module GitGem
  module Action
    class << self
      def add(repo_alias = nil, repo)
        repo_alias = repo if repo_alias.nil? || repo_alias.empty?

        abort("Alias could not start with '.'") if repo_alias.start_with?(".")

        should_add = true

        result = read_alias(repo_alias)

        unless result.nil?
          puts "#{repo_alias} is already exist: #{result}"
          printf "replace? (y/n): "
          input = STDIN.gets

          if input.start_with?("y")
            remove(repo_alias)
            should_add = true
          else
            should_add = false
          end
        end

        system("echo #{repo_alias}=#{repo} >> #{alias_path}") if should_add
      end

      def remove(repo_alias)
        result = read_alias(repo_alias)
        FileUtils.rm_rf(File.join(base_dir, repo_alias)) unless result.nil?
        system("sed -i '' '/#{repo_alias}=/d' #{alias_path}")
      end

      def install(repo_alias, gem_dir, bindir)
        abort("Please specify alias like alias/gem") if repo_alias.nil? || repo_alias.empty?
        result = read_alias(repo_alias)
        abort("Could not find alias named #{repo_alias}, please check again.") if result.nil?
        repo = result.gsub("#{repo_alias}=", "")

        alias_dir = File.join(base_dir, repo_alias)
        repo_dir = File.join(alias_dir, File.basename(repo, ".git"))
        pwd = Dir.pwd

        unless File.exist?(alias_dir)
          Dir.chdir(base_dir)
          FileUtils.mkdir_p(alias_dir)
          Dir.chdir(alias_dir)
          system("git clone -q #{repo}")
        end

        Dir.chdir(repo_dir)
        system("git checkout -- .")
        system("git pull -q")

        # 进入 gem 的目录，build gemspec
        Dir.chdir(gem_dir)

        gemspecs = Dir.glob("*.gemspec")
        abort("Could not find gemspec in #{File.join(Dir.pwd)}") if gemspecs.nil? || gemspecs.empty?
        abort("Mutiple gemspecs found in #{File.join(Dir.pwd)}") if gemspecs.count > 1

        Dir.glob("*.gem").each do |gem|
          FileUtils.rm_rf(gem)
        end

        result = system("sudo gem build #{gemspecs.first}")

        abort("Fail to build gemspec") unless result

        gems = Dir.glob("*.gem")
        abort("Could not find gem in #{File.join(Dir.pwd)}") if gemspecs.nil? || gemspecs.empty?

        # 获取最新 gem
        gem = gems.first
        bin = "-n #{bindir}" unless bindir.nil?

        system("sudo gem install #{gem} #{bin}")

        Dir.chdir(pwd)
      end

      def uninstall(repo_alias, gem_name, bindir)
        abort("Please specify alias like alias/gem") if repo_alias.nil? || repo_alias.empty?
        result = read_alias(repo_alias)
        abort("Could not find alias named #{repo_alias}, please check again.") if result.nil?
        repo = result.gsub("#{repo_alias}=", "")

        alias_dir = File.join(base_dir, repo_alias)
        repo_dir = File.join(alias_dir, File.basename(repo, ".git"))

        gems = Dir.glob(File.join(repo_dir, gem_dir, "*.gem"))
        abort("Could not find gem in #{File.join(repo_dir, gem_dir)}") if gems.nil? || gems.empty?

        bin = "-n #{bindir}" unless bindir.nil?
        gem_name = File.basename(gems.first, ".gem").split("-")[0...-1].join("-")
        system("sudo gem unisntall #{gem_name} #{bin}")
      end

      private

      def read_alias(repo_alias)
        result = `cat #{alias_path} | grep #{repo_alias}=`.chomp
        return nil if result.nil? || result.empty?
        result
      end

      def base_dir
        File.join(ENV["HOME"], ".gitgem")
      end

      def alias_path
        path = File.join(base_dir, "alias")
        FileUtils.mkdir_p(base_dir)
        system("touch #{path}") unless File.exist?(path)
        path
      end
    end
  end
end
