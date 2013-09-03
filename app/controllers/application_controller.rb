class ApplicationController < ActionController::Base

  protect_from_forgery
  include SessionsHelper

  before_filter :signed_in_user

  # Force signout to prevent CSRF attacks
  def handle_unverified_request
    sign_out
    super
  end

  private

  def signed_in_user
    unless signed_in?
      store_location
      redirect_to signin_url, notice: "Please sign in"
    end
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_path) unless current_user?(@user)
  end

  def admin_user
    redirect_to(root_path) unless current_user.admin?
  end

  def internal_user
    redirect_to(root_path) unless current_user.internal_user?
  end

  def internal_user_part_approver
    redirect_to(root_path) unless current_user.internal_user_part_approver?
  end

  def internal_user_rfq_approver
    redirect_to(root_path) unless current_user.internal_user_rfq_approver?
  end

end