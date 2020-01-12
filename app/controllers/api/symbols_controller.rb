class Api::SymbolsController < ApplicationController

  def symbols
    render json: { symbols_url: symbols_service.signed_symbols_url }
  end

  private

  def symbols_service
    @symbols_service ||= SymbolsService.new
  end

end