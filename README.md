## ArtStation Bot

### Installation

- Install [FoundationDB v6.1.8](https://www.foundationdb.org/downloads/6.1.8/macOS/installers/FoundationDB-6.1.8.pkg) and the [Document Layer v1.6.3](https://www.foundationdb.org/downloads/1.6.3/macOS/installers/FoundationDB-Document-Layer-1.6.3.pkg). Check if the instllation was successful by running `fdbcli` in the Terminal.
	
- Install MongoDB C driver libraries and shell

```
brew tap mongodb/brew
brew install mongodb-community@4.0
brew install libmongoc
```
	
- Add the binary to the Terminal path
 
```
export PATH="/usr/local/Cellar/mongodb-community@4.0/4.0.12/bin":$PATH
``` 

- Check connection to FoundationDB using document layer

```
mongo 127.0.0.1:27016
```

- Run the app

### Message Template

Message can be written as a template string, with string interpolation for the following keys.

| Key                  | Value                      |
|----------------------|----------------------------|
| `${user.fullName}`   | User's full name           |
| `${user.username}`   | User's username            |
| `${user.email}`      | User's email address       |
| `${user.profileURL}` | User's profile link        |
| `${sender.name}`     | The sender's name          |
| `${sender.url}`      | The sender's url           |
| `${sender.email}`    | The sender's email address |

