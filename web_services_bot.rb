#***********************************************************************
# Adanna Bot: web_services_bot.rb
#
# This bot tests the web services via HTTP requests that are stored in
# the database.
#
# Created by: Nathan Lane
# Last Updated: 05/09/2007
#***********************************************************************

require "libadanna"

include Adanna::Reporting
include Adanna::Agents

require "net/http"

class Bot < AgentBase
	
	def initialize(objAdannaLogger, objEnvironment)
		super(objAdannaLogger, objEnvironment)
		
		@logger = objAdannaLogger
		@environment = objEnvironment
		@agentState = PASS
		@agentMessages = ""
		
		setup_web_services_bot
	end # End: def initialize(objAdannaLogger, strEnvironment)
	
	def setup_web_services_bot()
	end # End: def setup_vin_decoder_bot()
	
	def clean_up_bot()
	end # End: def clean_up_bot()
	
	def run_bot()
		begin
			botHost = @environment.environmentHome
			botReferer = "http://" + botHost
			webPathArray = (@environment.paramString).split("$")
			webPathArrayLen = webPathArray.length
			
			intCounter = 1
			while(intCounter < webPathArrayLen)
				webPath, webData = webPathArray[intCounter].split(";")
				
				http = Net::HTTP.new(botHost)
				#@logger.log("Bot: Creating HTTP request object", PASS)
				
				response, data = http.head("/", nil)
				#@logger.log("Bot: Requested HEAD response", PASS)
				
				cookie = response.response["set-cookie"]
				#@logger.log("Bot: Set initial cookie: " + cookie, PASS)
				
				headers = { "Cookie" => cookie, "Referer" => botReferer }
				response, data = http.head("/", headers)
				cookie = response.response["set-cookie"]
				#@logger.log("Bot: Set session cookie: " + cookie, PASS)
				
				if(not cookie["ASP.NET_SessionId="].nil?)
					sessionId = (cookie.split("ASP.NET_SessionId=")[1]).split(";")[0]
					if(not webData.nil?)
						webData = webData + "&userSessionID=" + sessionId.to_s
					end # End: if(not webData.nil?)
					#@logger.log("Bot: Added session id to data: " + sessionId, PASS)
				end # End: if(not cookie["ASP.NET_SessionId="].nil?)
				
				headers = { "Cookie" => cookie, "Referer" => botReferer }
				data = webData
				#@logger.log("Bot: Posting data: " + data + " on " + webPath, PASS)
				response, data = http.post(webPath, data, headers)
				
				if(response.code == "200")
					@logger.log("Web Service PASSING: " + webPath.to_s + " on " + (response["ServerProd"]).to_s, PASS)
				else
					@agentState = FAIL
					@agentMessages = @agentMessages + "Web service: " + webPath.to_s + "Code: " + (response.code).to_s + " Body: " + (response.body).to_s + " Server: " + (response["ServerProd"]).to_s + "\n"
					@logger.log("Web Service FAILING: " + webPath.to_s, FAIL)
					@logger.log("Code: " + (response.code).to_s + " Body: " + (response.body).to_s, @agentState)
				end # End: if(response.code == "200")
				
				intCounter = intCounter + 1
				sleep(1)
			end # End: while(intCounter < webPathArrayLen)
			
			if(@agentState == PASS)
				@agentMessages = "Web Service PASSING"
			end # End: if(@agentState == PASS)
		ensure
			clean_up_bot
		end
	end # End: def run_bot()
	
end # End: class Bot
