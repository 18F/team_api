# @author Mike Bland (michael.bland@gsa.gov)

module TeamApi
  class Config
    def self.endpoint_config
      @endpoint_config ||= begin
        endpoint_config_path = File.join File.dirname(__FILE__), 'endpoints.yml'
        SafeYAML.load_file endpoint_config_path, safe: true
      end
    end

    def self.endpoint_info_by_collection
      @endpoint_info_by_collection ||= Config.endpoint_config.map do |item|
        [item['collection'], item]
      end.to_h
    end
  end
end
