#***********************************************************************
# Adanna Bot: testbot.rb
#
# This is an attempt to creat a bot script for Adanna that integrates
# into itself, so that Adanna has complete control over the script.
#
# Created by: Nathan Lane
# Last Updated: 05/03/2007
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
		@agentMessages = ""
		
		setup_vin_decoder_bot
	end # End: def initialize(objAdannaLogger, strEnvironment)
	
	def setup_vin_decoder_bot()
	     # Form library
		@formLibrary = Hash.new
		@formLibrary["VIN"] = "ctl00_BodyContent_vinTextBox"
		@formLibrary["Email Address"] = "ctl00_BodyContent_emailTextBox"
		@formLibrary["Zip Code"] = "ctl00_BodyContent_zipCodeTextBox"
		@formLibrary["Continue"] = "ctl00_BodyContent_continueRollOverButton_imageButton"
		
		# email address, and zipcode
		@emailAddress = "someone@somewhere.org"
		@zipCode = "84106"
	end # End: def setup_vin_decoder_bot()
	
	def clean_up_bot()
		@watirBrowser.close
	end # End: def clean_up_bot()
	
	def run_bot()
		@internalAgentState = PASS
		vinsArray = (@environment.paramString).split("$")
		vinsArray.each do |vin|
			begin
					@watirBrowser = WatirBrowser.new
					@logger.log("Bot: Running the VIN-Decoder bot", PASS)
					@watirBrowser.set_with_home(false, false, 0, 0, 1024, 990, @environment.environmentHome)
					@logger.log("Bot: Successfully browsed to starting page: " + @environment.environmentHome, PASS)
					currentURL = @watirBrowser.url?
							
					# Enter data into SYC form
					@watirBrowser.watir.textField(:id, @formLibrary["VIN"]).set(vin)
					if(not @watirBrowser.watir.textField(:id, @formLibrary["VIN"]).verify_contains(vin))
						@internalAgentState = FAIL
					end # End: if(@watirBrowser.watir.textField(:id, @formLibrary["VIN"]).verify_contains(vin)
					@logger.log("Bot: Entered VIN", @internalAgentState)
					
					@watirBrowser.watir.textField(:id, @formLibrary["Email Address"]).set(@emailAddress)
					if(not @watirBrowser.watir.textField(:id, @formLibrary["Email Address"]).verify_contains(@emailAddress))
						@internalAgentState = FAIL
					end # End: if(not @watirBrowser.watir.textField(:id, @formLibrary["Email Address"]).verify_contains(@emailAddress)
					@logger.log("Bot: Entered Email Address", @internalAgentState)
					
					@watirBrowser.watir.textField(:id, @formLibrary["Zip Code"]).set(@zipCode)
					if(not @watirBrowser.watir.textField(:id, @formLibrary["Zip Code"]).verify_contains(@zipCode))
						@internalAgentState = FAIL
					end # End: if(not @watirBrowser.watir.textField(:id, @formLibrary["Zip Code"]).verify_contains(@zipCode)
					@logger.log("Bot: Entered Zip Code", @internalAgentState)
					
					# Click on the Continue button
					@watirBrowser.watir.button(:id, @formLibrary["Continue"]).click
					
					# Get the server name
					serverName = @watirBrowser.watir.span(:class_name, "buildNumber").text
					
					# Check whether we got to the correct page
					if not (@watirBrowser.url? == currentURL)
						@logger.log("VIN Decoder PASSING on " + serverName + " for " + vin, PASS)
						@agentMessages = "VIN Decoder PASSING on " + serverName
					else
						@agentState = FAIL
						@logger.log("VIN Decoder FAILING on " + serverName + " for " + vin, FAIL)
						@agentMessages = @agentMessages + "VIN Decoder FAILING on " + serverName + " for " + vin + "; "
					end # End: if not (@watirBrowser.url? == currentURL)
			ensure
				clean_up_bot
			end
		end # End: vinsArray.each do |vin|
		
		@agentState
	end # End: def run_bot()
	
end # End: class Bot
