class ClaimsController < ApplicationController
  before_action :set_claim, only: [:show, :edit, :update, :destroy]

  # GET /claims
  def index
    @claims = Claim.all
  end

  # GET /claims/1
  def show
    respond_to do |format|
      format.html
      format.json { render json: @claim.to_json_document }
      format.pdf do
        # In a real application, you would generate a PDF here
        # For example, using a gem like Prawn or WickedPDF
        render plain: "PDF generation would happen here"
      end
    end
  end

  # GET /claims/new
  def new
    @claim = Claim.new
  end

  # GET /claims/1/edit
  def edit
  end

  # POST /claims
  def create
    @claim = Claim.new(claim_params)

    if @claim.save
      redirect_to @claim, notice: 'Claim was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /claims/1
  def update
    if @claim.update(claim_params)
      redirect_to @claim, notice: 'Claim was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /claims/1
  def destroy
    @claim.destroy
    redirect_to claims_url, notice: 'Claim was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_claim
      @claim = Claim.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def claim_params
      params.require(:claim).permit(
        :tracking_id,
        :submission_date,
        :collection_key,
        :language,
        claimant_attributes: [
          :full_name,
          :email,
          :phone,
          :date_of_birth,
          :ssn,
          :completed_at
        ]
      )
    end
end