require "Win32API" 

class WSProgressBar
	#SEND MESSAGE CONSTANTS:
	#Progress bar messages
	WM_USER			= 0x0400
	PBM_SETRANGE    = (WM_USER+1)
	PBM_SETPOS      = (WM_USER+2)
	PBM_DELTAPOS    = (WM_USER+3)
	PBM_SETSTEP     = (WM_USER+4)
	PBM_STEPIT      = (WM_USER+5)
	PBM_SETRANGE32  = (WM_USER+6)
	PBM_GETRANGE    = (WM_USER+7)
	PBM_GETPOS      = (WM_USER+8)
	PBM_SETBARCOLOR = (WM_USER+9)
	
	#Icon messages
	WM_SETICON      = 0x0080
	
	#Dialog Controls
	STATIC1			= 0x142
	STATIC2			= 0x145
	
	#Icon constants
	IMAGE_ICON      = 1
	LR_LOADFROMFILE = 0x00000040
	LR_DEFAULTSIZE  = 0x00000010
	ICON_BIG        = 1
	ICON_SMALL      = 0	
	
	#Window visibility
	SW_SHOW	= 5
	SW_HIDE	= 0

	def initialize()
		#User32.dll
		#	HWND WINAPI GetActiveWindow(void);
		@GetActiveWindow = Win32API.new("User32","GetActiveWindow", [], 'L')
		
		#User32.dll
		#	HWND WINAPI FindWindowEx(
		#	  _In_opt_ HWND    hwndParent,
		#	  _In_opt_ HWND    hwndChildAfter,
		#	  _In_opt_ LPCTSTR lpszClass,
		#	  _In_opt_ LPCTSTR lpszWindow
		#	);
		@FindWindowEx = Win32API.new("user32", "FindWindowEx", ['L','L','P','P'], 'L') 
		
		#User32.dll
		#	LRESULT WINAPI SendMessage(
		#	  _In_ HWND   hWnd,
		#	  _In_ UINT   Msg,
		#	  _In_ WPARAM wParam,
		#	  _In_ LPARAM lParam
		#	);
		@SendMessage = Win32API.new("user32", "SendMessage", ['L','L','L','L'], 'L') 
		
		#User32.dll
		#	HWND WINAPI GetDlgItem(
		#	  _In_opt_ HWND hDlg,
		#	  _In_     int  nIDDlgItem
		#	);
		@GetDlgItem = Win32API.new("user32", "GetDlgItem", ['L','I'], 'I')
		
		#User32.dll
		#	BOOL WINAPI SetWindowText(
		#	  _In_     HWND    hWnd,
		#	  _In_opt_ LPCTSTR lpString
		#	);
		@SetWindowText = Win32API.new("user32", "SetWindowText", ['L','P'], 'I') 
		
		#User32.dll
		#	HANDLE WINAPI LoadImage(
		#	  _In_opt_ HINSTANCE hinst,
		#	  _In_     LPCTSTR   lpszName,
		#	  _In_     UINT      uType,
		#	  _In_     int       cxDesired,
		#	  _In_     int       cyDesired,
		#	  _In_     UINT      fuLoad
		#	);
		@LoadImageA = Win32API.new("user32","LoadImageA",["l","p","l","i","i","l"],"p")
		
		#User32.dll
		#	BOOL WINAPI ShowWindow(
		#	  _In_ HWND hWnd,
		#	  _In_ int  nCmdShow
		#	);
		@ShowWindow = Win32API.new("user32","ShowWindow",["l","i"],"i")
		
		#Get the hwnd of the progress bar window
		@Hwnd = @GetActiveWindow.call()
		
		# Now find the window handle of progress bar
		@PBHwnd = @FindWindowEx.call(@Hwnd,0,"msctls_progress32","") 
		raise 'Failed to get progressbar handle' if (@PBHwnd <= 0)
		
		# Now find the window handle of the status text
		@STHwnd = @GetDlgItem.call(@Hwnd,STATIC1) 
		raise 'Failed to get progressbar handle' if (@STHwnd <= 0)
		
		# Now find the window handle of the percentage text
		@PTHwnd = @GetDlgItem.call(@Hwnd,STATIC2) 
		raise 'Failed to get progressbar handle' if (@PTHwnd <= 0)
		
		#Set progress bar minimum an maximum values
		@min = 0
		@max = 100
		
		@value = 0
		@prevValue = 0
		@message = "Starting..."
		@title = "Please wait..."
		
		@log_file = ""
	end
	
	def uuid
		"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".gsub("x") do
			"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"[rand(36)]
		end
	end
	
	def percent
		((@value.to_f - @min) / (@max-@min).abs * 100).round(2)
	end
	
	def value
		@value # = SendMessage.call(@PBHwnd, PBM_GETPOS,0,0)
	end
	
	def value=(i)
		@prevValue = percent
		@value = i.to_i
		@SendMessage.call(@PBHwnd, PBM_SETPOS,@value,0)
		@SetWindowText.call(@PTHwnd, "#{self.percent}%") unless @prevValue == self.percent
	end
	
	def step
		self.value = self.value + 1
	end
	
	def message
		@message
	end
	
	def message=(s)
		if s != @message
			@message = s
			@SetWindowText.call(@STHwnd,@message)
		end
	end
	
	def title
		@title
	end
	
	def title=(s)
		@title = s
		@SetWindowText.call(@Hwnd,@title)
	end
	
	def hidden
		@hidden
	end
	
	def hidden=(b)
		@hidden=b
		@ShowWindow.call(@Hwnd,@hidden ? SW_HIDE : SW_SHOW)
	end
	
	def max
		@max
	end
	
	def max=(i)
		raise "Maximum must be positive" if i.to_i < 0
		@max = i.to_i
		@SendMessage.call(@PBHwnd, PBM_SETRANGE32, @min,@max)
		
		#Re-evaluate percentage
		self.value = self.value
	end
	
	def min
		@min
	end
	
	def min=(i)
		raise "Minimum must be positive" if i.to_i < 0
		@min = i.to_i
		@SendMessage.call(@PBHwnd, PBM_SETRANGE32, @min,@max)
		
		#Re-evaluate percentage
		self.value = self.value
	end
	
	def log(file_spec="")
		if file_spec == ""
			file_spec = WSApplication.script_file + "\\..\\"
		end
	end
end




