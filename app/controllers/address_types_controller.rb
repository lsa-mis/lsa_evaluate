# app/controllers/address_types_controller.rb
class AddressTypesController < ApplicationController
  before_action :set_address_type, only: %i[show edit update destroy]

  def index
    authorize AddressType
    @address_types = policy_scope(AddressType)
  end

  def show
    authorize @address_type
  end

  def new
    @address_type = AddressType.new
    authorize @address_type
  end

  def edit
    authorize @address_type
  end

  def create
    @address_type = AddressType.new(address_type_params)
    authorize @address_type

    respond_to do |format|
      if @address_type.save
        format.html { redirect_to @address_type, notice: 'Address type was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @address_type
    respond_to do |format|
      if @address_type.update(address_type_params)
        format.html { redirect_to @address_type, notice: 'Address type was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @address_type
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
