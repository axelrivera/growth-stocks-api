class Api::QuotesController < ApplicationController

  def quote
    symbol = params[:symbol]
    refresh = 'refresh' if params[:refresh].present?
    quote = stocks_cache.get_quote(symbol, refresh: refresh)

    if quote.present?
      render json: quote
    else
      head :not_found
    end
  end

  def quotes
    symbols = params[:symbols]
    head :bad_request and return if symbols.blank?

    refresh = 'refresh' if params[:refresh].present?
    quotes = stocks_cache.get_quotes(symbols, refresh: refresh)

    if quotes.present?
      render json: quotes
    else
      head :not_found
    end
  end

  private

  def stocks_cache
    @stocks_cache ||= StocksCacheService.new
  end

end