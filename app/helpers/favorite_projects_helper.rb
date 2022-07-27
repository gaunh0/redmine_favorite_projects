module FavoriteProjectsHelper
  # include ProjectsHelper

  def retrieve_projects_query
    if unsafe_params[:query_id].present?
      @query = FavoriteProjectsQuery.find(unsafe_params[:query_id])
      raise ::Unauthorized unless @query.visible?
      session[:favorite_projects_query] = {:id => @query.id}
    elsif api_request? || unsafe_params[:set_filter] || session[:favorite_projects_query].nil?
      # Give it a name, required to be valid
      @query = FavoriteProjectsQuery.new(:name => "_")
      @query.build_from_params(unsafe_params)
      session[:favorite_projects_query] = {:filters => @query.filters, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = FavoriteProjectsQuery.find(session[:favorite_projects_query][:id]) if session[:favorite_projects_query][:id]
      @query ||= FavoriteProjectsQuery.new(:name => "_", :filters => session[:favorite_projects_query][:filters],  :column_names => session[:favorite_projects_query][:column_names])
    end
  end

  def favorite_tag(object, user, options={})
    return '' unless user && user.logged?
    favorite = FavoriteProject.favorite?(object.id, user.id)
    url = {:controller => 'favorite_projects',
           :action => (favorite ? 'unfavorite' : 'favorite'),
           :project_id => object.id}
    link = link_to(image_tag(favorite ? 'fav.png' : 'fav_off.png', :style => 'vertical-align: middle;'),
                    url,
                    :method => favorite ? :delete : :post,
                    :class => favorite ? :delete : :post,
                    :remote => true)

    content_tag("span", link, :id => "favorite_project_#{object.id}").html_safe
  end

  # Returns the css class used to identify watch links for a given +object+
  def favorite_css(objects)
    objects = Array.wrap(objects)
    id = (objects.size == 1 ? objects.first.id : 'bulk')
    "#{objects.first.class.to_s.underscore}-#{object.id}-favorite"
  end

  def favorite_project_modules_links(project)
    links = []
    menu_items_for(:project_menu, project) do |node|
       links << link_to(extract_node_details(node, project)[0], extract_node_details(node, project)[1]) unless node.name == :overview
    end
    links.join(", ").html_safe
  end

  def render_sidebar_favorite_project_queries(object_type)
    query_class = Object.const_get("#{object_type.camelcase}Query")
    out = ''.html_safe
    out << favorite_project_query_links(l(:label_my_queries),  sidebar_favorite_project_queries(query_class).select(&:is_private?), object_type)
    out << favorite_project_query_links(l(:label_query_plural),  sidebar_favorite_project_queries(query_class).reject(&:is_private?), object_type)
    out
  end

  def sidebar_favorite_project_queries(query_class)
    unless @sidebar_queries
      @sidebar_queries = query_class.visible.
        order("#{query_class.table_name}.name ASC")
    end
    @sidebar_queries
  end

  def favorite_project_query_links(title, queries, object_type)
    return '' unless queries.any?
    url_params = controller_name == "#{object_type}s" ? {:controller => "#{object_type}s", :action => 'index'} : unsafe_params
    content_tag('h3', title) + "\n" +
      content_tag('ul',
        queries.collect {|query|
            css = 'query'
            css << ' selected' if query == @query
            content_tag('li', link_to(query.name, url_params.merge(:query_id => query), :class => css))
          }.join("\n").html_safe,
        :class => 'queries'
      ) + "\n"
  end

  def favorite_project_list_style
    list_styles = favorite_project_list_styles_for_select.map(&:last)
    if unsafe_params[:favorite_project_list_style].blank?
      list_style = list_styles.include?(session[:favorite_project_list_style]) ? session[:favorite_project_list_style] : RedmineFavoriteProjects.default_list_style
    else
      list_style = list_styles.include?(unsafe_params[:favorite_project_list_style]) ? unsafe_params[:favorite_project_list_style] : RedmineFavoriteProjects.default_list_style
    end
    session[:favorite_project_list_style] = list_style
  end

  def favorite_project_list_styles_for_select
    list_styles = [[l(:label_favorite_project_list_cards), "list_cards"]]
    list_styles += [[l(:label_favorite_project_list_list), "list"]]
  end

  def unsafe_params
    (
      params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash : params
    ).with_indifferent_access
  end
end
