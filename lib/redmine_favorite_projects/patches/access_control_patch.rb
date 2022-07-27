require_dependency 'project'

module RedmineFavoriteProjects
  module Patches
    module AccessControlPatch
      def self.included(base) # :nodoc:
        base.send(:extend, ClassMethods)
        base.class_eval do
          class << self
            alias_method :available_project_modules_without_favorite_projects, :available_project_modules
            alias_method :available_project_modules, :available_project_modules_with_favorite_projects
          end
        end
      end

      module ClassMethods
        def available_project_modules_with_favorite_projects
          return @fp_available_project_modules if @fp_available_project_modules

          @fp_available_project_modules = available_project_modules_without_favorite_projects - [:favorite_projects]
        end
      end
    end
  end
end

unless Redmine::AccessControl.included_modules.include?(RedmineFavoriteProjects::Patches::AccessControlPatch)
  Redmine::AccessControl.send(:include, RedmineFavoriteProjects::Patches::AccessControlPatch)
end
