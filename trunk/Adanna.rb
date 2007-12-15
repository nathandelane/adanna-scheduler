#***********************************************************************
# Script Name: Adanna.rb    Version: 1.0.0
#
# This script becomes an agent between agents that are run on a given 
# host. It uses an XML config file to connect to a database server which
# retains information regarding the running of these agent scripts.
#
# Change Notes:
#  01-29-2007: Changed this script to utilize the Pod_Environment_01.xml
#              configuration file.
#
#  01-15-2007: Actually began writing this script.
#
# @author Nathan Lane
# Last Updated: 01/15/2006
#***********************************************************************

class Adanna
	
	require "pod/pod" # Required to do basic agent stuff
	
	include Pod # Basic set of classes to set up an agent
	include Agents # Agent specific helper classes
	include Logging # Logging module - includes PodLogger and RelayServer
	
	require "dbi" # Required to access db on server end
	require "fileutils" # Required to copy files

	def initialize()
		# Get the current working directory
		@adannaBase = Dir.getwd
		# Set config file name
		@adannaConfigFilename = "Adanna.config"

		# Set version
		@version = "1.3.5" + "_" + Pod::libraryVersion?
		
		# Create a logger for local logging
		@adannaLogger = PodLogger.new(false)
		# Set logging mode
		@loggingMode = PL.BOTH
		@adannaLogger.log(PL.INFO, "This is ADAnna (The Agent-Database Agent) version " + @version, @loggingMode)
		
		# Get agent data
		@adannaLogger.log(PL.INFO, "Getting agent data", @loggingMode)
		@agentData = AgentData.new
		
		# Create the arg table hash
		@adannaLogger.log(PL.INFO, "Getting command line arguments and setting parameters", @loggingMode)
		@argTable = Hash.new
		initialize_arg_table
		# Get command line arguments
		tempArguments = get_arguments
		# Set the parameters in the arg table
		set_parameters(tempArguments)
		
		# Create a config table
		@adannaLogger.log(PL.INFO, "Loading ADAnna configuration", @loggingMode)
		@configTable = Hash.new
		# load the configuration file
		load_config(@argTable["create-config"])
		
		# Set script folder
		@adannaAgentFolder = @configTable["adanna"][0]["adanna_agent_folder"][0]
		agentFolderPath = @adannaBase + "/" + @adannaAgentFolder
		if not File.exist?(agentFolderPath)
			Dir.mkdir(agentFolderPath)
		end # End: if not File.exist?(agentFolderPath)
		# Set db check interval
		@taskCheckInterval = (@configTable["adanna"][0]["task_check_interval"][0]).to_i # seconds
		# Set time span in which to check for tasks in seconds
		@taskTimeSpan = (@configTable["adanna"][0]["task_time_span"][0]).to_i
		# Set update check interval
		@updateCheckInterval = (@configTable["adanna"][0]["update_interval"][0]).to_i
		
		# Set up a communications port for agents
		@adannaLogger.log(PL.INFO, "Setting up and starting relay server", @loggingMode)
		@comPort = Util.intRandomPort
		# Set up relay server
		@relayServer = RelayServer.new(@comPort)
		@adannaLogger.log(PL.INFO, "Relay server running on port " + @comPort.to_s, @loggingMode)
		
		# Script running?
		@scriptRunning = false
	end # End: def initialize()
	
	#***********************************************************************
	# run_agent_mediator runs the Agent Mediator.
	#***********************************************************************
	def run_adanna()
		@adannaLogger.log(PL.INFO, "Running ADAnna", @loggingMode)
		adanna
	end # End: def run_agent_mediator()
	
	#***********************************************************************
	# clean_up_adanna cleans up any connections it needs to.
	#***********************************************************************
	def clean_up_adanna()
		begin
			@adannaLogger.log(PL.INFO, "Closing database connection", @loggingMode)
			close_database_binding # Close the database binding
		rescue
		end
		
		begin
			@adannaLogger.log(PL.INFO, "Closing logger", @loggingMode)
			@adannaLogger.close
		rescue
		end
	end # End: def clean_up_adanna()
	
	#***********************************************************************
	# initialize_arg_table initializes the @argTable hash with default 
	# values and thus sets the preferred type of the value.
	#***********************************************************************
	def initialize_arg_table()
		@argTable["create-config"] = false
	end # End: def initialize_arg_table()

	#***********************************************************************
	# get_arguments puts all of the commandline arguments into the argument
	# hash table.
	#***********************************************************************
	def get_arguments()
		tempArgTable = Hash.new
		
		ARGV.each { # Get each argument from the commandline arguments array
			|arg| argument = arg # Get the next argument
			
			nextArg = argument.downcase # Make all characters in the argument lowercase
			nextArg.chomp! # Get rib of newline and page feed characters
			nextArgSplit = nextArg.split("=") # Split the argument by its "=" sign
			
			if nextArgSplit.length == 1 # If there is only one element in the array, then make the second element an asterisk, "*"
				nextArgSplit[1] = "*"
			end # End: if nextArgSplit.length == 1
			
			if not nextArgSplit[0]["--"].nil? # Strip "--" characters from the beginning of the argument
				intLen = nextArgSplit[0].length - 1
				strTemp = nextArgSplit[0][2..intLen]
				nextArgSplit[0] = strTemp
			end # End: if not nextArgSplit[0]["--"].nil?
			
			tempArgTable[nextArgSplit[0]] = nextArgSplit[1] # Add the argument with its value to the argument hash table
		}
		
		return tempArgTable
	end # End: def get_arguments()
	
	#***********************************************************************
	# set_parameters uses the argument hash table to make sure that the
	# values are all of the correct type and ensures that defaults are set.
	#***********************************************************************
	def set_parameters(objArgumentHash)
		if objArgumentHash.has_key?("help") # If any of the commandline arguments was "--help", then show the help string and exit
			display_help # Call to method that shows help string
			exit(1) # Terminate the script abnormally
		else
			keysArray = objArgumentHash.keys # Get the keys of the hash of arguments
			# Iterate through each key
			keysArray.each {
				|k| nextKey = k
				
				if @argTable.has_key?(nextKey) # If the arg table has the same key, then it's valid
					if @argTable[nextKey].class == String # If the value's class is String convert parameter to String
						@argTable[nextKey] = objArgumentHash[nextKey].to_s
					elsif @argTable[nextKey].class == TrueClass # If the value's class is TrueClass convert parameter to boolean
						@argTable[nextKey] = Util.to_b(objArgumentHash[nextKey])
					elsif @argTable[nextKey].class == FalseClass # If the value's class is FalseClass convert parameter to boolean
						@argTable[nextKey] = Util.to_b(objArgumentHash[nextKey])
					elsif @argTable[nextKey].class == Fixnum # If the value's class is Fixnum convert parameter to integer
						@argTable[nextKey] = objArgumentHash[nextKey].to_i
					else
						@argTable[nextKey] = objArgumentHash[nextKey] # Otherwise just make them equal
					end # End: case @argTable[nextKey].class
				end # End: if @argTable.has_key?(nextKey)
			}
		end # End: if @argTable.has_key?("help")
	end # End: def set_parameters()
	
	#***********************************************************************
	# This method displays the commandline help for anyone who wants to see
	# it.
	#***********************************************************************
	def display_help()
		@adannaLogger.log(PL.INFO, "Displaying help for ADAnna", @loggingMode)
		puts "\nAdanna.rb [options]" +
			"\n\nOptions:" +
			"\n    --help Brings up this help listing" +
			"\n    --create-config=true or false\n"
	end # End: def voidDisplayHelp()
	
	#***********************************************************************
	# load_config loads the configuration file and saves off properties
	# needed by the AgentMediator script.
	#***********************************************************************
	def load_config(blnCreateConfigFile)
		# Create local config path
		localConfigFile = @adannaBase + "/" + @adannaConfigFilename
		
		if blnCreateConfigFile
			create_default_Properties(localConfigFile) # Create the config file
		else
			if File.exist?(localConfigFile)
				@configTable = XmlSimple.xml_in(localConfigFile, { "KeyAttr" => "name" }) # Load the config file
			else
				create_default_Properties(localConfigFile) # Create the config file
			end # End: if File.exist?(localConfigFile)
		end # End: if blnCreateConfigFile
		
		#@configTable#["database"]["db_host_name"].inspect + "\ndb_user_name=" + @configTable["database"]["db_user_name"].inspect + "\ndb_user_password=" + @configTable["database"]["db_user_password"].inspect + "\ndb_database_name=" + @configTable["database"]["db_database_name"].inspect
	end # End: def load_config()
	
	#***********************************************************************
	# create_default_Properties creates a default properties file in the 
	# default location if it doesn't already exist and loads the defaults
	# into its own properties.
	#***********************************************************************
	def create_default_Properties(strConfigFilePath)
		@adannaLogger.log(PL.INFO, "Creating default properties", @loggingMode)
		fileCleared = true # Set the file cleared flag to true by default
		retVal = nil
		
		# If the file already exists, true and delete the file
		if File.exist?(strConfigFilePath)
			begin
				File.unlink(strConfigFilePath)
				fileCleared = true
			rescue => ex
				fileCleared = false
			end
		end # End: if File.exist?(strConfigFilePath)
		
		# If file delete was successful or didn't already exist, then begin creating it (again)
		if fileCleared
			configFile = File.new(strConfigFilePath, File::CREAT) # Create or recreate the config file
			retVal = configFile # Store file object into retVal
			configFile.close # Close the file
			
			# Create the hash
			@configTable = Hash.new
			@configTable["adanna"] = Array.new
			@configTable["adanna"][0] = Hash.new
			@configTable["adanna"][0]["task_check_interval"] = [ 60 ]
			@configTable["adanna"][0]["task_time_span"] = [ 300 ]
			@configTable["adanna"][0]["adanna_agent_folder"] = [ "Agents" ]
			@configTable["adanna"][0]["update_interval"] = [ 1440 ]
			@configTable["adanna"][0]["task_run_user"] = [ "qarobot" ]
			@configTable["adanna"][0]["task_run_password"] = [ "qarobot" ]
			@configTable["scheduler_database"] = Array.new
			@configTable["scheduler_database"][0] = Hash.new
			@configTable["scheduler_database"][0]["db_connection_type"] = [ "ODBC" ]
			@configTable["scheduler_database"][0]["db_host_name"] = [ "localhost" ]
			@configTable["scheduler_database"][0]["db_user_name"] = [ "qarobot" ]
			@configTable["scheduler_database"][0]["db_user_password"] = [ "qarobot" ]
			@configTable["scheduler_database"][0]["db_database_name"] = [ "qastats" ]
			@configTable["results_database"] = Array.new
			@configTable["results_database"][0] = Hash.new
			@configTable["results_database"][0]["db_connection_type"] = [ "ODBC" ]
			@configTable["results_database"][0]["db_host_name"] = [ "localhost" ]
			@configTable["results_database"][0]["db_database_name"] = [ "qastats" ]
			@configTable["results_database"][0]["db_user_name"] = [ "qarobot" ]
			@configTable["results_database"][0]["db_user_password"] = [ "qarobot" ]
			@configTable["file_location"] = Array.new
			@configTable["file_location"][0] = Hash.new
			@configTable["file_location"][0]["storage_medium"] = [ "database" ]
			@configTable["file_location"][0]["db_connection_type"] = [ "ODBC" ]
			@configTable["file_location"][0]["host_name"] = [ "localhost" ]
			@configTable["file_location"][0]["database_name"] = [ "qastats" ]
			@configTable["file_location"][0]["user_name"] = [ "qarobot" ]
			@configTable["file_location"][0]["user_password"] = [ "qarobot" ]
			
			# Open up the config file for xml writing
			# Create options hash for xml-simple.xml_out
			optionsHash = Hash.new
			optionsHash["rootname"] = "config"
			optionsHash["outputfile"] = strConfigFilePath
			XmlSimple.xml_out(@configTable, optionsHash)
		else
			retVal = nil
		end # End: if fileCleared
		
		return retVal # return some value, either a File object or nil
	end # End: def create_default_Properties()
	
	def config_table()
		return @configTable
	end # End: def config_table()
	
	def bind_to_scheduler_database()
		@adannaLogger.log(PL.INFO, "Binding to scheduler database", @loggingMode)
		begin
			@binding = DBI.connect("DBI:" + @configTable["scheduler_database"][0]["db_connection_type"][0] + ":" + @configTable["scheduler_database"][0]["db_database_name"][0], @configTable["scheduler_database"][0]["db_user_name"][0], @configTable["scheduler_database"][0]["db_user_password"][0])
			retVal = @binding
		rescue => ex
			@adannaLogger.log(PL.ERROR, "Caught exception for bind_to_scheduler_database: " + ex.inspect, @loggingMode)
			retVal = nil
		end
		
		return retVal
	end # End: def bind_to_scheduler_database()
	
	def bind_to_results_database()
		@adannaLogger.log(PL.INFO, "Binding to results database", @loggingMode)
		begin
			@resBinding = DBI.connect("DBI:" + @configTable["results_database"][0]["db_connection_type"][0] + ":" + @configTable["results_database"][0]["db_database_name"][0], @configTable["results_database"][0]["db_user_name"][0], @configTable["results_database"][0]["db_user_password"][0])
			retVal = @resBinding
		rescue => ex
			@adannaLogger.log(PL.ERROR, "Caught exception for bind_to_results_database: " + ex.inspect, @loggingMode)
			retVal = nil
		end
		
		return retVal
	end # End: def bind_to_results_database()
	
	def bind_to_file_database()
		@adannaLogger.log(PL.INFO, "Binding to file database", @loggingMode)
		begin
			@fileBinding = DBI.connect("DBI:" + @configTable["file_location"][0]["db_connection_type"][0] + ":" + @configTable["file_location"][0]["database_name"][0], @configTable["file_location"][0]["user_name"][0], @configTable["file_location"][0]["user_password"][0])
			retVal = @fileBinding
		rescue => ex
			@adannaLogger.log(PL.ERROR, "Caught exception for bind_to_file_database: " + ex.inspect, @loggingMode)
			retVal = nil
		end
		
		return retVal
	end # End: def bind_to_file_database()
	
	def connect_to_file_server()
	end # End: def connect_to_file_server()
	
	def close_database_binding()
		begin
			@binding.close
			@resBinding.close
			@fileBinding.close
		rescue => ex
			puts "Error - unable to close database, perhaps it was already closed"
		end
	end # End: def close_database_binding()
	
	def clean_up_results(objResults)
		begin
			objResults.finish
		rescue => ex
			puts "Finish caused exception"
		end
	end # End: def clean_up_results(objResults)
	
	#***********************************************************************
	# send_log sends log information to the database.
	#***********************************************************************
	def send_log(timeStamp, status, details)
		# Rectify datTimeStamp
		todayDate = Date.today
		strToday = todayDate.year.to_s + "-" + todayDate.month.to_s + "-" + todayDate.mday.to_s + " "
		dateTimeStamp = strToday + timeStamp
		# Create query string
		logInsertString = "INSERT INTO script_history_log(ID_script_history, script_history_log_event_datetime_stamp, script_history_log_event_status, script_history_log_event_details) VALUES('" +
			@scriptHistoryID.to_s + "', '" +
			dateTimeStamp.to_s + "', '" + 
			status.to_s + "', '" + 
			details.to_s + "')"
		# Query the database
		results = @resBinding.prepare(logInsertString)
		results.execute
		#@resBinding.drop
		
		return results
	end # End: def send_log(dateTimeStamp, status, details)
	
	#***********************************************************************
	# send_script_history enters a record for the current script and returns
	# the ID for that record.
	#***********************************************************************
	def send_script_history(id_script, id_host)
		retVal = 0
		
		# Create a query string
		# Get today's date and time and make a date time for Mysql
		date = Date.today
		time = Time.now
		@date_time = date.year.to_s + "-" + 
			Util.strPad(2, date.month.to_s, "0") + "-" + 
			Util.strPad(2, date.mday.to_s, "0") + " " + 
			Util.strPad(2, time.hour.to_s, "0") + ":" + 
			Util.strPad(2, time.min.to_s, "0") + ":" + 
			Util.strPad(2, time.sec.to_s, "0")
		queryString = "INSERT INTO script_history(" +
			"ID_script, " + 
			"ID_script_group_joined, " +
			"ID_host, " + 
			"ID_host_group_joined, " +
			"script_history_date_created, " +
			"script_history_date_updated, " +
			"script_history_date_executed, " +
			"script_history_executed_status, " +
			"script_history_time_executed) " +
			"VALUES(" + id_script + ", 1, '" + id_host + "', 1, '" + @date_time + "', '" + @date_time + "', '" + @date_time + "', 'Created', 0)"
		query = @resBinding.prepare(queryString)
		query.execute
		clean_up_results(query)
		#@resBinding.drop
		# Get the ID back for this record
		queryString = "SELECT * FROM script_history WHERE id_host='" + id_host + "' AND script_history_date_created='" + @date_time + "'"
		# Query for the record
		resultSet = @resBinding.prepare(queryString)
		resultSet.execute
		#@resBinding.drop
		
		if row = resultSet.fetch_hash
			if row.has_key?("id")
				recordID = row["id"]
				retVal = recordID
			else
				retVal = 0
			end # End: if row.has_key?("id")
		else
			retVal = 0
		end # End: if row = resultSet.fetch_hash
		
		clean_up_results(resultSet)
		row = nil
		
		return retVal
	end # End: def send_script_history(id_script, id_host)
	
	#***********************************************************************
	# update_script_history_finished updates the script history with end of 
	# script data.
	#***********************************************************************
	def update_script_history_finished(strEndTime, strTotalTime, id_script_history)
		# Create a query string
		# Get today's date and time and make a date time for Mysql
		date = Date.today
		strEndTime.chomp!
		@date_time = date.year.to_s + "-" + 
			Util.strPad(2, date.month.to_s, "0") + "-" + 
			Util.strPad(2, date.mday.to_s, "0") + " " +
			strEndTime
		queryString = "UPDATE script_history SET " +
			"script_history_date_updated='" + @date_time + "', " +
			"script_history_executed_status='Done', " +
			"script_history_time_executed=" + strTotalTime +
			" WHERE id=" + id_script_history.to_s
		results = @resBinding.prepare(queryString)
		results.execute
		#@resBinding.drop
		
		return results
	end # End: def update_script_History(strEndTime, strTotalTime)
	
	#***********************************************************************
	# update_script_history_started updates the script history with start of 
	# script data.
	#***********************************************************************
	def update_script_history_started(strTime, id_script_history)
		puts "Updating started history"
		# Create a query string
		# Get today's date and time and make a date time for Mysql
		date = Date.today
		strTime.chomp!
		@date_time = date.year.to_s + "-" + 
			Util.strPad(2, date.month.to_s, "0") + "-" + 
			Util.strPad(2, date.mday.to_s, "0") + " " +
			strTime
		queryString = "UPDATE script_history SET " +
			"script_history_date_updated='" + @date_time + "', " +
			"script_history_executed_status='Started', " +
			"script_history_date_executed='" + @date_time +
			"' WHERE id=" + id_script_history.to_s
		results = @resBinding.prepare(queryString)
		results.execute
		#@resBinding.drop
		
		return results
	end # End: 
	
	#***********************************************************************
	# get_all_tasks returns an array of hashes containing task information.
	#***********************************************************************
	def get_all_tasks(timeSpanInSeconds)
		# Create a time string
		time = Time.now
		strTime_now = Util.strPad(2, time.hour.to_s, "0") + ":" + Util.strPad(2, time.min.to_s, "0") + ":" + Util.strPad(2, time.sec.to_s, "0")
		#strTime_now = "1/1/1900 " + strTime_now
		# And a second datetime string
		time = (Time.now + (timeSpanInSeconds)) # Add seconds
		strTime_future = Util.strPad(2, time.hour.to_s, "0") + ":" + Util.strPad(2, time.min.to_s, "0") + ":" + Util.strPad(2, time.sec.to_s, "0")
		#strTime_future = "1/1/1900 " + strTime_future
		@adannaLogger.log(PL.INFO, "Getting tasks for host " + @agentData.computerName + " within " + (timeSpanInSeconds / 60).to_s + " minutes of " + strTime_now, @loggingMode)
		# Build query string to get all tasks
		agentTasksQueryString = "SELECT * FROM scheduler WHERE ID_host = '" + @adannaID.to_s + "' and scheduler_time > '" + strTime_now + "' AND scheduler_time < '" + strTime_future + "'"
		# Query the database
		resultSet = @binding.prepare(agentTasksQueryString)
		resultSet.execute
		#@binding.drop
		# Initialize array
		taskList = Array.new
		# Get each row
		#resultSetCopy = resultSet.clone
		#rows = resultSetCopy.fetch_all
		#if rows.size > 0
		while row = resultSet.fetch_hash do
			# Add row hash table to taskList
			taskList << row
		end # End: while row = resultSet.fetch_hash do
		#end # End: if rows.size > 0
		
		clean_up_results(resultSet)
		row = nil
		
		return taskList
	end # End: def get_all_tasks()
	
	#***********************************************************************
	# get_agent_for_task returns a hash of the script to be run for the 
	# task.
	#***********************************************************************
	def get_agent_for_task(taskHash)
		retVal = nil
		
		if taskHash.instance_of?(Hash)
			if taskHash.has_key?("ID_script")
				# Use script id to get script info
				queryString = "SELECT * FROM script WHERE id=" + (taskHash["ID_script"]).to_s
				# Query for the script info
				resultSet = @fileBinding.prepare(queryString)
				resultSet.execute
				#@fileBinding.drop
				# Check result set
				if not retVal = resultSet.fetch_hash
					retVal = nil
				end # End: if not retVal = resultSet.fetch_hash
				clean_up_results(resultSet)				
			end # End: if taskHash.has_key?("id_script")
		end # End: if taskHash.instance_of?(Hash)
		
		return retVal # Return the agent hash
	end # End: def get_agent_for_task(taskHash)
	
	#***********************************************************************
	# run_agent runs the agent supplied.
	#***********************************************************************
	def run_agent(strAgentFilename, strCommandline, objTime)
		retVal = nil
		
		strAgentFilename.chomp!
		strCommandline.chomp!
		@strAgentRunTime = ((((objTime.to_s).split(" "))[1]).split("."))[0]
		
		# Change to Adanna base directory + agent directory
		Dir.chdir(@adannaBase + "/" + @adannaAgentFolder)
		# Check for agent script file
		if File.exist?(strAgentFilename)
			@adannaLogger.log(PL.INFO, "Will launch agent script " + strAgentFilename + " at " + @strAgentRunTime.to_s, @loggingMode)
			# Set up a scheduled task
			time = (Time.now + 60) # Get the current time + one minute
			# Create the command line and store in a batch file
			adannaBaseWithoutDrive = (@adannaBase.split(":"))[1]
			adannaBaseWithoutDrive.sub!("/","\\")
			batchString = "@echo off\n" +
				"C:\n" +
				"cd " + adannaBaseWithoutDrive + "\\" + @adannaAgentFolder + "\n" +
				"start /WAIT ruby " + strAgentFilename + " " + strCommandline + "\n"
			batchFile = File.new("Run_Agent.bat", "w+")
			batchFile.puts batchString
			batchFile.close
			# Create the scheduled task
			#atScript = "at " + time.hour.to_s + ":" + time.min.to_s + " ruby \"" + Dir.getwd + "/" + strAgentFilename + "\""
			taskName = strAgentFilename.split(".")
			schtasksScript = "schtasks /Create /S " + @agentData.computerName + " /RU " + @configTable["adanna"][0]["task_run_user"][0] + " /RP " + @configTable["adanna"][0]["task_run_password"][0] + " /SC ONCE /TN " + taskName[0].to_s + " /ST " + @strAgentRunTime + " /TR c:\\Adanna\\Agents\\Run_Agent.bat"
			puts "TN: " + schtasksScript
			#proc = IO.popen("rubyw " + strAgentFilename)
			IO.popen(schtasksScript)
			retVal = strAgentFilename
		else
			@adannaLogger.log(PL.INFO, "Could not locate script " + strAgentFilename, @loggingMode)
			retVal = nil
		end # End: if File.exist?(strAgentFilename)
		
		return retVal
	end # End: def run_agent(strAgentFilename)
	
	#***********************************************************************
	# check_agent_registration checks to see if the current agent based on
	# its agent data is registered on the current database. If it isn't,
	# then false is returned and the script stops, otherwise if it is, then
	# the agent gets its id and continues to check for scheduled tasks.
	#***********************************************************************
	def agent_registered?()
		@adannaLogger.log(PL.INFO, "Querying database to find out if ADAnna@" + @agentData.computerName + " is registered", @loggingMode)
		retVal = false # Initialize as false becaue we need a result set to be true
		
		# Build a query string to look for computer registration
		agentRegistrationQueryString = "SELECT * FROM host WHERE host_name = '" + @agentData.computerName + "'"
		# Query the database
		resultSet = @binding.prepare(agentRegistrationQueryString)
		resultSet.execute
		#@binding.drop
		# Vaildate and get ID
		while row = resultSet.fetch_hash
			if row["host_name"] == @agentData.computerName
				@adannaID = row["id"]
				retVal = true
			else
				retVal = false
			end # End: if row["host_name"] == @agentData.computerName
		end # End: while resultSet.fetch_hash do
		
		clean_up_results(resultSet)
		row = nil
		
		# Now we want to update that data, so that we know that ADAnna is still "alive"
		#@agentData
		# Create a datetimestamp
		date = Date.today
		time = Time.now
		localDateTime = date.year.to_s + "-" + 
			Util.strPad(2, date.month.to_s, "0") + "-" + 
			Util.strPad(2, date.mday.to_s, "0") + " " + 
			Util.strPad(2, time.hour.to_s, "0") + ":" + 
			Util.strPad(2, time.min.to_s, "0") + ":" + 
			Util.strPad(2, time.sec.to_s, "0")
		# Create a query string
		@agentData = nil
		@agentData = AgentData.new
		agentRegUpdateQueryString = "UPDATE host SET host_date_updated = '" + localDateTime.to_s + 
			"', host_ip = '" + @agentData.ipAddress.to_s + 
			"', host_ram = " + @agentData.memTotal.to_s +
			", host_hd_size = " + @agentData.diskTotal.to_s +
			", host_hd_free = " + @agentData.diskFreePercent.to_s +
			", host_processor_type = '" + @agentData.procName.to_s +
			"', host_processor_speed = " + @agentData.procSpeed.to_s +
			" WHERE id = " + @adannaID.to_s
		# Query the browser
		resultSet = @binding.prepare(agentRegUpdateQueryString)
		resultSet.execute
		# Clean up
		clean_up_results(resultSet)
		
		return retVal
	end # End: def check_agent_registration()
	
	#***********************************************************************
	# update_adanna_script updates this script.
	#***********************************************************************
	def update_adanna_script()
		# Make sure we're in the adanna base directory
		Dir.chdir(@adannaBase)
		# Build a query string
		queryString = "SELECT * FROM script_file WHERE script_file_name = 'Adanna.rb'"
		# Query the db
		resultSet = @fileBinding.prepare(queryString)
		resultSet.execute
		#@fileBinding.drop
		# Try and create the file
		if row = resultSet.fetch_hash
			fileName = row["script_file_name"]
			
			# Make sure the version is newer
			subVersionDB = (row["script_file_description"]).split("_")
			subVersionAdanna = @version.split("_")
			@adannaLogger.log(PL.INFO, "Current version=" + subVersionAdanna + " New version=" + subVersionDB, @loggingMode)
			if not (subVersionDB[0] == subVersionAdanna[0])
				@adannaLogger.log(PL.INFO, "Attempting to update ADAnna script", @loggingMode)
				# Delete the old file if it exists
				if File.exist?(fileName)
					File.unlink(fileName)
				end # End: if File.exist?(strScriptName)
				
				fileContents = row["script_file_content"]
				fw = File.new(fileName, "w+")
				fw.write(fileContents)
				fw.close
			end # End: if not (subVersionDB[0] == subVersionAdanna[0])
			@adannaLogger.log(PL.INFO, "ADAnna script was updated successfully - rebooting computer", @loggingMode)
			# Clean up Adanna
			clean_up_adanna
			# Reboot computer
			exec("shutdown -r -t 00")
		end # End: if rows.size == 1
		@adannaLogger.log(PL.INFO, "No update was found for ADAnna script", @loggingMode)
		
		clean_up_results(resultSet)
		row = nil
	end # End: def update_properties_file(strPropertiesFile)
	
	#***********************************************************************
	# update_properties_file updates a properties file if there is one.
	#***********************************************************************
	def update_properties_file(intPropertiesFile)
		if not intPropertiesFile == 0
			@adannaLogger.log(PL.INFO, "Attempting to update properties file", @loggingMode)
			# Find out if we're in the right directory
			if Dir.getwd["Agents"].nil?
				Dir.chdir(@adannaBase + "/" + "Agents")
			end # End: if Dir.getwd["Agents"].nil?
			# Build a query string
			queryString = "SELECT * FROM script_file WHERE id = " + intPropertiesFile.to_s
			# Query the db
			resultSet = @fileBinding.prepare(queryString)
			resultSet.execute
			#@fileBinding.drop
			# Try and create the file
			if row = resultSet.fetch_hash
				fileName = row["script_file_name"]
				
				# Delete the old file if it exists
				if File.exist?(fileName)
					File.unlink(fileName)
				end # End: if File.exist?(strScriptName)
				
				fileContents = row["script_file_content"]
				fw = File.new(fileName, "w+")
				fw.write(fileContents)
				fw.close
			end # End: if rows.size == 1
			@adannaLogger.log(PL.INFO, "Properties file was updated successfully", @loggingMode)
		else
			@adannaLogger.log(PL.INFO, "Not updating properties file - script was not associated with a properties file", @loggingMode)
		end # End: if not intPropertiesFile == 0
		
		clean_up_results(resultSet)
		row = nil
	end # End: def update_properties_file(strPropertiesFile)
	
	#***********************************************************************
	# update_xml_environment_file updates the xml environment.
	#***********************************************************************
	def update_xml_environment_file(intXMLFile)
		if not intXMLFile == 0
			@adannaLogger.log(PL.INFO, "Attempting to update XML environment file", @loggingMode)
			# Find out if we're in the right directory
			if Dir.getwd["Agents"].nil?
				Dir.chdir(@adannaBase + "/" + "Agents")
			end # End: if Dir.getwd["Agents"].nil?
			# Build a query string
			queryString = "SELECT * FROM script_file WHERE id = " + intXMLFile.to_s
			# Query the db
			resultSet = @fileBinding.prepare(queryString)
			resultSet.execute
			#@fileBinding.drop
			# Try and create the file
			if row = resultSet.fetch_hash
				fileName = row["script_file_name"]
				
				# Delete the old file if it exists
				if File.exist?(fileName)
					File.unlink(fileName)
				end # End: if File.exist?(strScriptName)
				
				fileContents = row["script_file_content"]
				fw = File.new(fileName, "w+")
				fw.write(fileContents)
				fw.close
			end # End: if row = resultSet.fetch_hash
			@adannaLogger.log(PL.INFO, "XML environment file was updated successfully", @loggingMode)
		else
			@adannaLogger.log(PL.INFO, "Not updating XML environment file - script was not associated with an environment file", @loggingMode)
		end # End: if not intXMLFile == 0
		
		clean_up_results(resultSet)
		row = nil
	end # End: def update_xml_environment_file(strXMLFile)
	
	#***********************************************************************
	# update_script grabs the script blob from the db and recreates the
	# file in the Agents directory.
	#***********************************************************************
	def update_script(strScriptName)
		@adannaLogger.log(PL.INFO, "Attempting to update script", @loggingMode)
		# Find out if we're in the right directory
		if Dir.getwd["Agents"].nil?
			Dir.chdir(@adannaBase + "/" + "Agents")
		end # End: if Dir.getwd["Agents"].nil?
		# Delete the old file if it exists
		if File.exist?(strScriptName)
			File.unlink(strScriptName)
		end # End: if File.exist?(strScriptName)
		# Build a query string
		queryString = "SELECT * FROM script_file WHERE script_file_name = '" + strScriptName + "'"
		# Query the db
		resultSet = @fileBinding.prepare(queryString)
		resultSet.execute
		#@fileBinding.drop
		# Try and create the file
		if row = resultSet.fetch_hash
			fileName = row["script_file_name"]
			fileContents = row["script_file_content"]
			fw = File.new(fileName, "w+")
			fw.write(fileContents)
			fw.close
		end # End: if row = resultSet.fetch_hash
		@adannaLogger.log(PL.INFO, "Script was updated successfully", @loggingMode)
		
		clean_up_results(resultSet)
		row = nil
	end # End: def update_script(strScriptName)
	
	#***********************************************************************
	# send_fail_safe_email send an email if called.
	#***********************************************************************
	def send_fail_safe_email()
		# Make the string
		strEmailText = 
			"TO: qateam@vehix.com <mailto:qateam@vehix.com>\n" +
			"FROM: adanna@vehix.com <mailto:adanna@vehix.com>\n" +
			"SUBJECT: From ADAnna Server - " + @agentData.computerName.to_s + ".\n" +
			"I cannot connect to the MySQL database!"
		
		# Write the file
		emailFile = File.new("adannafilasafe.txt", "w+")
		emailFile.puts strEmailText
		emailFile.close
		
		# Copy the file over
		FileUtils::cp("adannafilasafe.txt", "\\\\qaquality\\Pickup")
	end # End: def send_fail_safe_email()
		
	#***********************************************************************
	# adanna is the program loop for this script.
	#***********************************************************************
	def adanna()
		# Initialize important variables in this section
		check = true
		logMsg = ""
		logData = Array.new
		taskList = nil
		agentScript = nil
		intUpdateCountdown = @updateCheckInterval # Check for an update every 24 hour(s)
		
		@exceptionAllowance = 5
		@execptionTotal = 0
		@restartHost = false
		
		@binding = @resBinding = @fileBinding = nil
		if (not (bind_to_scheduler_database).nil?) and (not (bind_to_results_database).nil?) and (not (bind_to_file_database).nil?) # Connect to the databases
			while true
				begin
					if check
						if agent_registered?
							@adannaLogger.log(PL.INFO, "Agent was found to be registered with id: " + @adannaID.to_s, @loggingMode)
							taskList = get_all_tasks(@taskTimeSpan) # Get all tasks associated with host id
							@adannaLogger.log(PL.INFO, "Number of tasks for agent: " + taskList.length.to_s, @loggingMode)
							
							# If no tasks were found reset timer
							if taskList.length == 0
								strLastCheck = @adannaLogger.log(PL.INFO, "ADAnna will check for tasks associated with host " + @agentData.computerName + " in " + (@taskCheckInterval / 60).to_s + " minutes", @loggingMode)[1] # Get the time stamp
								@lastCheck = Time.parse(strLastCheck)
								check = false
							else # Otherwise QUEUE up tasks
								# TODO: QUEUE timing stuff
								# Run the task
								if not (@agentHash = get_agent_for_task(taskList[0])).nil? # Get the agent hash for the task hash
									@scriptHistoryID = send_script_history(@agentHash["id"], @adannaID)
									# Update the script
									update_script(@agentHash["script_name"])
									# Update properties file
									update_properties_file((taskList[0]["ID_script_file_properties"]).to_i)
									# Update the XML environment file
									update_xml_environment_file((taskList[0]["ID_script_file_xml_environment"]).to_i)
									# Set the flag to restart the host if necessary
									if ((taskList[0]["scheduler_restart_host"]) == true)
										# Set the flag to true
										@restartHost = true
									end # End: if ((taskList[0]["scheduler_restart_host"]) == true)
									# Create a scheduled task
									agentScript = run_agent(@agentHash["script_name"], taskList[0]["scheduler_script_command_line"], taskList[0]["scheduler_time"])
								else
									@adannaLogger.log(PL.INFO, "No agent was found for this task: " + taskList[0].keys.inspect + taskList[0].values.inspect, @loggingMode)
								end # End: if not (agentHash = get_agent_for_task(taskList[0])).nil?
								# Reset agent_registered? stuff
								@lastCheck = Time.now
								check = false
							end # End: if @taskList.length == 0							
						else
							@adannaLogger.log(PL.WARN, "No registration was found for ADAnna on " + @agentData.computerName, @loggingMode)
							@adannaLogger.log(PL.ERROR, "PLEASE RESTART ADANNA MANUALLY", @loggingMode)
							
							clean_up_adanna # Clean up the db connection
							return # Return from adanna program loop
						end # End: if agent_registered?
						@execptionTotal = 0 # Reset exception total
					end # End: if check
					
					if agentScript.nil?
						# Find out if we have waited long enough to check for more tasks
						sleep(@taskCheckInterval)
						check = true
						
						# See if we need to update this script
						intUpdateCountdown = intUpdateCountdown - 1 # Decrement countdown
						if intUpdateCountdown == 0
							update_adanna_script
							intUpdateCountdown = @updateCheckInterval
						end # End: if intUpdateCountdown == 0
						@execptionTotal = 0 # Reset exception total
					else # This occurs when any script has been found and set up
						begin
							# Set up variables that I'll use to insert data in the database
							agentEndTime = "00:00:00"
							agentTotalTime = "0"
							agentFinished = false
							# Check for tcp socket connections and messages
							startFlag = false
							while not agentFinished 
								if not (tempLogMsg = @relayServer.check_for_connection) == ""
									startFlag = true
									logTime = "00:00:00"
									logStatus = "Debug"
									if tempLogMsg =~ /(Error,|Info,|Fatal,){1} \d{2}:\d{2}:\d{2} - /
										logMsg = tempLogMsg.split(" - ")
										tempStatusTime = logMsg[0].split(", ")
										logTime = tempStatusTime[1] # Time is second in the log string
										logStatus = tempStatusTime[0] # Status is first
										logMsg = logMsg[1]
										# Update the start time
										if not tempLogMsg["version"].nil? # Update the history
											clean_up_results(update_script_history_started(logTime, @scriptHistoryID))
										end # End: if not tempLogMsg["version"].nil?
									else
										logMsg = tempLogMsg
										logStatus = "Debug"
										timeN = Time.now
										logTime = Util.strPad(2, timeN.hour.to_s, "0") + ":" + Util.strPad(2, timeN.min.to_s, "0") + ":" + Util.strPad(2, timeN.sec.to_s, "0")
									end # End: if tempLogMsg =~ /(Error,|Info,|Fatal,){1} \d{2}:\d{2}:\d{2} - /
									
									if not logMsg == ""
										if logMsg["End Time"]
											agentEndTime = logMsg.split("End Time: ")[1]
											puts "Got end time: " + agentEndTime
										elsif logMsg["Total Time"]
											agentTotalTime = logMsg.split("Total Time: ")[1]
											intT = agentTotalTime.to_i
											agentTotalTime = intT.to_s
											puts "Got total time: " + agentTotalTime
											# Get out of loop
											agentFinished = true
										elsif not logStatus == "Debug" # Otherwise log messages
											@adannaLogger.log(PL.DEBUG, "Log Msg: " + tempLogMsg, @loggingMode)
											# Send log data to db
											clean_up_results(send_log(logTime, logStatus, logMsg))
											logMsg = ""
										end # End: if not logMsg["Bot Results:"].nil?
									end # End: if not logMsg == ""
								else # Check to see that script has started within thirty seconds of start time
									startTime = Time.parse(@strAgentRunTime)
									if ((Time.now - startTime) > 30.0) and (not startFlag)
										agentScript = nil
										break
									end # End: if (Time.now - startTime) > 30.0
								end # End: if not (tempLogMsg = @relayServer.check_for_connection) == ""
							end # End: while not (tempLogMsg = @relayServer.check_for_connection) == ""
							# Update script_history table
							clean_up_results(update_script_history_finished(agentEndTime, agentTotalTime, @scriptHistoryID))
							@adannaLogger.log(PL.INFO, "Save run data", @loggingMode)
							check = true
							agentScript = nil
							clean_up_results(@scriptHistoryID)
						rescue => ex
							@adannaLogger.log(PL.ERROR, "Exception was caught! Inner message: " + ex.message + " Backtrace: " + ex.backtrace.inspect, @loggingMode)
							next
						end
						@execptionTotal = 0 # Reset exception total
						# Check the reset host flag
						if @restartHost
							shutdownString = "shutdown -r -t 10"
							IO.popen(shutdownString)
						end # End: if @restartHost
					end # End: if agentScript.nil?
				rescue => ex
					@adannaLogger.log(PL.ERROR, "Exception was caught! Message: " + ex.message + " Backtrace: " + ex.backtrace.inspect, @loggingMode)
					@execptionTotal = @execptionTotal + 1
					
					if @execptionTotal == @exceptionAllowance
						send_fail_safe_email
						break
					else
						retry
					end # End: if @execptionTotal == @exceptionAllowance
				end
			end # End: while true
		else
			puts "Error - connection denied to db: scheduler=" + @binding.to_s + " results=" + @reBinding.to_s + " files=" + @fileBinding.to_s
		end # End: if not bind_to_database.nil?
	end # End: def agent_mediator()

end # End: class Adanna

#***********************************************************************
#***********************************************************************
# This is the program entry point
#***********************************************************************
if __FILE__ == $0 # This verifies that the file name is the same as the zeroth argument, which is also the file name
	
	# Create a new Adanna object
	adanna = Adanna.new()
	adanna.run_adanna
	
end # End: if __FILE__ == $0