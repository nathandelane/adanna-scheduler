if(__FILE__ == $0)
  require 'adanna_logger'
  require 'adanna_scheduler'
  
  module Adanna
    @logger = AdannaLogger.new([STDOUT, STDERR])
    @logger.info("The logger works!")
    @adannaScheduler = AdannaScheduler.new(@logger)
    @logger.close()
  end
end