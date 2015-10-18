require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative 'site'

require 'jekyll/document'
require 'minitest/autorun'

module TeamApi
  # Tests via impl.team_by_email for convenience, as it's a thin wrapper
  # around `team_index_by_field 'email'`.
  class TeamByFieldTest < ::Minitest::Test
    def setup
      config = {
        'source' => '/',
        'collections' => { 'team' => { 'output' => true } },
      }
      @site = DummyTestSite.new config: config
      @team = @site.collections['team']
    end

    def add_team_member(member_hash, private: false)
      if private
        path = "/_team/private/#{member_hash['name']}.md"
      else
        path = "/_team/#{member_hash['name']}.md"
      end

      doc = ::Jekyll::Document.new path, site: @site, collection: @team
      doc.data.merge! member_hash
      @team.docs << doc
    end

    def impl
      joiner_impl = JoinerImpl.new @site
      joiner_impl.data.merge! joiner_impl.collection_data
      joiner_impl.init_team_data joiner_impl.data['team']
      joiner_impl.team_indexer
    end

    def test_empty_team
      assert_empty impl.team_by_email
    end

    def test_single_user_index
      add_team_member 'name' => 'mbland', 'email' => 'michael.bland@gsa.gov'
      assert_equal({ 'michael.bland@gsa.gov' => 'mbland' }, impl.team_by_email)
    end

    def test_single_user_with_private_email_index
      add_team_member(
        'name' => 'mbland', 'private' => { 'email' => 'michael.bland@gsa.gov' })
      assert_equal({ 'michael.bland@gsa.gov' => 'mbland' }, impl.team_by_email)
    end

    def test_single_private_user_index
      add_team_member(
        { 'name' => 'mbland', 'email' => 'michael.bland@gsa.gov' },
        private: true)
      assert_equal({ 'michael.bland@gsa.gov' => 'mbland' }, impl.team_by_email)
    end

    # rubocop:disable MethodLength
    def test_multiple_user_index
      add_team_member 'name' => 'mbland', 'email' => 'michael.bland@gsa.gov'
      add_team_member(
        'name' => 'foobar', 'private' => { 'email' => 'foo.bar@gsa.gov' })
      add_team_member(
        { 'name' => 'bazquux', 'email' => 'baz.quux@gsa.gov' }, private: true)

      expected = {
        'michael.bland@gsa.gov' => 'mbland',
        'foo.bar@gsa.gov' => 'foobar',
        'baz.quux@gsa.gov' => 'bazquux',
      }
      assert_equal expected, impl.team_by_email
    end
    # rubocop:enable MethodLength

    def test_ignore_users_without_email
      add_team_member 'name' => 'mbland'
      add_team_member 'name' => 'foobar', 'private' => {}
      add_team_member('name' => 'bazquux', private: true)
      assert_empty impl.team_by_email
    end
  end
end
