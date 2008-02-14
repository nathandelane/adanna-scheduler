#***********************************************************************
# Adanna Bot: spider_ie_1.rb
#
# This spider browses the site by clicking on links in Internet
# Explorer. This is a major attempt to simplify and integrate the spider
# script into Adanna more fully.
#
# Created by: Nathan Lane
# Last Updated: 06/05/2007
#***********************************************************************

require "libadanna"

include Adanna::Reporting
include Adanna::Agents
include Adanna::Browser

class Spider < AgentBase
	
	def initialize(objAdannaLogger, objEnvironment)
		super(objAdannaLogger, objEnvironment)
		
		@logger = objAdannaLogger
		@environment = objEnvironment
		@agentState = PASS
		
		setup_spider
	end # End: def initialize(objAdannaLogger, objEnvironment)
	
	def setup_spider()
		spiderParamsArray = (@environment.paramString).split("$")
		arrayLength = spiderParamsArray.length
		
		@startPage = "/"
		@depth = 4
		@takeScreenshots = true
		@linksFilteringRulesArray = []
		@masterVisitedURLsList = []
		@pagesVisitedCounter = 0
		
		intCounter = 1
		while(intCounter < arrayLength)
			if(not ((spiderParamsArray[intCounter])["startpage"]).nil?)
				@startPage = ((spiderParamsArray[intCounter]).split("~"))[1]
			elsif(not ((spiderParamsArray[intCounter])["depth"]).nil?)
				@depth = (((spiderParamsArray[intCounter]).split("~"))[1]).to_i
			elsif(not ((spiderParamsArray[intCounter])["takescreenshots"]).nil?)
				value = ((spiderParamsArray[intCounter]).split("~"))[1]
				
				case(value)
					when "true"
						@takeScreenshots = true
					when "false"
						@takeScreenshots = false
				end # End: case(value)
			elsif(not ((spiderParamsArray[intCounter])["excludeif"]).nil?)
				value = ((spiderParamsArray[intCounter]).split("~"))[1]
				
				@linksFilteringRulesArray = value.split(",")
			end # End: if(not ((spiderParamsArray[intCounter])["startpage"]).nil?)
			
			intCounter = intCounter + 1
		end # End: while(intCounter < arrayLength)
		
		@screenshotFolderName = "spider_ie_1_screenshots" + Adanna::Reporting::Logger.create_timestamp
		if(not File.exist?(@screenshotFolderName))
			Dir.mkdir(@screenshotFolderName)
		end # End: if(not File.exist?(@screenshotFolderName))
	end # End: def setup_bot()
	
	def clean_up_spider()
		@watirBrowser.close
	end # End: def clean_up_spider()
	
	def take_screenshot()
		# Create screenshot file name
		strTitle = @watirBrowser.watir.title
		
		# Replace invalid characters with underscores
		while not strTitle[":"].nil? or not strTitle["/"].nil? or not strTitle["#"].nil? or not strTitle[","].nil?
			strTitle = strTitle.sub(":", "_") # Get rid of : characters
			strTitle = strTitle.sub("/", "_") # Get rid of / characters
			strTitle = strTitle.sub("#", "_") # Get rid of # characters
			strTitle = strTitle.sub(",", "_") # Get rid of , characters
		end # End: while not strTitle[":"].nil?
		
		# Truncate file name to 100 characters if longer
		if strTitle.length > 100
			strTemp = strTitle[0..99]
			strTitle = strTemp
		end # End: if strTemp.length > 100
		
		screenshotFilename = strTitle + "_" + Time.now.to_i.to_s + "_level_" + @currentLevel.to_s # Take a screenshot of the page and save it in a file
		# Create string to execute in the shell
		strScreenshotString = "SaveScreenshot.exe \"" + @screenshotFolderName + "/" + screenshotFilename + ".jpeg\" " + "window " + (@watirBrowser.watir.ie.hwnd).to_s + " JPEG"
		# Execute strScreenshotString
		system(strScreenshotString)
		
		return screenshotFilename + ".jpeg"
	end # End: def take_screenshot()
	
	def get_all_relevant_links()
		links = @watirBrowser.watir.links
		relevantLinksArray = Array.new
		
		links.each {
			|l| nextLink = l
			
			addLink = true
			@linksFilteringRulesArray.each {
				|lfr| rule = lfr
				
				ruleComponents = rule.split(":")
				case(ruleComponents[0])
					when "id"
						if(not (((nextLink.id).to_s)[(ruleComponents[1])].nil?))
							addLink = false
						end # End: if(not (((nextLink.id).to_s)[(ruleComponents[1])]).nil?)
					when "class_name"
						if(not (((nextLink.class_name).to_s)[(ruleComponents[1])].nil?))
							addLink = false
						end # End: if(not (((nextLink.id).to_s)[(ruleComponents[1])]).nil?)
					when "href"
						if(not (((nextLink.href).to_s)[(ruleComponents[1])].nil?))
							addLink = false
						elsif((nextLink.href).empty?)
							addLink = false
						end # End: if(not (((nextLink.id).to_s)[(ruleComponents[1])]).nil?)
					when "src"
						#puts "src: " + (nextLink.src).to_s + " " + ruleComponents[1]
						if(not (((nextLink.src).to_s)[(ruleComponents[1])].nil?))
							addLink = false
						end # End: if(not (((nextLink.id).to_s)[(ruleComponents[1])]).nil?)
					when "text"
						if(not (((nextLink.innerText).to_s)[(ruleComponents[1])].nil?))
							addLink = false
						end # End: if(not (((nextLink.id).to_s)[(ruleComponents[1])]).nil?)
				end # End: case(ruleComponents)
				sleep(0.01)
			}
							
			if(not ((nextLink.href)["www.vehix.com/Default.aspx"]).nil?)
				addLink = false
			end # End: if(not ((nextLink.href)["www.vehix.com/Default.aspx"]).nil?)
			
			if(addLink)
				#####DEBUG##### puts "Link: " + nextLink.to_s
				relevantLinksArray << nextLink
			end # End: if(addLink)
			sleep(0.01)
		}
		
		relevantLinksArray.uniq!
		
		return relevantLinksArray
	end # End: def get_all_relevant_links()
	
	#***********************************************************************
	# This method is used to send an Internal Error Report when an error
	# page is found by Spider.
	#
	# @author Nathan Lane
	# Last Updated: 11/29/2006
	#***********************************************************************
	def transact_error_page()
		# Setup variables to be used in the form
		strEmail = "QA TESTING QA"
		strZipCode = "TEST"
		strComments = ""
		
		# Get the server name and build number
		strComments = @watirBrowser.watir.div(:id, "applicationInformationPanel").innerText
		# Go to the error feedback form
		@watirBrowser.watir.link(:id, "HelpDeskLink").click
		# Fill out the form and submit it
		@watirBrowser.watir.textField(:id, "ctl00_ErrorDescriptionPlaceHolder_EMailBox").set strEmail
		@watirBrowser.watir.textField(:id, "ctl00_ErrorDescriptionPlaceHolder_postalcode").set strZipCode
		@watirBrowser.watir.textField(:id, "ctl00_ErrorDescriptionPlaceHolder_FeedbackBox").set strComments
		@watirBrowser.watir.button(:id, "ctl00_ErrorDescriptionPlaceHolder_SubmitButton").click
	end # End: def voidTransactErrorPage()

	def recurse_site()
		if(@currentLevel < @depth and (@linksArrayCollection[@currentLevel]).length > 0)			
			if(@linksTraversedForLevel[@currentLevel] < (@linksArrayCollection[@currentLevel]).length)
				@lastURLForLevel[@currentLevel] = @watirBrowser.watir.url
				
				((@linksArrayCollection[@currentLevel])[(@linksTraversedForLevel[@currentLevel])]).flash
				((@linksArrayCollection[@currentLevel])[(@linksTraversedForLevel[@currentLevel])]).click
				@linksTraversedForLevel[@currentLevel] = @linksTraversedForLevel[@currentLevel] + 1
				@logger.log("Spider: Links traversed " + @linksTraversedForLevel.inspect + " " + ((@linksArrayCollection[@currentLevel]).length).to_s + " L" + @currentLevel.to_s, PASS)
				
				@currentLevel = @currentLevel + 1
				if(@masterVisitedURLsList.inspect[@watirBrowser.watir.url].nil?)
					
					sleep(1)
					
					# Check to see if the page is an error page
					if @watirBrowser.watir.image(:alt, "error").exists?
						@logger.log("Spider: Found an error page", FAIL)					
						transact_error_page
						@currentLevel = @currentLevel - 1
						@logger.log("Spider: oing Back to " + @currentLevel.to_s, PASS)
						@watirBrowser.watir.goto(@lastURLForLevel[@currentLevel])
						recurse_site
					else
						@logger.log("Spider: No error page was found", PASS)
					end # End: if $objWatirBrowser.image(:alt, "error").exists?
					
					# Here's when I know that the page is a good one and that I should include it in my array
					@pagesVisitedCounter = @pagesVisitedCounter + 1				
					
					if(@pagesVisitedCounter > 0)
						@masterVisitedURLsList << @watirBrowser.watir.url # Add current URL to master visited URLs list
						@logger.log("Spider: Added " + @masterVisitedURLsList[(@masterVisitedURLsList.length - 1)].to_s + " to master visited URLs list", DONE)
					end # End: if(@currentLevel > 0 and @linksTraversedForLevel[@currentLevel] > 0)
					
					sleep(1)
					
					if(@takeScreenshots)
						ssFileName = take_screenshot
						@logger.log("Spider: took screenshot " + ssFileName, PASS)
					end # End: if(@takeScreenshots)
					
					sleep(1)
					
					if(@currentLevel < @depth)
						@linksArrayCollection[@currentLevel] = get_all_relevant_links
						@logger.log("Spider: Links found: " + ((@linksArrayCollection[@currentLevel]).length).to_s, PASS)
						
						sleep(1)
					end # End: if(@currentLevel < @depth)
					
					recurse_site
				else # Go back and traverse the next link
					if(@currentLevel > 0)
						@currentLevel = @currentLevel - 1
						@logger.log("Spider: URL found in master list, going on to link " + @linksTraversedForLevel[@currentLevel].to_s + " on level " + @currentLevel.to_s, DONE)
						@watirBrowser.watir.goto(@lastURLForLevel[@currentLevel])
						sleep(1)
						recurse_site
					else
						puts "Error level was already 0: if(@masterVisitedURLsList.inspect[@watirBrowser.watir.url].nil?)"
					end # End: if(@currentLevel > 0)
				end # End: if(@masterVisitedURLsList.inspect[@watirBrowser.watir.url].nil?)
			else # Finished with one level, so go back a try the next level
				if(@currentLevel > 0)
					@linksTraversedForLevel[@currentLevel] = 0
					@currentLevel = @currentLevel - 1
					@logger.log("Spider: Going Back to " + @currentLevel.to_s, PASS)
					@watirBrowser.watir.goto(@lastURLForLevel[@currentLevel])
					sleep(1)
					
					recurse_site
				else
					puts "Error level was already 0: if(@linksTraversedForLevel[@currentLevel] < (@linksArrayCollection[currentLevel]).length)"
				end # End: if(@currentLevel > 0)
			end # End: if(@linksTraversedForLevel[@currentLevel] < (@linksArrayCollection[currentLevel]).length)
		else # Go back to last level and go to next link
			if(@currentLevel > 0)
				@currentLevel = @currentLevel - 1
				@logger.log("Spider: Going Back to " + @currentLevel.to_s, PASS)
				@watirBrowser.watir.goto(@lastURLForLevel[@currentLevel])
				sleep(1)
					
				recurse_site
			else
				puts "Error level was already 0: if(@currentLevel < @depth)"
			end # End: if(@currentLevel > 0)
		end # End: if(@currentLevel < @depth)
	end # End: def rescurse_site()
	
	def run_spider()
		@linksArrayCollection = Array.new(@depth)
		@lastURLForLevel = Array.new(@depth)
		@linksTraversedForLevel = Array.new(@depth)
		@currentLevel = 0
		
		@logger.log("Spider: set up spider with startPage='" + @startPage.to_s + "'; depth=" + @depth.to_s + "; takeScreenshots=" + @takeScreenshots.to_s + "; linksFilteringRulesArray=" + @linksFilteringRulesArray.inspect, DONE)
		
		begin
			@watirBrowser = WatirBrowser.new
			@logger.log("Spider: Running the TestSpider.rb script", PASS)
			@watirBrowser.set_with_home(false, false, 0, 0, 1024, 990, (@environment.environmentHome + @startPage))
			@logger.log("Spider: Successfully browsed to starting page: " + (@environment.environmentHome + @startPage), PASS)
			
			# Check to see if the page is an error page
			if @watirBrowser.watir.image(:alt, "error").exists?
				@logger.log("Spider: Found an error page", FAIL)					
				transact_error_page
			else
				@logger.log("Spider: No error page was found", PASS)
				
				@linksArrayCollection[@currentLevel] = get_all_relevant_links
				@logger.log("Spider: Links found: " + ((@linksArrayCollection[@currentLevel]).length).to_s, PASS)
				if(@takeScreenshots)
					ssFileName = take_screenshot
					@logger.log("Spider: took screenshot " + ssFileName, PASS)
				end # End: if(@takeScreenshots)
				
				@linksTraversedForLevel.fill(0)
				
				recurse_site
			end # End: if $objWatirBrowser.image(:alt, "error").exists?
		rescue => ex
			#@agentState = FAIL
		ensure
			clean_up_spider
		end
	end # End: def run_spider()
	
end # End: class Spider
