require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "railroadmap"
  gem.homepage = "http://github.com/munetoh/railroadmap"
  gem.license = "MIT"
  gem.summary = %Q{Generate behavior model of Ruby on Rails Web application.}
  gem.description = %Q{TBD}
  gem.email = "seiji.munetoh@gmail.com"
  gem.authors = ["Seiji Munetoh"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

#require 'rake/rdoctask'
require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "railroadmap #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


require 'rake/testtask'
Rake::TestTask.new

require 'rubocop/rake_task'
desc 'Run RuboCop on the lib directory'
Rubocop::RakeTask.new(:rubocop) do |task|
  task.patterns = [
    'lib/*.rb',
    'lib/railroadmap/*.rb',
    'lib/railroadmap/*/*.rb',
    'lib/railroadmap/*/*/*.rb',
    'spec/*.rb',
    'spec/*/*.rb',
    'spec/*/*/*.rb'
  ]
  # only show the files with failures
  #task.formatters = ['files']
  # don't abort rake on failure
  task.fail_on_error = false
end