require File.expand_path('../../test_helper', __FILE__)

class FavoriteProjectTest < ActiveSupport::TestCase

  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles

  def test_add_tag
    project = Project.find(4)
    User.current =  User.find(1)

    project.safe_attributes = { 'tag_list' => 'Tag1, Tag2'}
    project.save    
    assert_equal ['Tag1', 'Tag2'], project.reload.tag_list.sort
  end

end
