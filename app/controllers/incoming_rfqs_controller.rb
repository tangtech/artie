class IncomingRfqsController < ApplicationController

  before_filter :internal_user

  # View not implemented
  def edit
    @incoming_rfq = IncomingRfq.find(params[:id])
  end

  def update
    @incoming_rfq = IncomingRfq.find(params[:id])
    if @incoming_rfq.update_attributes(params[:incoming_rfq])
      flash[:success] = "RFQ changes saved"
      redirect_to @incoming_rfq
    else
      render 'edit'
    end
  end

  def show
    @incoming_rfq = IncomingRfq.find(params[:id])
    @incoming_rfq_items = @incoming_rfq.incoming_rfq_items.all
  end

  # View not implemented
  def new
    @incoming_rfq = IncomingRfq.new
  end

  def create
    @incoming_rfq = IncomingRfq.new(params[:incoming_rfq])
    if @incoming_rfq.save
      flash[:success] = "New RFQ created"
      redirect_to @incoming_rfq
    else
      render 'new'
    end
  end

  def index
    @incoming_rfqs = IncomingRfq.paginate(page: params[:page])
  end

  def destroy
    IncomingRfq.find(params[:id]).destroy
    flash[:success] = "RFQ deleted"
    redirect_to incoming_rfqs_url
  end

end

