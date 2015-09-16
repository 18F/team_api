# @author Mike Bland (michael.bland@gsa.gov)

module TeamApi
  class NameCanonicalizer
    # Sorts an array of team member data hashes based on the team members'
    # last names.
    # +team+:: An array of team member data hashes
    def self.sort_by_last_name(team)
      team.sort_by { |member| comparable_name member }
    end

    def self.sort_by_last_name!(team)
      team.sort_by! { |member| comparable_name member }
    end

    def self.comparable_name(person)
      if person['last_name']
        [person['last_name'].downcase, person['first_name'].downcase]
      else
        # Trim off title suffix, if any.
        full_name = person['full_name'].downcase.split(',')[0]
        last_name = full_name.split.last
        [last_name, full_name]
      end
    end
    private_class_method :comparable_name
  end
end
