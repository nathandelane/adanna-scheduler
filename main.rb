=begin
Main

This is the main entry point for the program.

author Nathan Lane
@date 02/04/2008
=end

# Main entry point.
if(__FILE__ == $0)
  require 'adanna_logger'
  require 'adanna_scheduler'
  
  # Create a new logger using the streams given in an array, then pass that
  # logger to the scheduler.  When the scheduler finishes executing close the
  # logger.
  module Adanna
    @logger = AdannaLogger.new([STDOUT, STDERR, "test.log", File.new("test_file.log", "w")])
    @logger.log(:info, "The logger works!")
    @adannaScheduler = AdannaScheduler.new(@logger)
    @logger.close()
  end
end