require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :db do
  desc "Create the test DB"
  task :create do
    `createdb rb_pager_test`
  end

  desc "Drop the test DB"
  task :drop do
    `dropdb rb_pager_test`
  end
end
