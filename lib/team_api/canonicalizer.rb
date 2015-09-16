# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'collection_canonicalizer'
require_relative 'cross_referencer'
require_relative 'name_canonicalizer'
require_relative 'tag_canonicalizer'

require 'lambda_map_reduce'

module TeamApi
  # Contains utility functions for canonicalizing names and the order of data.
  class Canonicalizer
    # Canonicalizes the order and names of certain fields within site_data.
    def self.canonicalize_data(site_data)
      CollectionCanonicalizer.sort_collections site_data
      TagCanonicalizer.canonicalize_categories site_data, %w(skills interests)
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
  end
end
