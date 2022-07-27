require File.expand_path('../../test_helper', __FILE__)

class FavoriteProjectsControllerTest < ActionController::TestCase
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
  end

  def test_search
    compatible_request :get, :search
    assert_select 'tr.project', { :count => 6 }

    compatible_request :get, :search, :search => 'E-commerce'
    assert_select 'tr.project', { :count => 1 }
    assert_match /E-commerce/, response.body
  end

  def test_search_with_query
    compatible_request :get, :search, :query_id => 1
    assert_select 'tr.project', { :count => 1 }
    assert_match /eCookbook/, response.body
  end

  def test_search_with_filters
    compatible_request :get, :search, :f =>['name', 'description', 'created_on', 'is_public', 'status'],
    :op => {
      'name' => '!',
      'description' => '!~',
      'created_on' => '>=',
      'is_public' => '=',
      'status' => '='
      },
    :v => { 
      'name' => ['OnlineStore'],
      'description' => ['E-commerce'],
      'created_on' => ['2006-06-19'],
      'is_public' => ['1'],
      'status' => ["#{Project::STATUS_ACTIVE}"],
    }
    assert_select 'tr.project', { :count => 4 }
  end

  def test_get_search_with_tag
    @request.session[:user_id] = 1

    project = Project.find(4)
    project.tag_list = 'Tag1, Tag2'
    project.save

    compatible_request :get, :search, {
      :f =>['tags'],
      :op => {'tags' => "="},
      :v => {'tags' => ['Tag1']}
    }

    assert_select 'tr.project', { :count => 1 }
    assert_match /eCookbook Subproject 2/, response.body
  end

  def test_get_search_by_cards
    compatible_request :get, :search, :favorite_project_list_style => 'list_cards'
    assert_select 'div.project_card', { :count => 6 }
  end

  def test_favorite
    assert_equal 2, FavoriteProject.where(:user_id => 1).count
    compatible_request :post, :favorite, project_id: 6, headers: { 'Referer' => '/', 'HTTP_REFERER' => '/' }
    assert_response 302
    assert_equal 3, FavoriteProject.where(:user_id => 1).count
  end

  def test_unfavorite
    compatible_request :delete, :unfavorite, project_id: 2, headers: { 'Referer' => '/', 'HTTP_REFERER' => '/' }
    assert_response 302
    assert_equal 1, FavoriteProject.where(:user_id => 1).count
  end
end
