class StocksCacheService
  QUOTE_KEY_PREFIX = "QT_".freeze
  QUOTE_EXPIRATION_PERIOD = ENV.fetch('QUOTE_EXPIRATION', '300').freeze.to_i
  QUOTE_EXPIRATION_JITTER = 30.freeze
  TIME_ZONE = 'America/New_York'.freeze
  MARKET_OPEN = '04:30:00'.freeze
  MARKET_CLOSE = '20:00:00'.freeze

  def random_ttl
    end_period = QUOTE_EXPIRATION_PERIOD + QUOTE_EXPIRATION_JITTER
    rand(QUOTE_EXPIRATION_PERIOD..end_period)
  end

  # Working with a single symbol

  def get_quote(symbol, refresh:)
    key = quote_key_for_symbol(symbol)
    logger.debug "redis: fetching #{key}"

    unless delete_key_if_stale_or_refresh(key, refresh: refresh)
      payload = redis.get(key)
    end
    
    if payload.blank?
      logger.debug "redis: #{symbol} empty, fetch from IEX"
      fresh_payload = iex.get_quote(symbol)

      set_quote(symbol, payload: fresh_payload) if fresh_payload.present?
      payload = fresh_payload
    end

    payload.present? ? payload : nil
  end

  def set_quote(symbol, payload:)
    raise Exception.new "missing symbol" if symbol.blank?
    raise Exception.new "missing payload for symbol #{symbol}" if payload.blank?

    key = quote_key_for_symbol(symbol)

    redis.multi do |multi|
      logger.debug "redis: caching #{key}"
      multi.set(key, payload)

      if market_open?
        ttl = random_ttl
        logger.debug "redis: set expiration of #{key} to #{ttl}"
        multi.expire(key, ttl)
      end
    end
  end

  # Working with multiple symbols

  def get_quotes(symbols_str, refresh:)
    symbols = symbols_str.split(',')
    keys = symbols.map { |s| quote_key_for_symbol(s) }
    logger.debug "redis: fetching #{keys.join(',')}"

    delete_multiple_keys_if_stale_or_refresh(keys, refresh: refresh)

    payloads = redis.mapped_mget(*keys)
    missing_keys = payloads.select { |key, value| value.nil? }.keys
    missing_symbols = missing_keys.map { |key| symbol_for_quote_key(key) }.join(',')

    if missing_symbols.present?
      logger.debug "redis: #{missing_symbols} empty, fetch from IEX"
      missing_payloads = iex.get_quotes(missing_symbols)
      set_quotes(missing_payloads) if missing_payloads.present?    
    end

    final_payloads = payloads.values.compact.map { |payload| JSON.parse(payload) }
    final_payloads.concat JSON.parse(missing_payloads) if missing_payloads.present?

    final_payloads.present? ? final_payloads.to_json : nil
  end

  def set_quotes(payloads_str)
    payloads = JSON.parse(payloads_str)
    raise Exception.new "missing payloads" if payloads.blank?

    mapped_payloads = Hash[payloads.collect { |row| [row["symbol"], row] } ]

    redis.multi do |multi|
      mapped_payloads.each do |symbol, payload|
        key = quote_key_for_symbol(symbol)

        logger.debug "redis: caching #{key}"
        multi.set(key, payload.to_json)

        if market_open? == true
          ttl = random_ttl
          logger.debug "redis: set expiration of #{key} to #{ttl}"
          multi.expire(key, ttl)
        end
      end
    end
  end

  # Flushing

  def flush_all_quotes_if_needed
    should_flush = ENV['FORCED'].present? || market_weekday?
    flush_all_quotes if should_flush
  end

  private

  def redis
    @redis ||= REDIS
  end

  def iex
    @iex ||= InvestorsExchangeService.new
  end

  def logger
    Rails.logger
  end

  def quote_key_for_symbol(symbol)
    QUOTE_KEY_PREFIX + symbol.upcase
  end

  def symbol_for_quote_key(key)
    key.delete_prefix(QUOTE_KEY_PREFIX)
  end

  # REDIS Helpers

  def flush_all_quotes
    logger.info "redis: flushing all keys with prefix #{QUOTE_KEY_PREFIX}"
    keys = redis.keys "#{QUOTE_KEY_PREFIX}*"
    redis.call [:del, *keys] if keys.present?
  end

  def delete_key_if_stale_or_refresh(key, refresh:)
    if refresh == 'refresh'
      logger.debug "redis: refreshing key #{key}"
      redis.del(key)
      return true
    elsif market_open? && redis.ttl(key) == -1
      logger.debug "redis: market open, flushing stale key #{key}"
      redis.del(key)
      return true
    end
    false
  end

  def delete_multiple_keys_if_stale_or_refresh(keys=[], refresh:)
    if refresh == 'refresh'
      logger.debug "redis: refreshing keys #{keys.join(',')}"
      redis.del(*keys)
    elsif market_open?
      stale_keys = keys.map { |key| key if redis.ttl(key) == -1 }.compact
      if stale_keys.present?
        logger.debug "redis: market open, flushing stale keys #{stale_keys.join(',')}"
        redis.call [:del, *stale_keys]
      end
    end
  end

  ## Helper Methods for Validating Dates

  def market_date_now
    Time.zone = TIME_ZONE
    Time.zone.now
  end

  def market_date_open
    Time.zone = TIME_ZONE
    Time.zone.parse(MARKET_OPEN)
  end

  def market_date_close
    Time.zone = TIME_ZONE
    Time.zone.parse(MARKET_CLOSE)
  end

  def market_weekday?
    today = Date.today
    !today.saturday? && !today.sunday?
  end

  def market_open?
    market_weekday? && market_date_now.between?(market_date_open, market_date_close)
  end

end