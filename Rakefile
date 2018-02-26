require 'rake'
require 'bundler/gem_tasks'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :clean do
  puts 'Cleaning spec/fixtures/target'
  FileUtils.rm_r('spec/fixtures/target') if(File.exists? 'spec/fixtures/target')
end

task :default => [:spec]
