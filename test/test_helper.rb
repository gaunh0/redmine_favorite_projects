# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

class RedmineFavoriteProjects::TestCase

  def self.create_fixtures(fixtures_directory, table_names, class_names = {})
    if ActiveRecord::VERSION::MAJOR >= 4
      ActiveRecord::FixtureSet.create_fixtures(fixtures_directory, table_names, class_names = {})
    else
      ActiveRecord::Fixtures.create_fixtures(fixtures_directory, table_names, class_names = {})
    end
  end
end

def compatible_request(type, action, parameters = {})
  headers = parameters.delete(:headers) || {}
  @request.headers.merge!(headers)
  @request.env.merge!(headers)
  return send(type, action, params: parameters) if Rails.version >= '5.1'
  send(type, action, parameters)
end

def compatible_xhr_request(type, action, parameters = {})
  return send(type, action, params: parameters, xhr: true) if Rails.version >= '5.1'
  xhr type, action, parameters
end
