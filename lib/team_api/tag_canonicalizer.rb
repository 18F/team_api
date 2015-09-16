# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'name_canonicalizer'

module TeamApi
  # Contains utility functions for canonicalizing names and the order of data.
  class TagCanonicalizer
    def self.canonicalize_categories(site_data, tag_categories)
      tag_categories.each do |category|
        xrefs = site_data[category]
        canonicalize_tag_category xrefs
        site_data['team'].values.each do |member|
          canonicalize_tags_for_item category, xrefs, member
        end
      end
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
