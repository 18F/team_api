require_relative 'endpoint'
require_relative 'api_impl_snippet_helpers'
require_relative 'api_impl_error_helpers'
require 'json'

module TeamApi
  class ApiImpl
    attr_accessor :site, :data, :index_endpoints, :baseurl
    include ApiImplSnippetHelpers
    include ApiImplErrorHelpers

    def initialize(site, baseurl)
      @site = site
      @data = site.data
      @index_endpoints = []
      @baseurl = baseurl
    end

    def self_link(endpoint)
      File.join site.config['url'], baseurl, endpoint
    end

    def envelop(endpoint, items)
      return if items.nil? || items.empty?
      { 'self' => self_link(endpoint), 'results' => items }
    end

    def generate_index_endpoint(endpoint, title, description, items)
      return if items.nil? || items.empty?
      Endpoint.create site, "#{baseurl}/#{endpoint}", items
      index_endpoints << {
        'endpoint' => endpoint, 'title' => title, 'description' => description
      }
    end

    def generate_schema_endpoint(schema_file_location)
      return if schema_file_location.nil? || schema_file_location.empty?
      file = File.read schema_file_location
      items = JSON.parse file
      generate_index_endpoint('schemas', 'Schemas',
        'Schema used to parse .about.yml files',
        items)
    end

    def generate_tag_category_endpoint(category)
      canonicalized = Canonicalizer.canonicalize(category)
      generate_index_endpoint(canonicalized, category,
        "Index of team members by #{category.downcase}",
        envelop(canonicalized, (data[canonicalized] || {}).values))
    end

    def generate_index_endpoint_for_collection(endpoint_info)
      collection = endpoint_info['collection']
      generate_index_endpoint(
        endpoint_info['collection'], endpoint_info['title'],
        endpoint_info['description'],
        envelop(collection, (data[collection] || {}).values))
    end

    def generate_item_endpoints(collection_name)
      (data[collection_name] || {}).each do |identifier, value|
        identifier = Canonicalizer.canonicalize(identifier)
        url = "#{baseurl}/#{collection_name}/#{identifier}"
        Endpoint.create site, url, value
      end
    end

    def generate_snippets_endpoints
      generate_latest_snippet_endpoint
      generate_snippets_by_date_endpoints
      generate_snippets_by_user_endpoints
      generate_snippets_index_summary_endpoint
    end

    def generate_error_endpoint
      generate_errors_endpoint
      generate_errors_index_summary_endpoint
    end
  end
end
