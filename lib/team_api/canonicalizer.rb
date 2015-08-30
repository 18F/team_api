# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'config'
require_relative 'cross_referencer'

module TeamApi
  # Contains utility functions for canonicalizing names and the order of data.
  class Canonicalizer
    # Canonicalizes the order and names of certain fields within site_data.
    def self.canonicalize_data(site_data)
      sort_collections site_data
      canonicalize_tag_category site_data['skills']
      canonicalize_tag_category site_data['interests']
    end

    def self.sort_collections(site_data)
      Config.endpoint_config.each do |endpoint_info|
        collection = endpoint_info['collection']
        next unless site_data.member? collection
        sorted = sort_collection_values(endpoint_info,
          site_data[collection].values)
        sort_item_xrefs endpoint_info, sorted
        item_id_field = endpoint_info['item_id']
        site_data[collection] = sorted.map { |i| [i[item_id_field], i] }.to_h
      end
    end

    def self.sort_collection_values(endpoint_info, values)
      sort_by_field = endpoint_info['sort_by']
      if sort_by_field == 'last_name'
        sort_by_last_name values
      else
        values.sort_by { |i| (i[sort_by_field] || '').downcase }
      end
    end
    private_class_method :sort_collection_values

    def self.sort_item_xrefs(endpoint_info, collection)
      collection.each do |item|
        sortable_item_fields(item, endpoint_info).each do |field, field_info|
          item[field] = sort_collection_values field_info, item[field]
        end
      end
    end
    private_class_method :sort_item_xrefs

    def self.sortable_item_fields(item, collection_endpoint_info)
      collection_endpoint_info['item_collections'].map do |item_spec|
        field, endpoint_info = parse_collection_spec item_spec
        [field, endpoint_info] if item[field]
      end.compact
    end
    private_class_method :sortable_item_fields

    def self.parse_collection_spec(collection_spec)
      if collection_spec.instance_of? Hash
        [collection_spec['field'],
         Config.endpoint_info_by_collection[collection_spec['collection']]]
      else
        [collection_spec, Config.endpoint_info_by_collection[collection_spec]]
      end
    end

    # Returns a canonicalized, URL-friendly substitute for an arbitrary string.
    # +s+:: string to canonicalize
    def self.canonicalize(s)
      s.downcase.gsub(/\s+/, '-')
    end

    def self.comparable_name(person)
      if person['last_name']
        [person['last_name'].downcase, person['first_name'].downcase]
      else
        # Trim off title suffix, if any.
        full_name = person['full_name'].downcase.split(',')[0]
        last_name = full_name.split.last
        [last_name, full_name]
      end
    end
    private_class_method :comparable_name

    # Sorts an array of team member data hashes based on the team members'
    # last names.
    # +team+:: An array of team member data hashes
    def self.sort_by_last_name(team)
      team.sort_by { |member| comparable_name member }
    end

    def self.team_xrefs(team, usernames)
      fields = CrossReferencer::TEAM_FIELDS
      usernames
        .map { |username| team[username] }
        .compact
        .map { |member| member.select { |field, _| fields.include? field } }
        .sort_by { |member| comparable_name member }
    end

    # Breaks a YYYYMMDD timestamp into a hyphenated version: YYYY-MM-DD
    # +timestamp+:: timestamp in the form YYYYMMDD
    def self.hyphenate_yyyymmdd(timestamp)
      "#{timestamp[0..3]}-#{timestamp[4..5]}-#{timestamp[6..7]}"
    end

    # Consolidate tags entries that are not exactly the same. Selects the
    # lexicographically smaller version of the tag as a standard.
    #
    # In the future, we may just consider raising an error if there are two
    # different strings for the same thing.
    def self.canonicalize_tag_category(tags_xrefs)
      return if tags_xrefs.nil? || tags_xrefs.empty?
      tags_xrefs.replace(CrossReferencer.map_reduce(tags_xrefs.values,
        ->(xref) { [[xref['slug'], xref]] }, method(:consolidate_xrefs)).to_h)
    end

    def self.consolidate_xrefs(slug, xrefs)
      xrefs.sort_by! { |xref| xref['name'] }
      result = xrefs.each_with_object(xrefs.shift) do |xref, consolidated|
        consolidated['members'].concat xref['members']
      end
      result['members'].sort_by! { |member| comparable_name member }
      [slug, result]
    end
    private_class_method :consolidate_xrefs
  end
end
