class TestData
  def self.config
    @config ||= YAML.load_file('spec-integration/test-data.yml')
  end
  def self.registered_domain(provider)
    config[provider.to_s]['registered-domain']
  end
end
