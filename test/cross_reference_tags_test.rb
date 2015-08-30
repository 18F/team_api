require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative 'site'

require 'minitest/autorun'

module TeamApi
  class CrossReferenceTagsTest < ::Minitest::Test
    attr_accessor :site, :xref

    TEAM = {
      'mbland' => {
        'name' => 'mbland', 'full_name' => 'Mike Bland',
        'skills' => %w(C++ Python Go Ruby Node) },
      'arowla' => {
        'name' => 'arowla', 'full_name' => 'Alison Rowland',
        'skills' => %w(Python Ruby Node) },
      'afeld' => {
        'name' => 'afeld', 'full_name' => 'Aidan Feldman',
        'skills' => %w(Ruby JavaScript) },
    }

    def setup
      @site = DummyTestSite.new config: { 'baseurl' => '/' }
      @xref = CrossReferenceData.new site, 'team', %w(name full_name)
    end

    def test_empty_team
      CrossReferencer.xref_tags_and_team_members site, ['skills'], xref
      refute site.data['skills']
    end

    def test_team_with_no_skills
      site.data['team'] = TEAM.keys.map { |k| [k, {}] }.to_h
      CrossReferencer.xref_tags_and_team_members site, ['skills'], xref
      refute site.data['skills']
    end

    def test_team_with_empty_skills
      site.data['team'] = TEAM.keys.map { |k| [k, { 'skills' => [] }] }.to_h
      CrossReferencer.xref_tags_and_team_members site, ['skills'], xref
      refute site.data['skills']
    end

    def self.skill_ref(skill, members)
      slug = Canonicalizer.canonicalize(skill)
      { 'name' => skill,
        'slug' => slug,
        'self' => File.join('https://team-api.18f.gov/api/skills', slug),
        'members' => Canonicalizer.team_xrefs(TEAM, members),
      }
    end

    SKILLS = {
      'C++' => %w(mbland),
      'Python' => %w(arowla mbland),
      'Go' => %w(mbland),
      'Ruby' => %w(afeld arowla mbland),
      'Node' => %w(arowla mbland),
      'JavaScript' => %w(afeld),
    }.map { |skill, members| [skill, skill_ref(skill, members)] }.to_h

    def test_team_skills
      site.data['team'] = TEAM
      CrossReferencer.xref_tags_and_team_members site, ['skills'], xref
      assert_equal SKILLS, site.data['skills']
    end
  end
end
