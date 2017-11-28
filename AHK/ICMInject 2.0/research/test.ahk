scriptsPath = %A_Appdata%\Innovyze\WorkgroupClient\scripts\scripts.csv
;Parse scripts.csv till "Inject RubyScript" is found 
			Loop, read, %scriptsPath% 
			{
				If RegexMatch(A_LoopReadLine,"i)Inject RubyScript\s*,\s*(.+)",m)
				{
					msgbox, %m1%
					break
				}
			}