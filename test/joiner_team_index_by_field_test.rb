require_relative 'test_helper'

module TeamApi
  # Tests via impl.team_by_email for convenience, as it's a thin wrapper
  # around `team_index_by_field 'email'`.
  class TeamByFieldTest < ::Minitest::Test
    def setup
      config = {
        'source' => '/'
      }

      @site = DummyTestSite.new config: config
      @site.data = {}

      @team_data = {
        'team' => {
          'foobar' => {
            'name' => 'foo.bar',
            'deprecated_name' => 'fbar',
            'github' => 'foobar',
            'private' => {
              'email' => 'foo.bar@example.com'
            }
          },
          'fizzbuzz' => {
            'name' => 'fizz.buzz',
            'github' => 'fizzbuzz',
            'private' => {
              'email' => 'fizz.buzz@example.com'
            }
          },
          'bazblip' => {
            'name' => 'baz.blip'
          }
        }
      }
    end

    def impl
      joiner_impl = JoinerImpl.new @site
      joiner_impl.restructure_team_data!
      joiner_impl.init_team_data joiner_impl.data['team']
      joiner_impl.team_indexer
    end

    def merge_team_data!
      @site.data = {}
      @site.data.merge!(@team_data)
    end

    def test_team_data_restructured_properly
      merge_team_data!
      impl
      assert_equal(['foo.bar', 'fizz.buzz','baz.blip'].sort, @site.data['team'].keys.sort)
    end

    def test_empty_team
      assert_empty impl.team_by_email
    end

    def test_single_user_index
      merge_team_data!
      assert_equal(@site.data['team']['foobar'], impl.team_member_from_reference('foo.bar'))
    end

    def test_single_user_with_github_index
      merge_team_data!
      assert_equal(@site.data['team']['foobar'], impl.team_member_from_reference('foobar'))
    end

    def test_single_user_with_deprecated_name_index
      merge_team_data!
      assert_equal(@site.data['team']['foobar'], impl.team_member_from_reference('fbar'))
    end

    def test_single_private_user_index
      merge_team_data!
      assert_equal(@site.data['team']['foobar'], impl.team_member_from_reference('foo.bar@example.com'))
    end

    # rubocop:disable MethodLength
    def test_multiple_user_index
      merge_team_data!

      expected = {
        'foo.bar@example.com' => 'foo.bar',
        'fizz.buzz@example.com' => 'fizz.buzz'
      }

      assert_equal expected, impl.team_by_email
    end
    # rubocop:enable MethodLength

    def test_ignore_users_without_email
      merge_team_data!

      expected = {
        'foo.bar@example.com' => 'foo.bar',
        'fizz.buzz@example.com' => 'fizz.buzz'
      }

      assert_equal expected, impl.team_by_email
    end
  end
end
