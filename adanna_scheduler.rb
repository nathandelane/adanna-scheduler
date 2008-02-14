=begin
Adanna::AdannaScheduler

This is the main program loop. In previous versions this became relatively
large in size, but in this version I hope to extract any and all things not
directly relevant to the program loop specifically.

author Nathan Lane
@date 02/13/2008
=end

module Adanna
  
  class AdannaScheduler
    
    def initialize(logger)
      if(logger.kind_of?(AdannaLogger))
        @_logger = logger
      else
        raise(ArgumentError, "logger: no definition found for AdannaScheduler.new(#{logger.class})")
      end
      
      @_logger.info("AdannaScheduler works!")
    end
    
  end
  
end
