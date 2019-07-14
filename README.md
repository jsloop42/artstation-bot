## ArtStation Bot

A bot which send message to [ArtStation](https://artstation.com) users. The bot works on macOS and is written in AppleScript 2.7.

### Usage

There are two input to the script, 

1. A list of user links and messages, in `artstation-users.txt` file
2. The sender's artstation credential in `creds.txt` file

both in the same working directory as of the script.

Run the `ArtStationBot.app`, which will first sign-in and then send message to each user from the list. Once the task completes, the bot produces a log file `artstationbot-{date}.log` with the status containing success and failure details.

### File Format

#### User List

User list expects the url in first line, followed by the message and an empty line. 

#### Credential

The credential file expects the first line to be the username, followed by password on the second line and an empty line.

### Side Note

Using AppleScript with Safari requires enabling Apple Events, which the script does. This can be done manually by enabling the option `Allow JavaScript from Apple Events` under `Develop` menu, which can be enabled from `Advanced` settings under `Preferences`.

---

jsloop
