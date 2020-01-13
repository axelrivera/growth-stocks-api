class InvestorsExchangeService

  def initialize
    base_url = ENV.fetch('IEX_PRODUCTION_URL', ENV['IEX_SANDBOX_URL'])
    @conn = Faraday.new(url: base_url) do |faraday|
      faraday.headers['Accept'] = 'application/json'
      faraday.headers['Content-Type'] = 'application/json'
      faraday.adapter Faraday.default_adapter
    end
  end

  def get_quote(symbol)
    get("stock/#{symbol}/quote")
  end

  def get_quotes(symbols)
    get("stock/market/quote", params: { symbols: symbols })
  end

  def get_symbols_string
    get("ref-data/symbols")
  end

  private

  def get(url, params: {})
    params[:token] = api_token
    parse_response(@conn.get(url, params))
  end

  def api_token
    @api_token ||= ENV.fetch('IEX_PRODUCTION_TOKEN', ENV['IEX_SANDBOX_TOKEN'])
  end

  def parse_response(res)
    res.success? ? res.body : nil
  end

end