## ArtStationBot

`v2.0`

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

The DB URL can be updated if required under the `config.plist` present in the app's content folder.

- Run the app, click `Settings`. Click `Start Crawl` to get the list of skills loaded. For each skill a message can be set with the interpolation values as per the message template keys. The ArtStation sender credential can also be added under `Settings`.

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

### App Design

Launch the app, click the crawl button to fetch the list of filters which contains the skills available. For each skill, the users are fetched with pagination same as the website and the data is added to the `users` collection and a reference to the corresponding skill under the `skills` collection. 

Click on the message button to send message to users who had not been messaged before for a particular skill. If a user belongs to multiple skills, the user will get multiple messages relevant for that skill. The message sent state is updated under the corresponding skill. For example, the below query gives the list of users belonging to a particular skill and had been messaged.

```
db.skills["2D Animation"].users.find({messaged: true})
```

There are two parts to the app, the crawler, the messenger and the frontier which coordinates them. Both these run independent of each other on separate schedule and queues. The scheduler uses Gaussian random distribution with a mean and a standard deviation, and have a different sets of them so that a new batch uses a different value than the previous batch.

When the job is paused, it continues until the current queue is complete. Once the current batch completes, new batch is not scheduled unless the job is started again.

The app uses FoundationDB with Document Layer as its backend database. The DB is accessible from any tool that talks the MongoDB wire protocol. The data can be viewed and managed using any MongoDB GUI front end as well.

The DB configuration can be specified in the `config.plist` under `Resources` folder of the app package. The default values are

```
ClusterConfigPath = /usr/local/etc/foundationdb/fdb.cluster
DocumentLayerURL = mongodb://127.0.0.1:27016/?retryWrites=true
```

For messaging, the app uses `WebKitView` to interact with the live web page. The webkit view controller loads the `artstationbot.js` user script on page load and sets up  a message handler which the JavaScript code uses to post messages to the native code. Native code have direct access to the script engine which is used to run JavaScript functions on the webpage.

Under settings view, the message for each skill can be configured. The ArtStation user credential as well the sender details used in message template can be set. The password for the sender is saved in the macOS keychain and is not added to the DB, whereas the rest of the sender details are persisted in the DB.

