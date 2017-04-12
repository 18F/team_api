require_relative '../../test/about_yml_file_test.rb'

desc 'Check your .about.yml file'
Rake::TestTask.new(:run_about_yml_check) { |t|
  t.libs = ['lib']
  t.pattern = File.expand_path '../../../test/about_yml_file_test', __FILE__
  t.verbose = true
  t.warning = false
}
