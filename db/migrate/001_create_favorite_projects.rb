class CreateFavoriteProjects < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def self.up
    create_table :favorite_projects do |t|
      t.column :project_id, :integer
      t.column :user_id, :integer
    end
    add_index :favorite_projects, [:project_id, :user_id]
  end


  def self.down
    drop_table :favorite_projects
  end
end
