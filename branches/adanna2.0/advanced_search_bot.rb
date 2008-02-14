#***********************************************************************
# Adanna Bot: advanced_search_bot.rb
#
# This is advanced search bot version 4.0.0, developed for the first
# time using Adanna version 2.0.0.  This version will use a parameter
# string to get its data, and utilize Adanna 2.0 logging features for
# failure notification.  Parameter string instructions include that the
# vehicle delimiter is '$' and that the key-value-pair delimiter is ';'
# and that the section delimiter is '?' and that the key-value delimiter
# is "=".
#
# Given the rules above a string identifying a vehicle might look like:
# $condition=CPO?bodystyle=Convertible;bodysyle=Sedan?make=Lexus?model=
# 
#
# Created by: Nathan Lane
# Last Updated: 05/10/2007
#***********************************************************************

require "libadanna"

include Adanna::Reporting
include Adanna::Agents
include Adanna::Browser

require "timeout"

include Timeout

class Bot < AgentBase
	
	PASS = "Pass"
	
	def initialize(objAdannaLogger, objEnvironment)
		super(objAdannaLogger, objEnvironment)
		
		@logger = objAdannaLogger
		@environment = objEnvironment
		@agentState = PASS
		
		setup_bot
	end # End: def initialize(objAdannaLogger, strEnvironment)
	
	def setup_bot()
		@formLibrary = Hash.new
		@formLibrary["condition_new"] = "condition_1"
		@formLibrary["condition_used"] = "condition_2"
		@formLibrary["condition_both"] = "condition_3"
		@formLibrary["condition_cpo"] = "condition_4"
		@formLibrary["year_begin"] = "yearbeg"
		@formLibrary["year_end"] = "yearend"
		@formLibrary["bodystyle_select_all"] = "allBodyStyles"
		@formLibrary["bodystyle_compact_coupe"] = "ctl00_ContentPlaceHolder1_CompactCoupeActionImage"
		@formLibrary["bodystyle_convertible"] = "ctl00_ContentPlaceHolder1_ConvertibleActionImage"
		@formLibrary["bodystyle_hybrid"] = "ctl00_ContentPlaceHolder1_HybridActionImage"
		@formLibrary["bodystyle_luxury"] = "ctl00_ContentPlaceHolder1_LuxuryActionImage"
		@formLibrary["bodystyle_mini_passenger_van"] = "ctl00_ContentPlaceHolder1_MinivanActionImage"
		@formLibrary["bodystyle_sedan"] = "ctl00_ContentPlaceHolder1_SedanActionImage"
		@formLibrary["bodystyle_sport"] = "ctl00_ContentPlaceHolder1_SportActionImage"
		@formLibrary["bodystyle_sport_utility_vehicle"] = "ctl00_ContentPlaceHolder1_SUVActionImage"
		@formLibrary["bodystyle_station_wagon"] = "ctl00_ContentPlaceHolder1_WagonActionImage"
		@formLibrary["bodystyle_truck"] = "ctl00_ContentPlaceHolder1_TrucksActionImage"
		@formLibrary["makes"] = "makes"
		@formLibrary["models"] = "models"
		@formLibrary["radius"] = "radius"
		@formLibrary["zip_code"] = "postalcode"
		@formLibrary["price_include_no_price"] = "noPrice"
		@formLibrary["price_lowest_price"] = "pricebeg"
		@formLibrary["price_highest_price"] = "priceend"
		@formLibrary["mileage"] = "mileage"
		@formLibrary["engine"] = "ctl00_ContentPlaceHolder1_engine"
		@formLibrary["drive"] = "ctl00_ContentPlaceHolder1_drive"
		@formLibrary["transmission"] = "ctl00_ContentPlaceHolder1_transmission"
		@formLibrary["fuel"] = "ctl00_ContentPlaceHolder1_fuel"
		@formLibrary["tally"] = "tally"
		@formLibrary["view_results"] = "btn_viewResults"
	end # End: def setup_bot()
	
	def clean_up_bot()
		begin
			@watirBrowser.close
			@watirBrowser = nil
		rescue
		end
	end # End: def clean_up_bot()
	
	def select_condition(strCondition)	
		# Expected is a string like condition=Both
		if (not strCondition["New"].nil?)
			@watirBrowser.watir.radio(:id, @formLibrary["condition_new"]).set()
		elsif (not strCondition["Used"].nil?)
			@watirBrowser.watir.radio(:id, @formLibrary["condition_used"]).set()
		elsif (not strCondition["Both"].nil?)
			@watirBrowser.watir.radio(:id, @formLibrary["condition_both"]).set()
		elsif (not strCondition["CPO"].nil?)
			@watirBrowser.watir.radio(:id, @formLibrary["condition_cpo"]).set()
		else
			# Do nothing
		end # End: case(strCondition)
	end # End: def select_condition(strCondition)
	
	def select_years(strYearString)
		# Expected is a string like yearbegin=2004;yearend=2006
		yearArray = strYearString.split(";")
		
		intCounter = 0
		while(intCounter < yearArray.length)
			key, value = (yearArray[intCounter]).split("=")
			
			case(key)
				when "yearbegin"
					@watirBrowser.watir.selectBox(:id, @formLibrary["year_begin"]).select(value)
				when "yearend"
					@watirBrowser.watir.selectBox(:id, @formLibrary["year_end"]).select(value)
				else
					# Do nothing
			end # End: case(value)
			
			intCounter = intCounter + 1
		end # End: while(intCounter < yearArray.length)
	end # End: def select_years(strYearString)
	
	def select_bodystyles(strBodyStylesString)
		# Expected is a string like bodystyle=Luxury;bodystyle=Sedan;bodystyle=StationWagon
		bodyStyleArray = strBodyStylesString.split(";")
		
		intCounter = 0
		while(intCounter < bodyStyleArray.length)
			value = (bodyStyleArray[intCounter]).split("=")[1]
			
			case(value)
				when "All"
					@watirBrowser.watir.checkBox(:id, @formLibrary["bodystyle_select_all"]).set()
				when "Compact/Coupe"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_compact_coupe"]).click()
				when "Convertible"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_convertible"]).click()
				when "Hybrid"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_hybrid"]).click()
				when "Luxury"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_luxury"]).click()
				when "Mini/PassengerVan"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_mini_passenger_van"]).click()
				when "Sedan"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_sedan"]).click()
				when "Sport"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_sport"]).click()
				when "SportUtilityVehicle"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_sport_utility_vehicle"]).click()
				when "StationWagon"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_station_wagon"]).click()
				when "Truck"
					@watirBrowser.watir.image(:id, @formLibrary["bodystyle_truck"]).click()
				else
					# Do nothing
			end # End: case(value)
			
			intCounter = intCounter + 1
		end # End: while(intCounter < bodyStyleArray)
	end # End: def select_bodystyles(strBodyStylesString)
	
	def select_price(strPriceString)
		# Expected is a string like includenoprice=true;lowestprice=5000;highestprice=30000
		priceElementArray = strPriceString.split(";")
		
		intCounter = 0
		while(intCounter < (priceElementArray.length))
			key, value = priceElementArray[intCounter].split("=")
			
			case(key)
				when "includenoprice"
					case(value)
						when "true"
							@watirBrowser.watir.checkBox(:id, @formLibrary["price_include_no_price"]).set()
						when "false"
							@watirBrowser.watir.checkBox(:id, @formLibrary["price_include_no_price"]).clear()
						else
							# Do nothing
					end # End: case(value)
				when "lowestprice"
					case(value)
						when "0"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$0")
						when "5000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$5,000")
						when "10000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$10,000")
						when "15000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$15,000")
						when "20000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$20,000")
						when "25000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$25,000")
						when "30000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$30,000")
						when "35000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$35,000")
						when "40000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$40,000")
						when "50000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$50,000")
						when "100000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_lowest_price"]).select("$100,000+")
						else
							# Do nothing
					end # End: case(value)
				when "highestprice"
					case(value)
						when "0"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$0")
						when "5000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$5,000")
						when "10000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$10,000")
						when "15000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$15,000")
						when "20000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$20,000")
						when "25000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$25,000")
						when "30000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$30,000")
						when "35000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$35,000")
						when "40000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$40,000")
						when "50000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$50,000")
						when "100000"
							@watirBrowser.watir.selectBox(:id, @formLibrary["price_highest_price"]).select("$100,000+")
						else
							# Do nothing
					end # End: case(value)
				else
					# Do nothing
			end # End: case(priceElementArray)
			
			intCounter = intCounter + 1
		end # End: while(intCounter < (priceElementArray.length))
	end # End: def select_price(strPriceString)
	
	def validate_inventory_results_page(strVehicleDetails) # TODO: Finish this and make it work
#		# Do conditional checking
#		strInventoryResultsScript = "" # Initialize strInventoryResultsScript
#		
#		# Search for the script in the page
#		@watirBrowser.watir.ie.document.scripts.each {
#			|script| tempScript = script.innerHTML
#			
#			if not tempScript["aInventory["].nil?
#				strInventoryResultsScript = tempScript
#			end # End: if not tempScript["aInventory["].nil?
#		}
#		
#		# Make sure we got something
#		if strInventoryResultsScript == "" # If we missed it, return
#			@botLogger.log(VL.INFO, "Error: aInventory not found in document.scripts", @loggingMode)
#			return nil
#		else # If we got it, continue!
#		end # End: if strInventoryResultsScript == "" # If we missed it, return
		@logger.log("Bot: Advanced search bot PASSED for " + strVehicleDetails, PASS)
	end # End: def validate_inventory_results_page()
	
	def run_bot()
		@logger.log("Bot: Running the advanced_search_bot.rb script", PASS)
		
		begin
			vehicleCollection = (@environment.paramString).split("$")
			arrayLength = vehicleCollection.length
			
			if(not vehicleCollection.nil? and vehicleCollection.length > 1)
				intCounter = 1
				while(intCounter < arrayLength)
					@watirBrowser = WatirBrowser.new
					@watirBrowser.set_with_home(false, false, 0, 0, 1024, 990, @environment.environmentHome)
					if(@watirBrowser.watir.image(:alt, "error").exists?)
						@logger.log("Error page was browsed to trying to browse to Advanced Search Landing Page", FAIL)
						@agentState = FAIL
						@agentMessages = "Error page was browsed to trying to browse to Advanced Search Inventory Results"
						return
					end # End: if(not @watirBrowser.watir.image(:alt, "error").exists?)

					while(not @watirBrowser.watir.image(:id, "ctl00_MainToolbar_TitleBarLogo").exists?)
						sleep(0.1)
					end # End: while(not @watirBrowser.watir.image(:id, "ctl00_MainToolbar_TitleBarLogo").exists?)

					@logger.log("Bot: Successfully browsed to starting page: " + @environment.environmentHome, PASS)
					
					vehicleDetails = (vehicleCollection[intCounter]).split("?")
					
					intDetailsCounter = 0
					while(intDetailsCounter < (vehicleDetails.length))
						selectString = vehicleDetails[intDetailsCounter]
						
						if (not selectString["condition"].nil?)
							select_condition(selectString)
						elsif (not selectString["year"].nil?)
							select_years(selectString)
						elsif (not selectString["bodystyle"].nil?)
							select_bodystyles(selectString)
						elsif (not selectString["make"].nil?)
							value = (selectString).split("=")[1]
							case(value)
								when "allmakes"
									@watirBrowser.watir.selectBox(:id, @formLibrary["makes"]).select("All Makes")
								else
									@watirBrowser.watir.selectBox(:id, @formLibrary["makes"]).select(value)
							end # End: case(value)
						elsif (not selectString["model"].nil?)
							value = (selectString).split("=")[1]
							case(value)
								when "allmodels"
									@watirBrowser.watir.selectBox(:id, @formLibrary["models"]).select("All Models")
								else
									@watirBrowser.watir.selectBox(:id, @formLibrary["models"]).select(value)
							end # End: case(value)
						elsif (not selectString["radius"].nil?)
							value = (selectString).split("=")[1]
							@watirBrowser.watir.selectBox(:id, @formLibrary["radius"]).select(value)
						elsif (not selectString["zipcode"].nil?)
							value = (selectString).split("=")[1]
							@watirBrowser.watir.textField(:id, @formLibrary["zip_code"]).set(value)
						elsif (not selectString["price"].nil?)
							select_price(selectString)
						elsif (not selectString["mileage"].nil?)
							value = (selectString).split("=")[1]
							@watirBrowser.watir.selectBox(:id, @formLibrary["mileage"]).select(value)
						elsif (not selectString["engine"].nil?)
							value = (selectString).split("=")[1]
							@watirBrowser.watir.selectBox(:id, @formLibrary["engine"]).select(value)
						elsif (not selectString["drive"].nil?)
							value = (selectString).split("=")[1]
							@watirBrowser.watir.selectBox(:id, @formLibrary["drive"]).select(value)
						elsif (not selectString["transmisson"].nil?)
							value = (selectString).split("=")[1]
							@watirBrowser.watir.selectBox(:id, @formLibrary["transmisson"]).select(value)
						elsif (not selectString["fuel"].nil?)
							value = (selectString).split("=")[1]
							@watirBrowser.watir.selectBox(:id, @formLibrary["fuel"]).select(value)
						else
							# Do nothing
						end # End: 
						
						intDetailsCounter = intDetailsCounter + 1
					end # End: while(intDetailsCounter < (vehicleDetails.length))
					
					# TODO: This needs to be finished up and include the inventory results page validation
					begin
						timeout(60) do
							while not @watirBrowser.watir.span(:id, @formLibrary["tally"]).text["Updating..."].nil?
								sleep(0.01)
							end
						end # End: timeout(60) do
					rescue TimeoutError
						@agentState = FAIL
						@Logger.log("Bot: Tally never updated from '...' or 'Updating...'", @agentState)
						return
					end
					
					if(not @watirBrowser.watir.span(:id, @formLibrary["tally"]).text == "0")
						@watirBrowser.watir.image(:class_name, @formLibrary["view_results"]).click
						if(not @watirBrowser.watir.image(:alt, "error").exists?)
							validate_inventory_results_page(vehicleCollection[intCounter])
						else
							@logger.log("Error page was browsed to trying to browse to Advanced Search Inventory Results", FAIL)
							@agentState = FAIL
							@agentMessages = "Error page was browsed to trying to browse to Advanced Search Inventory Results"
							return
						end # End: if(not @watirBrowser.watir.image(:alt, "error").exists?)
					elsif(@watirBrowser.watir.span(:id, @formLibrary["tally"]).text == "...")
						@agentState = FAIL
						@Logger.log("Bot: Tally showed '...'", @agentState)
						return
					end # End: if(not @watirBrowser.watir.span(:id, @formLibrary["tally"]).innerText == "0")
					
					clean_up_bot
					intCounter = intCounter + 1
				end # End: while(intCounter < arrayLength)
			end # End: if(not vehicleCollection.nil? and vehicleCollection.length > 1)
		ensure
			clean_up_bot
		end
	end # End: def run_bot()
	
end # End: class Bot
