require_dependency 'auto_completes_controller'

module RedmineFavoriteProjects
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
        end
      end

      module InstanceMethods
        def project_tags
          unless request.xhr?
            render_404
            return
          end

          @tags = Project.available_tags

          q = (params[:q] || params[:term]).to_s.strip.downcase
          if q.present?
            @tags = @tags.where("LOWER(#{RedmineCrm::Tag.table_name}.name) LIKE ?", "%#{q}%").limit(10)
          end
          render :layout => false, :partial => 'project_tag_list'
        end
      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedmineFavoriteProjects::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedmineFavoriteProjects::Patches::AutoCompletesControllerPatch)
end
