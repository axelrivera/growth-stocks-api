class SymbolsService
  SYMBOLS_FILE = "symbols.json".freeze

  def signed_symbols_url
    signer = Aws::S3::Presigner.new
    signer.presigned_url(:get_object, bucket: symbols_bucket, key: SYMBOLS_FILE)
  end

  def upload_symbols
    payload = iex.get_symbols_string
    raise Exception.new "symbols payload empty" if payload.blank?

    resource = Aws::S3::Resource.new
    object = resource.bucket(symbols_bucket).object(SYMBOLS_FILE)
    object.put(body: payload, content_type: 'application/json')
  end

  private

  def symbols_bucket
    ENV['AWS_S3_SYMBOLS_BUCKET']
  end

  def iex
    @iex ||= InvestorsExchangeService.new
  end

end