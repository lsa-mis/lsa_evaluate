# app/controllers/addresses_controller.rb
class AddressesController < ApplicationController
  before_action :set_address, only: %i[show edit update destroy]

  def index
    authorize Address
    @addresses = policy_scope(Address)
  end

  def show
    authorize @address
  end

  def new
    @address = Address.new
    authorize @address
  end

  def edit
    authorize @address
  end

  def create
    @address = Address.new(address_params)
    authorize @address

    respond_to do |format|
      if @address.save
        format.html { redirect_to @address, notice: 'Address was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @address

    respond_to do |format|
      if @address.update(address_params)
        format.html { redirect_to @address, notice: 'Address was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @address
    @address.destroy

    respond_to do |format|
      format.html { redirect_to addresses_url, notice: 'Address was successfully destroyed.' }
    end
  rescue ActiveRecord::DeleteRestrictionError => e
    flash[:error] = e.message
    redirect_to addresses_path
  end

  private

  def set_address
    @address = policy_scope(Address).find(params[:id])
  end

  def address_params
    params.require(:address).permit(:address1, :address2, :city, :state, :zip, :country, :address_type_id)
  end
end
