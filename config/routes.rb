Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Multi-step form routes
  resource :form_submission, path: 'form', only: [:show, :update] do
    post 'validate_step', on: :collection
    get 'complete', on: :collection
  end
  
  # Form API routes
  resources :form_submissions_api, only: [] do
    member do
      get 'state'
      post 'move_to_step'
      post 'add_timeline_entry'
      post 'update_timeline_entry'
      delete 'remove_timeline_entry'
    end
    
    collection do
      post 'validate_step'
      post 'submit'
    end
  end

  # Existing verification routes
  resources :verifications, only: [:new, :show] do
    member do
      get 'step/:step', to: 'verifications#step', as: :step
      post 'step/:step', to: 'verifications#update_step', as: :update_step
      get 'complete', to: 'verifications#complete', as: :complete
    end
  end

  # Language switching
  get 'language/:locale', to: 'language#switch', as: :switch_language

  # Tasks routes
  resources :tasks

  # Claims routes
  resources :claims

  # Root path - Form wizard as the entry point
  root "form_submissions#show"
end
