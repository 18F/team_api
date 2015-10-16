require_relative 'test_helper'

module TeamApi
  class CrossReferenceLocationsTest < ::Minitest::Test
    def create_site_and_xrefs(team: {}, public_mode: false)
      site = DummyTestSite.new config: { 'public' => public_mode }
      site.data['team'] = team
      site.data['locations'] = {}.merge locations
      [site,
       CrossReferenceData.new(site, 'team', %w(name)),
       [CrossReferenceData.new(site, 'projects', %w(name)),
        CrossReferenceData.new(site, 'working-groups', %w(name)),
        CrossReferenceData.new(site, 'guilds', %w(name)),
       ],
      ]
    end

    def test_xref_locations_empty_data
      site, team_xref, collection_xrefs = create_site_and_xrefs
      CrossReferencer.xref_locations site.data, team_xref, collection_xrefs
      assert_equal locations, site.data['locations']
    end

    def locations
      { 'DCA' => { 'code' => 'DCA', 'label' => 'Washington, D.C.' } }
    end

    def mbland
      { 'name' => 'mbland', 'location' => 'DCA',
        'working-groups' => [
          { 'name' => 'doc' }, { 'name' => 'testing' }, { 'name' => 'wg' }
        ]
      }
    end

    def nick
      { 'name' => 'nick', 'location' => 'DCA',
        'working-groups' => [{ 'name' => 'wg' }],
        'guilds' => [{ 'name' => 'accessibility' }]
      }
    end

    # rubocop:disable MethodLength
    def test_xref_locations
      site, team_xref, collection_xrefs = create_site_and_xrefs(
        team: { 'mbland' => mbland, 'nick' => nick })
      CrossReferencer.xref_locations site.data, team_xref, collection_xrefs
      expected = {
        'team' => [{ 'name' => 'mbland' }, { 'name' => 'nick' }],
        'working-groups' => [
          { 'name' => 'doc' }, { 'name' => 'testing' }, { 'name' => 'wg' }
        ],
        'guilds' => [{ 'name' => 'accessibility' }],
      }
      assert_equal({ 'DCA' => locations['DCA'].merge(expected) },
        site.data['locations'])
    end

    def test_xref_locations_handle_private_locations_in_public_mode
      mbland = {}.merge self.mbland
      # In private mode, private location values are removed from users.
      mbland.delete 'location'
      site, team_xref, collection_xrefs = create_site_and_xrefs(
        team: { 'mbland' => mbland, 'nick' => nick })
      CrossReferencer.xref_locations site.data, team_xref, collection_xrefs
      expected = {
        'team' => [{ 'name' => 'nick' }],
        'working-groups' => [{ 'name' => 'wg' }],
        'guilds' => [{ 'name' => 'accessibility' }],
      }
      assert_equal({ 'DCA' => locations['DCA'].merge(expected) },
        site.data['locations'])
    end
    # rubocop:enable MethodLength
  end
end
