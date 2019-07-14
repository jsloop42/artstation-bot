global cwd
global js
global username
global pass

set cwd to ""
set js to ""
set username to ""
set pass to ""

-- Get current working directory
to getCurrentDirectory()
	tell application "Finder"
		get path to me
		set cwd to container of the result
		log cwd
		return (cwd as alias)
	end tell
end getCurrentDirectory

-- Check if the file exists in the given path
on fileExists(thePath)
	try
		set thePath to thePath as alias
	on error
		return false
	end try
	return true
end fileExists

-- Read JS script file
to readScript()
	set scriptFile to (cwd as text) & "artstation.js"
	set js to (read file scriptFile)
	log js
	return js as text
end readScript

-- Read the input file if exists, else display file picker
to readInputFile()
	set inpFile to (cwd as text) & "artstation-users.txt"
	if fileExists(inpFile) then
		set inp to readFile(inpFile as alias)
	else
		set inp to getInputFile("Please select the user list file")
	end if
	return inp
end readInputFile

to readCreds()
	set inpFile to (cwd as text) & "creds.txt"
	if fileExists(inpFile) then
		set inp to readFile(inpFile as alias)
		set username to (item 1 of inp) as string
		set pass to (item 2 of inp) as string
	else
		set inp to getInputFile("Please select the credentials file")
	end if
	return inp
	
end readCreds

-- Enable Apple Events if not enabled in Safari
to enableAppleEvents()
	do shell script "defaults write -app Safari AllowJavaScriptFromAppleEvents 1"
end enableAppleEvents

-- Read the input file containing user details
on readFile(aFile)
	set inp to aFile as string
	set para to paragraphs of (read file inp)
	return para
end readFile

-- Display a dialog to get the input file from user
on getInputFile(msg)
	set inpFile to choose file of type "txt" with prompt msg
	set xs to readFile(inpFile)
	log (count of xs)
	return xs
end getInputFile

-- Wait until Safari loads the profile page
to waitForProfilePageLoad()
	tell application "Safari"
		tell front document to repeat until (do JavaScript Â
			"document.querySelector('.artist-name').innerText") as text is not ""
		end repeat
		log "Profile page loaded"
	end tell
end waitForProfilePageLoad

-- Wait for user sign-in
to waitForSignIn()
	tell application "Safari"
		tell front document to repeat until (do JavaScript Â
			"dl.isSignedIn() && dl.isUserProfileLoaded()") is true
		end repeat
		log "Is signed in"
	end tell
end waitForSignIn

-- Open safari with url to the user profile
on openSafariDoc(link, msg)
	tell application "System Events"
		tell application "Safari"
			make new document with properties {URL:link}
			--my execJS(msg)
		end tell
	end tell
end openSafariDoc

-- Process the input file
on processInput(xs)
	-- repeat with n from 1 to count of xs
	set user to ""
	set msg to ""
	repeat with n from 1 to 4
		log "mod: " & n mod 3
		if n = 3 then log (item n of xs) is ""
		if n mod 3 = 1 then set user to (item n of xs)
		if n mod 3 = 2 then set msg to (item n of xs)
		if n mod 3 = 0 then
			log "User: " & user
			log "Msg: " & msg
			openSafariDoc(user, msg)
		end if
	end repeat
end processInput

on constructVars(msg)
	return js & "DL.username = '" & username & "'; DL.password = '" & pass & Â
		"'; DL.message = '" & msg & "';" & js
end constructVars

to execJS(msg)
	set js to constructVars(msg)
	tell application "Safari"
		do JavaScript js in current tab of first window
		my waitForProfilePageLoad()
		do JavaScript "dl.init()" in current tab of first window
		my waitForSignIn()
		my waitForProfilePageLoad()
		log "signed in, profile page reloaded"
		set ret to do JavaScript "dl.message()" in current tab of first window
		log "Message sent status is " & ret
	end tell
	
end execJS

getCurrentDirectory()
--enableAppleEvents()
readCreds()
readScript()
log js
set inp to readInputFile()
log inp
processInput(inp)


log "done"

