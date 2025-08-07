Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  
  # Form Submissions
  resources :form_submissions, path: 'form', only: [:show, :update, :destroy] do
    member do
      get 'complete'
      post 'validate_step'
      get 'audit_trail'
      get 'resume'
    end
  end
  
  # Form Steps
  namespace :form_steps do
    resource :residence_history, only: [:show, :update, :destroy], controller: 'residence_history_step'
    resource :education, only: [:show, :update, :destroy], controller: 'education_step'
  end
  
  # Language switching
  get 'switch_language', to: 'application#switch_language', as: :switch_language
  
  # Root path
  root to: 'form_submissions#show'
end
