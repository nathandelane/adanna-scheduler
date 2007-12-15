#***********************************************************************
# Adanna Bot: testbot.rb
#
# This is an attempt to creat a bot script for Adanna that integrates
# into itself, so that Adanna has complete control over the script.
#
# Created by: Nathan Lane
# Last Updated: 05/10/2007
#***********************************************************************

require "libadanna"

include Adanna::Reporting
include Adanna::Agents
include Adanna::Browser

class Bot < AgentBase
	
	def initialize(objAdannaLogger, objEnvironment)
		super(objAdannaLogger, objEnvironment)
		
		@logger = objAdannaLogger
		@environment = objEnvironment
		@agentState = PASS
		
		setup_bot
	end # End: def initialize(objAdannaLogger, strEnvironment)
	
	def setup_bot()
		@formLibrary = Hash.new
		@formLibrary[""] = ""
	end # End: def setup_bot()
	
	def clean_up_bot()
		@watirBrowser.close
	end # End: def clean_up_bot()
	
	def run_bot()
		begin
			@logger.log("Bot: Running the TestBot.rb script", PASS)
		ensure
			clean_up_bot
		end
	end # End: def run_bot()
	
end # End: class Bot
