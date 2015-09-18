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
      assert_empty impl.join_team_list nil
    end

    def test_join_empty_team_list
      impl = JoinerImpl.new @site
      assert_empty impl.join_team_list []
    end

    def test_join_names_that_do_not_require_translation
      impl = JoinerImpl.new @site
      assert_equal(%w(mbland alison joshcarp),
        impl.join_team_list(%w(mbland alison joshcarp)))
    end

    def test_join_names_that_require_translation
      impl = JoinerImpl.new @site
      assert_equal(%w(mbland alison joshcarp),
        impl.join_team_list(%w(mbland alison@18f.gov jmcarp)))
    end

    def test_join_team_containing_hashes
      impl = JoinerImpl.new @site
      assert_equal(%w(mbland alison joshcarp boone),
        impl.join_team_list([
          'mbland',
          { 'email' => 'alison@18f.gov' },
          { 'github' => 'jmcarp' },
          { 'id' => 'boone' },
        ]))
    end

    def test_join_raises_if_identifier_unknown
      impl = JoinerImpl.new @site
      error = assert_raises(UnknownTeamMemberReferenceError) do
        impl.join_team_list(%w(mbland alison@18f.gov jmcarp foobar))
      end
      assert_equal 'foobar', error.message
    end

    def test_join_ignores_unknown_identifiers_in_public_mode
      @site.config['public'] = true
      impl = JoinerImpl.new @site
      assert_equal(%w(mbland alison joshcarp),
        impl.join_team_list(%w(mbland alison@18f.gov jmcarp foobar)))
    end
  end
end
