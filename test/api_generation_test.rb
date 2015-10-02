require_relative 'test_helper'

module TeamApi
  module ApiGenerationTestHelpers
    def collection_url(collection)
      "/api/#{Canonicalizer.canonicalize collection}/api.json"
    end

    def element_url(collection, element)
      "/api/#{Canonicalizer.canonicalize collection}/" \
        "#{Canonicalizer.canonicalize element}/api.json"
    end

    def assert_collection_endpoint_matches(pages, collection)
      url = collection_url collection
      page = (pages[url] || {})
      assert_equal(impl.envelop(collection, site.data[collection].values),
        JSON.parse(page.content))
    end

    def assert_element_endpoint_matches(pages, collection, element)
      page = (pages[element_url collection, element] || {})
      assert_equal site.data[collection][element], JSON.parse(page.content)
    end

    def expected_urls(collection, elements)
      element_urls = elements.map { |e| element_url collection, e }
      ['/api/', collection_url(collection)].concat element_urls
    end

    def assert_collection_and_element_endpoints_match(
      site,
      collection,
      elements
    )
      expected = expected_urls collection, elements
      assert_equal expected.sort, site.pages.map(&:url).sort

      pages = site.pages.map { |p| [p.url, p] }.to_h

      assert_collection_endpoint_matches pages, collection
      elements.each { |e| assert_element_endpoint_matches pages, collection, e }
    end
  end

  class ApiGenerationTest < ::Minitest::Test
    attr_accessor :site, :impl
    include ApiGenerationTestHelpers

    def setup
      @site = DummyTestSite.new
      @impl = ApiImpl.new @site, Api::BASEURL
    end

    def test_generate_api_with_no_data
      Api.generate_api site

      assert_equal ['/api/'], site.pages.map(&:url)
    end

    def test_generate_public_api_with_no_data
      site.config['baseurl'] = '/public'

      Api.generate_api site

      assert_equal ['/api/'], site.pages.map(&:url)
    end

    def test_generate_api_team
      site.data['team'] = {
        'mbland' => { 'name' => 'mbland', 'full_name' => 'Mike Bland' },
      }

      Api.generate_api site

      assert_collection_and_element_endpoints_match site, 'team', ['mbland']
    end

    def test_generate_api_locations
      site.data['locations'] = {
        'DCA' => { 'code' => 'DCA', 'members' => [{ 'name' => 'mbland' }] },
      }

      Api.generate_api site

      assert_collection_and_element_endpoints_match site, 'locations', ['DCA']
    end

    def test_generate_api_projects
      site.data['projects'] = {
        'hub' => { 'name' => 'hub', 'members' => [{ 'name' => 'mbland' }] },
      }

      Api.generate_api site

      assert_collection_and_element_endpoints_match site, 'projects', ['hub']
    end

    def test_generate_api_departments
      site.data['departments'] = {
        'practices' => {
          'name' => 'practices', 'members' => [{ 'name' => 'mbland' }]
        },
      }

      Api.generate_api site

      assert_collection_and_element_endpoints_match(
        site, 'departments', ['practices']
      )
    end

    def test_generate_api_working_groups
      site.data['working-groups'] = {
        'doc' => { 'name' => 'doc', 'members' => [{ 'name' => 'mbland' }] },
      }

      Api.generate_api site

      assert_collection_and_element_endpoints_match(
        site, 'working-groups', ['doc'])
    end

    def test_generate_api_guilds
      site.data['guilds'] = {
        'accessibility' => {
          'name' => 'accessibility',
          'members' => [{ 'name' => 'bristow' }],
        },
      }

      Api.generate_api site

      assert_collection_and_element_endpoints_match(
        site, 'guilds', ['accessibility'])
    end

    def test_generate_api_skills
      site.data['skills'] = {
        'C++' => {
          'name' => 'C++',
          'slug' => 'c++',
          'self' => File.join(site.config['url'], impl.baseurl, 'c++'),
          'members' => [{ 'name' => 'mbland' }],
        },
      }

      Api.generate_api site

      assert_collection_and_element_endpoints_match site, 'skills', ['C++']
    end

    # rubocop:disable MethodLength
    def test_generate_api_interests
      slug = 'fender-stratocasters'
      site.data['interests'] = {
        'Fender Stratocasters' => {
          'name' => 'Fender Stratocasters',
          'slug' => slug,
          'self' => File.join(site.config['url'], impl.baseurl, slug),
          'members' => [{ 'name' => 'mbland' }],
        },
      }
      Api.generate_api site

      assert_collection_and_element_endpoints_match(
        site, 'interests', ['Fender Stratocasters'])
    end
    # rubocop:enable MethodLength
  end
end
