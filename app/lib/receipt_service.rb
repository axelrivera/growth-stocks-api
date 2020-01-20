class ReceiptService
  STATUS_CODES = {
    success: 100,
    failed_request_error: 400,
    invalid_status_error: 401,
    invalid_bundle_id_error: 402,
    invalid_product_error: 403
  }.freeze

  def initialize(receipt_data: nil, device_timestamp: nil)
    @app_bundle_id = ENV['STOCKS_APP_BUNDLE_ID']
    @production_url = ENV['APPSTORE_PRODUCTION_URL']
    @sandbox_url = ENV['APPSTORE_SANDBOX_URL']
    @password = ENV['APPSTORE_SHARED_SECRET']
    @monthly_product = ENV['STOCKS_MONTHLY_PRODUCT']
    @yearly_product = ENV['STOCKS_YEARLY_PRODUCT']
    @receipt_data = receipt_data
    @device_timestamp = device_timestamp
    @request_succeeded = false
    @request_data = {}
    @conn = Faraday.new
  end

  def process
    process_receipt()
    parse_response()
  end

  private

  attr_reader :sandbox_url, :production_url, :password
  attr_reader :app_bundle_id, :monthly_product, :yearly_product
  attr_reader :receipt_data, :device_timestamp
  attr_reader :request_succeeded, :request_data

  def available_products
    [monthly_product, yearly_product]
  end

  def process_receipt
    body = { 'receipt-data': receipt_data, password: password, 'exclude-old-transactions': false }

    res = @conn.post(production_url, body.to_json)
    if should_run_in_sandbox?(res)
      logger.debug "fetching receipt from sandbox"
      res = @conn.post(sandbox_url, body.to_json)
    end

    @request_succeeded = res.success?
    @request_data = JSON.parse(res.body) if res.body.present?
  end

  def should_run_in_sandbox?(res)
    receipt = JSON.parse(res.body) if res.success? && res.body.present?
    receipt.present? && receipt["status"] == 21007
  end

  def status_for(key)
    STATUS_CODES[key]
  end

  def valid_status?
    status = request_data["status"]
    logger.debug "receipt status: #{status}"
    status == 0
  end

  def valid_bundle_id?
    request_data.dig("receipt", "bundle_id") == app_bundle_id
  end

  def parse_response
    return { valid: false } unless valid_receipt?
    
    receipt = latest_receipt()
    return { valid: false } unless receipt.present?

    { status: true, latest_info: receipt_payload(receipt) }
  end

  def valid_receipt?
    error = status_for(:failed_request_error) unless request_succeeded
    error ||= status_for(:invalid_status_error) unless valid_status?
    error ||= status_for(:invalid_bundle_id_error) unless valid_bundle_id?

    logger.debug "receipt error with code: #{error}" if error.present?
    error.blank?
  end

  def latest_receipt
    receipts = request_data["latest_receipt_info"] || []
    receipts = receipts.select { |receipt| available_products.include?(receipt["product_id"]) }
    receipt = receipts.sort_by { |info| info["expires_date_ms"] }.last

    logger.debug "receipt error: no valid products found" if receipt.blank?
    receipt
  end

  # Receipt Helpers

  def receipt_payload(receipt)
    {
      product_id: receipt["product_id"],
      expires_date: receipt["expires_date"],
      expires_date_ms: receipt["expires_date_ms"],
      purchase_date: receipt["purchase_date"],
      purchase_date_ms: receipt["purchase_date_ms"],
      original_transaction_id: receipt["original_transaction_id"],
      device_time_offset: device_time_offset
    }
  end

  def device_time_offset
    device_timestamp - Time.now.to_i
  end

  # Logger Helper

  def logger
    Rails.logger
  end

end
