-- Open targetURL in appName; reload an existing tab if one already shows it.
-- Arc: optionally route to a named Space (spaceName). Non-Arc Chromium
-- browsers (Chrome/Edge/Brave) share Chrome's dictionary via `using terms from`.
on run {targetURL, appName, spaceName}
	if appName is "Arc" then
		tell application "Arc"
			activate
			-- Optional Space routing.
			set targetWin to missing value
			set targetSpace to missing value
			if spaceName is not "" then
				try
					repeat with w in windows
						repeat with s in spaces of w
							if title of s is spaceName then
								set targetWin to w
								set targetSpace to s
								exit repeat
							end if
						end repeat
						if targetWin is not missing value then exit repeat
					end repeat
				end try
			end if
			-- Dedup across all windows.
			set foundTab to my findTabArc(targetURL)
			if foundTab is not missing value then
				tell foundTab to select
				try
					tell foundTab to reload
				end try
				return "reloaded"
			end if
			if targetSpace is not missing value then focus targetSpace
			if targetWin is missing value then
				if (count of windows) is 0 then make new window
				set targetWin to front window
			end if
			tell targetWin to make new tab with properties {URL:targetURL}
			return "opened"
		end tell
	else
		using terms from application "Google Chrome"
			tell application appName
				activate
				if (count of windows) is 0 then make new window
				-- Dedup across all windows/tabs.
				repeat with w in windows
					set i to 1
					repeat with t in tabs of w
						if (URL of t) is targetURL then
							set active tab index of w to i
							set index of w to 1
							tell t to reload
							return "reloaded"
						end if
						set i to i + 1
					end repeat
				end repeat
				tell front window to make new tab with properties {URL:targetURL}
				return "opened"
			end tell
		end using terms from
	end if
end run

-- Arc-specific tab lookup (Arc's dictionary, called only from the Arc branch).
on findTabArc(targetURL)
	tell application "Arc"
		repeat with w in windows
			try
				repeat with t in tabs of w
					try
						if (URL of t) is targetURL then return t
					end try
				end repeat
			end try
		end repeat
	end tell
	return missing value
end findTabArc
