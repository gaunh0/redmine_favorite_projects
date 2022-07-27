class FavoriteProjectsQuery < Query
  self.queried_class = Project
  self.view_permission = :view_issues if Redmine::VERSION.to_s >= '3.4'

  VISIBILITY_PRIVATE = 0
  VISIBILITY_ROLES   = 1
  VISIBILITY_PUBLIC  = 2

  @@default_filters = { 'status' => { operator: '=', :values => [Project::STATUS_ACTIVE.to_s] } }

  self.available_columns = [
    QueryColumn.new(:name, :sortable => "#{Project.table_name}.name", :caption => :field_name),
    QueryColumn.new(:description, :sortable => "#{Project.table_name}.description", :caption => :field_description),
    QueryColumn.new(:created_on, :sortable => "#{Project.table_name}.created_on", :caption => :field_created_on),
    QueryColumn.new(:is_public, :sortable => "#{Project.table_name}.is_public", :caption => :field_is_public),
    QueryColumn.new(:status, :sortable => "#{Project.table_name}.status", :caption => :field_status),
    QueryColumn.new(:tags, :caption => :label_favorite_project_tags_plural),
  ]

  scope :visible, lambda {|*args|
    user = args.shift || User.current

    if Redmine::VERSION.to_s < '2.4'
      field = 'is_public'
      public_value = true
      private_value = false
    else
      field = 'visibility'
      public_value = VISIBILITY_PUBLIC
      private_value = VISIBILITY_PRIVATE
    end

    if user.admin?
      where("#{table_name}.#{field} <> ? OR #{table_name}.user_id = ?", private_value, user.id)
    elsif user.logged?
      where("#{table_name}.#{field} = ? OR #{table_name}.user_id = ?", public_value, user.id)
    else
      where("#{table_name}.#{field} = ?", public_value)
    end
  }

  def visible?(user=User.current)
    return true if user.admin?
    case visibility
    when VISIBILITY_PUBLIC
      true
    else
      user.respond_to?(:id) && user.id == user_id
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  def visibility=(value)
    if Redmine::VERSION.to_s < '2.4'
      self.is_public = value.to_i == VISIBILITY_PUBLIC
    else
      self[:visibility] = value
    end
  end

  def visibility
    if Redmine::VERSION.to_s < '2.4'
      is_public ? VISIBILITY_PUBLIC : VISIBILITY_PRIVATE
    else
      self[:visibility]
    end
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public? && user.allowed_to?(:manage_public_favorite_project_queries, nil , :global => true)
  end

  def initialize(attributes = nil, *args)
    super attributes
    self.filters ||= @@default_filters
  end

  def in_default_state?
    self.filters == @@default_filters
  end

  def initialize_available_filters
    add_available_filter 'name', type: :string, name: l(:field_name), order: 0
    add_available_filter 'description', type: :string, name: l(:field_description), order: 1
    add_available_filter 'created_on', type: :date_past, order: 2

    add_available_filter('is_favorite', type: :list, name: l(:label_favorite_projects), order: 3,
      values: [
        [l(:general_text_yes), ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')],
        [l(:general_text_no), ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')]
      ])

    add_available_filter('is_public', type: :list_optional, name: l(:field_is_public), order: 4,
      values: [
        [l(:general_text_yes), ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')],
        [l(:general_text_no), ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')]
      ])

    add_available_filter('status', type: :list_optional, order: 6,
      values: [
        [l(:project_status_active), Project::STATUS_ACTIVE.to_s],
        [l(:project_status_closed), Project::STATUS_CLOSED.to_s],
        [l(:project_status_archived), Project::STATUS_ARCHIVED.to_s]
      ])

    principals = []
    if all_projects.any?
      if Principal.respond_to?(:visible)
        principals += Principal.member_of(all_projects).visible
      else
        principals += Principal.member_of(all_projects)
      end
    end
    principals.uniq!
    principals.sort!
    users = principals.select { |p| p.is_a?(User) }

    users_values = []
    users_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
    users_values += users.collect { |s| [s.name, s.id.to_s] }
    add_available_filter('user_id', type: :list, values: users_values, name: l(:label_members), order: 7) if users_values.any?

    add_available_filter('tags', type: :project_tags, values: Project.available_tags.collect { |t| [t.name, t.name] }, order: 8)

    add_custom_fields_filters(ProjectCustomField.where(is_filter: true))
  end

  def default_columns_names
    @default_columns_names ||= begin
      return [:name] unless RedmineFavoriteProjects.settings[:favorite_projects_list_default_columns]
      default_columns = RedmineFavoriteProjects.settings[:favorite_projects_list_default_columns].map(&:to_sym)
      default_columns.blank? ? [:name, :description, :created_on] : default_columns
    end
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup

    @available_columns += CustomField.where(:type => 'ProjectCustomField').all.collect { |cf| QueryCustomFieldColumn.new(cf) }
    @available_columns
  end

  def objects_scope(options={})
    scope = Project.visible.order(:lft)
    scope = scope.where(seach_condition(options[:search])) if options[:search].present?
    scope = scope.eager_load(query_includes) if query_includes.present?
    scope = scope.where(statement).where(options[:conditions])
    scope
  end

  def object_count
    objects_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def results_scope(options = {})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    objects_scope(options).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def sql_for_is_favorite_field(_field, _operator, value)
    if User.current.logged?
      compare   = (ActiveRecord::Base.connection.quoted_true.gsub(/'/, '') == value.try(:first)) ? 'IN' : 'NOT IN'
      ids_list  = FavoriteProject.where(:user_id => User.current.id).collect{|r| r.project_id }.push(0).join(',')
      "( #{Project.table_name}.id #{compare} (#{ids_list}) ) "
    end
  end

  def sql_for_tracker_field(field, operator, value)
    sql_for_field(field, operator, value, "#{Tracker.table_name}", 'id')
  end

  def sql_for_user_id_field(_field, operator, value)
    if value.present?
      compare   = '=' == operator ? 'IN' : 'NOT IN'
      ids_list  = Member.where(:user_id => value).map(&:project_id).push(0).join(',')
      "( #{Project.table_name}.id #{compare} (#{ids_list}) ) "
    end
  end

  def sql_for_tags_field(_field, _operator, value)
    compare   = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
    ids_list  = Project.tagged_with(value).collect { |project| project.id }.push(0).join(',')
    "( #{Project.table_name}.id #{compare} (#{ids_list}) ) "
  end

  private

  def seach_condition(search)
    pattern = "%#{search.to_s.strip.downcase}%"
    ["(LOWER(#{Project.table_name}.name) LIKE :p OR
       LOWER(identifier) LIKE :p OR
       LOWER(#{Project.table_name}.description) LIKE :p)",
       { p: pattern }]
  end

  def query_includes
    includes = []
    includes << :trackers if self.filters['tracker']
    includes
  end
end
