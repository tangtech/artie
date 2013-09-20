class PartsController < ApplicationController

  before_filter :internal_user

  # NOT implemented
  def edit
    @part = Part.find(params[:id])
  end

  def update
    @part = Part.find(params[:id])
    if @part.update_attributes(params[:part])
      flash[:success] = "Part changes saved"
      redirect_to @part
    else
      render 'edit'
    end
  end

  def show
    @part = Part.find(params[:id])
  end

  # NOT implemented
  def new
    @part = Part.new
  end

  def create
    @part = Part.new(params[:part])
    if @part.save
      flash[:success] = "New Part created"
      redirect_to @part
    else
      render 'new'
    end
  end

  def index
    @parts = Part.paginate(page: params[:page])
  end

  def destroy
    Part.find(params[:id]).destroy
    flash[:success] = "Part deleted"
    redirect_to parts_url
  end

end

