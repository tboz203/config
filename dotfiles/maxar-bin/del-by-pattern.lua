return redis.call('del', unpack(redis.call('keys', ARGV[1])))
