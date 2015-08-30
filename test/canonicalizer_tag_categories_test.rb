require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative './site'

require 'minitest/autorun'

module TeamApi
  class CanonicalizeTagCategoryTest < ::Minitest::Test
    attr_accessor :site

    def setup
      @site = DummyTestSite.new
    end

    def test_empty_team
      Canonicalizer.canonicalize_tag_category site.data['skills']
      refute site.data['skills']
    end

    def test_empty_skills
      site.data['skills'] = {}
      Canonicalizer.canonicalize_tag_category site.data['skills']
      assert_empty site.data['skills']
    end

    def c_plus_plus
      { 'C++' =>
        { 'name' => 'C++', 'slug' => 'c++',
          'members' => [{ 'name' => 'mbland', 'full_name' => 'Mike Bland' }]
        },
      }
    end

    def ruby_uppercase
      { 'Ruby' =>
        { 'name' => 'Ruby', 'slug' => 'ruby',
          'members' =>
            [{ 'name' => 'mbland', 'full_name' => 'Mike Bland' },
             { 'name' => 'arowla', 'full_name' => 'Alison Rowland' },
            ]
        },
      }
    end

    def ruby_lowercase
      { 'ruby' =>
        { 'name' => 'ruby', 'slug' => 'ruby',
          'members' => [{ 'name' => 'afeld', 'full_name' => 'Aidan Feldman' }]
        },
      }
    end

    def ruby_consolidated
      { 'ruby' =>
          { 'name' => 'Ruby', 'slug' => 'ruby',
            'members' =>
              [{ 'name' => 'mbland', 'full_name' => 'Mike Bland' },
               { 'name' => 'afeld', 'full_name' => 'Aidan Feldman' },
               { 'name' => 'arowla', 'full_name' => 'Alison Rowland' },
              ]
          },
      }
    end

    def test_single_skill
      site.data['skills'] = c_plus_plus
      Canonicalizer.canonicalize_tag_category site.data['skills']
      expected = { 'c++' => c_plus_plus['C++'] }
      assert_equal expected, site.data['skills']
    end

    def test_single_skill_multiple_names
      site.data['skills'] = ruby_uppercase.merge(ruby_lowercase)
      Canonicalizer.canonicalize_tag_category site.data['skills']
      assert_equal ruby_consolidated, site.data['skills']
    end
  end
end
