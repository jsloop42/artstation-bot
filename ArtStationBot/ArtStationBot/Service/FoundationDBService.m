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

@interface FoundationDBService ()
@property (nonatomic, readwrite) mongoc_uri_t *mongouri;
@property (nonatomic, readwrite) mongoc_client_t *client;
@property (nonatomic, readwrite) mongoc_database_t *database;
@property (nonatomic, readwrite) mongoc_collection_t *skills_coll;
@property (nonatomic, readwrite) mongoc_collection_t *users_coll;
@property (nonatomic, readwrite) bson_t *insertCommand;
@property (nonatomic, readwrite) bson_t *readCommand;
@property (nonatomic, readwrite) bson_t *updateCommand;
@property (nonatomic, readwrite) bson_t *deleteCommand;
@property (nonatomic, readwrite) bson_t reply;
@property (nonatomic, readwrite) bson_t *insert;

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
    mongoc_collection_destroy(self.skills_coll);
    mongoc_collection_destroy(self.users_coll);
    mongoc_database_destroy(self.database);
    mongoc_uri_destroy(self.mongouri);
    mongoc_client_destroy(self.client);
    mongoc_cleanup();
}

- (int)fail:(bson_error_t)err {
    error(@"DB error: code: %d, msg: %s" , err.code, err.message);
    return EXIT_FAILURE;
}

- (void)bootstrap {
    NSString *url = [Utils getDocLayerURL];
    _docLayerURL = (char *)[url UTF8String];
    [self initDocLayer];
    self.skills_coll = mongoc_client_get_collection(self.client, dbName, skills_coll_name);
    self.users_coll = mongoc_client_get_collection(self.client, dbName, users_coll_name);
}

- (int)initDocLayer {
    bson_error_t err;
    self.mongouri = mongoc_uri_new_with_error(_docLayerURL, &err);
    if (!self.mongouri) return [self fail:err];
    self.client = mongoc_client_new_from_uri(self.mongouri);
    if (!self.client) return [self fail:err];
    mongoc_client_set_appname(self.client, appName);
    self.database = mongoc_client_get_database(self.client, dbName);
    return EXIT_SUCCESS;
}

- (int)insertSkills:(char *)json {
    bson_error_t err;
    bson_t *skill_json = bson_new_from_json((const uint8_t *)json, -1, &err);
    bson_t reply;
    bool ret = mongoc_collection_insert_one(self.skills_coll, skill_json, NULL, &reply, &err);
    if (!ret) [self fail:err];
    char *str = bson_as_canonical_extended_json(skill_json, NULL);
    debug(@"%s\n", str);
    bson_destroy(skill_json);
    bson_destroy(&reply);
    bson_free(str);
    return EXIT_SUCCESS;
}

@end
