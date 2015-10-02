module TeamApi
  module ApiImplSnippetHelpers
    private

    def snippet_dates
      @snippet_dates ||= (data['snippets'] || {}).keys.sort.reverse
    end

    def snippets
      @snippets ||= snippet_dates.map { |t| [t, data['snippets'][t]] }.to_h
    end

    def snippets_by_user
      @snippets_by_user ||= snippets
        .flat_map { |date, batch| batch.map { |snippet| [date, snippet] } }
        .group_by { |_date, snippet| snippet['name'] }
        .map { |name, mapping| [name, mapping.to_h] }
        .to_h
    end

    def snippets_summary
      @snippet_summary ||= {
        'latest' => snippet_dates.first,
        'all' => snippet_dates,
        'users' => Canonicalizer.team_xrefs(
          data['team'], snippets_by_user.keys),
      }
    end

    def generate_latest_snippet_endpoint
      return if snippets.empty?
      latest = snippets.first
      endpoint = 'snippets/latest'
      Endpoint.create(site, "#{baseurl}/#{endpoint}",
        { 'datestamp' => latest[0] }.merge(envelop(endpoint, latest[1])))
    end

    def generate_snippets_by_date_endpoints
      snippets.each do |timestamp, batch|
        endpoint = "snippets/#{timestamp}"
        Endpoint.create site, "#{baseurl}/#{endpoint}", envelop(endpoint, batch)
      end
    end

    def generate_snippets_by_user_endpoints
      snippets_by_user.each do |name, batch|
        Endpoint.create site, "#{baseurl}/snippets/#{name}", batch
        Endpoint.create(
          site, "#{baseurl}/snippets/#{name}/latest", [batch.first].to_h)
      end
    end

    def generate_snippets_index_summary_endpoint
      generate_index_endpoint(
        'snippets', 'Snippets', 'Summary of all available snippets',
        snippets_summary) unless snippets.empty?
    end
  end
end
