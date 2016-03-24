require 'active_model'

module TeamApi
  class AboutYmlValidator
    include ActiveModel::Validations

    validates_presence_of %w(name
                             full_name
                             description
                             impact
                             stage
                             team
                             licenses
                             owner_type
                             testable)

    def initialize(attributes = {})
      @attributes = attributes
    end

    def read_attribute_for_validation(key)
      @attributes[key]
    end

    def get_attribute(key)
      @attributes[key]
    end

    def set_attribute(key, value)
      @attributes[key] = value
    end
  end
end
