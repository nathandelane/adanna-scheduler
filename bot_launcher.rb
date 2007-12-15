#***********************************************************************
# Adanna Bot: bot_launcher.rb
#
#
#
# Created by: Nathan Lane
# Last Updated: 05/10/2007
#***********************************************************************

class BotLauncher
	
	require "libadanna"

	include Adanna
	include Adanna::Reporting
	include Adanna::Browser
	include Adanna::Agents
	include Adanna::Environment

	def initialize()
		agentPassFlag = PASS
		agentMesages = ""
		botMessages = ""
		
		@agentData = AgentData.new
		@adannaConfig = AdannaConfiguration.new(".", "adannaconfig.xml")
		
		begin
			@environment = TestingEnvironment.new()
			@environment.set_environment("https://www.vehix.com/sellYourCar/Default.aspx?radius=75&year=&condition=1")
			@environment.set_param_string("JH4KB16687C001781$WBAEK13476CN78265$1G4HD572X6U135401$1HGCM66523A072034$1G1ND52J7Y6207368")
			
			@logger = Logger.new(".", "BotLauncher.xml", "Bot Launcher Log")
			
			load ARGV[0]
			@logger.log("Loaded bot class from file: " + ARGV[0], PASS)
			agent = Bot.new(@logger, @environment)
			agent.run_bot
			agentPassFlag = agent.agentState
			agentMessages = agent.agentMessages
			
			if(agentPassFlag == PASS)
				@logger.log("Bot PASSED", agentPassFlag)
			elsif(agentPassFlag == FAIL)
				@logger.log("Bot FAILED", agentPassFlag)
				@logger.log("Messages: " + agentMessages, agentPassFlag)
			end # End: if(agentPassFlag == PASS)
		rescue => ex
			botMessages = ex.to_s + "; backtrace: " + ex.backtrace.inspect
			if(not @logger.nil?)
				@logger.log("Exception caught! message: " + ex.to_s + " backtrace: " + ex.backtrace.inspect, FAIL)
			end # End: if(@logger)
		ensure
			@logger.log(ARGV[0] + " bot final state was " + agentPassFlag, agentPassFlag)
			if(agentPassFlag == FAIL)
				Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Bot failed: " + ARGV[0] + " Messages: " + botMessages + "; " + agentMesages, @adannaConfig.emailPickupServer)
			end # End: if(agentPassFlag == FAIL)
		end
	end # End: def initialize()
	
end # End: class BotLauncher

#***********************************************************************
# This is the program entry point
#***********************************************************************
if __FILE__ == $0 # This verifies that the file name is the same as the zeroth argument, which is also the file name
	
	bot = BotLauncher.new()
	
end # End: if __FILE__ == $0
