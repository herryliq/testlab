unless defined?(DEFAULT_DUMP_FILE)
  DEFAULT_DUMP_FILE = File.join('', 'tmp', 'testlab.dump')
end

unless defined?(DEFAULT_LOG_FILE)
  DEFAULT_LOG_FILE = File.join('', 'tmp', 'testlab.log')
end

unless defined?(DEFAULT_LOG_BACKUP)
  DEFAULT_LOG_BACKUP = File.join('', 'tmp', 'testlab.log.bak')
end
