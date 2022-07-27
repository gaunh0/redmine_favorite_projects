require File.expand_path('../../test_helper', __FILE__)

class AutoCompletesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details

  RedmineFavoriteProjects::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_favorite_projects).directory + '/test/fixtures/', [:favorite_projects, :queries])

  def setup
    @request.session[:user_id] = 1
    project = Project.find(4)
    User.current =  User.find(1)

    project.safe_attributes = { 'tag_list' => 'Tag1, Tag2'}
    project.save!
  end

  def test_project_tags
    compatible_request :get, :project_tags, :q => 'tag'
    assert_response 404

    compatible_xhr_request :get, :project_tags, :q => 'tag'
    assert_response 200
    assert_match /\"Tag1\"/, response.body
    assert_match /\"Tag2\"/, response.body

    compatible_xhr_request :get, :project_tags, :q => 'tag1'
    assert_match /\"Tag1\"/, response.body
    assert_no_match /\"Tag2\"/, response.body
  end
end
