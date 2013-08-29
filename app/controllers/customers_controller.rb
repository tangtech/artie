class CustomersController < ApplicationController

  before_filter :admin_user

  def edit
    @customer = Customer.find(params[:id])
  end

  def update
    @customer = Customer.find(params[:id])
    if @customer.update_attributes(params[:customer])
      flash[:success] = "Customer changes saved"
      redirect_to @customer
    else
      render 'edit'
    end
  end

  def show
    @customer = Customer.find(params[:id])
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(params[:customer])
    if @customer.save
      flash[:success] = "New customer created"
      redirect_to @customer
    else
      render 'new'
    end
  end

  def index
    @customers = Customer.paginate(page: params[:page])
  end

  def destroy
    Customer.find(params[:id]).destroy
    flash[:success] = "Customer deleted"
    redirect_to customers_url
  end

end
