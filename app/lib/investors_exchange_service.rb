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
    res = @conn.get("stock/#{symbol}/quote", { token: api_token })
    res.success? ? res.body : nil
  end

  def get_quotes(symbols)
    res = @conn.get("stock/market/quote", { token: api_token, symbols: symbols })
    res.success? ? res.body : nil
  end

  def get_symbols_string
    res = @conn.get("ref-data/symbols", { token: api_token })
    res.success? ? res.body : nil 
  end

  private

  def api_token
    @api_token ||= ENV.fetch('IEX_PRODUCTION_TOKEN', ENV['IEX_SANDBOX_TOKEN'])
  end

end