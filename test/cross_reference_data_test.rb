require_relative 'test_helper'

module TeamApi
  class CrossReferenceDataTest < ::Minitest::Test
    # rubocop:disable MethodLength
    def test_item_to_xref
      item = {
        'name' => 'mbland',
        'full_name' => 'Mike Bland',
        'first_name' => 'Mike',
        'last_name' => 'Bland',
        'quest' => 'To create the space in which great software can be written',
        'favorite_color' => 'purple',
        'avg_airspeed_of_an_unladen_swallow' => 'African or European?',
      }
      xref_fields = %w(name quest avg_airspeed_of_an_unladen_swallow)
      source = CrossReferenceData.new(DummyTestSite.new, 'source', xref_fields)

      expected = {
        'name' => 'mbland',
        'quest' => 'To create the space in which great software can be written',
        'avg_airspeed_of_an_unladen_swallow' => 'African or European?',
      }
      assert_equal expected, source.item_to_xref(item)
    end
    # rubocop:enable MethodLength

    def create_source_and_target_xrefs(source_data: nil, target_data: nil,
      public_mode: false)
      site = DummyTestSite.new config: { 'public' => public_mode }
      site.data = {}
      site.data['source'] = source_data if source_data
      site.data['target'] = target_data if target_data
      [CrossReferenceData.new(site, 'source', ['name']),
       CrossReferenceData.new(site, 'target', ['name'])]
    end

    def test_empty_source_data
      source, target = create_source_and_target_xrefs(
        target_data: { 'bar' => { 'name' => 'bar' } })

      source.create_xrefs target
      assert_equal({}, source.data)
      assert_nil target.data['bar']['source']
    end

    def test_missing_target_id_ignored_in_public_mode
      source, target = create_source_and_target_xrefs(
        source_data: { 'foo' => { 'name' => 'foo', 'target' => ['bar'] } },
        public_mode: true)

      source.create_xrefs target
      assert_equal [], source.data['foo']['target']
      assert_equal({}, target.data)
    end

    def test_missing_target_id_raises_exception_in_private_mode
      source, target = create_source_and_target_xrefs(
        source_data: { 'foo' => { 'name' => 'foo', 'target' => ['bar'] } })

      assert_raises(UnknownCrossReferenceTargetId) do
        source.create_xrefs target
      end
    end

    def test_xref_source_and_target
      source, target = create_source_and_target_xrefs(
        source_data: { 'foo' => { 'name' => 'foo', 'target' => ['bar'] } },
        target_data: { 'bar' => { 'name' => 'bar' } })

      source.create_xrefs target
      assert_equal [{ 'name' => 'bar' }], source.data['foo']['target']
      assert_equal [{ 'name' => 'foo' }], target.data['bar']['source']
    end

    def test_xref_source_and_target_using_alternate_target_field_name
      source, target = create_source_and_target_xrefs(
        source_data: {
          'foo' => { 'name' => 'foo', 'alternate_name' => ['bar'] },
        },
        target_data: { 'bar' => { 'name' => 'bar' } })

      source.create_xrefs target, source_to_target_field: 'alternate_name'
      assert_equal [{ 'name' => 'bar' }], source.data['foo']['alternate_name']
      assert_equal [{ 'name' => 'foo' }], target.data['bar']['source']
    end

    # rubocop:disable Metrics/AbcSize
    def test_remove_duplicate_source_references_in_target_object
      source_data = {
        'foo' => { 'name' => 'foo', 'list_a' => ['bar'], 'list_b' => ['bar'] },
      }
      source, target = create_source_and_target_xrefs(
        source_data: source_data, target_data: { 'bar' => { 'name' => 'bar' } })

      source.create_xrefs target, source_to_target_field: 'list_a'
      source.create_xrefs target, source_to_target_field: 'list_b'
      assert_equal [{ 'name' => 'bar' }], source.data['foo']['list_a']
      assert_equal [{ 'name' => 'bar' }], source.data['foo']['list_b']
      assert_equal [{ 'name' => 'foo' }], target.data['bar']['source']
    end
    # rubocop:enable Metrics/AbcSize
  end
end
