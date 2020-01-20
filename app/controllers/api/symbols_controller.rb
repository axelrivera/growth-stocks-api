class Api::SymbolsController < ApplicationController

  def symbols
    render json: { symbols_url: SymbolsService.new.signed_symbols_url }
  end

end
