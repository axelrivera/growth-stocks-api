desc "Flush Quotes"
task :flush_quotes => :environment do
  StocksCacheService.new.flush_all_quotes_if_needed
end
