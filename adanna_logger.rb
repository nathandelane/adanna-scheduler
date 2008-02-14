=begin
Adanna::AdannaLogger

This class extends the default Logger class that comes as part of the Ruby 
Core. In this way more control is given to Adanna to perpetuate logs of a 
particular format, such as XML, CSV, or plain text.

author Nathan Lane
@date 02/13/2008
=end

module Adanna
  
  class AdannaLogger
    
    def initialize(descriptors, logType = :plain)
      @_logtype = logType
      @_streams = Array.new
      @_datetimeformat = "%Y-%m-%d %H:%M:%S"
      
      # Set up the streams for use as logging devices.
      if (descriptors.kind_of?(Array))
        counter = 0
        descriptors.each { |descriptor|
          case (descriptor.class.to_s)
          when ("String")
            @_streams[counter] = File.new(descriptor, "w")
          when ("IO")
            @_streams[counter] = descriptor
          when ("File")
            @_streams[counter] = descriptor
          else
            raise(ArgumentError, "descriptor: no definition found for AdannaLogger.new(#{descriptor.class})")
          end
          
          counter = counter + 1
        }
      end
    end
    
    # messageType - symbol representing the message type, can be either :info,
    # :debug, :warn, :error, or :fatal
    
    def log(messageType, message)
      if ((messageType == :info) || 
            (messageType == :debug) || 
            (messageType == :warn) || 
            (messageType == :error) || 
            (messageType == :fatal))
        
        case (@_logtype)
        when (:plain)
          write_plain_log(messageType, message)
        else
          raise(ArgumentError, "messageType")
        end
      else
        raise(ArgumentError, "messageType: no definition found for AdannaLogger::log(#{messageType.class} #{messageType}, #{message.class})")
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
        if (stream != STDOUT && stream != STDERR)
          if (stream.methods.include?("close"))
            stream.close
          end
        end
      }
    end
    
    def datetimeformat=(value)
      @_datetimeformat = value
    end
    
    private
    
    # message - the text message to be written to the log
    def write_plain_log(messageType, message)
      @_streams.each { |stream|
        stream.puts("#{(Time.now()).strftime(@_datetimeformat)}, #{messageType}, #{message}")
        
        if (stream == STDOUT || stream == STDERR)
          stream.flush
        end
      }
    end
    
  end
  
end
