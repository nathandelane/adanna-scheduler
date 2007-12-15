#***********************************************************************
# Adanna Bot: testspider.rb
#
# This is an attempt to creat a spider script for Adanna that integrates
# into itself, so that Adanna has complete control over the script.
#
# Created by: Nathan Lane
# Last Updated: 05/14/2007
#***********************************************************************

require "libadanna"

include Adanna::Reporting
include Adanna::Agents
include Adanna::Browser

class Spider < AgentBase
	
	def initialize(objAdannaLogger, objEnvironment)
		super(objAdannaLogger, objEnvironment)
		
		@logger = objAdannaLogger
		@environment = objEnvironment
		@agentState = PASS
		
		setup_spider
	end # End: def initialize(objAdannaLogger, objEnvironment)
	
	def setup_spider()
		@formLibrary = Hash.new
		@formLibrary[""] = ""
	end # End: def setup_bot()
	
	def clean_up_spider()
		@watirBrowser.close
	end # End: def clean_up_spider()
	
	def run_spider()
		begin
			@logger.log("Spider: Running the TestSpider.rb script", PASS)
		ensure
			clean_up_spider
		end
	end # End: def run_spider()
	
end # End: class Spider
