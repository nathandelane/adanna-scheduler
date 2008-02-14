
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
