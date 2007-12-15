#***********************************************************************
# Script Name: Adanna.rb    Version: 1.0.0
#
# This script becomes an agent between agents that are run on a given 
# host. It uses an XML config file to connect to a database server which
# retains information regarding the running of these agent scripts.
#
# Change Notes:
#  01-15-2006: Actually began writing this script.
#
# @author Nathan Lane
# Last Updated: 01/15/2006
#***********************************************************************

class Adanna
	
	require "pod/pod" # Required to do basic agent stuff
	
	include Pod # Basic set of classes to set up an agent
	include Agents # Agent specific helper classes
	include Logging # Logging module - includes PodLogger and RelayServer
	
	require "mysql" # Required to access db on server end

	def initialize()
		# Get the current working directory
		@adannaBase = Dir.getwd
		# Set config file name
		@adannaConfigFilename = "Adanna.config"
		# Set script folder
		@adannaAgentFolder = "Agents"
		# Set db check interval
		@taskCheckInterval = 15 # minutes
		
		# Set version
		@version = "1.0.0" + "_" + Pod::libraryVersion?
		
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
			@configTable["db_host_name"] = [ "localhost" ]
			@configTable["db_user_name"] = [ "qarobot" ]
			@configTable["db_user_password"] = [ "qarobot" ]
			@configTable["db_database_name"] = [ "qastats" ]
			
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
	
	def bind_to_database()
		@adannaLogger.log(PL.INFO, "Binding to database", @loggingMode)
		begin
			dbConnection = Mysql.real_connect(@configTable["db_host_name"][0], @configTable["db_user_name"][0], @configTable["db_user_password"][0], @configTable["db_database_name"][0])
			retVal = dbConnection
		rescue => ex
			retVal = nil
		end
		
		return retVal
	end # End: def bind_to_database()
	
	def close_database_binding()
		begin
			@binding.close
		rescue => ex
			puts "Error - unable to close database, perhaps it was already closed"
		end
	end # End: def close_database_binding()
	
	#***********************************************************************
	# send_log sends log information to the database.
	#***********************************************************************
	def send_log(timeStamp, status, details)
		# Rectify datTimeStamp
		todayDate = Date.today
		strToday = todayDate.year.to_s + "-" + todayDate.month.to_s + "-" + todayDate.mday.to_s + " "
		dateTimeStamp = strToday + timeStamp
		# Create query string
		logInsertString = "INSERT INTO script_history_log(script_history_log_event_datetime_stamp, script_history_log_event_status, script_history_log_event_details) VALUES('" +
			dateTimeStamp + "', '" + 
			status.to_s + "', '" + 
			details.to_s + "')"
		# Query the database
		@binding.query(logInsertString)
	end # End: def send_log(dateTimeStamp, status, details)
	
	#***********************************************************************
	# get_all_tasks returns an array of hashes containing task information.
	#***********************************************************************
	def get_all_tasks()
		@adannaLogger.log(PL.INFO, "Getting tasks for host " + @agentData.computerName, @loggingMode)
		# Build query string to get all tasks
		agentTasksQueryString = "SELECT * FROM scheduler WHERE ID_host = '" + @adannaID.to_s + "'"
		# Query the database
		resultSet = @binding.query(agentTasksQueryString)
		# Initialize array
		taskList = Array.new
		# Get each row
		if resultSet.num_rows > 0
			while row = resultSet.fetch_hash do
				# Add row hash table to taskList
				taskList << row
			end # End: while row = resultSet.fetch_hash do
		end # End: if resultSet.num_rows > 0
		resultSet.free
		
		return taskList
	end # End: def get_all_tasks()
	
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
		agentRegistrationQueryString = "SELECT * FROM HOST WHERE host_name = '" + @agentData.computerName + "'"
		# Query the database
		resultSet = @binding.query(agentRegistrationQueryString)
		# Vaildate and get ID
		while row = resultSet.fetch_hash do
			if row["host_name"] == @agentData.computerName and resultSet.num_rows == 1
				@adannaID = row["id"]
				retVal = true
			else
				retVal = false
			end # End: if row["host_name"] == @agentData.computerName
		end # End: while resultSet.fetch_hash do
		resultSet.free
		
		return retVal
	end # End: def check_agent_registration()
	
	#***********************************************************************
	# locate_script returns the path to the latest update of the script.
	#***********************************************************************
	def locate_script(strScriptID)
		retVal = nil
		
		# Create a query string
		queryString = "SELECT * FROM script WHERE id=" + strScriptID
		# Query the DB
		resultSet = @binding.query(queryString)
		
		if resultSet.num_rows > 1
			retVal = nil
		else
			row = resultSet.fetch_hash
			strPath = row["script_file_location"] + "/" + row["script_name"]
			retVal = strPath
		end # End: if resultSet.num_rows > 1
		
		return retVal
	end # End: def locate_script()
	
	#***********************************************************************
	# update_agent_script updates the script.
	#***********************************************************************
	def update_agent_script(strScriptName)
		script_dir = @adannaBase + "/" + @adannaAgentFolder
		@adannaLogger.log(PL.INFO, "Looking for directory: " + script_dir, @loggingMode)
		
		# Check to see if the agent script directory exists
		if not File.exist?(script_dir)
			@adannaLogger.log(PL.INFO, "Creating agent script directory", @loggingMode)
			# If it doesn't exist, create it
			Dir.mkdir(script_dir)
			Dir.chdir(script_dir) # Move to that directory
		else
			@adannaLogger.log(PL.INFO, "Found agent script directory", @loggingMode)
			Dir.chdir(script_dir) # Move to that directory
		end # End: if not File.exist?(script_dir)
		
		@adannaLogger.log(PL.INFO, "Downloading agent script: " + strScriptName, @loggingMode)
	end # End: def update_agent_script(strScriptName)
	
	#***********************************************************************
	# run_agent_script runs the script that is scheduled.
	#***********************************************************************
	def run_agent_script(strScriptPath)
		retVal = nil
		
		if File.exist?(strScriptPath)
			# Open a new process to run the script
			agent_proc = IO.popen(strScriptName)
			# Set script running
			@scriptRunning = true
			
			retVal = agent_proc
		else
			retVal = nil
		end # End: if File.exist?(strScriptPath)
		
		return retVal
	end # End: def run_agent_script(strScriptName)
	
	#***********************************************************************
	# get_next_task gets the next task and returns a hash of items.
	#***********************************************************************
	def get_next_task(arrTaskList)
		@adannaLogger.log(PL.INFO, "Getting next task", @loggingMode)
		taskHash = Hash.new # Initialize the hash for the task
		
		arrTaskList.each {
			|t| tempTask = t
			
			taskTime = Time.parse(tempTask["scheduler_time"])
			# Check to see if time is near or right on (within five minutes)
			if Time.now > taskTime and taskTime < (Time.now + (5 * 60))
				taskHash = tempTask
			end # End: if taskTime == Time.now
		}
		
		return taskHash
	end # End: def get_next_task(arrTaskList)
	
	#***********************************************************************
	# adanna is the program loop for this script.
	#***********************************************************************
	def adanna()
		# Initialize important variables in this section
		check = true
		logMsg = ""
		logData = Array.new
		agentScript = nil
		
		if not (@binding = bind_to_database).nil? # Connect to the database
			begin
				while true
					if check
						if agent_registered?
							@adannaLogger.log(PL.INFO, "Agent was found to be registered with id: " + @adannaID.to_s, @loggingMode)
							taskList = get_all_tasks # Get all tasks associated with host id
							@adannaLogger.log(PL.INFO, "Number of tasks for agent: " + taskList.length.to_s, @loggingMode)
							
							# If no tasks were found reset timer
							if taskList.length == 0
								strLastCheck = @adannaLogger.log(PL.INFO, "ADAnna will check for tasks associated with host " + @agentData.computerName + " in " + @taskCheckInterval.to_s + " minutes", @loggingMode)[1] # Get the time stamp
								@lastCheck = Time.parse(strLastCheck)
								check = false
							else # Otherwise begin to parse through the tasks
								nextTask = get_next_task(taskList)
								if nextTask.has_key?("ID_script")
									scriptLoc = locate_script(nextTask["ID_script"])
									# Update script
									update_agent_script(scriptLoc)
									# Run script
									if (agentScript = run_agent_script(scriptLoc)).nil?
										@adannaLogger.log(PL.WARN, "WARNING! Could not locate script to run at " + scriptLoc, @loggingMode)
									end # End: if (agentScript = run_agent_script(scriptLoc)).nil?
								end # End: if nextTaskhas_key?("ID_script")
								@lastCheck = Time.now
								check = false
							end # End: if @taskList.length == 0							
						else
							@adannaLogger.log(PL.WARN, "No registration was found for ADAnna on " + @agentData.computerName, @loggingMode)
							@adannaLogger.log(PL.ERROR, "PLEASE RESTART ADANNA MANUALLY", @loggingMode)
							
							clean_up_adanna # Clean up the db connection
							return # Return from adanna program loop
						end # End: if agent_registered?
					end # End: if check
					
					if agentScript.nil?
						# Find out if we have waited long enough to check for more tasks
						if (Time.now - @lastCheck) >= (@taskCheckInterval * 60)
							check = true
						end # End: if (Time.now - @lastCheck) > (@taskCheckInterval * 60)
					end # End: if agentScript.nil?
					
					# Check for tcp socket connections and messages
					tempLogMsg = @relayServer.check_for_connection
					if not tempLogMsg == ""
						logMsg = tempLogMsg.split(" - ")
						tempStatusTime = logMsg[0].split(", ")
						logTime = tempStatusTime[1] # Time is second in the log string
						logStatus = tempStatusTime[0] # Status is first
						logMsg = logMsg[1]
						
						if not logMsg == ""
							@adannaLogger.log(PL.DEBUG, "Log Msg: " + tempLogMsg, @loggingMode)
							# Send log data to db
							send_log(logTime, logStatus, logMsg)
							logMsg = ""
						end # End: if not logMsg == ""
					end # End: if not tempLogMsg = ""
				end # End: while true
			rescue => ex
				@adannaLogger.log(PL.ERROR, "Exception was caught! Message: " + ex.message + " Backtrace: " + ex.backtrace.inspect, @loggingMode)
				retry
			end
		else
			puts "Error - connection denied to db " + @configTable["db_database_name"][0] + "@" + @configTable["db_host_name"][0] + " using " + @configTable["db_user_name"][0] + " with " + @configTable["db_user_password"][0]
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
