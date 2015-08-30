require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative 'site'

require 'minitest/autorun'
require 'weekly_snippets/version'

module TeamApi
  class JoinSnippetDataTest < ::Minitest::Test
    def setup
      @site = DummyTestSite.new
      @site.data['snippets'] = {}
      @site.data['team'] = {}
      @impl = JoinerImpl.new(@site)
      @expected = {}
    end

    def team=(team_hash)
      @site.data['team'] = team_hash
    end

    def set_public_mode
      @site.config['public'] = true
      @impl = JoinerImpl.new(@site)
    end

    # rubocop:disable ParameterLists
    def add_snippet(timestamp, name, full_name, email, public_or_private,
      last_week, this_week, expected: true)
      snippets = (@site.data['snippets'][timestamp] ||= [])
      snippets << {
        'timestamp' => timestamp,
        'public' => public_or_private,
        'username' => email,
        'last-week' => last_week,
        'this-week' => this_week,
      }
      add_expected_snippet snippets.last, timestamp, name, full_name if expected
    end

    def add_expected_snippet(snippet, timestamp, name, full_name)
      snippet = snippet.merge 'name' => name, 'full_name' => full_name
      snippet.delete 'username'
      (@expected[timestamp] ||= []) << snippet
    end

    def test_empty_snippet_data
      self.team = {}
      @impl.join_snippet_data
      assert_empty @site.data['snippets']
    end

    def test_raises_if_missing_team_usernames
      self.team = {}
      add_snippet('20141218', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        'unused', '- Did stuff', '', expected: false)
      add_snippet('20141225', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        '', '- Did stuff', '', expected: false)
      add_snippet('20141231', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        'Public', '- Did stuff', '', expected: false)
      assert_raises(UnknownSnippetUsernameError) { @impl.join_snippet_data }
    end

    def test_joined_snippets_are_empty_if_no_team_in_public_mode
      self.team = {}
      add_snippet('20141218', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        'unused', '- Did stuff', '', expected: false)
      add_snippet('20141225', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        '', '- Did stuff', '', expected: false)
      add_snippet('20141231', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        'Public', '- Did stuff', '', expected: false)

      set_public_mode
      @impl.join_snippet_data
      assert_empty @site.data['snippets']
    end

    # rubocop:disable MethodLength
    def test_join_all_snippets
      self.team = {
        'mbland' => {
          'name' => 'mbland', 'full_name' => 'Mike Bland',
          'email' => 'michael.bland@gsa.gov'
        },
      }
      add_snippet('20141218', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        'unused', '- Did stuff', '')
      add_snippet('20141225', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        '', '- Did stuff', '')
      add_snippet('20141231', 'mbland', 'Mike Bland', 'michael.bland@gsa.gov',
        'Public', '- Did stuff', '')
      @impl.join_snippet_data
      assert_equal @expected, @site.data['snippets']
    end
    # rubocop:enable MethodLength

    # This tests the case where we're publishing snippets imported into
    # _data/public using _data/import-public.rb. That script will substitute
    # the original snippets' email usernames with the corresponding Hub
    # username.
    # rubocop:disable MethodLength
    def test_join_snippets_with_hub_username_instead_of_email_address
      @site.config['public'] = true
      @impl = JoinerImpl.new(@site)

      self.team = {
        'mbland' => {
          'name' => 'mbland',
          'full_name' => 'Mike Bland',
          'email' => 'michael.bland@gsa.gov',
        },
      }
      add_snippet('20141231', 'mbland', 'Mike Bland', 'mbland',
        'Public', '- Did stuff', '')

      @impl.join_snippet_data
      assert_equal @expected, @site.data['snippets']
    end
    # rubocop:enable MethodLength
  end
end
