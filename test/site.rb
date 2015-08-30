require 'jekyll'
require 'jekyll/converters/identity'
require 'jekyll/site'
require 'safe_yaml'

module TeamApi
  class DummyTestSite < ::Jekyll::Site
    CONFIG = {
      'source' => File.join(File.dirname(__FILE__), 'test_site'),
      'permalink' => 'pretty',
      'baseurl' => '',
      'url' => 'https://team-api.18f.gov',
      'api_index_layout' => 'api_index.html',
    }

    def initialize(config: {})
      @config = CONFIG.merge config
      @permalink_style = @config['permalink'].to_sym
      @data = {}
      @converters = [::Jekyll::Converters::Identity.new]
      @pages = []
      @source = @config['source']
      @file_read_opts = {}
    end
  end
end
