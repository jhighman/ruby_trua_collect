class ApplicationController < ActionController::Base
  before_action :set_locale
  
  # Helper methods for authentication
  helper_method :user_signed_in?, :current_user
  
  private
  
  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end
  
  # Authentication methods
  def user_signed_in?
    session[:user_id].present? && User.exists?(session[:user_id])
  end
  
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if user_signed_in?
  end
end
