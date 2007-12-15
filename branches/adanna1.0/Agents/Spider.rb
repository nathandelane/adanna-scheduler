#***********************************************************************
# This test collects all of the links on a particular  page, browses  to 
# them and then back, and does this going four  levels  of  links  deep.  
# This excludes any  links that are  associated with menus, images (such 
# as submit buttons for forms), and breadcrumbs. I limited these because 
# these types of links in  particular are problematic as I will describe 
# below.
#
# Problematic links on pages:
# JavaScript  links  that  affect  on  page  objects  - these  links are 
#  problematic for this spider at this  time  as I  am  only looking for 
#  links that will cause new pages  to  be  loaded  into the browser. So
#  far I haven't discovered a way  to  perfectly filter out these links,
#  so for the previous versions of this, many of those links continue to
#  be clicked on.
# Menu links - in a recursive method, levels of  recursion must be  met, 
#  however we log page loads that are exactly the same in consecutive as
#  a single page load in  the browser  back  button  history, so  if  we 
#  traverse the same link  four  times, then click the back button once, 
#  then we'll return to the page where  the link was originally. because 
#  the menu links are all exactly the same on every  page, we experience 
#  this problem.
# Images (such as submit buttons for forms) - these links cause problems 
#  because specific data related to the form needs to be set before they 
#  can  be  used, otherwise an error dialog pops up stating that we need  
#  to enter that data.  For this particular test  those  links  are  not
#  traversed, simply because  entering  data  is beyond  the  scope.  Of 
#  course other image links will be excluded at this time as well, which
#  may limit our results somewhat, but  it  is  believed  that  for this 
#  test, the scope should be limited.
# Breadcrumbs - these links  cause  the  same  problem  as  Menu  links, 
#  especially since the  algorithm  used,  clicks  on  links  in  order, 
#  starting with the first or 0th link, which is always the same,  home, 
#  when we allow breadcrumb links to be used.
#
# Change Notes:
# 12-11-2006 16.00PM - Added method to click on modal  dialogs  if  they
# exist.
#
# 12-04-2006 11.55AM - Added commandline options to use certain javascr-
# ipt links and certain  image  links.  Also  fixed  link  filtering  to
# correctly filter links out.
#
# 11-30-2006 15.19PM - Fixed system to not append zip code  and  default
# web app to URL automatically, but rather to check whether it is needed
# first.
#
# 11-30-2006 08.37AM - Added a brief method to  print  out  and  log the
# current version and the last updated date.
#
# 11-29-2006 16.39PM - Added block to check  for  an  error  page, and a 
# method to transact the error page, should it find one.
#
# 11-27-2006 09.44AM - Added commandline options for browser window size
# and a call to create a report based on the results of the  latest  run 
# after the test completes.
#
# 11-22-2006 14.00PM -  Fixed  getRelevantLinks  to  filter  out  footer
# links.
#
# 11-21-2006 12.31AM - Changed commandline arguments  to  GNU  standard.
# Added method to read links from a file instead of recursing the links.
#
# 11-20-2006 08.47AM - Added a method to record all of the links  to  be
# browsed to in a separate file.
#
# 11-15-2006 12.41PM - Added one more character  that  causes  problems.
#
# 11-15-2006 08.15AM - Added some more  characters to  remove  from  the
# filename of a screenshot before sending it to  the  screenshot  making
# program.
#
# 11-14-2006 12.15PM - Resolved an order of operations issue that was in
# the recursive method.  I used the total  entries from  the  unscrubbed
# array of links and compared it to the total number  of scrubbed  links
# in the array.  That's why I was getting 200  null  pointer exceptions.
# But it's fixed now, so I also removed error handling  code  pertaining
# to the problem.
#
# 11-13-2006 07.48AM - Removed outside/global  error  handling  so  that 
# hopefully the Spider will continue further without error.
#
# 11-09-2006 12.48PM - Added some more error checking - I'm now checking
# for a benchmark format error and making sure that I still get as  much
# of  the  benchmark  as   possible.   I   reported  my  other  problems
# descriptively on Open QA in the Watir forum, but even Brett, the Watir
# creator couldn't get anything out of it.  So hopefully I can.
#
# 11-08-2006 13.47PM - Added ability  to  switch  whether  we  click  or
# browse to links that are collected to the command line parameters.  It
# is not yet completely implemented however.  Also added  help  for  the
# command line parameters by setting  the  firest  parameter  to  either
# "help", "h", or "?"
#
# 11-07-2006 15.49PM - Changed line 253 to check for empty? on the array
# instead of length == 0
#
# 11-07-2006 12.38PM - Added a little message to tell us how far through
# the array of links we've gone for a particular level.
#
# 11-07-2006 12.34PM - Added  checking  to  try  and  ensure  that  null
# "arrays" aren't added to the main array.  Hopefully this  works  as  I
# think it should!
#
# 11-07-2006 12.24PM - Added ability to filter out color swatch  images,
# because they show up as errors in the log since they  aren't preloaded
# with the page.
#
# 11-07-2006 10.01AM - Changed on screen logging format in  order to  be 
# more readable.
#
# 11-07-2006 08.34AM -  Added  filtering  for any  link  that  does  not
# contain "vehix" in it.
#
# 11-07-2006 07.41AM - Added ability to take three parameters specifying 
# whether of not to check all images, take screenshots always, never, or
# only on error pages, and how many levels deep to recurse, as  well  as
# filtering out of links that contain '@' symbols.
#
# 11-06-2006 10.49AM - Refactored  Spider   to  use  vehix.com  library.
# Rewrote  recurseLinks   method.  Reimplemented  screenshot  method  as
# separate  procedure.  Added  method  to  gather correct  links into an
# array.
#
# 11-06-2006 06.16AM - Removed recursive method and  began replacing  it
# with a new recursion method that will grab  all links  first and  then 
# browse to them rather than clicking on them.
#
# 11-03-2006 13.21PM - Changed the wording on the recursion back through
# levels to "Recursing back to level" so that it isn't confused  by  the 
# link checking part of the recursion algorithm  in  the  log.  And made 
# Spider independent on web  application  functionality  - it  bookmarks 
# each level and uses that to recurse back to specific levels.
#
# 11-03-2006 13.09PM - I added a feature to the image checking algorithm 
# (voidCheckAllImages) to ensure that if  the image  contains  the  text 
# "statsomni", which refers to a false image injected by  omniture, that 
# image is not  checked to see if it was downloaded  or  not.  This  has
# caused false negatives in the recent past.
#
# 11-03-2006 12.43PM - I completed an algorithm to check all images on a
# page to see if they were loaded by checking  their fileSize  attribute.  
# If this attribute returns -1, then  the  image  was  not  found on the
# server and was therefore not downloaded.  These are then  recorded  as 
# errors   in   the   log.   I   also   added    this   algorithm     as  
# voidCheckAllImages  in Spider.rb.
#
# @author Nathan Lane
# Last Updated: 12/11/2006
#***********************************************************************

# Includes
require "vehix.com"

include Vehix
include VehixConsumerPortal
include SI_NewUsedAdvanced

$intMaxLevels = 4 # The default number of maximum levels that should be recursed
# The folowing array will contain all of the links for a given level
$objLinkArraysArray = Array.new($intMaxLevels)

# The following are treated as parameters given at the command line
# Get the base directory
tempDir = Dir.getwd
Dir.chdir("..")
$strLinksFileDir = Dir.getwd
Dir.chdir(tempDir)
# Finish getting base directory
$strLinksFileToBeRead = nil
$strTakeScreenshots = "a"
$strZipCode = "" # Must be an empty string an not nil
$intNumberOfLevels = 4
$intBrowserWidth = 1024
$intBrowserHeight = 990
$blnClickOnLinks = false
$blnCheckForAllImages = true
$blnSendInternalErrors = false
$blnAddJavaScriptLinks = false
$blnUseImageLinks = false

# This is a file for links - I'm just dumping the actual link arrays into the file for each level, but it is unformatted
$objLinksFile = File.new("linksToBeVisited.txt", "w+")

#***********************************************************************
# This procedure looks at all of the images on the site and logs any
# that appear to have not downloaded.
#
# @author Nathan Lane
# Last Updated: 11/03/2006
#***********************************************************************
def blnCheckAllImages()
	retVal = false # There are no erroneous images by default

	intLastImageError = -1
	objAllImagesOnPageArray = $objWatirBrowser.images # Get all of the images on the page
	log($INFO, "Current URL: " + $objWatirBrowser.url, 2) # Log the current URL
	log($INFO, "Total number of images on this page = " + objAllImagesOnPageArray.length.to_s, 2) # Log the number of images on this page
	
	intCounter = 0 # initialize a counter
	objAllImagesOnPageArray.each { # Check each image in the array
		|img| testImg = img # Get the next image
		
		# Test to see if images was downloaded, -1 for file size means it wasn't
		strFileSize = testImg.fileSize
		intFileSize = strFileSize.to_i
		# Make sure the image wasn't injected by omniture, and that we're on one of our own "Vehix" pages, and that we don't check color swatches
		if testImg.src.to_s["omni"].nil? and not $objWatirBrowser.url["vehix"].nil? and testImg.src.to_s["color"].nil? and testImg.src["pointroll"].nil? and testImg.src["doubleclick"].nil? and not testImg.src.nil? and not testImg.src == ""
			if  intFileSize == -1
				strImageDescription = testImg.src.to_s # Get the string version of the test image
				log($DEBUG, "E\n", 2) # Just to make sure that the log item is on its own line
				log($ERROR, "Image was not present in web page: " + strImageDescription, 2)
				intLastImageError = intCounter
				begin
					testImg.focus # Try to bring image into focus so that the screenshot contains it
				rescue
					log($ERROR, "Could not bring image into focus: " + strImageDescription, 2)
					retVal = true # Set to true, because there was an error
				end
			else
				#log($INFO, "Image found in web page: Image[" + intCounter.to_s + "]", 2)
				log($DEBUG, ".", 2) # Print a consecutive dot for every image found
			end
		end # End: if testImg.src.to_s["statsomni"].nil?
		
		#Increment intCounter
		intCounter = intCounter + 1
	}
	log($DEBUG, "|\n", 2) # Print a '|' with a new line
	log($INFO, "Last erroneous image (-1 if none): " + intLastImageError.to_s, 2) # Log the last erroneous image
	
	return retVal # Return whether there was an error or not
end # End: def voidCheckAllImages()

#***********************************************************************
# This procedure takes a screenshot and stores it in the current 
# directory
#
# @author Nathan Lane
# Last Updated: 11/06/2006
#***********************************************************************
def voidTakeScreenshot(intCurrentLevel)
	# Create screenshot file name
	strTitle = $objWatirBrowser.title
	
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

	screenshotFilename = "Browsed to " + strTitle + "_" + Time.now.to_i.to_s + " level " + intCurrentLevel.to_s # Take a screenshot of the page and save it in a file
	# Create string to execute in the shell
	strScreenshotString = "../SaveScreenshot2.exe \"" + "./" + screenshotFilename + "_level" + intCurrentLevel.to_s + ".jpeg\" " + "window " + ($objWatirBrowser.ie.hwnd).to_s + " JPEG"
	# Execute strScreenshotString
	system(strScreenshotString)
	log($INFO, "Stored screenshot: " + screenshotFilename, 2)
end

#***********************************************************************
# This function closes an open dialog if one is open, and returns a
# result, otherwise it just returns.
#
# @author Nathan Lane
# Last Updated: 12/11/2006
#***********************************************************************
def intCloseDialog()
	# Create an AutoIt object to use to click on open dialogs
	objAutoit = WIN32OLE.new("AutoItX3.Control")
	
	# Look for any open dialogs and close them
	ans1 = objAutoit.ControlClick("Microsoft Internet Explorer",'', 'OK')
	ans2 = objAutoit.ControlClick("Security Information",'', '&Yes')
	ans3 = objAutoit.ControlClick("Security Alert",'', '&Yes')
	
	# Release the clicker object
	objAutoit = nil
	
	return (ans1 + ans2 + ans3)
end # End: def voidCloseDialog()

#***********************************************************************
# This function gets all of the links on the page, then returns an array
# containing only the relevant links, as defined in the documentation
# listed above.
#
# @author Nathan Lane
# Last Updated: 11/06/2006
#***********************************************************************
def getRelevantLinks()
	# Create a new temporary array object that can hold all of the links on the page
	objTempArray = $objWatirBrowser.links
	
	# Filter all of the irrelevant links out
	strHrefArray = Array.new
	objTempArray.each {
		|l| tempLink = l
		
		# Make sure that the link takes us to a new page and does not affect the page it is currently on
		if (tempLink.id.to_s)["menu"].nil? and (tempLink.id.to_s)["breadcrumb"].nil? and (tempLink.id.to_s)["Footer"].nil? and (tempLink.href.to_s)["@"].nil? and (tempLink.id.to_s)["hidden"].nil?
			if $blnAddJavaScriptLinks or $blnUseImageLinks
				tempURL = "None"
				blnAddLink = false
				# Javascript link collection and filtering
				if $blnAddJavaScriptLinks and (tempLink.href.to_s)["javascript:show"].nil? and (tempLink.href.to_s)["javascript:doDealerWebsite"].nil? and not (tempLink.href.to_s)["javascript"].nil? and (tempLink.href.to_s)["javascript:doShowInventory"].nil?
					bookmarkURL = $objWatirBrowser.url
					# Click on the link
					tempLink.click
					# Get the current URL
					tempURL = $objWatirBrowser.url
					# Store it into the array
					blnAddLink = true
					# Go back
					$objWatirBrowser.goto(bookmarkURL)
				end # End: if $blnAddJavaScriptLinks and (tempLink.href.to_s)["javascript:show"].nil? and (tempLink.href.to_s)["javascript:doDealerWebsite"].nil? 
				
				# Image link collection and filtering
				if $blnUseImageLinks and not (tempLink.src.to_s)[".gif"].nil? and (tempLink.src.to_s)["menu"].nil? and (tempLink.src.to_s)["titlebar"].nil? and not (tempLink.id.to_s)["Submit"].nil?
					if (tempLink.id.to_s)["ctl00_ContentPlaceHolder1_VehicleSelectorSR_vsSubmitButtonLink"].nil? # This seems to be a bug!
						bookmarkURL = $objWatirBrowser.url
						# Click on the link
						tempLink.click
						# Get the current URL
						tempURL = $objWatirBrowser.url
						# Store it into the array
						blnAddLink = true
						# Go back
						$objWatirBrowser.goto(bookmarkURL)
					end # End: if (tempLink.id.to_s)["ctl00_ContentPlaceHolder1_VehicleSelectorSR_vsSubmitButtonLink"].nil?
				end # End: if $blnUseImageLinks and not (tempLink.src.to_s)[".gif"].nil?
				
				# Add the link or not
				if blnAddLink
					strHrefArray << tempURL
				else
				end # End: if blnAddLink
			end # End: if $blnAddJavaScriptLinks or $blnUseImageLinks
			
			# This is used if $blnAddJavaScriptLinks and $blnUseImageLinks are not set to true, then we filter out all javascript and image links, and links that don't contain vehix in the href
			if (tempLink.href.to_s)["javascript"].nil? and not (tempLink.href.to_s).empty? and not (tempLink.href.to_s)["vehix"].nil?
				if (tempLink.src.to_s)[".gif"].nil?
					strHrefArray << tempLink.href.to_s
				end # End: if (tempLink.src.to_s)[".gif"].nil?
				
				if not (tempLink.src.to_s)["vehicleIcons"].nil?
					strHrefArray << tempLink.href.to_s
				end # End: if not (tempLink.src.to_s)["vehicleIcons"].nil?
			end # End: if (tempLink.href.to_s)["javascript"].nil? and (tempLink.src.to_s)[".gif"].nil?
		else
			#puts "Did not add: " + tempLink.href + " src=" + tempLink.src.to_s + " id=" + tempLink.id.to_s
			
			#puts "(tempLink.id.to_s)[\"menu\"].nil? = " + (tempLink.id.to_s)["menu"].nil?.to_s
			#puts "(tempLink.id.to_s)[\"breadcrumb\"].nil? = " + (tempLink.id.to_s)["breadcrumb"].nil?.to_s
			#puts "(tempLink.id.to_s)[\"Footer\"].nil? = " + (tempLink.id.to_s)["Footer"].nil?.to_s
			#puts "(tempLink.src.to_s)[\".gif\"].nil? = " + (tempLink.src.to_s)[".gif"].nil?.to_s
			#puts "not (tempLink.href.to_s).empty? = " + (not (tempLink.href.to_s).empty?).to_s
			#puts "(tempLink.href.to_s)[\"@\"].nil? = " + (tempLink.href.to_s)["@"].nil?.to_s
			#puts "(tempLink.href.to_s)[\"javascript:show\"].nil? = " + (not (tempLink.href.to_s)["javascript:show"].nil?).to_s
		end # End: if (tempLink.id.to_s)["menu"].nil? and (tempLink.id.to_s)["breadcrumb"].nil? and (tempLink.id.to_s)["Footer"].nil? and (tempLink.src.to_s)[".gif"].nil? and not (tempLink.href.to_s).empty? and (tempLink.href.to_s)["@"].nil? and (tempLink.id.to_s)["hidden"].nil
	}

	log($INFO, "Added " + strHrefArray.length.to_s + " links to strHrefArray.", 2)
	
	# Return the local href array
	return strHrefArray
end # End: def getRelevantLinks()

#***********************************************************************
# This method simply records all of the links for the current level into
# the links file created above
#
# @param Array objLinksArray Array containing textual urls
# @author Nathan Lane
# Last Updated: 11/20/2006
#***********************************************************************
def voidDropLinksIntoFile(objLinksArray)
	# Make sure that objLinksArray is a valid array
	if objLinksArray.class == Array
		# Drop each link into objLinksFile
		objLinksArray.each {
			|l| nextLink = l
			
			# Put the url into the file - it should already be a string
			$objLinksFile.puts(nextLink)
		} # End: objLinksArray.each {
	end # End: if objLinksArray.class == Array
end # End: def voidDropLinksIntoFile(objLinksArray)

#***********************************************************************
# This method is used to send an Internal Error Report when an error
# page is found by Spider.
#
# @author Nathan Lane
# Last Updated: 11/29/2006
#***********************************************************************
def voidTransactErrorPage()
	# Setup variables to be used in the form
	strEmail = "QA TESTING QA"
	strZipCode = "TEST"
	strComments = ""
	
	# Get the server name and build number
	strComments = $objWatirBrowser.div(:id, "applicationInformationPanel").innerText
	# Go to the error feedback form
	$objWatirBrowser.link(:id, "HelpDeskLink").click
	# Fill out the form and submit it
	$objWatirBrowser.textField(:id, "ctl00_ErrorDescriptionPlaceHolder_EMailBox").set strEmail
	$objWatirBrowser.textField(:id, "ctl00_ErrorDescriptionPlaceHolder_postalcode").set strZipCode
	$objWatirBrowser.textField(:id, "ctl00_ErrorDescriptionPlaceHolder_FeedbackBox").set strComments
	$objWatirBrowser.button(:id, "ctl00_ErrorDescriptionPlaceHolder_SubmitButton").click
end # End: def voidTransactErrorPage()

#***********************************************************************
# This function recurses through all pages linked to by normal links on
# a linked page, and collects all of the normal links it can find into
# an array.  Then it browses to each of those normal links and takes
# screenshots of the pages.
#
# @author Nathan Lane
# Last Updated: 10/21/2006
#***********************************************************************
def recurseLinks(intCurrentLevel)
	blnImageError = false # Set to false by default

	objLocalArray = nil # Initialize array as nil

	log($INFO, "Current level = " + intCurrentLevel.to_s, 0)
	# If the current level is beyond the defined $intMaxLevels, return false
	if intCurrentLevel > $intMaxLevels
		return false
	else	
		# If the level is greater than 1, then we need to create multiple arrays
		if intCurrentLevel > 1
			# Create new level array to contain links from all levels
			objBrowseArray = $objLinkArraysArray[intCurrentLevel - 2]
			if objBrowseArray.length > 0 # If this array has no elements, then an error occurs
				# Sort array and remove duplicate entries
				objBrowseArray.sort! # Sort self
				objBrowseArray.uniq! # Remove duplicates from self
				objBrowseArray.compact! # Remove any null entries
				objSubTempArray = Array.new(objBrowseArray.length)
				voidDropLinksIntoFile(objBrowseArray) # Drop the links into a file
				log($INFO, "Using " + objBrowseArray.length.to_s + " unique links from level " + (intCurrentLevel - 1).to_s + ".", 2)
				# Browse through each link in the array, and gather all of the relevant links on each page
				intCounter = 0 # Initialize intCounter to 0
				objBrowseArray.each {
					|l| strHref = l
					log($INFO, "This HREF=" + strHref, 2)
					
					# Just in case a format exception occurs, which is odd, catch it and return millisecond time for a benchmark
					floatStartTime = Time.now.to_f
					begin # Catch format exceptions and remedy them
						# Browse to the url stored in the next link
						log($INFO, "Benchmark - " + (Benchmark.measure {
							begin
								timeout(45) do
									$objWatirBrowser.goto(strHref)
								end # End: timeout(45) do
							rescue TimeoutError
								log($WARN, "It took a long time to get to this page - 45 seconds +", 2)
							end
						}).format(" %r seconds to browse to " + strHref), 2)
					rescue WIN32OLERuntimeError
						# Try and close a dialog
						if intCloseDialog > 0
							log($INFO, "Closed open dialogs - retrying browse action", 2)
						else
							log($INFO, "Tried to close open dialogs but none were open - retrying browse action", 2)
						end # End: if intCloseDialog > 0
						# Retry the execution for this iteration
						redo
					rescue => ex # Grab the exception that occurred
						floatEndTime = Time.now.to_f
						strTotalTime = (floatEndTime - floatStartTime).to_s
						log($INFO, "Benchmark error occurred", 2)
						log($INFO, "Benchmark - (" + strTotalTime + ") seconds to browse to " + strHref, 2)
						log($WARN, "line 240 - Exception => " + ex.backtrace.inspect, 2)
					end # End: begin # Catch format exceptions and remedy them
					
					# Check all images
					if $blnCheckForAllImages
						# Check all of the images on the page
						blnImageError = blnCheckAllImages
					end # End: if $blnCheckForAllImages
					
					#Take a screenshot
					if $strTakeScreenshots == "a"
						# Take a screenshot
						voidTakeScreenshot(intCurrentLevel)
					elsif $strTakeScreenshots == "e" and blnImageError
						# Take a screenshot
						voidTakeScreenshot(intCurrentLevel)
					end
					
					if $blnSendInternalErrors
						# Check to see if the page is an error page
						if $objWatirBrowser.image(:alt, "error").exists?
							voidTransactErrorPage
						end # End: if $objWatirBrowser.image(:alt, "error").exists?
					end # End: if $blnSendInternalErrors
					
					blnImageError = false # Reset blnImageError
					# Get all of the links on the next page and store them into a temporary array, then into the sub temp array
					objLocalArray = getRelevantLinks() # Get all relevant links
					objSubTempArray[intCounter] = objLocalArray # Store the temp array in the sub temp array
					log($INFO, "Stored links for page " + (intCounter + 1).to_s + "/" + objSubTempArray.length.to_s + " into objSubTempArray - gathered from level " + (intCurrentLevel - 1).to_s, 2) # Keep track of which link I'm on
					log($DEBUG, "-------------------------\n", 2)
					intCounter = intCounter + 1 # Increment the local counter
				}
				# Add the arrays store in temp sub array together
				objFinalLinkArray = objSubTempArray[0] # Add first array to final links array
				intMax = objSubTempArray.length - 1 # Get the number of arrays that were stored
				for x in 1..intMax do # Add arrays together
					xArray = objSubTempArray[x] # Get the next array
					objFinalLinkArray = objFinalLinkArray + objSubTempArray[x] # Add next array to final links array
				end # End: for x in 1..intMax do # Add arrays together
				log($INFO, "Storing " + objFinalLinkArray.length.to_s + " links from level " + intCurrentLevel.to_s + " into $objLinkArraysArray.", 2)
				$objLinkArraysArray[intCurrentLevel - 1] = objFinalLinkArray # Add final links array to the link arrays array also known as the levels array
			else
				log($INFO, "Could not continue because no links were found in the previous level that are usable", 2)
				return false
			end # End: if objBrowseArray.length > 0
		else # We are on level one, so do the same thing but not as elaborate because there is only one page
			# Check all images on level 1
			if $blnCheckForAllImages
				# Check all of the images on the page
				blnImageError = blnCheckAllImages
			end # End: if $blnCheckForAllImages
			
			# Take a screenshot of level 1
			if $strTakeScreenshots == "a"
				# Take a screenshot
				voidTakeScreenshot(intCurrentLevel)
			elsif $strTakeScreenshots == "e" and blnImageError
				# Take a screenshot
				voidTakeScreenshot(intCurrentLevel)
			end
			
			if $blnSendInternalErrors
				# Check to see if the page is an error page
				if $objWatirBrowser.image(:alt, "error").exists?
					voidTransactErrorPage
				end # End: if $objWatirBrowser.image(:alt, "error").exists?
			end # End: if $blnSendInternalErrors
			
			blnImageError = false # Reset blnImageError
			# Gather all of the links on the current page
			objLocalArray = getRelevantLinks()
			# Store current level of links into array
			$objLinkArraysArray[intCurrentLevel - 1] = objLocalArray
			log($DEBUG, "-------------------------\n", 2)
		end
		
		# Go to the next level
		if not recurseLinks(intCurrentLevel + 1)
			return false
		end
	end
end # End: def recurseLinks(intCurrentLevel)

#***********************************************************************
# This method is used to browse to each of the links found in the file,
# if one is specified.
#
# @param Boolean blnExcludeDuplicates If this is true, then we'll get
#	rid of all the duplicates first, otherwise just browse.
# @author Nathan Lane
# Last Updated: 11/20/2006
#***********************************************************************
def voidBrowseLinksInFile(blnExcludeDuplicates)
	intCurrentLevel = 0 # This implies that there are no levels
	# Set to false by default
	blnImageError = false
	# Set up an array to contain the links
	objFileLinksArray = Array.new
	
	log($INFO, "Browsing through links found in file named: " + $strLinksFileToBeRead, 2)

	strFileLocation = $strLinksFileDir + "\\" + $strLinksFileToBeRead
	# Open the file to retrieve the links!
	if File.exist?(strFileLocation)
		log($INFO, "Found file: " + strFileLocation, 2)
		log($INFO, "File size = " + File.size(strFileLocation).to_s, 2)
		# Open the file and read each line
		objLinksReadFile = File.new(strFileLocation)
		while (line = objLinksReadFile.gets)
			objFileLinksArray << line
			log($INFO, "Read line: " + line, 2)
		end # End: while (line = objLinksReadFile.gets)
		# Close file
		objLinksReadFile.close
		log($INFO, "Number of links found: " + objFileLinksArray.length.to_s, 2)
		
		# Ensure that array contains at least one link
		if objFileLinksArray.length > 0
			# Find out if we need to remove duplicates
			if blnExcludeDuplicates
				# Get rid of duplicates
				objFileLinksArray.uniq!
			end # End: if blnExcludeDuplicates
			
			# Start browsing through each link, starting with home page, which is the current page
			objFileLinksArray.each {
				|l| strHref = l
			
				# Check all images on level 1
				if $blnCheckForAllImages
					# Check all of the images on the page
					blnImageError = blnCheckAllImages
				end # End: if $blnCheckForAllImages
				
				# Take a screenshot of level 1
				if $strTakeScreenshots == "a"
					# Take a screenshot
					voidTakeScreenshot(intCurrentLevel)
				elsif $strTakeScreenshots == "e" and blnImageError
					# Take a screenshot
					voidTakeScreenshot(intCurrentLevel)
				end
				
				blnImageError = false # Reset blnImageError
				# Gather all of the links on the current page
				objLocalArray = getRelevantLinks()
				# Store links into file
				log($INFO, "Stored " + objLocalArray.length.to_s + " into links file", 2)
				voidDropLinksIntoFile(objLocalArray) # Drop the links into a file
				log($DEBUG, "-------------------------\n", 2)
				
				# Just in case a format exception occurs, which is odd, catch it and return millisecond time for a benchmark
				floatStartTime = Time.now.to_f
				begin # Catch format exceptions and remedy them
					# Browse to the url stored in the next link
					log($INFO, "Benchmark - " + (Benchmark.measure {
						begin
							timeout(45) do
								$objWatirBrowser.goto(strHref)
							end # End: timeout(45) do
						rescue TimeoutError
							log($WARN, "It took a long time to get to this page - 45 seconds +", 2)
						end
					}).format(" %r seconds to browse to " + strHref), 2)
				rescue WIN32OLERuntimeError
					# Try and close a dialog
					if intCloseDialog > 0
						log($INFO, "Closed open dialogs - retrying browse action", 2)
					else
						log($INFO, "Tried to close open dialogs but none were open - retrying browse action", 2)
					end # End: if intCloseDialog > 0
					# Retry the execution for this iteration
					redo
				rescue => ex # Grab the sception that occurred
					floatEndTime = Time.now.to_f
					strTotalTime = (floatEndTime - floatStartTime).to_s
					log($INFO, "Benchmark error occurred", 2)
					log($INFO,	"Benchmark - (" + strTotalTime + ") seconds to browse to " + strHref, 2)
					log($WARN, "line 240 - Exception => " + ex.backtrace.inspect, 2)
				end # End: begin # Catch format exceptions and remedy them
				
				if $blnSendInternalErrors
					# Check to see if the page is an error page
					if $objWatirBrowser.image(:alt, "error").exists?
						voidTransactErrorPage
					end # End: if $objWatirBrowser.image(:alt, "error").exists?
				end # End: if $blnSendInternalErrors
				
			} # End: objFileLinksArray.each {
		end # End: objFileLinksArray.each {
	else
		log($ERROR, "File could not be found: " + $strLinksFileToBeRead, 2)
	end # End: if File.exist($strLinksFileToBeRead)
end # End: def voidBrowseLinksInFile

#***********************************************************************
# This method displays the commandline help for anyone who wants to see
# it.
#
# @author Nathan Lane
# Last Updated: 11/20/2006
#***********************************************************************
def voidDisplayHelp()
	puts "\nSpider.rb [options]" +
		"\n\nOptions:" +
		"\n    --help Brings up this help listing" +
		"\n    --check-all-images=True|False To check all images" +
		"\n    --take-screenshots=n|a|e Take screenshots never, always, on error" +
		"\n    --levels=# This may be any number, 0 and 1 will always browse to the\n      first level, default=4" +
		"\n    --click-on-links=True|False <NOT YET IMPLEMENTED>" +
		"\n    --use-links-file=file name, uses none if not\n      specified" +
		"\n    --browser-width=# This must be numeric. If it is not set here, then\n      it defaults to 1024" +
		"\n    --browser-height=# This must be numeric. If it is not set here, then\n      it defaults to 990" +
		"\n    --check-for-error-pages=True|False defaults to False.  If True, then\n      error pages are transacted" +
		"\n    --zip-code=###### defaults to nothing, and should be a five-digit zip." +
		"\n    --use-javascript-links=True|False. If True adds javascript links." +
		"\n    --use-image-links=True|False. If true adds image links (ie buttons).\n" +
		"\n\n\t* In order to take screenshots on errors, --check-all-images must be\n\t  True." +
		"\n\n\t* If --levels is specified and --use-links-file is specified, the links\n\t  file takes precedence."
end # End: def voidDisplayHelp()

#***********************************************************************
# This method parses the command line and sets values appropriately or
# throws an exception and echos an error out to the log.
#
# @author Nathan Lane
# Last Updated: 11/20/2006
#***********************************************************************
def voidParseArguments()
	if ARGV.length == 1
		strTemp = ARGV[0].downcase
	end # End: if ARGV.length == 1

	if ARGV.length > 0
		commandlineArgumentsArray = ARGV # Get all of the commandline arguments
		# Go through each argument and set it appropriately
		commandlineArgumentsArray.each {
			|cla| nextArg = cla # Get next argument
			
			strNextArgSplit = nextArg.split("=") # Split the argument at the '=' sign
			if strNextArgSplit.length == 2
				strNextArgSplit[0].downcase!
				strNextArgSplit[1].downcase!
				case strNextArgSplit[0]
					when "--check-all-images"
						log($INFO, "Setting blnCheckForAllImages = " + strNextArgSplit[1], 2)
						case strNextArgSplit[1]
							when "true"
								$blnCheckForAllImages = true
								log($INFO, "Set $blnCheckForAllImages = true", 2)
							when "false"
								$blnCheckForAllImages = false
								log($INFO, "Set $blnCheckForAllImages = false", 2)
							else
						end # End: case strNextArgSplit[1]
					when "--take-screenshots"
						log($INFO, "Setting strTakeScreenshots = " + strNextArgSplit[1], 2)
						case strNextArgSplit[1]
							when "a"
								$strTakeScreenshots = "a"
								log($INFO, "Set $strTakeScreenshots = \"a\"", 2)
							when "n"
								$strTakeScreenshots = "n"
								log($INFO, "Set $strTakeScreenshots = \"n\"", 2)
							when "e"
								if $blnCheckForAllImages
									$strTakeScreenshots = "e"
									log($INFO, "Set $strTakeScreenshots = \"e\"", 2)
								end
							else
						end # End: case strNextArgSplit[1]
					when "--levels"
						log($INFO, "Setting intNumberOfLevels = " + strNextArgSplit[1], 2)
						$intNumberOfLevels = strNumberLevelsString.to_i
						log($INFO, "Set $intNumberOfLevels = " + strNumberLevelsString.to_i.to_s, 2)
					when "--click-on-links"
						log($INFO, "Setting blnClickOnLinks = " + strNextArgSplit[1], 2)
						# This isn't yet truly implemented
						case strNextArgSplit[1]
							when "true"
								#$blnClickOnLinks = true
								# Need to work through some potential problems
								$blnClickOnLinks = false
							when "false"
								$blnClickOnLinks = false
							else
						end # End: case strNextArgSplit[1]
					when "--use-links-file"
						log($INFO, "Setting strLinksFileToBeRead = " + strNextArgSplit[1], 2)
						# First get rid of the possible new-line character at the end
						strPathToLinksFile = strNextArgSplit[1].chomp
						$strLinksFileToBeRead = strPathToLinksFile
					when "--links-file-dir"
						if strNextArgSplit[1] == "."
							$strLinksFileDir = Dir.getwd # Get working directory if '.' is supplied
						else
							$strLinksFileDir = strNextArgSplit[1]
						end # End: if strNextArgSplit[1] == "."
					when "--browser-width"
						# Convert value to integer
						intWidth = strNextArgSplit[1].to_i
						if intWidth > 0
							$intBrowserWidth = intWidth
						end # End: if intWidth > 0
					when "--browser-height"
						# Convert value to integer
						intHeight = strNextArgSplit[1].to_i
						if intHeight > 0
							$intBrowserHeight = intHeight
						end # End: if intHeight > 0
					when "--check-for-error-pages"
						# Convert the value to a boolean value
						strTemp = strNextArgSplit[1].downcase
						$blnSendInternalErrors = strToBln(strTemp)
					when "--zip-code"
						# Set the zip code to this number - keep in string format
						$strZipCode = strNextArgSplit[1]
					when "--use-javascript-links"
						# Convert the value to a boolean value
						strTemp = strNextArgSplit[1].downcase
						$blnAddJavaScriptLinks = strToBln(strTemp)
					when "--use-image-links"
						# Convert the value to a boolean value
						strTemp = strNextArgSplit[1].downcase
						$blnUseImageLinks = strToBln(strTemp)
					else
						# Do nothing
						log($WARN, "Invalid argument: " + strNextArgSplit[0], 2)
						exit(1) # Exit due to an invalid argument
				end # End: case strNextArgSplit[0]
			else # Check to see if --help was entered (or 'h' or '?')
				strNextArgSplit[0].downcase!
				if nextArg == "--help" or strTemp == "h" or strTemp == "?"
					# Call help display method
					voidDisplayHelp
					exit(1) # Exit the script prematurely
				end # End: if strTemp == "help" or strTemp == "h" or strTemp == "?"
			end # End: if strNextArgSplit.length == 2
		} # End: commandlineArgumentsArray.each {
	else # When there are ZERO arguments passed, log it
		log($INFO, "Zero arguments were passed to Spider", 2)
		log($INFO, "Using defaults: --check-all-images=true --take-screenshots=a --levels=4", 2)
	end # End: if ARGV.length > 0
end # End: def voidParseArguments()

#***********************************************************************
# This function prints a string to the console stating what version it
# is, then returns.
#
# @author Nathan Lane
# Last Updated: 11/30/2006
#***********************************************************************
def voidDisplayVersion()
	strVersion = "1.0.1"
	strDateLastUpdated = "12/11/2006"
	
	log($DEBUG, "This is Spider version " + strVersion + " " + strDateLastUpdated + "\n", 2)
end # End :def voidDisplayVersion()

#*************** End function section ************************************

# Display the version and log it
voidDisplayVersion

# Parse the command line
voidParseArguments

# Benchmark this process
log($INFO, "BenchMark: " + (Benchmark.measure {
	if blnStartup($strZipCode, $intBrowserWidth, $intBrowserHeight)
	
		# Find out if a links file was specified or not
		if $strLinksFileToBeRead.nil?
			log($INFO, "Recursing links", 2)
			# Begin recursing links to gather them
			recurseLinks(1)
		else
			log($INFO, "Following links in file", 2)
			# Browse the links listed in the file
			voidBrowseLinksInFile(false)
		end # End: if $strLinksFileToBeRead.nil?
		
		sleep(3)
	end # End: if blnStartup
}).to_s, 2) # End Benchmark block

# Clean up a little
voidCleanup()
# Close links file
$objLinksFile.close

# Create batch file to easily create a report
puts "Creating batch file to easily create a report."
intLen = $currentRunFolderName.length - 2
objBatchFile = File.new("CreateReportFor_" + $currentRunFolderName[0..intLen] + ".bat", "w+")
strExecString = "SpiderReportCreator.rb --log-dir=" + $currentRunFolderName[0..intLen]
objBatchFile.puts strExecString
objBatchFile.close
# Tell the user that he can now easily create a report by running the batch file
puts "Batch file created.  You may now easily create a REPORT by running CreateReportFor_" + $currentRunFolderName[0..intLen] + ".bat.  The report will be accessible via index.html in the most recent log directory."
