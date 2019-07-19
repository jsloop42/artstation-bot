-- A bot to send messages to users at artstation.com website.
-- Author: jsloop42@gmail.com
-- Version: 1.0

global cwd -- The current working directory
global js -- The accompanying JavaScript source
global username -- Sender's username
global pass -- Sender's password
global baseURL -- The base url of the website
global cwURL -- Holds the current user's profile link
global failxs -- A list of user urls for which message sending failed
global okxs -- A list of user urls for which message sending succeeded
global logPath -- The log file path
global isEventsEnabled -- Flag which indicates if Apple Events are enabled

set cwd to ""
set js to ""
set username to ""
set pass to ""
set baseURL to "https://artstation.com"
set cwURL to ""
set failxs to {}
set okxs to {}
set logPath to ""
set isEventsEnabled to false

-- Get current working directory.
to getCurrentDirectory()
    tell application "Finder"
        get path to me
        set cwd to container of the result
        log cwd
        return (cwd as alias)
    end tell
end getCurrentDirectory

-- Enabled Develop menu if not enabled
to enableDevelopMenu()
    tell application "Safari"
        tell application "System Events"
            tell process "Safari"
                click menu item "Preferences…" of menu 1 of menu bar item "Safari" of menu bar 1
                click button "Advanced" of toolbar 1 of window 1
                tell checkbox "Show Develop menu in menu bar" of group 1 of group 1 of window 1
                    if value is 0 then click it
                end tell
                set frontmost to true
                keystroke "." using {command down}
            end tell
        end tell
    end tell
end enableDevelopMenu

-- Enabled Apple Events in Safari if not enabled using Menu
to enableAppleEventsUsingMenu()
    tell application "Safari"
        tell application "System Events"
            tell process "Safari"
                tell menu "Develop" of menu bar item "Develop" of menu bar 1
                    click it
                    get properties of menu item "Allow JavaScript From Apple Events"
                    tell menu item "Allow JavaScript From Apple Events"
                        if value of attribute "AXMenuItemMarkChar" is not "✓" then
                            set isEventsEnabled to false
                            click
                        else
                            set isEventsEnabled to true
                            keystroke return
                        end if
                        delay 1
                    end tell
                end tell
                if isEventsEnabled is false then
                    tell front window
                        click button "Allow"
                    end tell
                end if
            end tell
        end tell
    end tell
end enableAppleEventsUsingMenu

-- Enable Apple Events if not enabled in Safari.
to enableAppleEvents()
    do shell script "defaults write -app Safari AllowJavaScriptFromAppleEvents 1"
end enableAppleEvents

-- Check if the file exists in the given path.
on fileExists(thePath)
    try
        set thePath to thePath as alias
    on error
        return false
    end try
    return true
end fileExists

-- Read JS script file.
to readScript()
    set scriptFile to (cwd as text) & "artstation.js"
    set js to (read file scriptFile)
    log js
    return js as text
end readScript

-- Read the input file if exists, else display file picker to choose input the file.
to readInputFile()
    set inpFile to (cwd as text) & "artstation-users.txt"
    if fileExists(inpFile) then
        set inp to readFile(inpFile as alias)
    else
        set inp to getInputFile("Please select the user list file")
    end if
    return inp
end readInputFile

-- Read credentials from creds.txt if present or display file picker to input the credentials file.
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

-- Read the input file containing user details.
on readFile(aFile)
    set inp to aFile as string
    set para to paragraphs of (read file inp)
    return para
end readFile

-- Display a file picker dialog to get the input file from the user.
on getInputFile(msg)
    set inpFile to choose file of type "txt" with prompt msg
    set xs to readFile(inpFile)
    log (count of xs)
    return xs
end getInputFile

-- Wait till the home page loads.
to waitForHomePageLoad()
    tell application "Safari"
        tell front document to repeat until (do JavaScript ¬
            "document.querySelector('div.wrapper div.wrapper-main') != null") is true
        end repeat
        log "Home page loaded"
    end tell
end waitForHomePageLoad

-- Wait until Safari loads the profile page.
to waitForProfilePageLoad()
    tell application "Safari"
        tell front document to repeat until (do JavaScript ¬
            "document.querySelector('.artist-name').innerText") as text is not ""
        end repeat
        log "Profile page loaded"
    end tell
end waitForProfilePageLoad

-- Wait for user sign-in.
to waitForSignIn()
    tell application "Safari"
        set ret to false
        tell front document to repeat until ret is true
            set ret to (do JavaScript "document.querySelector(\"a[href='/users/sign_out']\") != null")
            log "wait for sign in " & ret
        end repeat
        log "Is signed in"
    end tell
end waitForSignIn

-- Open safari with url to the user profile.
on openSafariDoc(link, msg)
    tell application "System Events"
        tell application "Safari"
            activate
            make new document with properties {URL:link}
            my waitForProfilePageLoad()
            delay 2
            my execJS(msg)
        end tell
    end tell
end openSafariDoc

-- Close all Safari tabs.
to closeSafariTabs()
    tell application "Safari"
        close (every tab of every window)
    end tell
end closeSafariTabs

-- Close all Safari windows.
to closeSafari()
    tell application "Safari" to quit
end closeSafari

-- Process the input file.
on processInput(xs)
    set user to ""
    set msg to ""
    repeat with n from 1 to count of xs
        if n mod 3 = 1 then set user to (item n of xs)
        if n mod 3 = 2 then set msg to (item n of xs)
        if n mod 3 = 0 then
            set cwURL to user
            openSafariDoc(user, msg)
            delay 2
            closeSafariTabs()
        end if
    end repeat
end processInput

-- Set variables in the JS script.
on constructVars(msg)
    return js & "DL.username = '" & username & "'; DL.password = '" & pass & ¬
        "'; DL.message = '" & msg & "';" & js
end constructVars

-- Execute JavaScript once the website loads.
to execJS(msg)
    set artjs to constructVars(msg)
    tell application "Safari"
        do JavaScript artjs in current tab of first window
        set status to do JavaScript "dl.message()" in current tab of first window
        if status is false then
            log "Message sending failed for user " & cwURL
            set end of failxs to cwURL
        else
            log "Message sent successfully"
            set end of okxs to cwURL
        end if
    end tell
end execJS

-- Sign in to the website.
to signIn()
    set artjs to constructVars("")
    tell application "Safari"
        activate
        make new document with properties {URL:baseURL}
        my waitForHomePageLoad()
        do JavaScript artjs in current tab of first window
        do JavaScript "dl.init()" in current tab of first window
        my waitForSignIn()
    end tell
end signIn

-- Get current date.
on getDate()
    set {year:y, month:m, day:d, hours:h, minutes:min, seconds:s} to (current date)
    return y & "-" & m & "-" & d & "-" & h & "-" & min & "-" & s
end getDate

-- Write the given data to the file.
on writeToFile(fileData, filePath, isAppend)
    try
        set filePath to filePath as text
        set fileRef to ¬
            open for access file filePath with write permission
        if isAppend is false then ¬
            set eof of fileRef to 0
        write fileData to fileRef starting at eof
        close access fileRef
        return true
    on error
        try
            close access file filePath
        end try
        return false
    end try
end writeToFile

-- Sets the log path.
on configureLogFile()
    set logPath to (cwd as text) & "artstationbot" & getDate() & ".log"
    return logPath
end configureLogFile

-- Append log to the given file.
on writeLog(aText, filePath)
    my writeToFile(aText, filePath, true)
end writeLog

-- Logs and displays message sending status.
to logStatus(msg, xs)
    if (count of xs) > 0 then
        log msg
        writeLog(msg, logPath)
        repeat with n from 1 to count of xs
            set elem to (item n of xs) & " " & {return}
            log elem
            writeLog(elem, logPath)
        end repeat
        writeLog("" & {return}, logPath)
    end if
end logStatus

-- Process status list to log the details.
to processStatusList()
    writeLog(((current date) as string) & {return} & {return}, logPath)
    -- Failure list
    if (count of failxs) > 0 then
        logStatus("Sending message failed for " & {return}, failxs)
    end if
    -- Success list
    if (count of okxs) > 0 then
        logStatus("Sending message succeeded for " & {return}, okxs)
    end if
end processStatusList

-- Display local notification with sound
to displayNotification(atitle, msg)
    display notification msg with title atitle sound name "Ping"
end displayNotification

to enableAppleEventsInSafari()
    tell application "System Events"
        tell application "Safari"
            activate
            my enableDevelopMenu()
            my enableAppleEventsUsingMenu()
            my enableAppleEvents()
        end tell
    end tell
end enableAppleEventsInSafari

-- Begin processing.
getCurrentDirectory()
configureLogFile()
enableAppleEventsInSafari()
readCreds()
readScript()
set inp to readInputFile()
signIn()
delay 2
processInput(inp)
closeSafari()
processStatusList()
displayNotification("ArtStation Bot", "Completed processing the list")
log "Done"
