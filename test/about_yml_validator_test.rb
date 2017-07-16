require 'active_model'
require_relative 'test_helper'
require_relative '../lib/team_api/about_yml_validator'

module TeamApi
  class AboutYmlValidatorTest < ::MiniTest::Test
    def valid_data
      {
        'name' => 'project-name',
        'full_name' => 'Awesome Project Name',
        'description' => "Here's a cool description!",
        'impact' => 'No idea what this is supposed to mean',
        'stage' => 'beta?',
        'team' => ['ertzeid'],
        'licenses' => ['cc0'],
        'owner_type' => 'human',
        'testable' => 'true'
      }
    end

    def test_validates_presence
      @validator = AboutYmlValidator.new(valid_data)
      assert_equal true, @validator.valid?

      @validator.set_attribute('name', nil)
      assert_equal false, @validator.valid?
      assert_equal ["can't be blank"], @validator.errors[:name]
    end
  end
end
