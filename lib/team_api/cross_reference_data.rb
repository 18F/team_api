# @author Mike Bland (michael.bland@gsa.gov)

module TeamApi
  # Signals that a cross-reference ID value in one object is not present in
  # the target collection. Only raised in "private" mode, since "public" mode
  # may legitimately filter out data.
  class UnknownCrossReferenceTargetId < StandardError
  end

  # Provides a collection with the ability to replace identifiers with more
  # detailed cross-reference values from another collection, and with the
  # ability to construct its own cross-reference values to assign to values
  # from other collections.
  #
  # The intent is to provide enough cross-reference information to surface in
  # an API without requiring the client to join the data necessary to produce
  # cross-links. For example, instead of surfacing `['mbland']` in a list of
  # team members, this class will produce `[{'name' => 'mbland', 'full_name'
  # => 'Mike Bland', 'first_name' => 'Mike', 'last_name' => 'Bland'}]`, which
  # the client can use to more easily sort multiple values and transform into:
  # `<a href="https://hub.18f.gov/team/mbland/">Mike Bland</a>`.
  class CrossReferenceData
    attr_accessor :collection_name, :data, :item_xref_fields, :public_mode

    # @param site [Jekyll::Site] site object
    # @param collection_name [String] name of collection within site.data
    # @param field_to_xref [String] name of the field to cross-reference
    # @param item_xref_fields [Array<String>] list of fields from which to
    #   produce cross-references for this collection
    def initialize(site, collection_name, item_xref_fields)
      @collection_name = collection_name
      @data = site.data[collection_name] || {}
      @item_xref_fields = item_xref_fields
      @public_mode = site.config['public']
    end

    # Selects fields from `item` to produce a smaller hash as a
    # cross-reference.
    def item_to_xref(item)
      item.select { |field, _| item_xref_fields.include? field }
    end

    # Translates identifiers into cross-reference values in both this object's
    # collection and the `target` collection.
    #
    # This object's collection is considered the "source", and references to
    # its values will be injected into "target". For each "source" object,
    # `source[target.collection_name]` should be an existing field containing
    # identifiers that are keys into `target.data`. The `target` collection
    # values should not contain a `target[source.collection_name]` field; that
    # field will be created by this method.
    #
    # @param target [CrossReferenceData] contains data to cross-reference with
    #   items from this object's collection
    # @param source_to_target_field [String] if specified, the field from this
    #   collection's objects that contain identifiers of objects stored within
    #   target; if not specified, target.collection_name will be used instead
    def create_xrefs(target, source_to_target_field: nil)
      target_collection_field = source_to_target_field || target.collection_name
      data.values.each do |source|
        create_xrefs_for_source source, target_collection_field, target
      end
      target.data.values.each { |item| (item[collection_name] || []).uniq! }
    end

    private

    def create_xrefs_for_source(source, target_collection_field, target)
      source_xref = item_to_xref source
      target_ids = filter_target_ids target, source, target_collection_field
      link_source_to_targets source_xref, target_ids, target
      source[target_collection_field] = target_xrefs target, target_ids
    end

    def filter_target_ids(target_xref, source_item, target_collection_field)
      (source_item[target_collection_field] || []).map do |target_id|
        if target_xref.data.member? target_id
          target_id
        elsif !public_mode
          fail UnknownCrossReferenceTargetId, unknown_cross_reference_msg(
            collection_name, source_item, target_collection_field,
            target_xref, target_id)
        end
      end.compact
    end

    def unknown_cross_reference_msg(collection_name,
      source_item, target_collection_field, target_xref, target_id)
      "source collection: \"#{collection_name}\" " \
        "source xref: #{item_to_xref source_item} " \
        "target collection field: \"#{target_collection_field}\" " \
        "target collection: \"#{target_xref.collection_name}\" " \
        "target ID: \"#{target_id}\""
    end

    def link_source_to_targets(source_xref, target_ids, target_xref)
      target_ids.each do |target_id|
        (target_xref.data[target_id][collection_name] ||= []) << source_xref
      end
    end

    def target_xrefs(target_xref, target_ids)
      target_ids.map { |id| target_xref.item_to_xref target_xref.data[id] }
    end
  end
end
