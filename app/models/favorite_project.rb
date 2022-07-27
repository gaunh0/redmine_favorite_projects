class FavoriteProject < ActiveRecord::Base
  unloadable

  validates_presence_of :project_id, :user_id
  validates_uniqueness_of :project_id, :scope => [:user_id]

  def self.favorite?(project_id, user_id=User.current.id)
    FavoriteProject.where(:project_id => project_id, :user_id => user_id).present?
  end
end
