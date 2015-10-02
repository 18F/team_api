require 'jekyll'

module TeamApi
  class Endpoint < ::Jekyll::Page
    private_class_method :new

    def initialize(site, endpoint_path)
      @site = site
      @base = site.source
      @dir = endpoint_path
      @name = 'api.json'
      @data = {}
    end

    def self.create(site, endpoint_path, data)
      endpoint = new site, endpoint_path
      endpoint.process endpoint.name
      endpoint.content = data.to_json
      site.pages << endpoint
    end
  end
end
