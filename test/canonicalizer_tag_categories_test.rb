require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative './site'

require 'minitest/autorun'

module TeamApi
  class CanonicalizeTagTestData
    def c_plus_plus
      { 'C++' =>
        { 'name' => 'C++', 'slug' => 'c++',
          'members' => [{ 'username' => 'mbland', 'full_name' => 'Mike Bland' }]
        },
      }
    end

    def ruby_uppercase
      { 'Ruby' =>
        { 'name' => 'Ruby', 'slug' => 'ruby',
          'members' =>
            [{ 'username' => 'mbland', 'full_name' => 'Mike Bland' },
             { 'username' => 'arowla', 'full_name' => 'Alison Rowland' },
            ]
        },
      }
    end

    def ruby_lowercase
      { 'ruby' =>
        { 'name' => 'ruby', 'slug' => 'ruby',
          'members' => [{ 'username' => 'afeld', 'full_name' => 'Aidan Feldman' }]
        },
      }
    end

    def all_ruby
      ruby_uppercase.merge ruby_lowercase
    end

    def ruby_consolidated
      { 'ruby' =>
          { 'name' => 'Ruby', 'slug' => 'ruby',
            'members' =>
              [{ 'username' => 'mbland', 'full_name' => 'Mike Bland' },
               { 'username' => 'afeld', 'full_name' => 'Aidan Feldman' },
               { 'username' => 'arowla', 'full_name' => 'Alison Rowland' },
              ]
          },
      }
    end

    def all_skills
      c_plus_plus.merge(ruby_uppercase).merge(ruby_lowercase)
    end

    def consolidated_skills
      ruby_consolidated.merge('c++' => c_plus_plus['C++'])
    end
  end

  class CanonicalizeTagCategoryTest < ::Minitest::Test
    attr_accessor :site, :tag_test_data

    def setup
      @site = DummyTestSite.new
      @tag_test_data = CanonicalizeTagTestData.new
    end

    def test_empty_team
      TagCanonicalizer.canonicalize_tag_category site.data['skills']
      refute site.data['skills']
    end

    def test_empty_skills
      site.data['skills'] = {}
      TagCanonicalizer.canonicalize_tag_category site.data['skills']
      assert_empty site.data['skills']
    end

    def test_single_skill
      cpp_data = tag_test_data.c_plus_plus
      site.data['skills'] = cpp_data
      expected = { 'c++' => cpp_data['C++'] }
      TagCanonicalizer.canonicalize_tag_category site.data['skills']
      assert_equal expected, site.data['skills']
    end

    def test_single_skill_multiple_names
      site.data['skills'] = tag_test_data.all_ruby
      TagCanonicalizer.canonicalize_tag_category site.data['skills']
      assert_equal tag_test_data.ruby_consolidated, site.data['skills']
    end

    def test_multiple_skills
      site.data['skills'] = tag_test_data.all_skills
      TagCanonicalizer.canonicalize_tag_category site.data['skills']
      assert_equal tag_test_data.consolidated_skills, site.data['skills']
    end
  end

  class CanonicalizeTagsForItemTest < ::Minitest::Test
    attr_accessor :site, :tag_test_data

    SELF_URL = 'https://team-api.18f.gov/api/skills/'
    TEAM_MEMBER = {
      'skills' => [
        { 'name' => 'ruby', 'slug' => 'ruby', 'self' => SELF_URL + 'ruby' },
        { 'name' => 'C++', 'slug' => 'c++', 'self' => SELF_URL + 'c++' },
      ],
    }

    def setup
      @site = DummyTestSite.new
      @tag_test_data = CanonicalizeTagTestData.new
    end

    def test_canonicalize_tag_xrefs_empty_input
      empty_member = {}
      TagCanonicalizer.canonicalize_tags_for_item(
        'skills', tag_test_data.consolidated_skills, empty_member)
      assert_nil empty_member['skills']
    end

    def test_canonicalize_tag_xrefs
      expected = [
        { 'name' => 'C++', 'slug' => 'c++', 'self' => SELF_URL + 'c++' },
        { 'name' => 'Ruby', 'slug' => 'ruby', 'self' => SELF_URL + 'ruby' },
      ]
      TagCanonicalizer.canonicalize_tags_for_item(
        'skills', tag_test_data.consolidated_skills, TEAM_MEMBER)
      assert_equal expected, TEAM_MEMBER['skills']
    end
  end
end
