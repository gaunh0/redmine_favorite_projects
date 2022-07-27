module RedmineFavoriteProjects
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_html_head, partial: 'favorite_projects/additional_assets'
      render_on :view_layouts_base_body_bottom, partial: 'favorite_projects/select2_transformation_rules'
    end
  end
end
