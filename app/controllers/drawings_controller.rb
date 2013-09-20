class DrawingsController < ApplicationController

  before_filter :internal_user

  # NOT implemented
  def edit
    @drawing = Drawing.find(params[:id])
  end

  def update
    @drawing = Drawing.find(params[:id])
    if @drawing.update_attributes(params[:drawing])
      flash[:success] = "Drawing changes saved"
      redirect_to @drawing
    else
      render 'edit'
    end
  end

  def show
    @drawing = Drawing.find(params[:id])
  end

  # NOT implemented
  def new
    @drawing = Drawing.new
  end

  def create
    @drawing = Drawing.new(params[:drawing])
    if @drawing.save
      flash[:success] = "New Drawing created"
      redirect_to @drawing
    else
      render 'new'
    end
  end

  def index
    @drawings = Drawing.paginate(page: params[:page])
  end

  def destroy
    Drawing.find(params[:id]).destroy
    flash[:success] = "Drawing deleted"
    redirect_to drawings_url
  end

end

