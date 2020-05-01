Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resource :login, only: [:show] do
    member do
      post :openid
      post :account
    end
  end

  resource :logout, only: [:show]

  resource :list do
    member do
      get :refresh
      get :download
    end
  end

  resources :config, only: [:show], controller: :configs do
    member do
      post :find_user
      patch :update_roles
    end
  end

  get '/config_html/:id', to: 'pages#show', as: :config_html
  resources :togodb_pages, only: %i[edit update], controller: :pages do
    member do
      patch :columns_settings
      patch :columns_link
      get :view_css_default
      get :view_header_default
      get :view_body_default
      get :quickbrowse_default
      get :show_css_default
      get :show_header_default
      get :show_body_default
    end
  end

  # Uploaded files (Supplementary files)
  resources :togodb_supplementary_files, controller: :supplementary_files, only: %i[create update destroy]
  get '/upload_files/:id', to: 'supplementary_files#show', as: :upload_files
  get '/supplementary_files/:id/:dirpath', to: 'supplementary_files#list', dirpath: /.+/
  get '/files/:id/:fpath', to: 'supplementary_files#send_supplementary_file', fpath: /.+/

  resources :tables do
    member do
      get   :copy
      post  :copy
      get   :copied_percentage
      get   :copy_result
      get   :append
      post  :columns_rdf
      get   :release
      get   :download
    end
  end

  resources :togodb_tables, controller: :tables
  resources :togodb_columns, controller: :columns

  # Entry
  get '/entry/:db(/:id)', to: 'entries#show'
  get '/entry_form/:db(/:id)', to: 'entries#form', id: /.+/, as: :entry_form
  post '/entry/:db', to: 'entries#create', as: :create_entry
  patch '/entry/:db/:id', to: 'entries#update', as: :update_entry
  delete '/entries/:db', to: 'entries#destroy', as: :delete_entries
  get '/entries/quickbrowse/:db/:id', to: 'entries#quickbrowse', as: :quickbrowse
  get '/entries/quickbrowse_edit_form/:db/:id', to: 'entries#quickbrowse_edit_form', as: :quickbrowse_form

  # Preview
  post '/preview/table/:id', to: 'tables#show'
  post '/preview/entry/:db', to: 'entries#show'

  resources :users do
    member do
      get :toggle_deleted, format: "js"
    end
  end
  resources :togodb_users, controller: :users

  # Create (Data import)
  get '/create', to: 'creates#new'
  resources :creates, only: [:create] do
    member do
      get  :upload
      post :upload
      get  :header
      post :header
      get  :columns
      post :columns
      get  :progress
      get  :status
      get  :populated_percentage
      get  :convert_progress
    end
  end

  # Release
  get '/release/:id', to: 'releases#show', format: false, as: :release
  get '/release/:id.:format', to: 'releases#download'
  resource :release, only: [] do
    member do
      get :list
    end
  end
  resources :releases, only: [:index] do
    member do
      get :run
      get :redraw
    end
  end

  # Metadata
  resources :togodb_db_metadata, controller: :metadata

  # User role
  resources :togodb_roles, only: %i[create destroy], controller: :roles

  # SPARQL
  resources :sparql do
    member do
      # for D2RQ Mapper
      post :search
    end
  end

  get '/db/:id', to: 'tables#show', as: :data_list
  get '/togodb/flexigrid/:id', to: 'tables#flexigrid'
  get '/togodb/fetch/:id', to: 'tables#fetch', as: :flexigrid_fetch
  get '/togodb/info/:id', to: 'tables#info'

  #----- D2RQ Mapper -----#
  resources :triples_maps, except: [:show]
  get '/config_rdf/:id', to: 'triples_maps#show', as: :config_rdf
  get '/change_subject_format_form/:class_map_property_id/:class_map_property_setting_id', to: 'triples_maps#change_subject_format_form'
  get '/change_object_value_form/:property_bridge_id/:property_bridge_property_id', to: 'triples_maps#change_object_value_form'
  get '/ajax/new_property_bridge_form', to: 'triples_maps#new_property_bridge_form'
  get '/ajax/del_property_bridge_form', to: 'triples_maps#del_property_bridge_form'
  get '/ajax/new_predicate_form', to: 'triples_maps#new_predicate_form'

  resources :namespaces, only: %i[show update] do
    resources :ontologies, shallow: true, as: :namespace_settings
  end
  get '/namespaces/new_namespace_form/:id', to: 'namespaces#new_namespace_form', as: :new_namespace_form
  get '/ontologies/:id/:ontology_name', to: 'ontologies#content'

  # Ontology
  get '/ontology/:id', to: 'ontologies#content'

  resources :d2rq_mapping do
    member do
      get :download
      get :by_table
      get :by_column
      get :by_table_join
    end
  end

  resources :r2rml_mapping do
    member do
      get :download
    end
  end

  resources :turtle do
    member do
      get :download
      get :by_table
      get :by_column
      get :by_table_join
      get :preview
      get :generate
      get :generation_status
      get :refresh_button_area
    end
  end

  # Search API (Like REST API)
  get '/search/:id(/:query(/:page))(.:format)', to: 'tables#open_search', query: /[^\/]*/
  get '/db/:id(/:search(/:page))(.:format)', to: 'tables#show'

  #----- root -----#
  root 'welcome#index'
end
