require_relative 'test_helper'

module TeamApi
  class AddSelfLinkTest < ::Minitest::Test
    def test_baseurl
      site = DummyTestSite.new config: { 'baseurl' => '/public' }

      assert_equal(
        "#{site.config['url']}#{site.config['baseurl']}/#{Api::BASEURL}",
        Api.baseurl(site),
      )
    end

    def test_add_self_link_to_collection_items
      site = DummyTestSite.new config: { 'baseurl' => '/public' }
      site.data['team'] = {
        'mbland' => { 'name' => 'mbland', 'full_name' => 'Mike Bland' },
      }

      Api.add_self_links(site)

      assert_equal(
        "#{Api.baseurl site}/team/mbland",
        site.data['team']['mbland']['self'],
      )
    end
  end
end
