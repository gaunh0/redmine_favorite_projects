require_dependency 'project'

module RedmineFavoriteProjects
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
          safe_attributes 'tag_list'
          rcrm_acts_as_taggable
        end
      end
    end
  end
end

unless Project.included_modules.include?(RedmineFavoriteProjects::Patches::ProjectPatch)
  Project.send(:include, RedmineFavoriteProjects::Patches::ProjectPatch)
end
