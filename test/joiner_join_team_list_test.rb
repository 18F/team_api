require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative 'site'

require 'minitest/autorun'

module TeamApi
  class JoinTeamListTest < ::Minitest::Test
    def setup
      @site = DummyTestSite.new config: {}
      @site.data['team'] = {
        'mbland' => { 'name' => 'mbland' },
        'alison' => { 'name' => 'alison', 'email' => 'alison@18f.gov' },
        'joshcarp' => { 'name' => 'joshcarp', 'github' => 'jmcarp' },
        'boone' => { 'name' => 'boone' },
      }
    end

    def test_join_nil_team_list
      impl = JoinerImpl.new @site
      assert_empty impl.join_team_list nil, nil
    end

    def test_join_empty_team_list
      impl = JoinerImpl.new @site
      assert_empty impl.join_team_list [], []
    end

    def test_join_names_that_do_not_require_translation
      impl = JoinerImpl.new @site
      outlist = %w(mbland alison joshcarp)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_empty outerror
    end

    def test_join_names_that_require_translation
      impl = JoinerImpl.new @site
      outlist = %w(mbland alison@18f.gov jmcarp)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_empty outerror
    end

    def test_join_team_containing_hashes
      impl = JoinerImpl.new @site
      outlist = [
        'mbland',
        { 'email' => 'alison@18f.gov' },
        { 'github' => 'jmcarp' },
        { 'id' => 'boone' }]
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp boone), outlist)
      assert_empty outerror
    end

    def test_join_error_returned_if_identifier_unknown
      impl = JoinerImpl.new @site
      outlist = %w(mbland alison@18f.gov jmcarp foobar)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_equal 'Unknown Team Member: foobar', outerror[0]
    end

    def test_join_ignores_unknown_identifiers_in_public_mode
      @site.config['public'] = true
      impl = JoinerImpl.new @site
      outlist = %w(mbland alison@18f.gov jmcarp foobar)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_empty outerror
    end
  end
end
