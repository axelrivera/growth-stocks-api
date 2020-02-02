class Api::QuotesController < ApplicationController
  before_action :set_refresh
  before_action :validate_symbols_param, only: [:quotes]

  def quote
    quote = StocksCacheService.new.get_quote(params[:symbol], refresh: refresh)

    if quote.present?
      render json: quote
    else
      head :not_found
    end
  end

  def quotes
    quotes = StocksCacheService.new.get_quotes(symbols, refresh: refresh)

    if quotes.present?
      render json: quotes
    else
      head :not_found
    end
  end

  protected

  def set_refresh
    @refresh = 'refresh' if params[:refresh].present?
  end

  def refresh
    @refresh
  end

  def validate_symbols_param
    @symbols = params[:symbols]
    head :bad_request unless @symbols.present?
  end

  def symbols
    @symbols
  end

end
