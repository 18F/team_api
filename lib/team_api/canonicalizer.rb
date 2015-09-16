# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'collection_canonicalizer'
require_relative 'cross_referencer'
require_relative 'name_canonicalizer'

require 'lambda_map_reduce'

module TeamApi
  # Contains utility functions for canonicalizing names and the order of data.
  class Canonicalizer
    # Canonicalizes the order and names of certain fields within site_data.
    def self.canonicalize_data(site_data)
      CollectionCanonicalizer.sort_collections site_data
      %w(skills interests).each do |category|
        xrefs = site_data[category]
        canonicalize_tag_category xrefs
        site_data['team'].values.each do |member|
          canonicalize_tags_for_item category, xrefs, member
        end
      end
    end

    # Returns a canonicalized, URL-friendly substitute for an arbitrary string.
    # +s+:: string to canonicalize
    def self.canonicalize(s)
      s.downcase.gsub(/\s+/, '-')
    end

    def self.team_xrefs(team, usernames)
      fields = CrossReferencer::TEAM_FIELDS
      result = usernames
        .map { |username| team[username] }
        .compact
        .map { |member| member.select { |field, _| fields.include? field } }
      NameCanonicalizer.sort_by_last_name result
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
      tags_xrefs.replace(LambdaMapReduce.map_reduce(
        tags_xrefs.values,
        ->(xref) { [[xref['slug'], xref]] },
        method(:consolidate_xrefs)).to_h)
    end

    def self.consolidate_xrefs(slug, xrefs)
      xrefs.sort_by! { |xref| xref['name'] }
      result = xrefs.each_with_object(xrefs.shift) do |xref, consolidated|
        consolidated['members'].concat xref['members']
      end
      NameCanonicalizer.sort_by_last_name! result['members']
      [slug, result]
    end
    private_class_method :consolidate_xrefs

    def self.canonicalize_tags_for_item(category, xrefs, item)
      return if item[category].nil?
      item[category].each { |tag| tag['name'] = xrefs[tag['slug']]['name'] }
        .sort_by! { |tag| tag['name'] }
    end
  end
end
