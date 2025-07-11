class SymbolsService
  SYMBOLS_FILE = "symbols.json".freeze

  def initialize
    @iex = InvestorsExchangeService.new
    @region = ENV['AWS_REGION']
    @symbols_bucket = ENV['AWS_S3_SYMBOLS_BUCKET']
    @s3_client = Aws::S3::Client.new(
      region: region,
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def signed_symbols_url
    signer = Aws::S3::Presigner.new(client: s3_client)
    signer.presigned_url(:get_object, bucket: symbols_bucket, key: SYMBOLS_FILE)
  end

  def upload_symbols
    payload = iex.get_symbols_string
    raise Exception.new "symbols payload empty" if payload.blank?

    resource = Aws::S3::Resource.new(region: region)
    object = resource.bucket(symbols_bucket).object(SYMBOLS_FILE)
    object.put(body: payload, content_type: 'application/json')
    Rails.logger.info "uploaded #{SYMBOLS_FILE} to bucket #{symbols_bucket}"
  end

  private

  attr_reader :iex
  attr_reader :s3_client, :region, :symbols_bucket

end
