class Api::AppstoreController < ApplicationController
  before_action :validate_receipt_params, only: [:verify_receipt]

  def verify_receipt
    receipt_status = ReceiptService.new(
      receipt_data: receipt_data,
      original_transaction_id: params[:original_transaction_id]
    ).process

    render json: receipt_status, status: :ok
  end

  def ping
    render json: { server_timestamp: Time.now.to_i }, status: :ok
  end

  protected

  def validate_receipt_params
    @receipt_data = params[:receipt_data]
    head :bad_request unless @receipt_data.present?
  end

  def receipt_data
    @receipt_data
  end

end
