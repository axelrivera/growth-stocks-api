class ReceiptService
  STATUS_CODES = {
    success: 100,
    failed_request_error: 400,
    invalid_status_error: 401,
    invalid_bundle_id_error: 402,
    invalid_product_error: 403
  }.freeze

  def initialize(receipt_data: nil, original_transaction_id: nil)
    # parameters methods
    @receipt_data = receipt_data
    @original_transaction_id = original_transaction_id

    # other variables
    @app_bundle_id = ENV['STOCKS_APP_BUNDLE_ID']
    @production_url = ENV['APPSTORE_PRODUCTION_URL']
    @sandbox_url = ENV['APPSTORE_SANDBOX_URL']
    @password = ENV['APPSTORE_SHARED_SECRET']
    @monthly_product = ENV['STOCKS_MONTHLY_PRODUCT']
    @yearly_product = ENV['STOCKS_YEARLY_PRODUCT']
    @request_succeeded = false
    @request_data = {}
    @conn = Faraday.new
  end

  def process
    process_receipt()
    parse_response()
  end

  private

  attr_reader :receipt_data, :original_transaction_id
  attr_reader :sandbox_url, :production_url, :password
  attr_reader :app_bundle_id, :monthly_product, :yearly_product
  attr_reader :request_succeeded, :request_data

  def available_products
    [monthly_product, yearly_product]
  end

  def verify_receipt_url
    Rails.env.production? ? production_url : sandbox_url
  end

  def process_receipt
    body = { 'receipt-data': receipt_data, password: password, 'exclude-old-transactions': true }

    logger.info "POST #{verify_receipt_url} at #{Time.now}"
    res = @conn.post(verify_receipt_url, body.to_json)
    logger.info "Completed with HTTP Status #{res.status}"

    if should_run_in_sandbox?(res)
      logger.info "POST #{sandbox_url} at #{Time.now}"
      res = @conn.post(sandbox_url, body.to_json)
      logger.info "Completed with HTTP Status #{res.status}"
    end

    @request_succeeded = res.success?
    @request_data = JSON.parse(res.body) if res.body.present?
  end

  def should_run_in_sandbox?(res)
    receipt = JSON.parse(res.body) if res.success? && res.body.present?
    receipt.present? && receipt["status"] == 21007
  end

  def parse_response
    return { valid: false } unless valid_receipt?
    
    latest_field = latest_receipt_field()
    return { valid: false, refresh: true } unless latest_field.present?

    {
      valid: true,
      latest_info: receipt_info_payload(latest_field, latest_receipt()),
    }
  end

  def valid_receipt?
    error = STATUS_CODES[:failed_request_error] unless request_succeeded
    error ||= STATUS_CODES[:invalid_status_error] unless valid_status?
    error ||= STATUS_CODES[:invalid_bundle_id_error] unless valid_bundle_id?

    logger.debug "receipt error with code: #{error}" if error.present?
    error.blank?
  end

  def valid_status?
    status = request_data["status"] || -1
    logger.info "Found App Store receipt with status: #{status}"
    status == 0
  end

  def valid_bundle_id?
    request_data.dig("receipt", "bundle_id") == app_bundle_id
  end

  def latest_receipt_field
    receipts = request_data.dig("receipt", "in_app") || []

    receipts = receipts.select do |rec|
      if original_transaction_id.present?
        # filter by `original_transaction_id` if present
        rec["original_transaction_id"] == original_transaction_id
      else
        # if no `original_transaction_id`, then filter by product
        available_products.include?(rec["product_id"])
      end
    end
    receipt = receipts.sort_by { |rec| rec["expires_date_ms"].to_i }.last

    logger.debug "receipt error: no valid products found" if receipt.blank?
    receipt
  end

  def latest_receipt
    request_data["latest_receipt"]
  end

  # Receipt Helpers

  def receipt_info_payload(field, latest_receipt)
    {
      product_id: field["product_id"],
      expires_date: field["expires_date"],
      expires_date_ms: field["expires_date_ms"],
      purchase_date: field["purchase_date"],
      purchase_date_ms: field["purchase_date_ms"],
      original_transaction_id: field["original_transaction_id"],
      latest_receipt: latest_receipt,
      latest_receipt_date: Time.now.to_i
    }
  end

  # Logger Helper

  def logger
    Rails.logger
  end

end
