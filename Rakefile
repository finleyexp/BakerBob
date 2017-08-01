require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'bakerbob'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts << if ENV['HELL_ENABLED']
    '-W2'
  else
    '-W1'
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

task default: :test

task :console do
  exec "irb -r bakerbob -I ./lib"
end

task :report, :limit do |t, args|
  limit = args[:limit]
  BakerBob.bounce_once(limit, pretend: true)
end

task :bounce_once, :limit do |t, args|
  limit = args[:limit] || '200'
  BakerBob.bounce_once(limit)
end

task :bounce, :limit do |t, args|
  limit = args[:limit] || '200'
  BakerBob.bounce(limit)
end

task :bounce_stream do
  BakerBob.bounce_stream
end

task :manual_bounce, :trx_id do |t, args|
  BakerBob.manual_bounce(args[:trx_id])
end

task :run do
  BakerBob.run
end

task :run_once do
  BakerBob.run_once
end

task :state do
  BakerBob.state
end
