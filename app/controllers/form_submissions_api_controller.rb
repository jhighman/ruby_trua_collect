class FormSubmissionsApiController < ApplicationController
  protect_from_forgery with: :null_session

  def state
    render json: {
      form_state: {},
      navigation_state: {},
      requirements: {}
    }
  end
end