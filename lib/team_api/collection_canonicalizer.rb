# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'config'
require_relative 'name_canonicalizer'

module TeamApi
  class CollectionCanonicalizer
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
        NameCanonicalizer.sort_by_last_name values
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
  end
end
