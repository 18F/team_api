require_relative 'test_helper'

module TeamApi
  class EnvelopApiEndpointTest < ::Minitest::Test
    attr_accessor :site, :impl

    def setup
      @site = DummyTestSite.new
      @impl = ApiImpl.new @site, Api::BASEURL
    end

    def test_envelop_empty
      refute impl.envelop 'team', {}
    end

    def test_envelop_nil
      refute impl.envelop 'team', nil
    end

    def test_envelop
      mbland_data = { 'name' => 'mbland', 'full_name' => 'Mike Bland' }
      site.data['team'] = { 'mbland' => mbland_data }
      assert_equal(
        { 'self' => File.join(site.config['url'], Api::BASEURL, 'team'),
          'results' => [mbland_data],
        }, impl.envelop('team', site.data['team'].values))
    end
  end
end
