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

    respond_to do |format|
      if @address.save
        format.html { redirect_to @address, notice: 'Address was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @address.update(address_params)
        format.html { redirect_to @address, notice: 'Address was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @address.destroy
    if @contest_description.destroy
      respond_to do |format|
        format.html { redirect_to addresses_url, notice: 'Address was successfully destroyed.' }
      end
    end
  rescue ActiveRecord::DeleteRestrictionError => e
    flash[:error] = e.message
    redirect_to contest_descriptions_path
  end

  private

  def set_address
    @address = Address.find(params[:id])
  end

  def address_params
    params.require(:address).permit(:address1, :address2, :city, :state, :zip, :country, :address_type_id)
  end
end
