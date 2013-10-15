require 'rubygems'
require 'rake'
require 'bundler'
require 'bundler/gem_tasks'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/unit_tests/**/*.rb'
  spec.rcov = true
  spec.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
end

task :clean do
  puts 'Cleaning old coverage'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
  FileUtils.rm_r('coverage') if(File.exists? 'coverage')
  puts 'Cleaning .yardoc and doc folders'
  FileUtils.rm_r('.yardoc') if(File.exists? '.yardoc')
  FileUtils.rm_r('doc') if(File.exists? 'doc')
  puts 'Cleaning spec/fixtures/target'
  FileUtils.rm_r('spec/fixtures/target') if(File.exists? 'spec/fixtures/target')

end

task :default => [:spec]

