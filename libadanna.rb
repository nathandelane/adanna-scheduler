#***********************************************************************
# Adanna library: libadanna.rb
# This library is designed to be used by Adanna, as well as its pieces,
# and contains a module for Agents written external to it.  The new
# design of this version of Adanna is meant to make Adanna more stable
# and robust and create an environment that it has control over.  Also
# contained in this library is a new Reporting method, which utilizes XML
# to produce a log.  A simple xsl file can be used to display the log,
# and new methods and approaches will be utilized to make the Reporting
# more meaningful.
#
# One goal of this version is to not rely on any libraries external to 
# Ruby core, when unnecessary.
#
# This is Adanna, the Agent - Database - Agent controller.
#
# Note: This agent is to run on each client machine.
#
# Created by: Nathan Lane
# Last Updated: 05/03/2007
#***********************************************************************

module Adanna
	
	require "rexml/document"
	
	class AdannaConfiguration
		
		attr_reader :config, :dbName, :dbUserName, :dbPassword, :dbType, :taskCheckDelay, :taskTimeBounds, :rebootRegularly, :rebootInterval, :errorEmailAddress, :emailPickupServer, :logFileSuffix, :creatorEmailAddress
		attr_writer :rebootRegularly, :rebootInterval
		
		def initialize(strDirectory, strFilename)
			absoluteFilePath = strDirectory + "/" + strFilename
			configFile = File.new(absoluteFilePath)
			@config = REXML::Document.new(configFile)
			
			@dbName = @config.root.elements["database_name"].text
			@dbUserName = @config.root.elements["database_user_name"].text
			@dbPassword = @config.root.elements["database_password"].text
			@dbType = @config.root.elements["database_type"].text
			@taskCheckDelay = @config.root.elements["task_check_delay"].text
			@taskTimeBounds = @config.root.elements["task_time_bounds"].text
			@rebootRegularly = @config.root.elements["reboot_regularly"].text
			@rebootInterval = @config.root.elements["reboot_interval"].text
			@errorEmailAddress = @config.root.elements["error_email_address"].text
			@creatorEmailAddress = @config.root.elements["creator_email_address"].text
			@emailPickupServer = @config.root.elements["email_pickup_server"].text
			@logFileSuffix = @config.root.elements["log_file_suffix"].text
		end # End: 
		
	end # End: class AdanaConfiguration
	
	module Environment
		
		PRODUCTION = "http://www.vehix.com"
		QAPROD1 = "http://www.qa.prod1.vehix.com"
		QAPROD2 = "http://www.qa.prod2.vehix.com"
		QAPROD3 = "http://www.qa.prod3.vehix.com"
		QAPROD4 = "http://www.qa.prod4.vehix.com"
		STAGING = "http://www.staging.vehix.com"
		
		class TestingEnvironment
			
			attr_reader :environmentHome, :paramString
			
			def initialize()
				@environmentHome = "about:blank"
			end # End: def initialize()
			
			def set_environment(constStrEnvironment)
				@environmentHome = constStrEnvironment
			end # End: def set_environment(constStrEnvironment)
			
			def set_param_string(constStrParamString)
				@paramString = constStrParamString
			end # End: def set_param_string(constStrParamString)
			
		end # End: class TestingEnvironment
		
	end # End: module Environment
	
	module Database
		
		MYSQL = "MySQL"
		MSSQL = "MSSQL"
		
		class AdannaDBConnection
			
			require "dbi"
			
			attr_reader :dbBinding, :dbType, :dbEngine
			
			def initialize(strDBType, dbName, dbUser, dbPassword, dbLocation = "")
				@dbType = strDBType
				case @dbType
					when MYSQL
						@dbBinding = DBI.connect("DBI:ODBC:" + dbName, dbUser, dbPassword)
						@dbEngine = QueryEngine.new(@dbBinding)
					when MSSQL
						@dbBinding = DBI.connect("DBI:ODBC:" + dbName, dbUser, dbPassword)
						@dbEngine = QueryEngine.new(@dbBinding)
					else
						@dbType = nil
						@dbBinding = nil
						@dbEngine = nil
				end # End: case @dbType
			end # End: def initialize(strDBType)
			
			def close()
				@dbBinding.disconnect
			end # End: def close()
			
		end # End: class AdannaDBConnection
		
		class QueryEngine
			
			attr_reader :binding, :queryString
			
			require "dbi"
			
			def initialize(dbBinding)
				@binding = dbBinding
			end # End: def initialize()
			
			def log(scriptLogId, timestamp, type, message)
				@queryString = "INSERT INTO script_history_log(" +
					"id_script_history, " +
					"script_history_log_event_datetime_stamp, " +
					"script_history_log_event_status, " +
					"script_history_log_event_details) " +
					"VALUES('" +
					scriptLogId.to_s + "', '" +
					timestamp.to_s + "', '" + 
					type.to_s + "', '" + 
					message.to_s + "')"
				results = @binding.prepare(@queryString)
				results.execute
				results.finish
			end # End: def log(scriptLogId, timestamp, type, message)
			
			def send_script_history(timestamp, id_script, id_host)
				retVal = 0
				
				@queryString = "INSERT INTO script_history(" +
					"ID_script, " + 
					"ID_script_group_joined, " +
					"ID_host, " + 
					"ID_host_group_joined, " +
					"script_history_date_created, " +
					"script_history_date_updated, " +
					"script_history_date_executed, " +
					"script_history_executed_status, " +
					"script_history_time_executed) " +
					"VALUES(" + id_script.to_s + ", 1, " + id_host.to_s + ", 1, '" + timestamp + "', '" + timestamp + "', '" + timestamp + "', 'Created', 0)"
				@binding.do(@queryString)
				
				@queryString = "SELECT * FROM script_history WHERE id_host=" + id_host.to_s + " AND script_history_date_created='" + timestamp + "'"
				results = @binding.prepare(@queryString)
				results.execute
				
				if row = results.fetch_hash
					if row.has_key?("id")
						recordID = row["id"]
						retVal = recordID
					else
						retVal = 0
					end # End: if row.has_key?("id")
				else
					retVal = 0
				end # End: if row = results.fetch_hash
				
				results.finish
				row = nil
				
				return retVal
			end # End: def send_script_history(timestamp, id_script, id_host)
			
			def update_script_history_finished(timestamp, strTotalTime, idScriptHistory)
				@queryString = "UPDATE script_history SET " +
					"script_history_date_updated='" + timestamp + "', " +
					"script_history_executed_status='Done', " +
					"script_history_time_executed=" + strTotalTime.to_s +
					" WHERE id=" + idScriptHistory.to_s
				results = @binding.prepare(@queryString)
				results.execute
				results.finish
			end # End: def update_script_history_finished(timestamp, strTotalTime, idScriptHistory)
			
			def update_script_history_started(timestamp, idScriptHistory)
				@queryString = "UPDATE script_history SET " +
					"script_history_date_updated='" + timestamp + "', " +
					"script_history_executed_status='Started', " +
					"script_history_date_executed='" + timestamp +
					"' WHERE id=" + idScriptHistory.to_s
				results = @binding.prepare(@queryString)
				results.execute
				results.finish
			end # End: def update_script_history_started(strTime, idScriptHistory)
			
			def get_all_tasks(timeSpanInSeconds, clientId)				
				time = Time.now
				strTimeNow = Reporting::Logger.pad(2, time.hour.to_s, "0") + ":" + Reporting::Logger.pad(2, time.min.to_s, "0") + ":" + Reporting::Logger.pad(2, time.sec.to_s, "0")
				time = (Time.now + (timeSpanInSeconds)) # Add seconds
				
				taskDate = "1900-1-1 "
				
				strTimeFuture = Reporting::Logger.pad(2, time.hour.to_s, "0") + ":" + Reporting::Logger.pad(2, time.min.to_s, "0") + ":" + Reporting::Logger.pad(2, time.sec.to_s, "0")
				
				@queryString = "SELECT * FROM scheduler WHERE ID_host = '" + clientId.to_s + "' and scheduler_time > '" + taskDate + strTimeNow + "' AND scheduler_time < '" + taskDate + strTimeFuture + "'"
				results = @binding.prepare(@queryString)
				results.execute
				
				taskList = Array.new
				while row = results.fetch do
					taskList << row
				end # End: while row = results.fetch_hash do
				
				results.finish
				
				return taskList
			end # End: def get_all_tasks()
			
			def get_agent_for_task(agentId)
				retVal = nil
				
				@queryString = "SELECT * FROM script WHERE id=" + agentId.to_s
				results = @binding.prepare(@queryString)
				results.execute
				
				while row = results.fetch
					retVal = row
				end # End: if not retVal = results.fetch
				
				results.finish
				
				return retVal # Return the agent hash
			end # End: def get_agent_for_task(agentId)
			
			def client_registered?(agentData)
				retVal = 0 # Initialize as false becaue we need a result set to be true
				
				@queryString = "SELECT * FROM host WHERE host_name = '" + agentData.computerName + "'"
				results = @binding.prepare(@queryString)
				results.execute
				
				while row = results.fetch
					if row["host_name"] == agentData.computerName
						adannaID = row["id"]
						retVal = adannaID
					else
						retVal = 0
					end # End: if row["host_name"] == @agentData.computerName
				end # End: while results.fetch do
				
				results.finish
								
				return retVal
			end # End: def client_registered?(agentData)
			
			def update_client_information(agentData, clientId)
				localDateTime = Reporting::Logger.create_timestamp("-", " ", ":")
				@queryString = "UPDATE host SET host_date_updated = '" + localDateTime.to_s + 
					"', host_ip = '" + agentData.ipAddress.to_s + 
					"', host_ram = " + agentData.memTotal.to_s +
					", host_hd_size = " + agentData.diskTotal.to_s +
					", host_hd_free = " + agentData.diskFreePercent.to_s +
					", host_processor_type = '" + agentData.procName.to_s +
					"', host_processor_speed = " + agentData.procSpeed.to_s +
					" WHERE id = " + clientId.to_s
				results = @binding.prepare(@queryString)
				results.execute
				results.finish
			end # End: def update_client_information(agentData)
			
			def update_script(strScriptName)
				retVal = false
				
				@queryString = "SELECT * FROM script_file WHERE script_file_name = '" + strScriptName + "'"
				results = @binding.prepare(@queryString)
				results.execute
				
				# Try and create the file
				if row = results.fetch
					if File.exist?(strScriptName)
						File.unlink(strScriptName)
					end # End: if File.exist?(strScriptName)
					
					retVal = true
					fileName = row["script_file_name"]
					fileContents = row["script_file_content"]
					fw = File.new(fileName, "w+")
					fw.write(fileContents)
					fw.close
				end # End: if row = results.fetch_hash
				
				results.finish
				
				return retVal
			end # End: def update_script(strScriptName)
			
			def update_script_execution_status(scriptId, strScriptExecutionStatus)
				@queryString = "UPDATE script SET script_last_execution_status = '" + (strScriptExecutionStatus.downcase!).to_s +
					"' WHERE id = " + scriptId.to_s
				results = @binding.prepare(@queryString)
				results.execute
				results.finish
			end # End: def update_script_execution_status(scriptId)
			
			def get_agent_environment(intScriptEnvironmentId)
				retVal = Hash.new
				retVal["environment"] = "http://www.vehix.com"
				retVal["parameter_string"] = ""
				
				@queryString = "SELECT * FROM script_file WHERE id = " + intScriptEnvironmentId.to_s
				results = @binding.prepare(@queryString)
				results.execute
				
				if row = results.fetch
					retVal["environment"] = row["script_file_description"]
					retVal["parameter_string"] = row["script_file_content"]
				end # End: if row = results.fetch
				
				results.finish
				
				return retVal
			end # End: def get_agent_environment(intScriptEnvironmentId)
			
		end # End: class QueryEngine
		
	end # End: module Database
	
	module Agents
		
		class AgentBase
			
			attr_reader :agentState, :logger, :environment, :properties, :agentMessages
			
			def initialize(objAdannaLogger, objEnvironment)
				@logger = objAdannaLogger
				@environment = objEnvironment
				@agentMessages = ""
			end # End: def initialize(objLogger)
			
			def load_script_xml_properties(strDirectory, strFilename)
				xmlPropertiesPath = strDirectory + "/" + strFilename
				propertiesFile = File.new(xmlPropertiesPath)
				@properties = REXML::Document.new(propertiesFile)
			end # End: def load_script_xml_properties(strDirectory, strFilename)
			
		end # End: class AgentBase
		
		class AgentData
			
			require "socket"
			require "Win32API"
			require "win32/registry"
			
			attr_reader :computerName, :ipAddress, :procName, :procSpeed, :memTotal, :scriptName, :diskTotal, :diskFreePercent
			
			def initialize()
				@computerName = Socket.gethostname # Get the computer host name
				@ipAddress = ip_address # Get the computer ip address
				@procName = processor_info # Get processor info
				@procSpeed = (Win32::Registry::HKEY_LOCAL_MACHINE.open("HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0").read("~MHz"))[1]
				@memTotal = total_physical_memory # Get total memory
				@scriptName = $0 # Get script name
				disk_usage # Get disk uasage
			end # End: def initialize()
			
			def ip_address()
				ipadd = IPSocket.getaddress(@computerName)
				
				return ipadd
			end # End: def ip_address()
			
			def processor_info()
				# Get processor type
				getSystemInfo = Win32API.new("kernel32.dll", "GetSystemInfo", ['P'], 'i')
				# Setup a pointer variable
				sysInfo = " " * 72
				# Get the system information
				getSystemInfo.call(sysInfo)
				# Find out which processor it is
				procName = ""
				procID = sysInfo.unpack("LLLLLLLLL")[6]
				case(procID)
					when 386:
						procName = "Intel 386"
					when 486:
						procName = "Intel 486"
					when 586:
						procName = "Intel Pentium"
					else
						procName = "Unkown"
				end # End: case(procID)
				
				return procName
			end # End: def processor_info()
			
			def total_physical_memory()
				# Grab GlobalMemoryStatus from kernel32.dll
				globalMemoryStatus = Win32API.new("kernel32.dll", "GlobalMemoryStatus", ['P'], 'i')
				# Initialize a pointer to contain info from GlobalMemoryStatus
				memoryStatus = " " * 64
				# Call GlobalMemoryStatus
				globalMemoryStatus.call(memoryStatus)
				
				# Return the physical memory (Kilobytes)
				return ((memoryStatus.unpack("LLLLLLLL")[2]) / 1024)
			end # End: def total_physical_memory()
			
			def disk_usage()
				# Grap GetDiskFreeSpace method from kernel32.dll
				getFreeSpace = Win32API.new("kernel32.dll", "GetDiskFreeSpace", ['P','P','P','P','P'], 'i')
				# Initialize pointer-like variables
				sectorsPerCluster = " " * 8
				bytesPerSec = " " * 8
				noOfFreeClusters = " " * 8
				totalNoOfClusters = " " * 8
				# Call the GetDiskFreeSpace method
				getFreeSpace.call("C:\\", sectorsPerCluster, bytesPerSec, noOfFreeClusters, totalNoOfClusters)
				# Unpack the returned pointers
				spc = (sectorsPerCluster.unpack("LL"))[0]
				bps = (bytesPerSec.unpack("LL"))[0]
				nfc = (noOfFreeClusters.unpack("LL"))[0]
				tnc = (totalNoOfClusters.unpack("LL"))[0]
				
				@diskTotal = ((spc * bps * tnc) / 1024) # Kilobytes
				diskFree = ((spc * bps * nfc) / 1024) # Kilobytes
				@diskFreePercent = (((diskFree.quo(@diskTotal)).to_f) * 100).to_i # Integer percentage
			end # End: def disk_usage()
			
			def to_s()
				strTemp = "  computerName=" + @computerName.to_s + 
					"\n  ipAddress=" + @ipAddress.to_s + 
					"\n  processorName=" + @procName.to_s + 
					"\n  processorSpeed=" + @procSpeed.to_s + 
					" MHz\n  memTotal=" + memTotal.to_s +
					" Kb\n  scriptName=" + @scriptName.to_s + 
					"\n  diskTotal=" + @diskTotal.to_s + 
					"\n  diskFreePercent=" + @diskFreePercent.to_s
					
				return strTemp
			end # End: def to_s()
			
		end # End: class AgentData
		
	end # End: module Agents
	
	module Reporting
		
		require "fileutils"
		
		PASS = "Pass"
		FAIL = "Fail"
		DONE = "Done"
		EXCEPTION = "Exception"
		
		class Logger
			
			attr_reader :loggerFilePath, :loggerDocument, :threads, :scriptHistoryId
			
			def initialize(strDirectory = ".", strFilename = "Adanna.log", strTitle = "Adanna Log")
				@reportingQueryEngine = nil
				@scriptHistoryId = -1
				@loggerFilePath = strDirectory + "/" + strFilename
				create_log_file(@loggerFilePath)
				@loggerDocument = REXML::Document.new("<?xml-stylesheet type=\"text/xsl\" href=\"log_style.xsl\"?>");
				create_log_header(strTitle)
			end # End: def initialize(strDirectory = Dir.getwd, strFilename)
			
			def create_log_file(strAbsoluteFilePath)
				logFile = File.new(strAbsoluteFilePath, "w")
				logFile.close
			end # End: def create_log_file()
			
			def create_log_header(strTitle)
				@docRoot = @loggerDocument.add_element("Log")
				header = @docRoot.add_element("Header")
				title = header.add_element("Title")
				title.text = strTitle
				timestamp = header.add_element("Timestamp")
				timestamp.text = Logger.create_timestamp("/", " ", ":")
				record_changes
			end # End: def create_log_stub()
			
			def self.create_timestamp(strDateSeparator = ".", strConnector = "_", strTimeSeparator = ".")
				time = Time.now
				timestamp = time.year.to_s + strDateSeparator + 
					Logger.pad(2, time.mon.to_s, "0") + strDateSeparator +
					Logger.pad(2, time.mday.to_s, "0") + strConnector +
					Logger.pad(2, time.hour.to_s, "0") + strTimeSeparator +
					Logger.pad(2, time.min.to_s, "0") + strTimeSeparator +
					Logger.pad(2, time.sec.to_s, "0")
				
				return timestamp
			end # End: def create_timestamp()
			
			def self.pad(intFieldSize, strInteger, charPadding)
				strTemp = ""
				
				if strInteger.length < intFieldSize
					intPadding = intFieldSize - strInteger.length
					intPadding.times {
						strTemp = strTemp + charPadding
					}
				end # End: if strInteger.length < intFieldSize
				strTemp = strTemp + strInteger
				
				return strTemp
			end # End: def pad(intFieldSize, strInteger)
			
			def self.send_fail_safe_email(errorEmailAddress, agentData, strMessage, smtpServerPickupLocation)
				# Make the string
				strEmailText = 
					"TO: " + errorEmailAddress + " <mailto:" + errorEmailAddress + ">\n" +
					"FROM: adanna@vehix.com <mailto:adanna@vehix.com>\n" +
					"SUBJECT: From ADAnna Server - " + agentData.computerName.to_s + ".\n" +
					strMessage
				
				# Write the file
				emailFile = File.new("adannafailsafe.txt", "w+")
				emailFile.puts strEmailText
				emailFile.close
				
				# Copy the file over
				FileUtils::cp("adannafailsafe.txt", smtpServerPickupLocation)
			end # End: def send_fail_safe_email()
			
			def self.subtract_timestamps(postTimeStamp, preTimeStamp)
				strTimeStamp = "1900-01-01 00:00:00"
				
				postTime = Time.parse(postTimeStamp)
				preTime = Time.parse(preTimeStamp)
				
				totalTime = postTime - preTime
				
				return totalTime
			end # End: def self.subtract_timestamps(postTimeStamp, preTimeStamp)
				
			def log(strMessage = "No message received.", strMessageType = PASS)
				logElement = @docRoot.add_element("LogItem")
				msgtypeElement = logElement.add_element("MessageType")
				msgtypeElement.text = strMessageType
				timestampElement = logElement.add_element("Timestamp")
				newTimestamp = Logger.create_timestamp("/", " ", ":")
				timestampElement.text = newTimestamp
				msgElement = logElement.add_element("Message")
				msgElement.text = strMessage
				record_changes
				puts(newTimestamp + ", " + strMessageType + ", " + strMessage)
				
				if not @reportingQueryEngine.nil? and @scriptHistoryId > -1
					@reportingQueryEngine.log(@scriptHistoryId, timestampElement.text, strMessageType, strMessage)
				end # End: if not @reportingQueryEngine.nil? and @scriptHistoryId > -1
			end # End: def log()
			
			def set_script_history_id(intScriptHistoryId)
				@scriptHistoryId = intScriptHistoryId
			end # End: def set_script_history_id(intScriptHistoryId)
			
			def set_query_engine(objQueryEngine)
				@reportingQueryEngine = objQueryEngine
			end # End: def setQueryEngine(objQueryEngine)
			
			def record_changes()
				logFile = File.new(@loggerFilePath, "w")
				@loggerDocument.write(logFile, 2)
				logFile.close
			end # End: def record_changes(strAbsolutLogFilePath = @loggerFilePath)
			
			def close()
				@loggerDocument = nil
			end # End: def close()
			
		end # End: class Logger
		
	end # End: module Reporting
	
	module Browser
		
		class WebPage
			
			attr_reader :pageLoadBenchmark, :pageTitle, :pageURL, :imageStatus
			
			def initialize(floatBenchmark, strTitle, strURL)
				@pageLoadBenchmark = floatBenchmark
				@pageTitle = strTitle
				@pageURL = strURL
				@imageStatus = Array.new
			end # End: def initialize()
			
			def set_page_images(strImageStatusArray)
				if strImageStatusArray.class == Array
					@imageStatus = strImageStatusArray
				end # End: if strImageStatusArray.class == Array
			end # End: def set_page_images(strImageStatusArray)
			
		end # End: class WebPage
		
		class UserProfile
			
			require "win32ole"
			
	        INTERNET_CACHE = 0x0020
	        COOKIES = 0x0021
			
			def initialize()
				# Start a new process 'echo "%USERPROFILE%"'
				process = IO.popen("echo \"%USERPROFILE%\"")
				# Get the directory name from the output
				strArray = process.gets
				# Close the popen process
				process.close
				# Trim newline and double quotes
				intStrLength = strArray.length - 3
				# Create the directory string
				@homeDir = strArray[1..intStrLength]
				
				# Create a shell service
				@shell = WIN32OLE.new("Shell.Application")
			end # End: def initialize()
			
			def userCacheDir?()
				folder = @shell.Namespace(INTERNET_CACHE)
				folderItem = folder.Self
				folderPath = folderItem.Path
			end # End: def userCacheDir?()
			
			def userCookieDir?()	        
				folder = @shell.Namespace(COOKIES)
				folderItem = folder.Self
				folderPath = folderItem.Path
			end # End: def userCookieDir?()
			
			def userHome?()
				return @homeDir
			end # End: def userProfile()
			
		end # End: class UserProfile

		class WatirBrowser
			
			require "watir"
			require "timeout"
			require "benchmark"	
			
			include Watir
			include Timeout
			
			def initialize()
				# Create a new UserProfile object
				@objProfile = UserProfile.new
				
				# Get rid of old files
				@remainingCookies = delete_cookies # Delete cookies
				@remainingCache = clear_internet_cache # Clear the Internet cache
				
				# Initialize a new browser window
				@objBrowser = IE.new # Create a new browser object
				@strCurrentURL = "about:blank" # Set the current URL to "about:blank"
				@objBrowser.goto(@strCurrentURL) # Goto that URL
				
				# Setup secondary variables
				@objPageList = Array.new
				@home = @strCurrentURL
			end # End: def initialize()
			
			def set(blnStatusBar, blnToolBar, intTop, intLeft, intWidth, intHeight)
				@objBrowser.ie.StatusBar = blnStatusBar # Set the statusbar status to blnStatusBar
				@objBrowser.ie.ToolBar = blnToolBar # Set the toolbar status
				@objBrowser.ie.top = intTop # Set IE's top location
				@objBrowser.ie.left = intLeft # Set IE's left location
				@objBrowser.ie.width = intWidth # Set IE's width
				@objBrowser.ie.height = intHeight # Set IE's height
				
				return self
			end # End: def setupBrowser(blnStatusBar, blnToolBar, intTop, intLeft, intWidth, intHeight)
			
			def set_with_home(blnStatusBar, blnToolBar, intTop, intLeft, intWidth, intHeight, strHomeURL)
				@objBrowser.ie.StatusBar = blnStatusBar # Set the statusbar status to blnStatusBar
				@objBrowser.ie.ToolBar = blnToolBar # Set the toolbar status
				@objBrowser.ie.top = intTop # Set IE's top location
				@objBrowser.ie.left = intLeft # Set IE's left location
				@objBrowser.ie.width = intWidth # Set IE's width
				@objBrowser.ie.height = intHeight # Set IE's height
				@strCurrentURL = strHomeURL # Set current URL
				@home = @strCurrentURL # Setup home URL
				
				# Use local copy of browseTo instead of Watir goto
				browse_to(@strCurrentURL) # Browse to the home URL
				
				return self
			end # End: def setupBrowser(blnStatusBar, blnToolBar, intTop, intLeft, intWidth, intHeight)

			def watir()
				return @objBrowser
			end # End: def watir()
			
			def close()
				@objBrowser.close # Close the browser
				@objBrowser = nil
				
				return @objBrowser
			end # End: def close()
			
			def browse_to(strURL)
				# Define the timing variable outside the block so we can use it later
				floatTimeToBrowse = 0.0
				# Timeout after 60 seconds and catch the exception
				begin
					timeout(60) do
						# Get the benchmark time to load
						floatTimeToBrowse = @objBrowser.goto(strURL)
					end # End: timeout(60) do
				rescue TimeoutError
					floatTimeToBrowse = 60.0
				end
				# Get page title
				strTitle = title?
				# Get page's URL
				strURL = url?
				# Add a page to the page array
				objPage = WebPage.new(floatTimeToBrowse, strTitle, strURL)
				@objPageList << objPage
			end # End: def browseTo(strURL)
			
			def recorded_pages()
				return @objPageList
			end #def recordedPages()
			
			def title?()
				return @objBrowser.title
			end # End: def title?()
			
			def url?()
				return @objBrowser.url
			end # End: def url?()
			
			def status_bar?()
				@blnStatusBar = @objBrowser.ie.StatusBar # Get the statusbar status
				
				return @blnStatusBar
			end # End: def statusBar?()
			
			def tool_bar?()
				@blnToolBar = @objBrowser.ie.ToolBar # Get the toolbar status
				
				return @blnToolBar
			end # End: def toolBar?()
			
			def top?()
				@intTop = @objBrowser.ie.top # Get IE's top location
				
				return @intTop
			end # End: def top?()
			
			def left?()
				@intLeft = @objBrowser.ie.left # Get IE's left location
				
				return @intLeft
			end # End: def left?()
			
			def width?()
				@intWidth = @objBrowser.ie.width # Get IE's width
				
				return @intWidth
			end # End: def width?()
			
			def height?()
				@intHeight = @objBrowser.ie.height # Get IE's height
				
				return @intHeight
			end # End: def height?()
			
			def current_url?()
				@strCurrentURL = @objBrowser.url # Get current URL	
				
				return @currentURL
			end # End: def currentURL?()
			
			def delete_cookies()
				cookieDirStr = @objProfile.userCookieDir?
				fileNameArray = Dir.entries(cookieDirStr)
				# Attempt to delete each cookie
				fileNameArray.each {
					|fName| strTemp = fName
					if not strTemp == ".." and not strTemp == "." and not strTemp == "index.dat"
						strPathToFile = strTemp
						begin
							strPathToFile = cookieDirStr + "\\" + strTemp
							# Make sure we're not accessing a read-only file
							if File.writable?(strPathToFile)
								File.unlink(strPathToFile)
							end # End: if File.writable?(strPathToFile)
						rescue => ex
						end
					end # End: if not strTemp == ".." and not strTemp == "."
				}
				
				return Dir.entries(cookieDirStr)
			end
			
			def clear_internet_cache()
				cacheDirStr = @objProfile.userCacheDir?
				fileNameArray = Dir.entries(cacheDirStr)
				# Attempt to delete each cookie
				fileNameArray.each {
					|fName| strTemp = fName
					strPathToFile = strTemp
					if not strTemp == ".." and not strTemp == "."
						begin
							strPathToFile = cacheDirStr + "\\" + strTemp
							# Make sure we're not accessing a read-only file
							if File.writable?(strPathToFile)
								File.unlink(strPathToFile)
							end # End: if File.writable?(strPathToFile)
						rescue => ex
						end
					end # End: if not strTemp == ".." and not strTemp == "."
				}
				
				return Dir.entries(cacheDirStr)
			end # End: def voidClearInternetCache()
			
		end # End: class browser
		
	end # End: module Browser

end # End: module Adanna
