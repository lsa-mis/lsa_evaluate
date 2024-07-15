class TestingrsmokesController < ApplicationController
  before_action :set_testingrsmoke, only: %i[show edit update destroy]

  # GET /testingrsmokes or /testingrsmokes.json
  def index
    @testingrsmokes = Testingrsmoke.all
  end

  # GET /testingrsmokes/1 or /testingrsmokes/1.json
  def show
  end

  # GET /testingrsmokes/new
  def new
    @testingrsmoke = Testingrsmoke.new
  end

  # GET /testingrsmokes/1/edit
  def edit
  end

  # POST /testingrsmokes or /testingrsmokes.json
  def create
    @testingrsmoke = Testingrsmoke.new(testingrsmoke_params)

    respond_to do |format|
      if @testingrsmoke.save
        format.html { redirect_to testingrsmoke_url(@testingrsmoke), notice: 'Testingrsmoke was successfully created.' }
        format.json { render :show, status: :created, location: @testingrsmoke }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @testingrsmoke.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /testingrsmokes/1 or /testingrsmokes/1.json
  def update
    respond_to do |format|
      if @testingrsmoke.update(testingrsmoke_params)
        format.html { redirect_to testingrsmoke_url(@testingrsmoke), notice: 'Testingrsmoke was successfully updated.' }
        format.json { render :show, status: :ok, location: @testingrsmoke }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @testingrsmoke.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /testingrsmokes/1 or /testingrsmokes/1.json
  def destroy
    @testingrsmoke.destroy!

    respond_to do |format|
      format.html { redirect_to testingrsmokes_url, notice: 'Testingrsmoke was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_testingrsmoke
    @testingrsmoke = Testingrsmoke.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def testingrsmoke_params
    params.require(:testingrsmoke).permit(:name)
  end
end
