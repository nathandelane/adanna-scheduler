#***********************************************************************
# Adanna Bot: testspider.rb
#
# This is an attempt to creat a spider script for Adanna that integrates
# into itself, so that Adanna has complete control over the script.
#
# Created by: Nathan Lane
# Last Updated: 05/03/2007
#***********************************************************************

require "libadanna"

include Adanna::Reporting
include Adanna::Agents

class Spider < AgentBase
	
	def initialize(objAdannaLogger, strEnvironment)
		super(objAdannaLogger, strEnvironment)
		@logger = objAdannaLogger
		@environment = strEnvironment
		@agentState = PASS
	end # End: def initialize(objAdannaLogger, strEnvironment)
	
	def run_spider()
		@logger.log("Spider: Running the TestSpider.rb script", PASS)
	end # End: def run_bot()
	
end # End: class Bot
