Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  
  root 'home#index'
  
  # Form Wizard routes
  get '/form', to: 'form_submissions#show', as: :form_submission
  patch '/form', to: 'form_submissions#update'
  post '/form/validate_step', to: 'form_submissions#validate_step', as: :validate_step_form_submission
  get '/form/complete', to: 'form_submissions#complete', as: :complete_form_submission
end