module TeamApi
  class IndexPage < ::Jekyll::Page
    private_class_method :new

    def initialize(site)
      @site = site
      @base = site.source
      @dir = Api::BASEURL
      @name = 'index.html'
      @data = {}
    end

    def self.create(site, index_endpoints)
      index_page = new site
      index_page.process index_page.name
      layout = site.config['api_index_layout']
      fail '`api_index_layout:` not defined in _config.yml' unless layout
      index_page.read_yaml File.join(site.source, '_layouts'), layout
      index_page.data['endpoints'] = index_endpoints
      site.pages << index_page
    end
  end
end
