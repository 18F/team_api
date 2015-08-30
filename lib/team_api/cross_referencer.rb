# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'api'
require_relative 'canonicalizer'

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

  # Builds cross-references between data sets.
  class CrossReferencer
    TEAM_FIELDS = %w(name last_name first_name full_name self)
    PROJECT_FIELDS = %w(name project self)
    WORKING_GROUP_FIELDS = %w(name full_name self)
    GUILD_FIELDS = %w(name full_name self)
    TAG_CATEGORIES = %w(skills interests)

    # Build cross-references between data sets.
    # +site_data+:: Jekyll +site.data+ object
    def self.build_xrefs(site)
      team, projects, working_groups, guilds = create_xref_data site

      projects.create_xrefs team
      [working_groups, guilds].each do |grouplet|
        grouplet.create_xrefs team, source_to_target_field: 'leads'
        grouplet.create_xrefs team, source_to_target_field: 'members'
      end

      xref_tags_and_team_members site, TAG_CATEGORIES, team
      xref_locations site.data, team, [projects, working_groups, guilds]
    end

    def self.create_xref_data(site)
      [CrossReferenceData.new(site, 'team', TEAM_FIELDS),
       CrossReferenceData.new(site, 'projects', PROJECT_FIELDS),
       CrossReferenceData.new(site, 'working-groups', WORKING_GROUP_FIELDS),
       CrossReferenceData.new(site, 'guilds', GUILD_FIELDS),
      ]
    end
    private_class_method :create_xref_data

    def self.xref_tags_and_team_members(site, tag_categories, team_xref)
      tag_categories.each do |category|
        xrefs = create_tag_xrefs(site, (site.data['team'] || {}).values,
          category, team_xref)
        site.data[category] = xrefs unless xrefs.empty?
      end
    end

    def self.create_tag_xrefs(site, items, category, xref_data)
      map_items_to_tags = lambda do |item|
        item_xref = xref_data.item_to_xref item
        item[category].map { |tag| [tag, item_xref] } unless item[category].nil?
      end
      create_tag_xrefs = lambda do |tag, item_xrefs|
        [tag, tag_xref(site, category, tag, item_xrefs)]
      end
      map_reduce(items, map_items_to_tags, create_tag_xrefs).to_h
    end

    # Returns an Array of objects after mapping and reducing items.
    # mapper takes a single item and returns an Array of [key, value] pairs.
    # reducer takes a [key, Array of values] pair and returns a single item.
    def self.map_reduce(items, mapper, reducer)
      items.flat_map { |item| mapper.call(item) }.compact
        .each_with_object({}) { |kv, shuffle| (shuffle[kv[0]] ||= []) << kv[1] }
        .map { |key, values| reducer.call(key, values) }.compact
    end

    def self.tag_xref(site, category, tag, members)
      category_slug = Canonicalizer.canonicalize category
      tag_slug = Canonicalizer.canonicalize tag
      { 'name' => tag,
        'slug' => tag_slug,
        'self' => File.join(Api.baseurl(site), category_slug, tag_slug),
        'members' => Canonicalizer.sort_by_last_name(members || []),
      }
    end

    def self.group_names_to_team_xrefs(team, collection_xrefs)
      collection_xrefs.map do |xref|
        xrefs = team.flat_map { |i| i[xref.collection_name] }.compact.uniq
        [xref.collection_name, xrefs] unless xrefs.empty?
      end.compact.to_h
    end

    # Produces an array of locations containing cross references to team
    # members and all projects, working groups, guilds, etc. associated with
    # each team member. All team member cross-references must already exist.
    def self.xref_locations(site_data, team_xref, collection_xrefs)
      location_xrefs = site_data['team'].values.group_by { |i| i['location'] }
        .map do |location_code, team|
          [location_code,
           {
             'team' => team.map { |member| team_xref.item_to_xref member },
           }.merge(group_names_to_team_xrefs(team, collection_xrefs)),
          ] unless location_code.nil?
        end
      HashJoiner.deep_merge site_data['locations'], location_xrefs.compact.to_h
    end
  end
end
