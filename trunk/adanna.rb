#***********************************************************************
# Adanna 2.0: adanna.rb
#
# This is the second attempt at creating Adanna, the Agent - Database -
# Agent controller.  It is version 2.0 and uses a brand new library. The
# intent of this version is to get away from multiple libraries and
# having Adanna based on the bots and spider, and force the bots and 
# spider to use Adanna as a resource.
#
# Created by: Nathan Lane
# Last Updated: 05/03/2007
#***********************************************************************

PASS = "Pass"
FAIL = "Fail"
DONE = "Done"
EXCEPTION = "Exception"

class AgentDatabaseAgentController
	
	require "libadanna"
	
	include Adanna
	include Adanna::Environment
	include Adanna::Agents
	include Adanna::Reporting
	include Adanna::Database
	include Adanna::Browser
	
	attr_reader :passFlag, :adannaLogger, :agentData, :adannaConfig, :dbAdapter, :adannaId
	
	def initialize()
		@startTime = Time.parse(Logger.create_timestamp("/", " ", ":"))
		@passFlag = PASS
		
		@agentData = AgentData.new
		
		@adannaConfig = AdannaConfiguration.new(".", "adannaconfig.xml")
		@adannaLogger = Logger.new(".", "Adanna_" + Logger.create_timestamp + @adannaConfig.logFileSuffix, "Adanna Log")
		
		begin
			if(not @adannaConfig.nil?)
				@adannaLogger.log("Successfully loaded Adanna configuration file", PASS)
				@rebootTime = @startTime + @adannaConfig.rebootInterval.to_i
				@dbAdapter = AdannaDBConnection.new(@adannaConfig.dbType, @adannaConfig.dbName, @adannaConfig.dbUserName, @adannaConfig.dbPassword)
				if(not @dbAdapter.dbBinding.nil?)
					@adannaLogger.set_query_engine(@dbAdapter.dbEngine)
					@adannaLogger.log("Successfully connected to " + @dbAdapter.dbType + " database " + @adannaConfig.dbName, PASS)
					@adannaId = @dbAdapter.dbEngine.client_registered?(@agentData)
					if(not @adannaId == 0)
						@adannaLogger.log("Adanna registered with id " + @adannaId.to_s, PASS)
						@dbAdapter.dbEngine.update_client_information(@agentData, @adannaId)
						#***** RUN ADANNA *****#
						run_adanna
					else
						@adannaLogger.log("Adanna is not registered for this client", FAIL)
						Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Adanna is not registered for this client: " + @agentData.computerName, @adannaConfig.emailPickupServer)
						@passFlag = FAIL
					end # End: if(not @adannaId == 0)
				else
					@adannaLogger.log("Could not connect to " + @dbAdapter.dbType + " database" + @adannaConfig.dbName, FAIL)
					Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Could not connect to " + @dbAdapter.dbType + " database" + @adannaConfig.dbName, @adannaConfig.emailPickupServer)
					@passFlag = FAIL
				end # End: if(not @DBAdapter.dbType.nil?)
				
				@closeAdanna = false
			else
				@adannaLogger.log("Could not load Adanna configuration file", FAIL)
				@passFlag = FAIL
			end # End: if(not @adannaConfig.nil?)
		rescue => ex
			@passFlag = EXCEPTION
			@adannaLogger.log("Error occurred, " + ex.to_s + "; backtrace, " + ex.backtrace.inspect, @passFlag)
			if(not @adannaConfig.nil? and not @agentData.nil?)
				Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Adanna is not registered for this client: " + @agentData.computerName, @adannaConfig.emailPickupServer)
			end # End: if(not @adannaConfig.nil? and not @agentData.nil?
		ensure
			@adannaLogger.log("Final state: " + @passFlag, @passFlag)
		end
	end # End: def initialize()
	
	def run_adanna()
		@adannaLogger.log("Running Adanna", PASS)
		main_program_loop
	end # End: def run_adanna()
	
	def clean_up_adanna()
		@dbAdapter.close
		@adannaLogger.close
	end # End: def clean_up_adanna()
	
	def wait_until_launch_time(strTaskLaunchTime)
		timeWithoutMS = strTaskLaunchTime.split(".")[0]
		launchTime = Time.parse(timeWithoutMS)
		while(launchTime > Time.now)
			sleep(1)
		end # End: while(launchTime < nowTime)
	end # End: def wait_until_launch_time(strTaskLaunchTime)
	
	def reboot_system()
		@closeAdanna = true
	end # End: def reboot_system()
	
	def run_bot(agentScript, launchTime, agentEnvironment)
		agentPassFlag = PASS
		agentMesages = ""
		botMessages = ""
		
		begin
			load agentScript["script_name"]
			puts agentEnvironment
			agent = Bot.new(@adannaLogger, agentEnvironment)
			@adannaLogger.log("Loaded bot named " + agentScript["script_name"] + ", waiting for launch time, " + launchTime, PASS)
			wait_until_launch_time(launchTime)
			preLaunchTime = Logger.create_timestamp("-", " ", ":")
			@dbAdapter.dbEngine.update_script_history_started(preLaunchTime, @scriptHistoryId)
			agent.run_bot
			postLaunchTime = Logger.create_timestamp("-", " ", ":")
			@dbAdapter.dbEngine.update_script_history_finished(Logger.create_timestamp("-", " ", ":"), (Logger.subtract_timestamps(postLaunchTime, preLaunchTime)).to_s, @scriptHistoryId)
			agentPassFlag = agent.agentState
			agentMesages = agent.agentMessages
		rescue => ex
			@adannaLogger.log("Bot script error occurred; " + ex.to_s + "; backtrace: " + ex.backtrace.inspect, FAIL)
			agentPassFlag = EXCEPTION
			botMessages = ex.to_s + "; backtrace: " + ex.backtrace.inspect
			@adannaLogger.log("Waiting until after scheduled time of " + launchTime + " to check again", DONE)
			wait_until_launch_time(launchTime)
		ensure
			@adannaLogger.log(agentScript["script_name"] + " bot final state was " + agentPassFlag, agentPassFlag)
			if(agentPassFlag == FAIL)
				Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Bot failed: " + agentScript["script_name"] + " Messages: " + botMessages + "; " + agentMesages, @adannaConfig.emailPickupServer)
			elsif(agentPassFlag == EXCEPTION)
				Logger.send_fail_safe_email(@adannaConfig.creatorEmailAddress, @agentData, "Bot failed: " + agentScript["script_name"] + " Messages: " + botMessages + "; " + agentMesages, @adannaConfig.emailPickupServer)
			end # End: if(agentPassFlag == FAIL)
		end
		
		return agentPassFlag
	end # End: def run_bot(launchTime)
	
	def run_spider(agentScript, launchTime, agentEnvironment)
		agentPassFlag = PASS
		agentMesages = ""
		spiderMessages = ""
		
		begin
			load agentScript["script_name"]
			agent = Spider.new(@adannaLogger, agentEnvironment)
			@adannaLogger.log("Loaded spider named " + agentScript["script_name"] + ", waiting for launch time, " + launchTime, PASS)
			wait_until_launch_time(launchTime)
			preLaunchTime = Logger.create_timestamp("-", " ", ":")
			@dbAdapter.dbEngine.update_script_history_started(preLaunchTime, @scriptHistoryId)
			agent.run_spider
			postLaunchTime = Logger.create_timestamp("-", " ", ":")
			@dbAdapter.dbEngine.update_script_history_finished(Logger.create_timestamp("-", " ", ":"), (Logger.subtract_timestamps(postLaunchTime, preLaunchTime)).to_s, @scriptHistoryId)
			agentPassFlag = agent.agentState
			agentMesages = agent.agentMessages
		rescue => ex
			@adannaLogger.log("Spider script error occurred; " + ex.to_s + "; backtrace: " + ex.backtrace.inspect, FAIL)
			agentPassFlag = EXCEPTION
			spiderMessages = ex.to_s + "; backtrace: " + ex.backtrace.inspect
			@adannaLogger.log("Waiting until after scheduled time of " + launchTime + " to check again", DONE)
			wait_until_launch_time(launchTime)
		ensure
			@adannaLogger.log(agentScript["script_name"] + " spider final state was " + agentPassFlag, agentPassFlag)
			if(agentPassFlag == FAIL)
				Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Spider failed: " + agentScript["script_name"] + " Messages: " + spiderMessages + "; " + agentMesages, @adannaConfig.emailPickupServer)
			elsif(agentPassFlag == EXCEPTION)
				Logger.send_fail_safe_email(@adannaConfig.creatorEmailAddress, @agentData, "Spider failed: " + agentScript["script_name"] + " Messages: " + spiderMessages + "; " + agentMesages, @adannaConfig.emailPickupServer)
			end # End: if(agentPassFlag == FAIL)
		end
		
		return agentPassFlag		
	end # End: def run_spider(agentScript, launchTime)
	
	def get_agent_execution_environment(environmentId)
		retVal = @dbAdapter.dbEngine.get_agent_environment(environmentId)
		@adannaLogger.log("Successfully got agent environment: " + retVal["environment"] + "; paramString: " + retVal["parameter_string"], PASS)
		
		return retVal
	end # End: def get_agent_execution_environment()
	
	def main_program_loop()
		taskList = nil
		agentPassFlag = PASS
		agentEnvironment = TestingEnvironment.new
		@scriptHistoryId = -1
		
		while(not @closeAdanna)
			taskList = @dbAdapter.dbEngine.get_all_tasks(@adannaConfig.taskTimeBounds.to_i, @adannaId)
			@adannaLogger.log("Adanna found " + taskList.length.to_s + " task(s) within the next " + (@adannaConfig.taskTimeBounds.to_i / 60).to_s + " minute(s) to run", DONE)
			
			if(taskList.length > 0)
				if(taskList[0]["scheduler_restart_host"] == "true")
					@adannaConfig.rebootRegularly = "yes"
					@rebootTime = Time.now
				end # End: if(taskList[0]["scheduler_restart_host"] == "true"
				
				if(taskList[0]["scheduler_paused"] == "false")
					launchTime = ((taskList[0]["scheduler_time"].to_s).split(" "))[1]
					env = get_agent_execution_environment((taskList[0]["ID_script_file_xml_environment"]))
					agentEnvironment.set_environment(env["environment"])
					agentEnvironment.set_param_string(env["parameter_string"])
					agentScript = @dbAdapter.dbEngine.get_agent_for_task(taskList[0]["ID_script"])
					if(@dbAdapter.dbEngine.update_script(agentScript["script_name"]))
						@scriptHistoryId = @dbAdapter.dbEngine.send_script_history(Logger.create_timestamp("-", " ", ":"), taskList[0]["ID_script"], @adannaId)
						@adannaLogger.set_script_history_id(@scriptHistoryId)
						@adannaLogger.log("Agent script named " + agentScript["script_name"] + " was successfully updated", PASS)
						@adannaLogger.log("Agent script named " + agentScript["script_name"] + " will be run", DONE)
						if(agentScript["script_type"] == "bot")
							agentPassFlag = run_bot(agentScript, launchTime, agentEnvironment)
							@dbAdapter.dbEngine.update_script_execution_status(taskList[0]["ID_script"], agentPassFlag)
						elsif(agentScript["script_type"] == "spider")
							agentPassFlag = run_spider(agentScript, launchTime, agentEnvironment)
							@dbAdapter.dbEngine.update_script_execution_status(taskList[0]["ID_script"], agentPassFlag)
						else
							@adannaLogger.log("Agent script named " + agentScript["script_name"] + " was not of a known script type: " + agentScript["script_type"], FAIL)
							agentPassFlag = FAIL
							Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Agent script named " + agentScript["script_name"] + " was not of a known script type: " + agentScript["script_type"], @adannaConfig.emailPickupServer)
							@adannaLogger.log("Waiting until after scheduled time of " + launchTime + " to check again", DONE)
							wait_until_launch_time(launchTime)
						end # End: if(agentScript["script_type"] == "bot")
					else
						@adannaLogger.log("Agent script named " + agentScript["script_name"] + " could not be updated", FAIL)
						agentPassFlag = FAIL
						Logger.send_fail_safe_email(@adannaConfig.errorEmailAddress, @agentData, "Agent script named " + agentScript["script_name"] + " could not be updated", @adannaConfig.emailPickupServer)
						@adannaLogger.log("Waiting until after scheduled time of " + launchTime + " to check again", DONE)
						wait_until_launch_time(launchTime)
					end # End: if(@dbAdapter.dbEngine.update_script)
				end # End: if(taskList[0]["scheduler_paused"] == "false")
				if(@adannaConfig.rebootRegularly == "yes")
					if(Time.now > @rebootTime)
						@adannaLogger.log("Rebooting system now - final state: " + passFlag, passFlag)
						reboot_system
					end # End: if(Time.now > Time.parse(@startTime + @adannaConfig.rebootInterval.to_i))
				end # End: if(@adannaConfig.rebootRegularly == "yes")
			else
				@adannaLogger.log("Will check again in " + (@adannaConfig.taskCheckDelay.to_i / 60).to_s + " minute(s) for tasks", DONE)
				sleep(@adannaConfig.taskCheckDelay.to_i)
			end # End: if(taskList.length > 0)
			
			@dbAdapter.dbEngine.update_client_information(@agentData, @adannaId)
			#@closeAdanna = true
		end # End: while(not @closeAdanna)
	end # End: def main()
	
end # End: class AgentDatabaseAgentController

#***********************************************************************
# This is the program entry point
#***********************************************************************
if __FILE__ == $0 # This verifies that the file name is the same as the zeroth argument, which is also the file name
	
	adanna = nil
	
	# Error event handler - I want Adanna to restart if a major exception gets caught
	while(true)
		begin
			# Create a new Adanna object
			adanna = AgentDatabaseAgentController.new()
		rescue => ex
			adanna.adannaLogger.log("*** Adanna Failed Severely: Waiting one minute to auto restart Adanna ***", FAIL)
		ensure
			adanna.adannaLogger.log("Adanna restarting: Waiting one minute to auto restart Adanna", DONE)
			adanna.clean_up_adanna
			adanna = nil
			sleep(60)
		end
	end # End: while(true)
	
end # End: if __FILE__ == $0
