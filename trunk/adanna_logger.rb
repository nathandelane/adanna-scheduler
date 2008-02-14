# Adanna::AdannaLogger
#
# This class extends the default Logger class that comes as part of the Ruby 
# Core. In this way more control is given to Adanna to perpetuate logs of a 
# particular format, such as XML, CSV, or plain text.
#
# author Nathan Lane
# @date 02/13/2008

module Adanna
  
  class AdannaLogger
    
    attr_reader :stream
    
    def initialize(descriptors, logType = :plain)
      @_logtype = logType
      @_streams = Array.new
      
      if(descriptors.kind_of?(Array))
        counter = 0
        descriptors.each { |descriptor|
          case(descriptor.class.to_s)
          when "String"
            @_streams[counter] = File.new(descriptor, "w")
          when "IO"
            @_streams[counter] = descriptor
          when "File"
            @_streams[counter] = descriptor
          else
            raise(ArgumentError, "descriptor: no definition found for AdannaLogger.new(#{descriptor.class})")
          end
          
          counter = counter + 1
        }
      end
    end
    
    def log(messageType, message)
      case (@_logtype)
      when :plain
        write_plain_log(message, messageType)
      else
        raise(ArgumentError, "messageType")
      end
    end
    
    def info(message)
      log(:info, message)
    end
    
    def debug(message)
      log(:debug, message)
    end
    
    def warn(message)
      log(:warn, message)
    end
    
    def error(message)
      log(:error, message)
    end
    
    def fatal(message)
      log(:fatal, message)
    end
    
    def close()
      @_streams.each { |stream|
        if(stream != STDOUT && stream != STDERR)
          if(stream.methods.include?("close"))
            stream.close()
          end
        end
      }
    end
    
    private
    
    def write_plain_log(message, messageType)
      @_streams.each { |stream|
        stream.puts("#{(Time.now()).strftime("%m/%d/%Y %H:%M:%S")}, #{messageType}, #{message}")
      }
    end
    
  end
  
end
