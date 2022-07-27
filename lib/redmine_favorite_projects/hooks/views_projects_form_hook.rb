module RedmineFavoriteProjects
  module Hooks
    class ViewsProjectFormHook < Redmine::Hook::ViewListener
      render_on :view_projects_form, :partial => "projects/tags"
    end
  end
end