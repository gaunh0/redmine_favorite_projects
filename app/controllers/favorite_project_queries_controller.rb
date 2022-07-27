class FavoriteProjectQueriesController < ApplicationController
  before_action :find_query, :except => [:new, :create, :index]

  accept_api_auth :index

  helper :queries
  include QueriesHelper
  include FavoriteProjectsHelper

  before_action do
    unless(User.current.allowed_to?(:manage_public_favorite_project_queries, nil, :global => true) || User.current.allowed_to?(:manage_favorite_project_queries, nil, :global => true))
      deny_access
    end
  end

  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end
    @query_count = FavoriteProjectsQuery.visible.count
    @query_pages = Paginator.new @query_count, @limit, params['page']
    @queries = FavoriteProjectsQuery.visible.
                                     order("#{Query.table_name}.name").
                                     limit(@limit).
                                     offset(@offset).
                                     all
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @query = FavoriteProjectsQuery.new
    @query.user = User.current

    unless User.current.allowed_to?(:manage_public_favorite_project_queries, nil, :global => true) || User.current.admin?
      @query.visibility = FavoriteProjectsQuery::VISIBILITY_PRIVATE
    end

    @query.build_from_params(params)
  end

  def create
    @query = FavoriteProjectsQuery.new(unsafe_params[:query])
    @query.user = User.current

    @query.build_from_params(params)

    unless User.current.allowed_to?(:manage_public_favorite_project_queries, nil, :global => true) || User.current.admin?
      @query.visibility = FavoriteProjectsQuery::VISIBILITY_PRIVATE
    end

    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to url_for(controller: 'favorite_projects', action: 'search', query_id: @query.id)
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.build_from_params(params)
    @query.name = params[:query] && params[:query][:name]

    unless User.current.allowed_to?(:manage_public_favorite_project_queries, nil, :global => true) || User.current.admin?
      @query.visibility = FavoriteProjectsQuery::VISIBILITY_PRIVATE
    end

    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to url_for(controller: 'favorite_projects', action: 'search', query_id: @query.id)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to url_for(controller: 'favorite_projects', action: 'search', set_filter: 1)
  end

  private

  def find_query
    @query = FavoriteProjectsQuery.find(params[:id])
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
