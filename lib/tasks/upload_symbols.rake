desc "Upload Symbols"
task :upload_symbols => :environment do
  SymbolsService.new.upload_symbols
end
