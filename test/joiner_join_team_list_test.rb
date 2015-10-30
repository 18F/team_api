require_relative 'test_helper'

module TeamApi
  class JoinTeamListTest < ::Minitest::Test
    def setup
      @site = DummyTestSite.new config: {}
      @site.data['team'] = {
        'mbland' => { 'name' => 'mbland' },
        'alison' => { 'name' => 'alison', 'email' => 'alison@18f.gov' },
        'joshcarp' => { 'name' => 'joshcarp', 'github' => 'jmcarp' },
        'boone' => { 'name' => 'boone' },
        'private' => { 'mrsecret' => {
          'name' => 'mrsecret', 'github' => 'secret'
        } },
      }
    end

    def impl
      impl = JoinerImpl.new @site
      impl.init_team_data @site.data['team']
      impl
    end

    def test_join_nil_team_list
      assert_empty impl.join_team_list nil, nil
    end

    def test_join_empty_team_list
      assert_empty impl.join_team_list [], []
    end

    def test_join_names_that_do_not_require_translation
      outlist = %w(mbland alison joshcarp)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_empty outerror
    end

    def test_join_names_that_do_not_require_translation_with_private
      outlist = %w(mbland alison joshcarp mrsecret)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp mrsecret), outlist)
      assert_empty outerror
    end

    def test_join_names_that_require_translation
      outlist = %w(mbland alison@18f.gov jmcarp)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_empty outerror
    end

    def test_join_names_that_require_translation_with_private
      outlist = %w(mbland alison@18f.gov secret jmcarp)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison mrsecret joshcarp), outlist)
      assert_empty outerror
    end

    def test_join_team_containing_hashes
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
      outlist = %w(mbland alison@18f.gov jmcarp foobar)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_equal 'Unknown Team Member: foobar', outerror[0]
    end

    def test_join_includes_unknown_identifiers_in_public_mode
      @site.config['public'] = true
      outlist = %w(mbland alison@18f.gov jmcarp foobar)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_equal 'Unknown Team Member: foobar', outerror[0]
    end

    def test_join_excludes_private_identifiers_in_public_mode
      @site.config['public'] = true
      outlist = %w(mbland alison@18f.gov jmcarp mrsecret)
      outerror = []
      impl.join_team_list outlist, outerror
      assert_equal(%w(mbland alison joshcarp), outlist)
      assert_empty outerror
    end
  end
end
