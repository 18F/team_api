# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'api'
require_relative 'canonicalizer'
require_relative 'cross_referencer'
require_relative 'joiner'
require_relative 'snippets'
require 'hash-joiner'
require 'jekyll'

module TeamApi
  # Processes site data, generates authorization artifacts, publishes an API,
  # and generates cross-linked Hub pages.
  class Generator < ::Jekyll::Generator
    safe true

    # Executes all of the data processing and artifact/page generation phases
    # for the Hub.
    def generate(site)
      Joiner.join_data(site)
      Snippets.publish(site)
      CrossReferencer.build_xrefs(site)
      Canonicalizer.canonicalize_data(site.data)
      ::HashJoiner.prune_empty_properties(site.data)
      Api.generate_api(site)
    end
  end
end
