# @author Mike Bland (michael.bland@gsa.gov)

require 'safe_yaml'

module TeamApi
  class FrontMatter
    class Error < StandardError
    end

    MARKER = '---'
    START_MARKER = "#{MARKER}\n"
    END_MARKER = "\n#{MARKER}\n"

    def self.update_front_matter(filename)
      end_front_matter = front_matter_end_index filename, content
      front_matter = content[0..end_front_matter]
      content = content[end_front_matter..-1]
      front_matter = SafeYAML.load front_matter, safe: true
      yield front_matter
      File.write filename, "#{front_matter.to_yaml}#{content}"
    end

    def self.front_matter_end_index(filename, content)
      unless content.start_with? START_MARKER
        fail Error, "#{filename}: contains no front matter"
      end
      end_front_matter = content.index END_MARKER, START_MARKER.size
      return end_front_matter unless end_front_matter.nil?
      fail Error, "#{filename}: front matter does not end with '#{MARKER}'"
    end
    private_class_method :front_matter_end_index
  end
end
