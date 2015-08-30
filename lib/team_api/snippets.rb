# @author Mike Bland (michael.bland@gsa.gov)

require 'weekly_snippets/publisher'

module TeamApi
  class Snippets
    # Used to convert snippet headline markers to h4, since the layout uses
    # h3.
    HEADLINE = "\n####"

    MARKDOWN_SNIPPET_MUNGER = proc do |text|
      text.gsub!(/^::: (.*) :::$/, "#{HEADLINE} \\1") # For jtag. ;-)
      text.gsub!(/^\*\*\*/, HEADLINE) # For elaine. ;-)
    end

    # TODO(mbland): Push this to the snippet import script.
    def self.publish(site)
      publisher = ::WeeklySnippets::Publisher.new(
        headline: HEADLINE, public_mode: site.config['public'],
        markdown_snippet_munger: MARKDOWN_SNIPPET_MUNGER)
      site.data['snippets'] = publisher.publish site.data['snippets']
    end
  end
end
