require File.expand_path('../../test_helper', __FILE__)

class FavoriteProjectsQueryTest < ActiveSupport::TestCase
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
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details

  RedmineFavoriteProjects::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_favorite_projects).directory + '/test/fixtures/',
   [:favorite_projects, :custom_fields, :custom_values, :custom_fields_projects, :queries])

  def setup
    @query = FavoriteProjectsQuery.new(:name => '_')

    @admin = User.find(1)
    @user_2 = User.find(2)
    @user_4 = User.find(4)

    @queries = FavoriteProjectsQuery.order('id').all
    User.current = @admin
  end

  def test_objects_scope
    assert_equal [1, 2, 3, 4, 5, 6], @query.objects_scope.map(&:id).sort

    hash = {
      :f =>['name', 'description', 'created_on', 'is_public', 'status'],
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
    }
    @query = @query.build_from_params(hash)
    assert_equal [1, 3, 4, 6], @query.objects_scope.map(&:id).sort
  end

  def test_objects_scope_with_private_scope
    User.current = nil
    assert_equal [1, 3, 4, 6], @query.objects_scope.map(&:id).sort
  end

  def test_objects_scope_with_custom_field
    p = lambda { |v| return {
        :f => ['cf_22'],
        :op => { 'cf_22' => '='},
        :v => { 'cf_22' => [v] }
      }
    }

    @query = @query.build_from_params( p.call('Value 1'))
    assert_equal [2], @query.objects_scope.map(&:id).sort
  end

  def test_objects_scope_with_search_string
    assert_equal [1, 3, 4, 5], @query.objects_scope({:search => 'eCookbook'}).map(&:id).sort
  end

  def test_objects_scope_with_user_id
    p = lambda { |v, o| return {
        :f => ['user_id'],
        :op => { 'user_id' => o},
        :v => { 'user_id' => [v] }
      }
    }
    @query = @query.build_from_params( p.call('1', '='))
    assert_equal [5], @query.objects_scope.map(&:id).sort

    @query = @query.build_from_params( p.call('2', '='))
    assert_equal [1, 2, 5], @query.objects_scope.map(&:id).sort

    @query = @query.build_from_params( p.call('3', '!'))
    assert_equal [2, 3, 4, 5, 6], @query.objects_scope.map(&:id).sort
  end

  def test_objects_scope_with_user_id_with_me_value
    p = {
        :f => ['user_id'],
        :op => { 'user_id' => '='},
        :v => { 'user_id' => ['me'] }
    }

    @query = @query.build_from_params( p )

    # For user_4
    User.current = @user_4
    assert_equal [], @query.objects_scope.map(&:id).sort

    User.current = @user_2
    assert_equal [1, 2, 5], @query.objects_scope.map(&:id).sort

    User.current = User.find(3)
    assert_equal [1], @query.objects_scope.map(&:id).sort
  end

  def test_object_scope_with_tag
    User.current = @admin
    project = Project.find(4)
    project.safe_attributes = { 'tag_list' => 'Tag1'}
    project.save

    hash = {
      :f =>['tags'],
      :op => {'tags' => "="},
      :v => {'tags' => ['Tag1']}}

    @query = @query.build_from_params(hash)
    assert_equal [4], @query.objects_scope.map(&:id)
  end

  def test_objects_scope_with_favorite_projects
    User.current = User.find(1)
    p = lambda { |v| return {
        :f => ['is_favorite'],
        :op => { 'is_favorite' => '='},
        :v => { 'is_favorite' => [v] }
      }
    }

    @query = @query.build_from_params( p.call(ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')) )
    assert_equal [1, 2], @query.objects_scope.map(&:id).sort

    @query = @query.build_from_params( p.call(ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')) )
    assert_equal [3, 4, 5, 6], @query.objects_scope.map(&:id).sort
  end

  def test_visible_and_visible?
    assert_equal ['Private query 2', 'Public query 1'], FavoriteProjectsQuery.visible(@admin).map(&:name).sort
    assert_equal ['Private query 2', 'Private query 3', 'Public query 1'], FavoriteProjectsQuery.visible(@user_4).map(&:name).sort
    assert_equal ['Private query 2', 'Public query 1'], FavoriteProjectsQuery.visible(@user_2).map(&:name).sort

    assert @queries[0].visible?( @user_4 )
    assert @queries[1].visible?( @user_4 )
    assert @queries[2].visible?( @user_4 )

    assert @queries[0].visible?( @user_2 )
    assert (not @queries[2].visible?( @user_2 ))
  end

  def test_editable_by?
    assert @queries[1].editable_by?(@admin)
    assert @queries[1].editable_by?(@user_4)
    assert (not @queries[1].editable_by?(@user_2))

    Member.where(:user_id => @user_2.id).first.roles << Role.create(:name => 'EditableByRole', :issues_visibility => 'all',
                                                                    :permissions => ['manage_public_favorite_project_queries'])
    @user_2 = User.find(2) # reload user

    assert @queries[1].editable_by?(@user_2)
  end

end
