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

    CANONICALIZED_XREFS = %w(C++ Ruby).map do |skill|
      slug = skill.downcase
      self_url = "https://team-api.18f.gov/api/skills/#{slug}"
      [slug, { 'name' => skill, 'slug' => slug, 'self' => self_url }]
    end.to_h

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

    def all_consolidated
      c_plus_plus.merge(ruby_uppercase).merge(ruby_lowercase)
    end

    def expected_consolidated
      ruby_consolidated.merge('c++' => c_plus_plus['C++'])
    end

    def test_multiple_skills
      site.data['skills'] = all_consolidated
      Canonicalizer.canonicalize_tag_category site.data['skills']
      assert_equal expected_consolidated, site.data['skills']
    end

    SELF_URL = 'https://team-api.18f.gov/api/skills/'
    TEAM_MEMBER = {
      'skills' => [
        { 'name' => 'ruby', 'slug' => 'ruby', 'self' => SELF_URL + 'ruby' },
        { 'name' => 'C++', 'slug' => 'c++', 'self' => SELF_URL + 'c++' },
      ],
    }

    def test_canonicalize_tag_xrefs_empty_input
      empty_member = {}
      Canonicalizer.canonicalize_tags_for_item(
        'skills', expected_consolidated, empty_member)
      assert_nil empty_member['skills']
    end

    def test_canonicalize_tag_xrefs
      expected = [
        { 'name' => 'C++', 'slug' => 'c++', 'self' => SELF_URL + 'c++' },
        { 'name' => 'Ruby', 'slug' => 'ruby', 'self' => SELF_URL + 'ruby' },
      ]
      Canonicalizer.canonicalize_tags_for_item(
        'skills', expected_consolidated, TEAM_MEMBER)
      assert_equal expected, TEAM_MEMBER['skills']
    end
  end
end
