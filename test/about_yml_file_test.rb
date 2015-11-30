require 'about_yml'
require 'safe_yaml'
require_relative 'test_helper'

module TeamApi
  class AboutYmlFileTest < ::Minitest::Test
    def test_about_yml_file(filepath=File.expand_path('./.about.yml'))
      about_file = File.join filepath
      about_data = SafeYAML.load_file about_file, safe: true
      errors = ::AboutYml::AboutFile.validate_single_file about_data
      assert_empty(errors, "ERRORS in .about.yml file: #{errors}")
    end
  end
end
