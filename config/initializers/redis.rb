REDIS = Redis.new(url: ENV.fetch('REDISCLOUD_URL', 'redis://127.0.0.1:6379'))
