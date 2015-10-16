require_relative '../lib/team_api'
require_relative 'site'

require 'minitest/autorun'

if ENV['TRAVIS']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

`rm -rf _test/tmp _test/tmp_public`
