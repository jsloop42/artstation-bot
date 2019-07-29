//
//  FoundationDBService.m
//  ArtStationBot
//
//  Created by jsloop on 23/07/19.
//


#import "FoundationDBService.h"
#import "ArtStationBot-Swift.h"
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
static const char *appName = "artstationbot";
static const char *skills_coll_name = "skills";
static const char *users_coll_name = "users";

static mongoc_uri_t *mongouri;
static mongoc_client_t *client;
static mongoc_database_t *database;
static mongoc_collection_t *skills_coll;
static mongoc_collection_t *users_coll;
static bson_t *insertCommand;
static bson_t *readCommand;
static bson_t *updateCommand;
static bson_t *deleteCommand;
static bson_t reply;
static bson_t *insert;

@interface FoundationDBService ()
@end

@implementation FoundationDBService {
    NSString *_configPath;
    NSString *_config;
    char *_docLayerURL;
}

@synthesize configPath = _configPath;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self bootstrap];
    }
    return self;
}

- (void)dealloc {
    mongoc_collection_destroy(skills_coll);
    mongoc_collection_destroy(users_coll);
    mongoc_database_destroy(database);
    mongoc_uri_destroy(mongouri);
    mongoc_client_destroy(client);
    mongoc_cleanup();
}

- (int)fail:(bson_error_t)err {
    MONGOC_ERROR("DB error: code: %d, msg: %s" , err.code, err.message);
    return EXIT_FAILURE;
}

- (void)bootstrap {
    NSString *url = [Utils getDocLayerURL];
    _docLayerURL = (char *)[url UTF8String];
    [self initDocLayer];
    skills_coll = mongoc_client_get_collection(client, dbName, skills_coll_name);
    users_coll = mongoc_client_get_collection(client, dbName, users_coll_name);
}

- (int)initDocLayer {
    bson_error_t err;
    mongoc_init();
    mongouri = mongoc_uri_new_with_error(_docLayerURL, &err);
    if (!mongouri) return [self fail:err];
    client = mongoc_client_new_from_uri(mongouri);
    if (!client) return [self fail:err];
    mongoc_client_set_appname(client, appName);
    database = mongoc_client_get_database(client, dbName);
    return EXIT_SUCCESS;
}

- (int)insertSkills:(char *)json {
    bson_error_t err;
    bson_t *skill_json = bson_new_from_json((const uint8_t *)json, -1, &err);
    bson_t reply;
    bool ret = mongoc_collection_insert_one(skills_coll, skill_json, NULL, &reply, &err);
    if (!ret) [self fail:err];
    char *str = bson_as_canonical_extended_json(skill_json, NULL);
    debug(@"%s\n", str);
    bson_destroy(skill_json);
    bson_destroy(&reply);
    bson_free(str);
    return EXIT_SUCCESS;
}

- (int)insertUser {
    mongoc_client_session_t *session;
    mongoc_session_opt_t *session_opts;
    mongoc_transaction_opt_t *default_txn_opts;
    mongoc_transaction_opt_t *txn_opts;
    mongoc_read_concern_t *read_concern;
    mongoc_write_concern_t *write_concern;
    bson_t *doc;
    bson_t *insert_opts;
    bson_error_t err;
    default_txn_opts = mongoc_transaction_opts_new();
    read_concern = mongoc_read_concern_new();
    mongoc_read_concern_set_level(read_concern, "snapshot");
    mongoc_transaction_opts_set_read_concern(default_txn_opts, read_concern);
    session_opts = mongoc_session_opts_new();
    mongoc_session_opts_set_default_transaction_opts(session_opts, default_txn_opts);
    session = mongoc_client_start_session(client, session_opts, &err);
    if (!session) {
        MONGOC_ERROR("Failed to start session: %s", err.message);
        return EXIT_FAILURE;
    }
    txn_opts = mongoc_transaction_opts_new();
    write_concern = mongoc_write_concern_new();
    mongoc_write_concern_set_wmajority(write_concern, 1000);  // write timeout
    mongoc_transaction_opts_set_write_concern(txn_opts, write_concern);
    insert_opts = bson_new();
    // user_json: {"_id": 123, "username": "Foo"}
    // "2D Animation": {"_id": 1, "users": [123]} // db["2D Animation"].update({"_id": 1}, {"$push": {"users": 123}})
    // FIXME: insert docs to user, skills
    insertUserTransaction(self, session, txn_opts, &err);
    return EXIT_SUCCESS;
}

// FIXME: test
int insertUserTransaction(id self, mongoc_client_session_t *session, mongoc_transaction_opt_t *txn_opts, bson_error_t *err) {
    bool ret = mongoc_client_session_start_transaction(session, txn_opts, err);
    if (!ret) {
        MONGOC_ERROR("Failed to start transaction: %s", err->message);
        return EXIT_FAILURE;
    }
    bson_t *selector = BCON_NEW ("_id", BCON_INT32(1));
    bson_t *update = BCON_NEW("$push", "{", "users", BCON_INT32(123), "}");
    bson_t *update_opts = bson_new();
    ret = mongoc_client_session_append(session, update_opts, err);
    if (!ret) {
        MONGOC_ERROR("Failed to update session: %s", err->message);
        return EXIT_FAILURE;
    }
    bson_t reply;
    ret = mongoc_collection_update_one(skills_coll, selector, update, update_opts, &reply, err);
    if (!ret) {
        MONGOC_ERROR("Failed to update collection: %s", err->message);
        return EXIT_FAILURE;
    }
    bson_destroy(&reply);
    bson_destroy(update_opts);
    bson_destroy(update_opts);
    bson_destroy(update);
    bson_destroy(selector);
    mongoc_transaction_opts_destroy(txn_opts);
    return EXIT_SUCCESS;
}

@end
