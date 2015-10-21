module TeamApi
  module ApiImplErrorHelpers
    private

    def errors
      @errors ||= (data['errors'] || {})
    end

    def missing
      @missing ||= (data['missing'] || {})
    end

    def error_summary
      @error_summary ||= {
        'errors' => errors,
        'missing' => missing,
      }
    end

    def generate_errors_endpoint
      return if errors.empty? && missing.empty?
      endpoint = 'errors'
      Endpoint.create(site, "#{baseurl}/#{endpoint}", error_summary)
    end

    def generate_errors_index_summary_endpoint
      return if errors.empty? && missing.empty?
      generate_index_endpoint(
        'errors', 'Errors', '.about.yml parsing errors and ' \
        'repos missing a .about.yml file.',
        error_summary)
    end
  end
end
