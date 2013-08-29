class UsersController < ApplicationController

  # Normal users are only allowed to change their password
  before_filter :correct_user, only: [:edit, :update]
  before_filter :admin_user, only: [:show, :new, :create, :index, :destroy]

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      flash[:success] = "New password saved"
      sign_in @user
      redirect_to root_path
    else
      render 'edit'
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:success] = "New user created"
      redirect_to @user
    else
      render 'new'
    end
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

end
