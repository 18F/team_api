require_relative 'test_helper'

module TeamApi
  class ErrorsApiTest < ::Minitest::Test
    attr_accessor :site

    def setup
      @site = DummyTestSite.new

      site.data['team'] = {
        'mbland' => { 'name' => 'mbland', 'full_name' => 'Mike Bland' },
      }
      site.data['errors'] = {
        'projA' => %w(Error1 Error2),
        'projB' => ['Error3'],
      }
      site.data['missing'] = %w(projC projD)

      Api.generate_api site
    end

    def expected_endpoints
      [
        '/api/',
        '/api/errors/api.json',
        '/api/team/api.json',
        '/api/team/mbland/api.json',
      ]
    end

    def pages
      site.pages.map { |page| [page.url, page] }.to_h
    end

    def errors
      site.data['errors']
    end

    def test_all_endpoints_present
      assert_equal expected_endpoints.sort, pages.keys.sort
    end

    def parse_page_content(page_url)
      JSON.parse pages[page_url].content
    end

    def test_error_summary
      expected = {
        'errors' => {
          'projA' => %w(Error1 Error2),
          'projB' => ['Error3'],
        },
        'missing' => %w(projC projD),
      }
      assert_equal expected, parse_page_content('/api/errors/api.json')
    end
  end
end
