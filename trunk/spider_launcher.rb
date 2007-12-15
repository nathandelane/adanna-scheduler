#***********************************************************************
# Adanna Spider: spider_launcher.rb
#
#
#
# Created by: Nathan Lane
# Last Updated: 05/14/2007
#***********************************************************************

class SpiderLauncher
	
	require "libadanna"

	include Adanna
	include Adanna::Reporting
	include Adanna::Browser
	include Adanna::Agents
	include Adanna::Environment

	def initialize()
		agentPassFlag = PASS
		agentMesages = ""
		spiderMessages = ""
		
		@agentData = AgentData.new
		@adannaConfig = AdannaConfiguration.new(".", "adannaconfig.xml")
		
		begin
			@environment = TestingEnvironment.new()
			@environment.set_environment("http://www.vehix.com")
			# DEFAULT "$startpage~/Default.aspx?zip=84106$depth~4$takescreenshots~true$excludeif~id:menu,id:breadcrumb,id:Footer,id:hidden,id:inventory,href:@,href:javascript,href:doubleclick,href:#,src:!.gif,src:menu,src:titlebar"
			# BROWSE VEHICLES "$startpage~/research/browseVehicles.aspx?radius=75&zip=90210$depth~4$takescreenshots~true$excludeif~id:menu,id:breadcrumb,id:Footer,id:hidden,id:inventory,href:@,href:javascript,href:doubleclick,href:#,src:!.gif,src:menu,src:titlebar"
			@environment.set_param_string("$startpage~/$depth~4$takescreenshots~true$excludeif~class_name:Menu,class_name:footerLink,id:breadcrumb,id:hidden,href:@,id:inventory,href:javascript,href:doubleclick,href:#,src:!.gif,src:menu,src:titlebar,text:Visit the Dealer Website")
			
			@logger = Logger.new(".", "SpiderLauncher.xml", "Spider Launcher Log")
			
			load ARGV[0]
			@logger.log("Loaded spider class from file: " + ARGV[0], PASS)
			agent = Spider.new(@logger, @environment)
			agent.run_spider
			agentPassFlag = agent.agentState
			agentMessages = agent.agentMessages
			
			if(agentPassFlag == PASS)
				@logger.log("Spider PASSED", agentPassFlag)
			elsif(agentPassFlag == FAIL)
				@logger.log("Spider FAILED", agentPassFlag)
				@logger.log("Messages: " + agentMessages, agentPassFlag)
			end # End: if(agentPassFlag == PASS)
		rescue => ex
			spiderMessages = ex.to_s + "; backtrace: " + ex.backtrace.inspect
			if(not @logger.nil?)
				@logger.log("Exception caught! message: " + ex.to_s + " backtrace: " + ex.backtrace.inspect, FAIL)
			end # End: if(@logger)
		ensure
			@logger.log(ARGV[0] + " bot final state was " + agentPassFlag, agentPassFlag)
			if(agentPassFlag == FAIL)
				Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Bot failed: " + ARGV[0] + " Messages: " + spiderMessages + "; " + agentMesages, @adannaConfig.emailPickupServer)
			end # End: if(agentPassFlag == FAIL)
		end
	end # End: def initialize()
	
end # End: class SpiderLauncher

#***********************************************************************
# This is the program entry point
#***********************************************************************
if __FILE__ == $0 # This verifies that the file name is the same as the zeroth argument, which is also the file name
	
	spider = SpiderLauncher.new()
	
end # End: if __FILE__ == $0
