#custom routes for this plugin

resources :favorite_project_queries

match "favorite_projects/favorite" => "favorite_projects#favorite", :via => [:post]
match "favorite_projects/unfavorite" => "favorite_projects#unfavorite", :via => [:delete]

match "favorite_projects/search" => "favorite_projects#search", :as => "search_favorite_projects", :via => [:get, :post]

match 'auto_completes/project_tags' => 'auto_completes#project_tags', :via => :get, :as => 'auto_complete_project_tags'
