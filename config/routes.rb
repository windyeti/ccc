Rails.application.routes.draw do
  root to: 'tovs#index'
  resources :tovs do
    collection do
      get :download
      post :import
      get :xml
      get :csv_param
      post :delete_selected
      get :create_csv_with_params
    end
  end
end
