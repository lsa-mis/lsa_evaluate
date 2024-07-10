# app/controllers/address_types_controller.rb
class AddressTypesController < ApplicationController
  before_action :set_address_type, only: %i[show edit update destroy]

  def index
    @address_types = AddressType.all
  end

  def show; end

  def new
    @address_type = AddressType.new
  end

  def edit; end

  def create
    @address_type = AddressType.new(address_type_params)
    if @address_type.save
      redirect_to @address_type, notice: 'Address type was successfully created.'
    else
      render :new
    end
  end

  def update
    if @address_type.update(address_type_params)
      redirect_to @address_type, notice: 'Address type was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @address_type.destroy
    redirect_to address_types_url, notice: 'Address type was successfully destroyed.'
  end

  private

  def set_address_type
    @address_type = AddressType.find(params[:id])
  end

  def address_type_params
    params.require(:address_type).permit(:kind, :description)
  end
end
