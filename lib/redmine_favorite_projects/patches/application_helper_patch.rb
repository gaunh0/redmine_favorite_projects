require_dependency 'application_helper'

module RedmineFavoriteProjects
  module Patches

    module ApplicationHelperPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method :render_project_jump_box_without_only_favorites, :render_project_jump_box
          alias_method :render_project_jump_box, :render_project_jump_box_with_only_favorites
        end
      end

      module InstanceMethods
        # Adds a rates tab to the user administration page
        def render_project_jump_box_with_only_favorites
          return unless User.current.logged?
          favorite_projects_ids = FavoriteProject.where(:user_id => User.current.id).map(&:project_id)
          projects = Project.visible.where(:id => favorite_projects_ids)

          projects = Project.visible unless projects.any?

          if projects.any?
            s = '<select name="project_quick_jump_box" id="project_quick_jump_box" onchange="if (this.value != \'\') { window.location = this.value; }">' +
            "<option value=''>#{ l(:label_jump_to_a_project) }</option>" +
            '<option value="" disabled="disabled">---</option>'
            s << project_tree_options_for_select(projects, :selected => @project) do |p|
              { :value => url_for(:controller => 'projects', :action => 'show', :id => p, :jump => current_menu_item) }
            end
            s << '</select>'
            s.html_safe
          end
        end
      end

    end
  end
end


if Redmine::VERSION.to_s < '3.4' && !ApplicationHelper.included_modules.include?(RedmineFavoriteProjects::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineFavoriteProjects::Patches::ApplicationHelperPatch)
end
