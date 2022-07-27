Rails.configuration.to_prepare do
  require 'redmine_favorite_projects/helpers/favorite_projects_helper'

  require 'redmine_favorite_projects/hooks/views_projects_form_hook'
  require 'redmine_favorite_projects/hooks/views_layouts_hook'

  if Redmine::VERSION.to_s < '3.4'
    require 'redmine_favorite_projects/patches/application_helper_patch'
  end
  require 'redmine_favorite_projects/patches/project_patch'
  require 'redmine_favorite_projects/patches/projects_controller_patch'
  require 'redmine_favorite_projects/patches/projects_helper_patch'
  require 'redmine_favorite_projects/patches/auto_completes_controller_patch'
  require 'redmine_favorite_projects/patches/queries_helper_patch'
  require 'redmine_favorite_projects/patches/access_control_patch'
end

module RedmineFavoriteProjects

  def self.settings() Setting[:plugin_redmine_favorite_projects].blank? ? {} : Setting[:plugin_redmine_favorite_projects] end

  def self.default_list_style
    return (%w(list list_cards) && [RedmineFavoriteProjects.settings["default_list_style"]]).first || "list"
  end

end
