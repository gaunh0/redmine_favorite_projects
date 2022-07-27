class CreateFavoriteProjectsTemplates < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :favorite_projects_templates do |t|
      t.string :name
      t.integer :visibility, default: 0
      t.text :template
      t.text :description
      t.references :owner, index: true
    end
  end
end
