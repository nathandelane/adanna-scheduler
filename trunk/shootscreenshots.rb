require "win32ole"

class ScreenshotShooter
	
	def initialize()
		@wsh = WIN32OLE.new("Wscript.Shell")
	end # End: def initialize()
	
	def run_screenshot_shooter()
		@wsh.SendKeys("%{PRTSC}")
		@wsh.SendKeys("%{PRTSC}")
		@wsh.SendKeys("%{PRTSC}")
		@wsh.SendKeys("%{PRTSC}")
	end # End: def run_screenshot_shooter()
	
end # End: class ScreenshotShooter

if __FILE__ == $0
	
	sss = ScreenshotShooter.new
	sss.run_screenshot_shooter
	
end # End: if __FILE__ == $0