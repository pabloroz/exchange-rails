class EmailAlertsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_email_alert, only: %i[ show edit update destroy ]

  # GET /email_alerts or /email_alerts.json
  def index
    @email_alerts = EmailAlert.all
  end

  # GET /email_alerts/1 or /email_alerts/1.json
  def show
  end

  # GET /email_alerts/new
  def new
    @email_alert = EmailAlert.new(
      base_currency: params[:base_currency],
      quote_currency: params[:quote_currency],
      multiplier: params[:multiplier]
    )
  end

  # GET /email_alerts/1/edit
  def edit
  end

  # POST /email_alerts or /email_alerts.json
  def create
    @email_alert = current_user.email_alerts.new(email_alert_params)

    respond_to do |format|
      if @email_alert.save
        format.html { redirect_to @email_alert, notice: "Email alert was successfully created." }
        format.json { render :show, status: :created, location: @email_alert }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @email_alert.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /email_alerts/1 or /email_alerts/1.json
  def update
    respond_to do |format|
      if @email_alert.update(email_alert_params)
        format.html { redirect_to @email_alert, notice: "Email alert was successfully updated." }
        format.json { render :show, status: :ok, location: @email_alert }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @email_alert.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /email_alerts/1 or /email_alerts/1.json
  def destroy
    @email_alert.destroy!

    respond_to do |format|
      format.html { redirect_to email_alerts_path, status: :see_other, notice: "Email alert was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_email_alert
      @email_alert = EmailAlert.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def email_alert_params
      params.expect(email_alert: [ :user_id, :base_currency, :quote_currency, :comparison_operator, :multiplier, :active, :unsubscribed_at, :last_sent_at ])
    end
end
