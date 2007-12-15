#***********************************************************************
# Script Name: VehixBot_AdvancedSearch.rb    Version: 2.0.0
#
# This Bot script is designed to be more robust, and more modular, as
# well as easier to maintain.  It is an effort to utilize the new more
# Object Oriented Programming features of Ruby.
#
# Change Notes:
#  01-11-2006: Actually began writing this script.
#
# @author Nathan Lane
# Last Updated: 01/11/2006
#***********************************************************************

class Bot

	# Require second generation library
	require "vehix.com/vehix.com"
	
	# Include Vehix module - contains basic browser stuff
	include Vehix
	# Include Agents module - contains ErrorPageBot, and PageInfo classes
	include Agents
	
	public # Public methods
	
	#***********************************************************************
	# initialize sets up the Bot.  The following are set up in this 
	# method:
	#
	# @botBaseDir - the directory where the Bot script is located
	# @version - simply a text version that is displayed in the logs
	# @argTable - a hash table to contain commandline arguments and their
	#  values
	# @botLogger - the VehixLogger object for this Bot
	# @agentData - data pertaining to this agent and the computer it is
	#  running on
	# @pageNumber - the current page number that we have browsed to; this
	#  is used to access VehixPage information from the WatirBrowser object
	# @watirEnv - WatirEnvironment object containing environment variables
	#***********************************************************************
	def initialize()
		# Get current working directory
		@botBaseDir = Dir.getwd
		# Set logging mode
		@loggingMode = VL.BOTH
		
		@version = "2.0.0" + "_" + Vehix::libraryVersion?
		
		# Set up logger
		@botLogger = VehixLogger.new
		@botStartTime = @botLogger.log(VL.INFO, "This is VehixBot Advanced Search version " + version?, @loggingMode)[1]
		@botLogger.log(VL.INFO, "Setting up Bot", @loggingMode)
		
		# Get agent data
		@botLogger.log(VL.INFO, "Getting agent data", @loggingMode)
		@agentData = AgentData.new
		@botLogger.log(VL.INFO, "Agent data was retrieved", @loggingMode)
		
		# This contains any command line arguments that were passed
		@argTable = Hash.new
		initialize_arg_table
		
		# Setup the form data hash so we know where to click and such
		setup_form_data
		
		# Parse any command line arguments first
		@botLogger.log(VL.INFO, "Getting command line arguments: " + ARGV.length.to_s + " found", @loggingMode)
		tempArgTable = get_arguments # Get arguments from commamd line
		@botLogger.log(VL.INFO, "Setting parameters for Bot script", @loggingMode)
		set_parameters(tempArgTable) # Set the paramters of the Bot script
		tempArgTable = nil
		
		# Set up secondary variables and such
		@pageNumber = 0
		@finished = false
		
		# Get Watir settings
		@watirEnv = WatirEnvironment.new
		if @watirEnv.blnSetupEnvironment(@argTable["environment-config-path"])
			@botLogger.log(VL.INFO, "Got Watir Environment", @loggingMode)
			@botHome = @watirEnv.vcp_env?
			
			# Setup browser
			@watirBrowser = WatirBrowser.new # Create a new browser object
			@watirBrowser.set(false, false, 0, 0, @argTable["browser-width"], @argTable["browser-height"]) # Set up browser features
			@botLogger.log(VL.INFO, "Created new Watir Browser and set it up", @loggingMode)
			
			# Setup bot appendages
			@errorPageBot = ErrorPageBot.new(0, 0, @argTable["check-for-error-pages"], @watirBrowser)
			@botLogger.log(VL.INFO, "Created new Error Page Bot", @loggingMode)
			@pageInfo = BrowserPageInfo.new(@watirBrowser)
			@botLogger.log(VL.INFO, "Created new Browser Page Info object", @loggingMode)
		else
			@botLogger.log(VL.INFO, "Unable to get Watir Environment: " + @watirEnv.path_to_environment?, @loggingMode)
			@argTable["environment-config-path"] = ""
		end # End: if @watirEnv.blnSetupEnvironment("C:\\QTP_Environment_01.xml")
	end # End: def initialize()
	
	def run_bot()
		# Run the advanced search bot
		advanced_search_bot
	end # End: def run_bot()
	
	#***********************************************************************
	# initialize_arg_table initializes the @argTable hash with default 
	# values and thus sets the preferred type of the value
	#***********************************************************************
	def initialize_arg_table()
		@argTable["browser-width"] = 1024
		@argTable["browser-height"] = 990
		@argTable["check-for-error-pages"] = true
		@argTable["take-screenshots"] = "n"		
		@argTable["environment-config-path"] = "C:\\QTP_Environment_01.xml"
		@argTable["custom-string"] = @botLogger.logger_name? + ""
	end # End: def initialize_arg_table()

	#***********************************************************************
	# clean_up_spider closes stream specific resources for this Spider
	#***********************************************************************
	def clean_up_bot()
		begin
			@watirBrowser.close # Close the browser
		rescue => ex
			@botLogger.log(VL.WARN, "WatirBrowser may have already been closed when trying to close it", @loggingMode)
		end
		
		begin
			@botLogger.close # Close the logger
		rescue => ex
			# I don't want to do anything here
		end
	end # End: def clean_up_spider()
	
	#***********************************************************************
	# log_error is a user method to log errors that happen outside of this
	# Spider
	#***********************************************************************
	def log_error(strMessage)
		@botLogger.log(VL.ERROR, strMessage, @loggingMode)
	end # End: def log_error()
	
	#***********************************************************************
	# log_results logs the results of running the Spider script
	#***********************************************************************
	def log_results()
		@botEndTime = @botLogger.log(VL.DEBUG, "------------------------------------------------------------\n", @loggingMode)[1]
		@botLogger.log(VL.DEBUG, "Bot Results:\n", @loggingMode)
		@botLogger.log(VL.DEBUG, "Bot Start Time: " + @botStartTime + "\n", @loggingMode)
		@botLogger.log(VL.DEBUG, "Bot End Time: " + @botEndTime + "\n", @loggingMode)
		timeStart = Time.parse(@botStartTime)
		timeEnd = Time.parse(@botEndTime)
		timeDiff = timeEnd - timeStart
		@botLogger.log(VL.DEBUG, "Bot Total Time: " + timeDiff.to_s + "\n", @loggingMode)
		@botLogger.log(VL.DEBUG, "Agent Data:\n" + @agentData.to_s + "\n", @loggingMode)
		@botLogger.log(VL.DEBUG, "------------------------------------------------------------\n", @loggingMode)
	end # End: def log_results()
	
	#***********************************************************************
	# finished? returns whether or not the script finished
	#***********************************************************************
	def finished?()
		return @finished
	end # End: def finished?()
	
	#***********************************************************************
	# version? returns the current version of this Spider
	#***********************************************************************
	def version?()
		return @version.to_s
	end # End: def displayVersion()
	
	#***********************************************************************
	# arg_table returns the current argument hash table for this Spider
	#***********************************************************************
	def arg_table()
		return @argTable
	end # End: def arg_table()
	
	protected # Protected methods - only for Spider usage
	
	def setup_form_data()
		@hashAdvancedSearchFormTable = Hash.new
		# Total available number
		@hashAdvancedSearchFormTable["Total"] = "totalAvailable"
		# Advanced Searh form hash table
		@hashAdvancedSearchFormTable["New"] = "condition_1"
		@hashAdvancedSearchFormTable["Used"] = "condition_2"
		@hashAdvancedSearchFormTable["Both"] = "condition_3"
		@hashAdvancedSearchFormTable["CPO"] = "condition_4"
		@hashAdvancedSearchFormTable["Certified Pre Owned"] = "condition_4"
		# Year drop downs hash table
		@hashAdvancedSearchFormTable["Year Begin"] = "yearbeg"
		@hashAdvancedSearchFormTable["Year End"] = "yearend"
		# Body styles hash table
		@hashAdvancedSearchFormTable["All"] = "allBodyStyles"
		@hashAdvancedSearchFormTable["Compact/Coupe"] = "26000000000002"
		@hashAdvancedSearchFormTable["Luxury"] = "26000000000005"
		@hashAdvancedSearchFormTable["Sport"] = "26000000000008"
		@hashAdvancedSearchFormTable["Truck"] = "2600000000000B"
		@hashAdvancedSearchFormTable["Convertible"] = "26000000000003"
		@hashAdvancedSearchFormTable["Mini/Passenger Van"] = "26000000000006"
		@hashAdvancedSearchFormTable["Sport Utility Vehicle"] = "26000000000009"
		@hashAdvancedSearchFormTable["Hybrid"] = "26000000000004"
		@hashAdvancedSearchFormTable["Sedan"] = "26000000000007"
		@hashAdvancedSearchFormTable["Station Wagon"] = "2600000000000A"
		# Makes, models, radius, zip code hash table
		@hashAdvancedSearchFormTable["Makes"] = "makes"
		@hashAdvancedSearchFormTable["Models"] = "models"
		@hashAdvancedSearchFormTable["Radius"] = "radius"
		@hashAdvancedSearchFormTable["Zip Code"] = "postalcode"
		# Price drop downs hash table
		@hashAdvancedSearchFormTable["No Price"] = "noPrice"
		@hashAdvancedSearchFormTable["Price Begin"] = "pricebeg"
		@hashAdvancedSearchFormTable["Price End"] = "priceend"
		# All other drop downs hash table
		@hashAdvancedSearchFormTable["Mileage"] = "mileage"
		@hashAdvancedSearchFormTable["Engine"] = "ctl00_ContentPlaceHolder1_engine"
		@hashAdvancedSearchFormTable["Drive"] = "ctl00_ContentPlaceHolder1_drive"
		@hashAdvancedSearchFormTable["Trans"] = "ctl00_ContentPlaceHolder1_transmission"
		@hashAdvancedSearchFormTable["Fuel"] = "ctl00_ContentPlaceHolder1_fuel"
		# Results number
		@hashAdvancedSearchFormTable["Tally"] = "tally"
		# View Results button
		@hashAdvancedSearchFormTable["View Results"] = "btn_viewResults" # This one is class-based, the others are all id's
	end # End: def setup_form_data()
	
	#***********************************************************************
	# get_arguments puts all of the commandline arguments into the argument
	# hash table
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
	# values are all of the correct type and ensures that defaults are set
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
	def voidDisplayHelp()
		puts "\nVehixBot_AdvancedSearch.rb [options]" +
			"\n\nOptions:" +
			"\n    --help Brings up this help listing" +
			"\n    --check-for-error-pages=True|False defaults to True.  If True, then\n      error pages are transacted" +
			"\n    --use-properties-file=Path to properties file" +
			"\n    --browser-width=# With of the browser" +
			"\n    --browser-height=# Height of the browser" +
			"\n    --environment-config-path=Path to XML Environment file" +
			"\n    --custom-string=Custom string to include in error page transaction\n"
	end # End: def voidDisplayHelp()
	
	#***********************************************************************
	# This method opens the local properties file, which is always names the
	# same as the program running + .properties.
	#***********************************************************************
	def get_properties()
		@propertiesArray = Array.new # Set up an array to store properties hashes into
		intPathLen = $0.length - 4 # remove the '.rb' and zeroify the length
		Dir.chdir("..")
		strPropertiesFileName = $0[0..intPathLen] + ".properties"
		if File.exist?(strPropertiesFileName)
			# Create a new hash to store properties for search
			botProperties = Hash.new
			@botLogger.log(VL.INFO, "Found properties file: " + strPropertiesFileName, @loggingMode)
			# Open properties file
			propFile = File.new(strPropertiesFileName, "r")
			@botLogger.log(VL.INFO, "Reading properties from properties file", @loggingMode)
			# Initialize counter
			intCounter = -1
			# Read properties
			while not propFile.eof
				# Read next line of file
				strNextLine = propFile.readline
				# If line has # in it, then ignore it - it's a comment
				if strNextLine["#"].nil? 
					# Find out if line contains 'index'
					if not strNextLine["index"].nil?
						intCounter = intCounter + 1
						strNextLine = "index = " + intCounter.to_s
						# Create a new hash
						if intCounter > 0
							@propertiesArray << botProperties # Store hash
							# Create a new hash to store properties for search
							botProperties = Hash.new
						end # End: if intCounter > 0
					end # End: if not strNextLine["index"].nil?
					
					if not strNextLine["index"].nil? or not strNextLine["condition"].nil? or not strNextLine["bodystyles"].nil? or not strNextLine["make"].nil? or not strNextLine["model"].nil? or not strNextLine["radius"].nil? or not strNextLine["zipcode"].nil?
						# Store the data
						strNextLine.chomp! # Get rid of newline characters
						strNextLineSplit = strNextLine.split("=") # Split string at equals sign
						key = strNextLineSplit[0].strip
						value = strNextLineSplit[1].strip
						# Set key/value pair for this property
						botProperties[key] = value
					end # End: if not strNextLine["index"].nil? or not strNextLine["condition"].nil? or not strNextLine["bodystyles"].nil? or not strNextLine["make"].nil? or not strNextLine["model"].nil? or not strNextLine["radius"].nil? or not strNextLine["zipcode"].nil?
				end # End: if strNextLine["#"].nil? 
			end # End: while not propFile.eof
			# Close properties file
			propFile.close
		else
			@botLogger.log(VL.WARN, "Could not find properties file: " + strPropertiesFileName, @loggingMode)
		end # End: if File.exist?(strPropertiesFileName)
		@botLogger.log(VL.INFO, "Found " + @propertiesArray.length.to_s + " vehicles", @loggingMode)
	end # End: def get_properties()
	
	#***********************************************************************
	# This function selects a condition using an array and by randomly
	# selecting one of the array elements to use.
	#
	# @param strCondition String condition. StrCondition is normally an
	# array, so you'll have to send only one item of that array, [0] if only
	# one item exists in the array. This is because only one item may be
	# selected at a time. Other methods behave differently.
	#***********************************************************************
	def strSelectCondition(strCondition)
		if not strCondition.class == Array
			# Select condition
			@botLogger.log(VL.INFO, "Clicking on condition: " + strCondition, @loggingMode)
			# Timeout after 45 seconds to relinquish time over to the other procs
			begin
				timeout(45) do
					@watirBrowser.watir.radio(:id, @hashAdvancedSearchFormTable[strCondition]).click
				end # End: timeout(45) do
			rescue TimeoutError
				@botLogger.log(VL.INFO, "Timed out after 45 seconds on strSelectCondition", @loggingMode)
			end
			
			# Return a string containing the step to reproduce
			return "Clicked on " + strCondition + " condition."
		else
			return "Error: Condition string was an array"
		end # End: if not strCondition.class == Array
	end # End: def strSelectCondition(strCondition)

	#***********************************************************************
	# This function selects all of the body styles defined by the array,
	# strBodyStyles.
	#
	# @param strBodyStyles This is an array containing body styles.
	#***********************************************************************
	def strSelectBodyStyles(strBodyStyles)
		if not strBodyStyles.inspect["None"].nil?
			return "Click on no body style check boxes"
		end # End: if not strBodyStyles.inspect["None"].nil?

		strBodyStylesList = ""

		# Select body styles
		if strBodyStyles.class == Array
			if strBodyStyles.length > 0
				strBodyStyles.each {
					|bs| tempBodyStyle = bs
					
					tempBodyStyle.strip! # Remove any surreounding spaces
					# Select the next body style in the array
					@botLogger.log(VL.INFO, "Clicking on body style: " + tempBodyStyle, @loggingMode)
					# Timeout after 45 seconds to relinquish time over to the other procs
					begin
						timeout(45) do
							@watirBrowser.watir.checkBox(:id, @hashAdvancedSearchFormTable[tempBodyStyle]).set(true)
						end # End: timeout(45) do
					rescue TimeoutError
						@botLogger.log(VL.INFO, "Timed out after 45 seconds on strSelectBodyStyles", @loggingMode)
					end
					
					# Add body style to body styles list string
					strBodyStylesList = strBodyStylesList + tempBodyStyle + ", "
				}
			end # End: if strBodyStyles.length > 0
			
			intLen = strBodyStylesList.length - 3
			# Return a string containing the step to reproduce
			return "Click on " + strBodyStylesList[0..intLen] + " body style check box"
		else
			return "Error: Body style were not formed into an array"
		end # End: if strBodyStyles.class == Array
	end # End: def strSelectBodyStyles(strBodyStyles)

	#***********************************************************************
	# This function selects one make as defined by strMake.
	#
	# @param strMake String containing the make you'd like to select.
	#***********************************************************************
	def strSelectMake(strMake)
		if not strMake.class == Array
			# Select the make
			@botLogger.log(VL.INFO, "Selecting make: " + strMake, @loggingMode)
			# Timeout after 45 seconds to relinquish time over to the other procs
			begin
				timeout(45) do
					@watirBrowser.watir.selectBox(:id, @hashAdvancedSearchFormTable["Makes"]).select(strMake)
				end # End: timeout(45) do
			rescue TimeoutError
				@botLogger.log(VL.INFO, "Timed out after 45 seconds on strSelectMake", @loggingMode)
			end
			
			# Return a string containing the step to reproduce
			return "Select " + strMake + " from the makes drop down list"
		else
			return "Error: Make string was an array"
		end # End: if not strMake.class == Array
	end # End: def strSelectMake(strMake)

	#***********************************************************************
	# This function selects one model as defined by strModel.
	#
	# @param strModel String containing the model you'd like to select.
	#***********************************************************************
	def strSelectModel(strModel)
		if not strModel.class == Array
			# Select the model
			@botLogger.log(VL.INFO, "Selecting model: " + strModel, @loggingMode)
			# Timeout after 45 seconds to relinquish time over to the other procs
			begin
				timeout(45) do
					@watirBrowser.watir.selectBox(:id, @hashAdvancedSearchFormTable["Models"]).select(strModel)
				end # End: timeout(45) do
			rescue TimeoutError
				@botLogger.log(VL.INFO, "Timed out after 45 seconds on strSelectModel", @loggingMode)
			end
			
			# Return a string containing the step to reproduce
			return "Select " + strModel + " from the models drop down list"
		else
			return "Error: Model string was an array"
		end # End: if not strModel.class == Array
	end # End: def strSelectModel(strModel)

	#***********************************************************************
	# This function selects the radius as defined by strRadius.
	#
	# @param strRadius String containing a radius string to select from the
	# radius drop down list.
	#***********************************************************************
	def strSelectRadius(strRadius)
		if not strRadius.class == Array
			# Select the radius
			@botLogger.log(VL.INFO, "Selecting radius: " + strRadius, @loggingMode)
			# Timeout after 45 seconds to relinquish time over to the other procs
			begin
				timeout(45) do
					@watirBrowser.watir.selectBox(:id, @hashAdvancedSearchFormTable["Radius"]).select(strRadius)
				end # End: timeout(45) do
			rescue TimeoutError
				@botLogger.log(VL.INFO, "Timed out after 45 seconds on strSelectRadius", @loggingMode)
			end
			
			# Return a string containing the step to reproduce
			return "Select " + strRadius + " from the radius drop down list"
		else
			return "Error: Radius string was an array"
		end # End: if not strRadius.class == Array
	end # End: def strSelectRadius(strRadius)

	#***********************************************************************
	# This function enters a zip code into the zip code box.
	#
	# @param strZipCode String containing a five digit zip code.
	#***********************************************************************
	def strEnterZipCode(strZipCode)
		if not strZipCode.class == Array
			# Enter the zip code
			@botLogger.log(VL.INFO, "Entering zip code: " + strZipCode, @logginMode)
			# Timeout after 45 seconds to relinquish time over to the other procs
			begin
				timeout(45) do
					@watirBrowser.watir.textField(:id, @hashAdvancedSearchFormTable["Zip Code"]).set(strZipCode)
				end # End: timeout(45) do
			rescue TimeoutError
				@botLogger.log(VL.INFO, "Timed out after 45 seconds on strEnterZipCode", @loggingMode)
			end
			
			# Return a string containing the step to reproduce
			return "Enter " + strZipCode + " in zip code text field"
		else
			return "Error: Zip Code string was an array"
		end # End: if not strZipCode.class == Array
	end # End: def strEnterZipCode(strZipCode)

	#***********************************************************************
	# This function clicks on the View Results button.
	#***********************************************************************
	def strClickViewResultsButton()
		# Click on View Results button
		@botLogger.log(VL.INFO, "Clicking on View Results button", @loggingMode)
		#@watirBrowser.clickImageByClassName(@hashAdvancedSearchFormTable["btn_viewResults"])
		@watirBrowser.watir.images.each {
			|img| tempImage = img
			
			tempOLEObj = tempImage.getOLEObject
			# Find the right image to click on
			if tempOLEObj.invoke("className").to_s == "btn_viewResults"
				# Timeout after 45 seconds to relinquish time over to the other procs
				begin
					timeout(45) do
						tempImage.click
					end # End: timeout(45) do
				rescue TimeoutError
					@botLogger.log(VL.INFO, "Timed out after 45 seconds on strEnterZipCode", @logginMode)
				end
				break
			end # End: if tempImage.class_name == "btn_viewResults"
		}
		
		# Return a string containing the step to reproduce
		return "Click on View Results button"
	end # End: def strClickViewResultsButton()
	
	#***********************************************************************
	# wait_for_matches waits for the tally to show that there are some
	# vehicle matches.
	#***********************************************************************
	def wait_for_matches()
		retVal = false
		
		begin
			# Only wait a minute for this to populate
			timeout(60) do
				while not @watirBrowser.watir.span(:id, @hashAdvancedSearchFormTable["Tally"]).text["Updating..."].nil?
					# Keep looping until we get out
					sleep(0.01) # Sleep for 1/100 second
				end
			end # End: timeout(60) do
		rescue TimeoutError
			@botLogger.log(VL.FATAL, "Tally never updated from '...' or 'Updating...'", @loggingMode)
		end
		@botLogger.log(VL.INFO, @watirBrowser.watir.span(:id, @hashAdvancedSearchFormTable["Tally"]).text + " criteria matches found", @loggingMode)
		# Check if Tally shows '...' - this is an error
		if @watirBrowser.watir.span(:id, @hashAdvancedSearchFormTable["Tally"]).text == "..."
			retVal = false
		elsif @watirBrowser.watir.span(:id, @hashAdvancedSearchFormTable["Tally"]).text == "0"
			retVal = false
		else
			retVal = true
		end # End: if $objWatirBrowser.span(:id, $hashAdvancedSearchFormTable["Tally"]).text == "..."
		
		return retVal
	end # End: def wait_for_matches()

	#***********************************************************************
	# This function validates the Inventory Results page by going through
	# and finding the script containing all of the data for I.R. and then
	# parsing through it to see if it's correct.
	#***********************************************************************
	def voidValidateInventoryResultsPage(properties)
		strInventoryResultsScript = "" # Initialize strInventoryResultsScript
		
		# Search for the script in the page
		@watirBrowser.watir.ie.document.scripts.each {
			|script| tempScript = script.innerHTML
			
			if not tempScript["aInventory["].nil?
				strInventoryResultsScript = tempScript
			end # End: if not tempScript["aInventory["].nil?
		}
		
		# Make sure we got something
		if strInventoryResultsScript == "" # If we missed it, return
			@botLogger.log(VL.INFO, "Error: aInventory not found in document.scripts", @loggingMode)
			return nil
		else # If we got it, continue!
			intVehicleCounter = 0
			intThisVehicle = 0
			# Split the script up
			strScriptSplit = strInventoryResultsScript.split("aInventory[")
			# Get rid of the first element which in our case only contains non-printing characters
			strScriptSplit.delete_at(0)
			@botLogger.log(VL.INFO, "Found " + strScriptSplit.length.to_s + " vehicles in the script", @loggingMode)
			
			# Go through each of the script elements and make sure they match our search criteria
			strScriptSplit.each {
				|scriptSplit| tempScript = scriptSplit
				@botLogger.log(VL.INFO, "Checking vehicle " + intThisVehicle.to_s, @loggingMode)
				
				# Split the script line by ',' characters
				strElements = tempScript.split(",")
				
				intChecks = 0 # A counter to make sure everything checks out for a vehicle
				# Go through each of those to make certain that the correct criteria exists
				strElements.each {
					|e| tempElement = e
					
					# Make sure it's an element that we want, if not then throw it away
					# Check #1
					if not tempElement["DealerShortModel"].nil?
						# Make sure this is the model we chose
						if not tempElement[properties["model"]].nil?
							intChecks = intChecks + 1 # Incerement the checks counter
						end # End: if not tempElement[$objVehixBotProperties[intCounter].strMakesArray[0]].nil?
					# Check #2
					elsif not tempElement["DealerMake"].nil?
						# Make sure this is the make we chose
						if not tempElement[properties["make"]].nil?
							intChecks = intChecks + 1 # Incerement the checks counter
						end # End: if not tempElement[$objVehixBotProperties[intCounter].strMakesArray[0]].nil?
					# Check #4
					elsif not tempElement["DealerBodyStyle"].nil?
						if properties.has_key?("bodystyles") and properties["bodystyles"]["Al"].nil?
							# Make sure this is one of the body styles we chose
							bsArray = properties["bodystyles"].split(",")
							bsArray.each {
								|bs| tempBodyStyle = bs
								
								tempBodyStyle.strip!
								if not tempElement[tempBodyStyle].nil?
									intChecks = intChecks + 1 # Incerement the checks counter
								end # End: if not tempElement[$objVehixBotProperties[intCounter].strMakesArray[0]].nil?
							}
						else
							# Increment if All body styles were selected
							intChecks = intChecks + 1 # Incerement the checks counter
						end # End: if $objVehixBotProperties[intCounter].strBodyStylesArray.length > 0 and $objVehixBotProperties[intCounter].strBodyStylesArray.inspect["All"].nil?
					# Check #3
					elsif not tempElement["Condition"].nil?
						# Make sure this is the condition we chose
						# Forget the case of Both for now
						# Normal cases, e.g. (New == New) = true
						if not tempElement[properties["condition"]].nil?
							intChecks = intChecks + 1 # Increment the checks counter
						# Both cases
						elsif properties["condition"] == "Both"
							# Increment it, because 'Both' is all-inclusive
							intChecks = intChecks + 1 # Incerement the checks counter
						# CPO/Used cases
						elsif not tempElement["CertifiedPreOwned"].nil?
							if properties["condition"] == "CPO"
								intChecks = intChecks + 1 # Incerement the checks counter
							elsif properties["condition"] == "Certified Pre Owned"
								intChecks = intChecks + 1 # Incerement the checks counter
							elsif properties["condition"] == "Used"
								intChecks = intChecks + 1 # Incerement the checks counter
							end # End: if $objVehixBotProperties[intCounter].strConditionsArray[0] == "CPO"
						else
							# Ignore if none of these cases are valid
						end # End: if not tempElement[$objVehixBotProperties[intCounter].strMakesArray[0]].nil?
					else
						# Throw away elements that we don't need
					end # End: if not tempElement["DealerModel"].nil?
				}
				# Log the results dependent upon what was found
				if not properties.has_key?("bodystyles") and intChecks >= 4
					# Increment intVehicleCounter
					intVehicleCounter = intVehicleCounter + 1
					intThisVehicle = intThisVehicle + 1
				elsif properties.has_key?("bodystyles") and intChecks == 3
					# Increment intVehicleCounter
					intVehicleCounter = intVehicleCounter + 1		
					intThisVehicle = intThisVehicle + 1
				else
					@botLogger.log(VL.FATAL, "Vehicle " + (intThisVehicle + 1).to_s + " found to be INVALID for search criteria: " + tempScript, @loggingMode)
					intThisVehicle = intThisVehicle + 1
				end # End: if $objVehixBotProperties[intCounter].strBodyStylesArray.length > 0 and intChecks >= 4
			}
			
			# See if we found only valid vehicles
			if intVehicleCounter == strScriptSplit.length
				strVehicle = properties["condition"] + " " + properties["make"] + " " + properties["model"]
				@botLogger.log(VL.PASS, "PASS - Search for " + strVehicle + " resulted in VALID results: " + intVehicleCounter.to_s + "/" + strScriptSplit.length.to_s + " valid", @loggingMode)
			else
				strVehicle = properties["condition"] + " " + properties["make"] + " " + properties["model"]
				@botLogger.log(VL.WARN, "FAIL - Search for " + strVehicle + " resulted in INVALID results: " + intVehicleCounter.to_s + "/" + strScriptSplit.length.to_s + " valid", @loggingMode)
			end # End: if intVehicleCounter == strScriptSplit.length
		end # End: if strInventoryResultsScript == ""
	end # End: def voidValidateInventoryResultsPage()

	#***********************************************************************
	# This is the bot loop.
	#***********************************************************************
	def advanced_search_bot
		# Get the properties for this bot
		@botLogger.log(VL.INFO, "Getting properties for bot", @loggingMode)
		get_properties
		# Go through each vehicle
		intCounter = 0
		@propertiesArray.each {
			|prop| tempProp = prop
			
			# Get to the advanced search page
			@botLogger.log(VL.INFO, "************************************************************", @loggingMode)
			@botLogger.log(VL.INFO, "Starting test for vehicle #" + intCounter.to_s, @loggingMode)
			@watirBrowser.browse_to("http://www.vehix.com/inventory/advancedSearch.aspx") # Browse to nexst link
			
			# Check to see if this is an error page :)
			@botLogger.log(VL.INFO, "Checking for an error page", @loggingMode)
			botErrorPageMessage = @agentData.computerName + " found an error page trying to browse to " + @watirBrowser.url? + ". Custom message: " + @argTable["custom-string"]
			intResult = @errorPageBot.intCheckForErrorPage(botErrorPageMessage) # Check for an error page
			if intResult == 1
				@botLogger.log(VL.INFO, "Found an error page", @loggingMode)
			elsif intResult == 0
				@botLogger.log(VL.INFO, "No error page was found", @loggingMode)
			end # End: if intResult == 1
			
			# Transact advanced search page
			begin
				if tempProp.has_key?("condition")
					# Set condition
					strSelectCondition(tempProp["condition"])
				end # End: if tempProp.has_key?("condition")
				
				if tempProp.has_key?("bodystyles")
					# Select body styles
					strSelectBodyStyles(tempProp["bodystyles"].split(","))
				end # End: if tempProp.has_key?("bodystyles")
				
				if tempProp.has_key?("make")
					# Select the make
					strSelectMake(tempProp["make"])
				end # End: if tempProp.has_key?("make")
				
				if tempProp.has_key?("model")
					# Select the model
					strSelectModel(tempProp["model"])
				end # End: if tempProp.has_key?("model")
				
				if tempProp.has_key?("radius")
					# Select the radius
					strSelectRadius(tempProp["radius"])
				end # End: if tempProp.has_key?("radius")
				
				if tempProp.has_key?("zipcode")
					# Enter the zip code
					strEnterZipCode(tempProp["zipcode"])
				end # ENd: if tempProp.has_key?("zipcode")
			rescue => ex
				@botLogger.log(VL.WARN, "Warning during transaction: " + ex.message + " Backtrace: " + ex.backtrace.inspect, @loggingMode)
			end
			
			@botLogger.log(VL.INFO, "Waiting for matches to load", @loggingMode)
			if wait_for_matches # If this is true, then the matches came up
				# Click on the View Results button
				strClickViewResultsButton
				
				# Check to see if this is an error page :)
				@botLogger.log(VL.INFO, "Checking for an error page", @loggingMode)
				botErrorPageMessage = @agentData.computerName + " found an error page trying to browse to " + @watirBrowser.url? + ". Custom message: " + @argTable["custom-string"]
				intResult = @errorPageBot.intCheckForErrorPage(botErrorPageMessage) # Check for an error page
				if intResult == 1
					@botLogger.log(VL.INFO, "Found an error page", @loggingMode)
				elsif intResult == 0
					@botLogger.log(VL.INFO, "No error page was found", @loggingMode)
				end # End: if intResult == 1				
				
				# Validate the results
				voidValidateInventoryResultsPage(tempProp)
			end # End: if wait_for_matches
			
			# End the test
			@botLogger.log(VL.INFO, "Ending test for vehicle #" + tempProp["index"], @loggingMode)
			@botLogger.log(VL.INFO, "************************************************************", @loggingMode)
			@watirBrowser.browse_to("about:blank") # Browse to nexst link			
			@watirBrowser.clearInternetCache # Clear the cache
			@watirBrowser.deleteCookies # Delete cookies
			
			intCounter = intCounter + 1 # Increment the counter
		}
	end # End: def advanced_search_bot
	
end # End: class Bot 

#***********************************************************************
#***********************************************************************
# This is the program entry point
#***********************************************************************
if __FILE__ == $0 # This verifies that the file name is the same as the zeroth argument, which is also the file name
	
	# Create a new Spider object
	vehixBot = Bot.new()
	
	begin
		# Make sure that our environment was set
		if not vehixBot.arg_table["environment-config-path"] == ""
			# Run the bot
			vehixBot.run_bot
		end # End: if not vehixSpider.argTable["environment-config-path"] == ""
	rescue => ex
		vehixBot.log_error("A FATAL exception occurred! Message: " + ex.message + " Backtrace: " + ex.backtrace.inspect)
	ensure
		vehixBot.log_results
		vehixBot.clean_up_bot
	end
end # End: if __FILE__ == $0
