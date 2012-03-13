Leihs::Application.routes.draw do

  root :to => "application#index"

#rails3#
  # Install the default routes as the lowest priority.
  match '/authenticator/zhdk/login', :to => 'authenticator/zhdk#login'
  match '/authenticator/zhdk/login_successful/:id', :to => 'authenticator/zhdk#login_successful'
  match '/authenticator/db/:action', :to => 'authenticator/database_authentication'
  match '/authenticator/ldap/:action', :to => 'authenticator/ldap_authentication'
  match '/authenticator/shibboleth/:action/:id', :to => 'authenticator/shibboleth_authentication'

  # For RESTful_Authentication
  match '/activate/:activation_code', :to => 'users#activate', :activation_code => nil
  match '/signup', :to => 'users#new'
  match '/login', :to => 'sessions#new'
  match '/logout', :to => 'sessions#destroy'
  match '/switch_to_ldap', :to => 'sessions#switch_to_ldap' #TODO 1009: Remove when not used anymore
  
  match '/backend', :to => "backend/backend#index"
  # match '/inventory', :to => 'inventory/inventory_pools#index' # NOTE seems not to be used any longer

############################################################################
# Frontend

  match '/search', :to => 'frontend#search'

  # used for the current_user
  resource :user do
    resources :orders do #TODO#, :only => [:show, :destroy]
      member do
        get :submitted
      end
    end
    resources :contracts
  end

  # used for the current_order
  resource :order do
    member do
      post :submit
      post :add_line
      post :change_line_quantity
      delete :remove_lines
      post :change_time_lines
    end
  end

  resource :session do
    member do
      get :authenticate # TODO 2012 both needed? 
      post :authenticate # TODO 2012 both needed? 
      get :old_new # TODO 05** remove, only for offline login
    end
  end

  resource :authenticator do
    match 'login', :to => "authenticator/database_authentication#login"
  end

  resources :models, :except => :index do
    member do
      get :chart
      get :book
    end
  end
  
  resources :categories do 
    resources :models
  end
  
  resources :templates do 
    resources :models
  end
  
  resources :inventory_pools

############################################################################
# Backend

  namespace :backend do
    #tmp# match 'database_backup', :to => 'backend#database_backup'
    
    root :to => "backend#index"
    match 'search', :to => 'backend#search'

    resources :barcodes

    resources :users do
      member do
        get :access_rights
        post :add_access_right
        delete :remove_access_right
        get :extended_info
        post :update_badge_id
      end
    end
   
    resources :mails

    resources :inventory_pools do
      resources :acknowledge, :except => :index do
        member do
          post :approve
          get :reject
          post :reject
          get :delete
          post :add_line
          post :update_lines 
          get :swap_user
          post :swap_user
          get :change_purpose
          post :change_purpose
        end
      end
      match 'search', :to => 'backend#search'
  
      resources :mails

      resources :orders
      resources :contracts
      resources :visits, :only => :index
      
      resources :locations do
        resources :items
      end
      resources :categories do
        member do
          #rails3# OPTIMIZE
          get :add_parent
          post :add_parent
          put :add_parent
          delete :add_parent
        end
        resources :parents, :controller => 'categories'
        resources :children, :controller => 'categories'
        resources :models
      end
      resources :options
      resources :models do
        collection do
          get :new_package
          post :update_package
        end
        member do
          get :details
          get :groups
          get :properties
          post :properties
          get :accessories
          post :accessories
          put :accessories
          delete :accessories
          get :package
          delete :destroy_package
          put :update_package
          get :package_roots
          post :package_roots
          put :package_roots
          delete :package_roots
          get :package_item
          put :package_item
          delete :package_item
          get :categories
          post :categories
          get :images
          post :images
          delete :images
          get :attachments
          post :attachments
          delete :attachments
          post :set_group_partition          
        end
            resources :compatibles, :controller => 'models'
            resources :items do
              member do
                get :location
                post :location
                put :location
                get :status
                get :notes
                post :notes
                get :show 
                post :toggle_permission
                get :retire
                post :retire
                post :get_notes
               end
           end
      end
      resources :templates do
        member do
          get :models
          put :add_model
        end
      end
      resources :items do
        collection do
          get :supplier
          post :supplier
          get :inventory_codes
        end
        member do
          get :location
          post :location
          put :location
          get :status
          get :notes
          post :notes
          get :show 
          post :toggle_permission
          post :get_notes
        end
      end
      resources :users do
        member do
          get :new_contract
          get :remind
          get :access_rights
          post :add_access_right
          delete :remove_access_right
          post :suspend_access_right
          post :reinstate_access_right
          get :extended_info
          get :things_to_return
          get :groups
          put :add_group
          delete :remove_group
          post :update_badge_id          
        end
        resource :hand_over, :controller => 'hand_over' do
          member do
            get :add_line
            post :add_line
            post :add_line_with_item # TODO 29**
            post :change_line_quantity
            post :change_line
            get :remove_lines
            delete :remove_lines
            get :swap_model_line
            post :swap_model_line
            get :time_lines
            post :time_lines
            get :sign_contract
            post :sign_contract
            get :add_option
            post :add_option
            post :assign_inventory_code
            delete :delete_visit
            get :swap_user 
            post :swap_user 
            post :set_purpose
          end
        end
        resource :take_back, :controller => 'take_back' do
          member do
            get :close_contract
            post :close_contract
            post :assign_inventory_code
            get :inspection
            post :inspection
            get :time_lines
            post :time_lines
          end
        end
      end
      resources :workdays do
        collection do
          get :close # OPTIMIZE post (ajax)
          get :open # OPTIMIZE post (ajax)
          post :add_holiday
          get :delete_holiday # OPTIMIZE post (ajax)
        end
      end
      resources :groups do
        member do
          get :users
          put :add_user
        end
      end
      resource :availability, :controller => 'availability'
    end
  end

end
