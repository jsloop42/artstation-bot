//
//  FoundationDBService.m
//  ArtStationBot
//
//  Created by jsloop on 23/07/19.
//


#import "FoundationDBService.h"
#import "mongoc/mongoc.h"
//#import "bson/bcon.h"

#define NSLog(FORMAT, ...) fprintf(stderr, "%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#ifdef DEBUG
#   define debug(...) NSLog(__VA_ARGS__)
#   define info(...) NSLog(__VA_ARGS__)
#   define error(...) NSLog(__VA_ARGS__)
#else
#   define info(...) NSLog(__VA_ARGS__)
#   define error(...) NSLog(__VA_ARGS__)
#endif

static const char *dbName = "artstation";

@implementation FoundationDBService {
    NSString *_configPath;
    NSString *_config;
}

@synthesize configPath = _configPath;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self bootstrap];
    }
    return self;
}

- (int)fail {
    debug(@"DB error")
    return EXIT_FAILURE;
}

- (void)bootstrap {
    //[self initDocLayer];
}

- (int)initDocLayer {
    const char *_fdbURL = "mongodb://localhost:27016";
    bson_error_t err;
    mongoc_uri_t *mongouri = mongoc_uri_new_with_error(_fdbURL, &err);
    if (!mongouri) return [self fail];
    mongoc_client_t *client = mongoc_client_new_from_uri(mongouri);
    if (!client) return [self fail];
    mongoc_client_set_appname(client, "artstationbot");
    mongoc_database_t *database = mongoc_client_get_database(client, dbName);
    mongoc_collection_t *coll = mongoc_client_get_collection(client, dbName, "users");
    bson_t *command = BCON_NEW("ping", BCON_INT32(1));
    bson_t reply;
    bool retVal = mongoc_client_command_simple(client, dbName, command, NULL, &reply, &err);
    if (!retVal) return EXIT_FAILURE;
    char *str = bson_as_json(&reply, NULL);
    printf("%s\n", str);
    bson_t *insert = BCON_NEW("hello", BCON_UTF8("world"));
    if (!mongoc_collection_insert_one(coll, insert, NULL, &reply, &err)) {
        return [self fail];
    }
    bson_destroy(insert);
    bson_destroy(&reply);
    bson_destroy(command);
    bson_free(str);
    mongoc_collection_destroy(coll);
    mongoc_database_destroy(database);
    mongoc_uri_destroy(mongouri);
    mongoc_client_destroy(client);
    mongoc_cleanup();
    return EXIT_SUCCESS;
}

@end
