require_relative 'test_helper'
require_relative '../lib/team_api'

require 'minitest/autorun'

module TeamApi
  class SortByLastNameTest < ::Minitest::Test
    def test_sort_empty_team
      assert_empty Canonicalizer.sort_by_last_name []
    end

    def test_sort_single_entry_without_last_name
      team = [{ 'name' => 'mbland', 'full_name' => 'Mike Bland' }]
      assert_equal([{ 'name' => 'mbland', 'full_name' => 'Mike Bland' }],
        Canonicalizer.sort_by_last_name(team))
    end

    def test_sort_single_entry_without_full_name
      team = [
        { 'name' => 'mbland', 'first_name' => 'Mike', 'last_name' => 'Bland' },
      ]
      expected = [
        { 'name' => 'mbland', 'first_name' => 'Mike', 'last_name' => 'Bland' },
      ]
      assert_equal expected, Canonicalizer.sort_by_last_name(team)
    end

    # rubocop:disable MethodLength
    def test_sort_mixed_entries
      team = [
        { 'name' => 'adelevie',
          'first_name' => 'Alan', 'last_name' => 'deLevie' },
        { 'name' => 'afeld',
          'first_name' => 'Aidan', 'last_name' => 'Feldman' },
        { 'name' => 'annalee', 'full_name' => 'Annalee Flower Horne',
          'first_name' => 'Annalee', 'last_name' => 'Flower Horne' },
        { 'name' => 'mbland',
          'full_name' => 'Mike Bland' },
        { 'name' => 'mhz',
          'first_name' => 'Michelle', 'last_name' => 'Hertzfeld' },
      ]

      expected = [
        { 'name' => 'mbland',
          'full_name' => 'Mike Bland' },
        { 'name' => 'adelevie',
          'first_name' => 'Alan', 'last_name' => 'deLevie' },
        { 'name' => 'afeld',
          'first_name' => 'Aidan', 'last_name' => 'Feldman' },
        { 'name' => 'annalee', 'full_name' => 'Annalee Flower Horne',
          'first_name' => 'Annalee', 'last_name' => 'Flower Horne' },
        { 'name' => 'mhz',
          'first_name' => 'Michelle', 'last_name' => 'Hertzfeld' },
      ]
      assert_equal expected, Canonicalizer.sort_by_last_name(team)
    end
    # rubocop:enable MethodLength
  end
end
