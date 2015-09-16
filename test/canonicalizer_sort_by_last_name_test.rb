require_relative 'test_helper'
require_relative '../lib/team_api'

require 'minitest/autorun'

module TeamApi
  class SortByLastNameTest < ::Minitest::Test
    def test_sort_empty_team
      assert_empty NameCanonicalizer.sort_by_last_name []
    end

    def test_sort_single_entry_without_last_name
      team = [{ 'username' => 'mbland', 'full_name' => 'Mike Bland' }]
      assert_equal([{ 'username' => 'mbland', 'full_name' => 'Mike Bland' }],
        NameCanonicalizer.sort_by_last_name(team))
    end

    def test_sort_single_entry_without_full_name
      team = [
        { 'username' => 'mbland', 'first_name' => 'Mike', 'last_name' => 'Bland' },
      ]
      expected = [
        { 'username' => 'mbland', 'first_name' => 'Mike', 'last_name' => 'Bland' },
      ]
      assert_equal expected, NameCanonicalizer.sort_by_last_name(team)
    end

    # rubocop:disable MethodLength
    def test_sort_mixed_entries
      team = [
        { 'username' => 'adelevie',
          'first_name' => 'Alan', 'last_name' => 'deLevie' },
        { 'username' => 'afeld',
          'first_name' => 'Aidan', 'last_name' => 'Feldman' },
        { 'username' => 'annalee', 'full_name' => 'Annalee Flower Horne',
          'first_name' => 'Annalee', 'last_name' => 'Flower Horne' },
        { 'username' => 'mbland',
          'full_name' => 'Mike Bland' },
        { 'username' => 'mhz',
          'first_name' => 'Michelle', 'last_name' => 'Hertzfeld' },
      ]

      expected = [
        { 'username' => 'mbland',
          'full_name' => 'Mike Bland' },
        { 'username' => 'adelevie',
          'first_name' => 'Alan', 'last_name' => 'deLevie' },
        { 'username' => 'afeld',
          'first_name' => 'Aidan', 'last_name' => 'Feldman' },
        { 'username' => 'annalee', 'full_name' => 'Annalee Flower Horne',
          'first_name' => 'Annalee', 'last_name' => 'Flower Horne' },
        { 'username' => 'mhz',
          'first_name' => 'Michelle', 'last_name' => 'Hertzfeld' },
      ]
      assert_equal expected, NameCanonicalizer.sort_by_last_name(team)
    end
    # rubocop:enable MethodLength
  end
end
