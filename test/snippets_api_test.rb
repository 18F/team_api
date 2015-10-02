require_relative 'test_helper'

module TeamApi
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

    # rubocop:disable MethodLength
    def expected_endpoints
      [
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
    end
    # rubocop:enable MethodLength

    def pages
      site.pages.map { |page| [page.url, page] }.to_h
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

    def snippet_response_body(date)
      {
        'self' => "https://team-api.18f.gov/api/snippets/#{date}",
        'results' => snippets[date],
      }
    end

    def test_all_endpoints_present
      assert_equal expected_endpoints.sort, pages.keys.sort
    end

    def test_snippet_summary
      expected = {
        'latest' => '20150706',
        'all' => %w(20150706 20150629),
        'users' => [{ 'name' => 'mbland', 'full_name' => 'Mike Bland' }],
      }

      assert_equal expected, parse_page_content('/api/snippets/api.json')
    end

    def test_weekly_batches
      first_date = '20150629'
      second_date = '20150706'

      assert_equal(
        snippet_response_body(first_date),
        parse_page_content("/api/snippets/#{first_date}/api.json"),
      )

      assert_equal(
        snippet_response_body(second_date),
        parse_page_content("/api/snippets/#{second_date}/api.json"),
      )
    end

    def test_latest_batch
      assert_equal(
        {
          'datestamp' => '20150706',
          'self' => 'https://team-api.18f.gov/api/snippets/latest',
          'results' => snippets['20150706'],
        },
        parse_page_content('/api/snippets/latest/api.json'),
      )
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
        parse_page_content('/api/snippets/mbland/latest/api.json'),
      )
    end
  end
end
