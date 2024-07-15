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

    respond_to do |format|
      if @address_type.save
        format.html { redirect_to @address_type, notice: 'Address type was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @address_type.update(address_type_params)
        format.html { redirect_to @address_type, notice: 'Address type was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @address_type.destroy

    respond_to do |format|
      format.html { redirect_to address_types_url, notice: 'Address type was successfully destroyed.' }
    end
  end

  private

  def set_address_type
    @address_type = AddressType.find(params[:id])
  end

  def address_type_params
    params.require(:address_type).permit(:kind, :description)
  end
end
