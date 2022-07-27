class FavoriteProjectsController < ApplicationController
  unloadable
  include FavoriteProjectsHelper
  helper :projects
  helper :custom_fields
  helper :queries

  skip_before_action :check_if_login_required, :only => [:search]
  before_action :deny_for_unauthorized, :only => [:favorite, :unfavorite, :favorite_css]
  before_action :find_project_by_project_id, :except => :search

  accept_api_auth :search

  def search
    retrieve_projects_query
    @limit = Setting.feeds_limit.to_i
    if @query.valid?

      case params[:format]
      when 'csv', 'pdf'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end

      @project_count = @query.object_count

      @project_pages = Paginator.new(@project_count ,  @limit, params[:page])
      @offset ||= @project_pages.offset

      @projects = @query.results_scope(
          :include => [:avatar],
          :search => params[:search],
          :limit  =>  @limit,
          :offset =>  @offset
      )

      respond_to do |format|
        if request.xhr?
          format.html { render :partial => "projects/#{favorite_project_list_style}", :layout => false }
        else
          @tags = Project.available_tags
          format.html { render :template => "projects/index"}
        end
        format.js { render :partial => "search" }

        format.api  {
          @offset, @limit = api_offset_and_limit
          @project_count = @project_count
          @projects = @projects.to_a
          render :template => "projects/index", :type => 'api'
        }
        format.atom {
          projects = @projects.reorder(:created_on => :desc).limit(Setting.feeds_limit.to_i).to_a
          render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
        }
      end
    else #not valid query
      respond_to do |format|
        format.html do
          @tags = Project.available_tags
          render(:template => 'projects/index', :layout => !request.xhr?)
        end
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def favorite
    if @project.respond_to?(:visible?) && !@project.visible?(User.current)
      render_403
    else
      set_favorite(User.current, true)
    end
  end

  def unfavorite
    set_favorite(User.current, false)
  end

  # Returns the css class used to identify watch links for a given +object+
  def favorite_css(object)
    "#{object.class.to_s.underscore}-#{object.id}-favorite"
  end

  private

  def set_favorite(user, favorite)
    if favorite
      FavoriteProject.create(:project_id => @project.id, :user_id => user.id)
    else
      favorite_project = FavoriteProject.where(:project_id => @project.id, :user_id => user.id).first
      favorite_project.delete if favorite_project.present?
    end

    respond_to do |format|
      format.html do
        redirect_back_or(projects_url) do
          return render(
            plain: (favorite ? 'Favorite added.' : 'Favorite removed.'),
            layout: true
          )
        end
      end
      format.js { render :partial => 'set_favorite' }
    end
  end

  def deny_for_unauthorized
    deny_access unless User.current.logged?
  end

  def redirect_back_or(fallback_location, &block)
    referer = Rails.version > '5.0' ? request.headers['Referer'] : request.headers['HTTP_REFERER']
    return yield block unless referer
    return redirect_to :back if defined?(::ActionController::RedirectBackError)
    redirect_back(fallback_location: fallback_location)
  end
end
