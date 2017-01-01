task default: 'assets:precompile'

namespace :assets do
  task :precompile do
    Rake::Task['clean'].invoke
    sh 'JEKYLL_ENV=production bundle exec jekyll build'
  end
end

desc 'Remove compiled files'
task :clean do
  sh "rm -rf #{File.dirname(__FILE__)}/_site/*"
end
