require_relative 'test_helper'
require_relative '../lib/team_api'
require_relative 'site'

require 'json'
require 'minitest/autorun'

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

    def assert_collection_and_element_endpoints_match(site, collection,
      elements)
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
        site, 'departments', ['practices'])
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

  class AddSelfLinkTest < ::Minitest::Test
    def test_baseurl
      site = DummyTestSite.new config: { 'baseurl' => '/public' }
      assert_equal(
        "#{site.config['url']}#{site.config['baseurl']}/#{Api::BASEURL}",
        Api.baseurl(site))
    end

    def test_add_self_link_to_collection_items
      site = DummyTestSite.new config: { 'baseurl' => '/public' }
      site.data['team'] = {
        'mbland' => { 'name' => 'mbland', 'full_name' => 'Mike Bland' },
      }
      Api.add_self_links(site)
      assert_equal("#{Api.baseurl site}/team/mbland",
        site.data['team']['mbland']['self'])
    end
  end

  # Since snippets are split across endpoints in particular ways, they warrant
  # their own test fixture.
  class SnippetsApiTest < ::Minitest::Test
    attr_accessor :site

    def setup
      @site = DummyTestSite.new

      site.data['team'] = {
        'mbland' => { 'name' => 'mbland', 'full_name' => 'Mike Bland' },
      }
      site.data['snippets'] = {
        '20150629' => [{ 'name' => 'mbland', 'last-week' => 'did stuff' }],
        '20150706' => [{ 'name' => 'mbland', 'last-week' => 'did moar stuff' }],
      }

      Api.generate_api site
    end

    def pages
      site.pages.map { |p| [p.url, p] }.to_h
    end

    def snippets
      site.data['snippets']
    end

    def parse_page_content(page_url)
      JSON.parse pages[page_url].content
    end

    def user_snippet_from_batch(datestamp, username)
      snippets[datestamp].detect { |snippet| snippet['name'] == username }
    end

    # rubocop:disable MethodLength
    def test_all_endpoints_present
      expected = [
        '/api/',
        '/api/snippets/api.json',
        '/api/snippets/20150629/api.json',
        '/api/snippets/20150706/api.json',
        '/api/snippets/latest/api.json',
        '/api/snippets/mbland/api.json',
        '/api/snippets/mbland/latest/api.json',
        '/api/team/api.json',
        '/api/team/mbland/api.json',
      ]
      assert_equal expected.sort, pages.keys.sort
    end
    # rubocop:enable MethodLength

    def test_snippet_summary
      expected = {
        'latest' => '20150706',
        'all' => %w(20150706 20150629),
        'users' => [{ 'name' => 'mbland', 'full_name' => 'Mike Bland' }],
      }
      assert_equal expected, parse_page_content('/api/snippets/api.json')
    end

    def test_weekly_batches
      assert_equal(
        { 'self' => 'https://team-api.18f.gov/api/snippets/20150629',
          'results' => snippets['20150629'],
        },
        parse_page_content('/api/snippets/20150629/api.json'))
      assert_equal(
        { 'self' => 'https://team-api.18f.gov/api/snippets/20150706',
          'results' => snippets['20150706'],
        },
        parse_page_content('/api/snippets/20150706/api.json'))
    end

    def test_latest_batch
      assert_equal(
        { 'datestamp' => '20150706',
          'self' => 'https://team-api.18f.gov/api/snippets/latest',
          'results' => snippets['20150706'],
        },
        parse_page_content('/api/snippets/latest/api.json'))
    end

    def test_user_batch
      expected = {
        '20150706' => user_snippet_from_batch('20150706', 'mbland'),
        '20150629' => user_snippet_from_batch('20150629', 'mbland'),
      }
      actual = parse_page_content '/api/snippets/mbland/api.json'
      assert_equal expected, actual
      assert_equal expected.keys, actual.keys
    end

    def test_latest_user_snippet
      assert_equal(
        { '20150706' => user_snippet_from_batch('20150706', 'mbland') },
        parse_page_content('/api/snippets/mbland/latest/api.json'))
    end
  end
end
