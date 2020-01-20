class Api::AppstoreController < ApplicationController
  before_action :validate_receipt_params, only: [:verify_receipt]

  def verify_receipt
    receipt_status = ReceiptService.new(
      receipt_data: receipt_data,
      device_timestamp: device_timestamp
    ).process
    render json: receipt_status, status: :ok
  end

  protected

  def validate_receipt_params
    @receipt_data = params[:receipt_data]
    @device_timestamp = params[:device_timestamp]
    head :bad_request unless @receipt_data.present? && @device_timestamp.present?
  end

  def receipt_data
    @receipt_data
  end

  def device_timestamp
    @device_timestamp
  end

end
