class AddressesController < ApplicationController
  before_action :set_address, only: %i[show edit update destroy]

  def index
    @addresses = Address.all
  end

  def show; end

  def new
    @address = Address.new
  end

  def edit; end

  def create
    @address = Address.new(address_params)
    if @address.save
      redirect_to @address, notice: 'Address was successfully created.'
    else
      render :new
    end
  end

  def update
    if @address.update(address_params)
      redirect_to @address, notice: 'Address was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @address.destroy
    redirect_to addresses_url, notice: 'Address was successfully destroyed.'
  end

  private

  def set_address
    @address = Address.find(params[:id])
  end

  def address_params
    params.require(:address).permit(:address1, :address2, :city, :state, :zip, :phone, :country, :address_type_id)
  end
end
