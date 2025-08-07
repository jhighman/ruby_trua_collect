class ApplicationController < ActionController::Base
  before_action :set_locale
  
  # Helper methods for authentication
  helper_method :user_signed_in?, :current_user
  
  def switch_language
    locale = params[:locale].to_s.strip.to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      I18n.locale = locale
    end
    
    redirect_back(fallback_location: root_path)
  end
  
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
