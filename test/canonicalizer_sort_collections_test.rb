require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative 'site'

require 'minitest/autorun'

module TeamApi
  class CanonicalizerSortCollectionsTest < ::Minitest::Test
    def test_empty_collections
      site = DummyTestSite.new
      CollectionCanonicalizer.sort_collections site.data
    end

    def mbland
      { 'username' => 'mbland', 'first_name' => 'Mike', 'last_name' => 'Bland',
        'working-groups' => [
          { 'name' => 'wg', 'full_name' => 'Working Group' },
          { 'name' => 'doc', 'full_name' => 'Documentation' },
          { 'name' => 'testing', 'full_name' => 'Testing Grouplet' },
        ]
      }
    end

    def nick
      { 'username' => 'nick', 'first_name' => 'Nick', 'last_name' => 'Bristow',
        'working-groups' => [{ 'name' => 'wg' }],
        'guilds' => [{ 'name' => 'accessibility' }]
      }
    end

    def arowla
      { 'username' => 'arowla', 'first_name' => 'Alison', 'last_name' => 'Rowland',
        'working-groups' => [{ 'name' => 'testing' }],
        'projects' => [
          { 'name' => 'openfec', 'full_name' => 'OpenFEC' },
          { 'name' => 'calc', 'full_name' => 'CALC' },
          { 'name' => 'fbopen', 'full_name' => 'FBOpen' },
        ]
      }
    end

    def team_member_xref(member)
      member.select { |k, _| %w(username first_name last_name).include? k }
    end

    def doc_wg
      { 'name' => 'documentation', 'full_name' => 'Documentation Working Group',
        'leads' => [team_member_xref(mbland)]
      }
    end

    def testing_grouplet
      { 'name' => 'testing', 'full_name' => 'Testing Grouplet',
        'leads' => [team_member_xref(arowla), team_member_xref(mbland)]
      }
    end

    def wg_wg
      { 'name' => 'working-group', 'full_name' => 'Working Group WG',
        'members' => [team_member_xref(nick), team_member_xref(mbland)]
      }
    end

    def team
      { 'nick' => nick, 'arowla' => arowla, 'mbland' => mbland }
    end

    def working_groups
      { 'working-group' => wg_wg,
        'documentation' => doc_wg,
        'testing' => testing_grouplet,
      }
    end

    def site
      @site ||= DummyTestSite.new
    end

    def assert_group_names_for_team_member(expected, member_id, group_name)
      groups = site.data['team'][member_id][group_name]
      assert_equal expected, groups.map { |group| group['name'] }
    end

    def assert_member_names_for_group(expected, group_collection, group_name,
      member_field)
      members = site.data[group_collection][group_name][member_field]
      assert_equal expected, members.map { |member| member['username'] }
    end

    def test_sort_team
      site.data['team'] = team
      CollectionCanonicalizer.sort_collections site.data
      assert_equal %w(mbland nick arowla), site.data['team'].keys
      assert_group_names_for_team_member(%w(doc testing wg),
        'mbland', 'working-groups')
      assert_group_names_for_team_member(%w(calc fbopen openfec),
        'arowla', 'projects')
    end

    def test_sort_working_groups
      site.data['working-groups'] = working_groups
      CollectionCanonicalizer.sort_collections site.data
      assert_equal(%w(documentation testing working-group),
        site.data['working-groups'].keys)
      assert_member_names_for_group(%w(mbland arowla),
        'working-groups', 'testing', 'leads')
      assert_member_names_for_group(%w(mbland nick),
        'working-groups', 'working-group', 'members')
    end
  end
end
