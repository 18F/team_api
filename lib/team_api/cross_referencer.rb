# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'api'
require_relative 'canonicalizer'
require_relative 'cross_reference_data'
require_relative 'name_canonicalizer'

require 'lambda_map_reduce'

module TeamApi
  # Builds cross-references between data sets.
  class CrossReferencer
    TEAM_FIELDS = %w(name last_name first_name full_name self)
    PROJECT_FIELDS = %w(name full_name self)
    WORKING_GROUP_FIELDS = %w(name full_name self)
    GUILD_FIELDS = %w(name full_name self)
    TAG_CATEGORIES = %w(skills interests)
    TAG_XREF_FIELDS = %w(name slug self)

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
      team = (site.data['team'] || {})
      tag_categories.each do |category|
        xrefs = create_tag_xrefs(site, team.values, category, team_xref)
        next if xrefs.empty?
        site.data[category] = xrefs
        replace_item_tags_with_xrefs category, xrefs, team.values
      end
    end

    def self.replace_item_tags_with_xrefs(tag_category, tag_xrefs, items)
      items.each do |item|
        (item[tag_category] || []).map! do |tag|
          tag_xrefs[tag].select { |field| TAG_XREF_FIELDS.include? field }
        end
      end
    end

    # Generates a Hash of { tag => cross-reference } generated from the tag
    # `category` Arrays from each element of `items`.
    #
    # For example:
    #   TEAM = {
    #   'mbland' => {
    #     'name' => 'mbland', 'full_name' => 'Mike Bland',
    #     'skills' => ['C++', 'Python'] },
    #   'arowla' => {
    #     'name' => 'arowla', 'full_name' => 'Alison Rowland',
    #     'skills' => ['Python'] },
    #   }
    #   TEAM_XREF = CrossReferenceData.new site, 'team', ['name', 'full_name']
    #   create_tag_xrefs site, TEAM, 'skills', TEAM_XREF
    #
    # will produce:
    #   {'C++' => {
    #      'name' => 'C++',
    #      'slug' => 'c++',
    #      'self' => 'https://.../skills/c++',
    #      'members' => [{ 'name' => 'mbland', 'full_name' => 'Mike Bland' }],
    #    },
    #
    #    'Python' => {
    #      'name' => 'Python',
    #      'slug' => 'python',
    #      'self' => 'https://.../skills/python',
    #      'members' => [
    #        { 'name' => 'mbland', 'full_name' => 'Mike Bland' },
    #        { 'name' => 'arowla', 'full_name' => 'Alison Rowland' },
    #      ],
    #    },
    #  }
    def self.create_tag_xrefs(site, items, category, xref_data)
      items_to_tags = lambda do |item|
        item_xref = xref_data.item_to_xref item
        item[category].map { |tag| [tag, item_xref] } unless item[category].nil?
      end
      create_tag_xrefs = lambda do |tag, item_xrefs|
        [tag, tag_xref(site, category, tag, item_xrefs)]
      end
      LambdaMapReduce.map_reduce(items, items_to_tags, create_tag_xrefs).to_h
    end

    def self.tag_xref(site, category, tag, members)
      category_slug = Canonicalizer.canonicalize category
      tag_slug = Canonicalizer.canonicalize tag
      { 'name' => tag,
        'slug' => tag_slug,
        'self' => File.join(Api.baseurl(site), category_slug, tag_slug),
        'members' => NameCanonicalizer.sort_by_last_name(members || []),
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
