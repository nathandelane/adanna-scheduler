#***********************************************************************
# Adanna Bot: http_spider_basic.rb
#
# This spider undertakes the task of going through all http-based links
# on the site in order to find broken links, images, 404 errors, etc.
#
# Created by: Nathan Lane
# Last Updated: 05/15/2007
#***********************************************************************

require "libadanna"

include Adanna::Reporting
include Adanna::Agents
include Adanna::Browser

require "net/http"

class Spider < AgentBase
	
	def initialize(objAdannaLogger, objEnvironment)
		super(objAdannaLogger, objEnvironment)
		
		@logger = objAdannaLogger
		@environment = objEnvironment
		@agentState = PASS
		@agentMessages = ""
		@debug = false
		
		@hrefsArray = [ "/" ]
		@levelMax = 4
		
		setup_spider
	end # End: def initialize(objAdannaLogger, objEnvironment)
	
	def setup_spider()
		arguments = (@environment.paramString).split("$")
		
		intCounter = 0
		while(intCounter < arguments.length)				
			puts arguments[intCounter]
			if(not (arguments[intCounter])["path"].nil?)
				@hrefsArray = [ (arguments[intCounter]).split("=")[1] ]
			elsif(not (arguments[intCounter])["depth"].nil?)
				@levelMax = ((arguments[intCounter]).split("=")[1]).to_i
			end # End: if(not (arguments[intCounter])[""].nil?)
			
			intCounter = intCounter + 1
		end # End: while(intCounter < arguments.length)
	end # End: def setup_bot()
	
	def clean_up_spider()
		# Do nothing for this spider
	end # End: def clean_up_spider()
	
	def browse_to_link(linkHref)
		@http = Net::HTTP.new(@environment.environmentHome)
		headResp = nil
		data = ""
		
		if(@debug)
			@logger.log("Spider: Browsing to: " + linkHref.to_s, DONE)
		end # End: if(@debug)
		
		intTries = 0
		begin
			headResp, data = @http.head(linkHref, @header)
			if(@debug)
				@logger.log("Spider: Got " + headResp.code + " for " + linkHref, DONE)
			end # End: if(@debug)
			
			if(not headResp["set-cookie"].nil?)
				@cookie = headResp["set-cookie"]
			end # End: if(not headResp["set-cookie"].nil?)
			
			if(@debug)
				@logger.log("Spider: Setting cookie: " + @cookie.to_s, DONE)
			end # End: if(@debug)
			@header = { "Cookie" => @cookie, "Referer" => headerSocket + @environment.environmentHome }
			
			if(headResp.code =~ /40(0|3|4){1}/)
				@logger.log("Spider: Error occurred: " + headResp.code.to_s + " Body: " + headResp.body.to_s + " URL: " + linkHref, FAIL)
			end # End: if(headResp.code == "400")
			
			intTries = intTries + 1
		end until(headResp.code == "200" or intTries == 5)
		
		if(@debug)
			@logger.log("Spider: Got 200 code for " + linkHref + ". GETting HTML for page", PASS)
		end # End: if(@debug)
		
		resp, data = @http.get(linkHref, @header)
		if(@debug)
			@logger.log("Spider: Got HTML for page", PASS)
		end # End: if(@debug)
		
		return [ resp, data ]
	end # End: def browse_to_link()
	
	def get_all_links(strHTML, strCurrentUrl)
		links = Array.new
		
		bodySlice = nil
		bodySlice = strHTML.slice(/(<body>)[\s<>A-Za-z=".\?\d&;:_\-!\$\/\+'\(\),{}\[\]\^\\!%\|#]*/)
		
		if(not bodySlice.nil?)
			#puts "Body length: " + bodySlice.length.to_s
			offset = 0
			while(not (nextLinkBegin = bodySlice.index(/(<a)/, offset)).nil?)
				if(not (nextLinkEnd = bodySlice.index(/(<\/a>)/, offset)).nil?)
					strLink = bodySlice.slice(nextLinkBegin, (nextLinkEnd - nextLinkBegin + 4))
					
					if(strLink["http"].nil? and strLink["/"].nil?)
						basePath = strCurrentUrl
						currentLinkComponents = ""
						if(strCurrentUrl["http://"])
							basePath = strCurrentUrl.split("http://")
							currentLinkComponents = basePath[1].split("/")
						else
							currentLinkComponents = basePath.split("/")
						end # End: if(strCurrentUrl["http://"])
						
						intCounter = 0
						strPath = ""
						while(intCounter < (currentLinkComponents.length - 1))
							strPath = strPath + "/" + currentLinkComponents[intCounter]
							intCounter = intCounter + 1
						end # End: while(intCounter < (currentLinkComponents.length - 1))
						
						links << strPath + "/" + strLink
					else
						links << strLink
					end # End: if(strLink["http"].nil?)
					
					offset = (nextLinkEnd + 4)
				else
					offset = (nextLinkBegin + 4)
				end # End: if(not (nextLinkEnd = bodySlice.index(/(<\/a>)/, offset)).nil?)
			end # End: while((nextLinkBegin = bodySlice.index("(<a){1}")) > -1)
		end # End: if(not bodySlice.nil?)
		
		return links
	end # End: def get_all_links(strHTML)
	
	def extract_hrefs(links)
		hrefs = Array.new
		
		intCounter = 0
		while(intCounter < links.length)
			rawHref = links[intCounter].slice(/(href="){1}[<>A-Za-z=.\?\d&;:_\-!\$\/\+'\(\),{}\[\]\^\\!%\|#]*("){1}/)
			if(not rawHref.nil?)
				len = rawHref.length - ("href=\"".length + 1)
				actualHref = rawHref.slice("href=\"".length, len)
				hrefs << actualHref
			end # End: if(not rawHref.nil?)
			
			intCounter = intCounter + 1
		end # End: while(intCounter < links.length)
		
		return hrefs
	end # End: def extract_hrefs(links)
	
	def get_server_info(strResponseHash)
		strServerName = "[servername]"
		
		strServerName = strResponseHash["server"]
		
		return strServerName
	end # End: def get_server_info(strHTML)
	
	def check_for_error_page(strUrl, objResponse, strData)
		errorPageFound = false
		
		if(not strData["alt=\"error\""].nil?)
			errorPageFound = true
			@agentMessages = "Error page was found trying to browse to URL: " + strUrl + " on Server: " + objResponse["server"]
			@agentState = FAIL
			@logger.log("Error page was found trying to browse to URL: " + strUrl + " on Server: " + objResponse["server"], FAIL)
		end # End: if(not strData[""].nil?)
		
		return errorPageFound
	end # End: def check_for_error_page(strUrl, objResponse, strData)
	
	def remove_duplicate_urls(oldUrlArray, newUrlArray)
		returnArray = newUrlArray
		
		intCounter = 0
		intDelCounter = 0
		newUrlArray.each {
			|newUrl| nextUrl = newUrl
			
			oldUrlArray.each {
				|oldUrl| nextOldUrl = oldUrl
				
				if(nextOldUrl == nextUrl)
					returnArray.delete(intCounter)
				else
					intDelCounter = intDelCounter + 1
				end # End: if(nextOldUrl == nextUrl)
			}
			
			intCounter = intCounter + 1
		}
		
		return returnArray
	end # End: def remove_duplicate_urls(oldUrlArray, newUrlArray)
	
	def spider_site(currentLevel, urlArray, oldUrlArray)
		localURLArray = Array.new
		intUrlArrayLen = urlArray.length
		
		@logger.log("Current spider depth is " + currentLevel.to_s, DONE)
		urlArray = remove_duplicate_urls(oldUrlArray, urlArray)
		intFilteredUrlArrayLen = urlArray.length
		@logger.log("Using " + intFilteredUrlArrayLen.to_s + "/" + intUrlArrayLen.to_s + " collected links", DONE)
		
		urlCounter = 1
		urlArray.uniq!
		urlArray.each {
			|nextHref| url = nextHref
			
			currentStep = "begin"
			begin
				if(url["javascript"].nil? and url["doubleclick"].nil? and url["#"].nil?)
					currentStep = "browse_to_link=" + url
					response, data = browse_to_link(url)
					currentStep = "check_for_error_page"
					if(check_for_error_page(url, response, data))
						# Not sure if I really want to exit her or what
					else
						if(not data.nil?)
							currentStep = "get_server_info"
							serverInfo = get_server_info(response)
							@logger.log(urlCounter.to_s + " > Level: " + currentLevel.to_s + "; Reponse code: " + response.code + " for: " + url + " on " + serverInfo, PASS)
							currentStep = "get_all_links"
							linksArray = get_all_links(data, url)
							@logger.log("Level: " + currentLevel.to_s + "; " + linksArray.length.to_s + " links found for: " + url, PASS)
							currentStep = "extract_hrefs"
							localURLArray = localURLArray + extract_hrefs(linksArray)
							localURLArray.uniq!
							@logger.log("Level: " + currentLevel.to_s + "; " + localURLArray.length.to_s + " hrefs found so far", PASS)
						else
							@logger.log("Level: " + currentLevel.to_s + "; Data for" + url + " was nil", FAIL)
						end # End: if(not data.nil?)
					end # End: if(check_for_error_page(url, response, data))					
				end # End: if(url["javascript"].nil?)
			rescue => ex
				@logger.log("Error occurred on Step: " + currentStep + " Message: " + ex.to_s + " Backtrace: " + ex.backtrace.inspect, FAIL)
			end
			
			urlCounter = urlCounter + 1
			sleep(0.2)
		}
		
		if(not currentLevel == @levelMax)
			spider_site(currentLevel + 1, localURLArray, urlArray)
		end # End: if(not currentLevel == @levelMax)
	end # End: def spider_site(currentLevel, urlArray, oldUrlArray)
	
	def run_spider()
		begin
			@logger.log("Spider: Running the HTTP_Spider_Basic.rb script", DONE)
			@logger.log("Spider: Starting path = " + @hrefsArray[0], DONE)
			@logger.log("Spider: Spider depth = " + @levelMax.to_s, DONE)
			
			spider_site(0, @hrefsArray, Array.new)
			
			@agentState = PASS
		ensure
			clean_up_spider
		end
	end # End: def run_spider()
	
end # End: class Spider
