require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative 'site'

require 'jekyll/document'
require 'minitest/autorun'

module TeamApi
  class JoinProjectDataTest < ::Minitest::Test
    def setup
      config = {
        'source' => '/',
        'collections' => { 'projects' => { 'output' => true } },
      }
      @site = DummyTestSite.new config: config
      collection = @site.collections['projects']
      doc = ::Jekyll::Document.new(
        '/_projects/msb-usa.md', site: @site, collection: collection)
      doc.data.merge! 'name' => 'MSB-USA', 'status' => 'Hold'
      collection.docs << doc
    end

    def project_self_link(name)
      File.join Api.baseurl(@site), 'projects', name
    end

    def test_join_project
      Joiner.join_data @site
      assert_equal(
        { 'msb-usa' =>
          {
            'name' => 'MSB-USA', 'status' => 'Hold',
            'self' => project_self_link('msb-usa')
          },
        },
        @site.data['projects'])
    end

    def test_hide_hold_projects_in_public_mode
      @site.config['public'] = true
      Joiner.join_data @site
      assert_empty @site.data['projects']
    end
  end
end
