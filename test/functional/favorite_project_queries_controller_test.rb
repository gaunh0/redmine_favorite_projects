require File.expand_path('../../test_helper', __FILE__)

class FavoriteProjectQueriesControllerTest < ActionController::TestCase
  fixtures :users, :members, :member_roles, :roles

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineFavoriteProjects::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_favorite_projects).directory + '/test/fixtures/', [:queries])

  def setup
    @p = { :default_columns => '1',
           :f => ['name'],
           :op => { 'name' => '=' },
           :v => { 'name' => ['Ivan'] }
         }
    role = Role.non_member
    role.update_attributes(permissions: ['manage_favorite_project_queries'])
  end

  def test_delete_without_deny
    @request.session[:user_id] = 2
    compatible_request :delete, :destroy, :id => 1
    assert_response 403
  end

  def test_post_create_favorite_project_public_query_without_permission
    @request.session[:user_id] = 2
    query_params = { 'name' => 'test_new_public_favorite_project_query', 'visibility' => '2' }

    compatible_request :post, :create, @p.merge(query: query_params)

    q = FavoriteProjectsQuery.find_by_name('test_new_public_favorite_project_query')
    assert_redirected_to :controller => 'favorite_projects' , :action => 'search', :query_id => q.id
    assert (not q.is_public?)
  end

  def test_edit_favorite_project_public_query_without_permission
    @request.session[:user_id] = 2
    compatible_request :get, :edit, :id => 1
    assert_response 403
  end

  def test_get_new_favorite_project_query
    @request.session[:user_id] = 1
    compatible_request :get, :new
    assert_response :success

    att = { :type => 'checkbox',
            :name => 'query_is_for_all',
            :checked => nil,
            :disabled => nil }
    assert_select 'input', :attributes => att
  end

  def test_post_create_favorite_project_public_query
    @request.session[:user_id] = 1

    query_params = { 'name' => 'test_new_public_favorite_project_query', 'visibility' => '2' }

    compatible_request :post, :create, @p.merge(query: query_params)

    q = FavoriteProjectsQuery.find_by_name('test_new_public_favorite_project_query')
    assert_redirected_to :controller => 'favorite_projects', :action => 'search', :query_id => q.id
    assert q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end

  def test_post_create_private_query
    @request.session[:user_id] = 1

    query_params = { 'name' => 'test_new_public_favorite_project_query', 'visibility' => '0' }

    compatible_request :post, :create, @p.merge(query: query_params)

    q = FavoriteProjectsQuery.find_by_name('test_new_public_favorite_project_query')
    assert_redirected_to :controller => 'favorite_projects', :action => 'search', :query_id => q.id
    assert !q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end

  def test_put_update_public_query
    @request.session[:user_id] = 1
    query_params = { 'name' => 'updated_query_name' }

    compatible_request :put, :update, @p.merge(query: query_params, id: 1)

    q = FavoriteProjectsQuery.find_by_name('updated_query_name')
    assert_redirected_to :controller => 'favorite_projects', :action => 'search', :query_id => q.id
    assert q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end

  def test_delete_destroy
    @request.session[:user_id] = 1
    compatible_request :delete, :destroy, :id => 2
    assert_redirected_to :controller => 'favorite_projects', :action => 'search', :set_filter => '1'
    assert_nil Query.find_by_id(2)
  end
end
