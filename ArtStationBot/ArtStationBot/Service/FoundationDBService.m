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
    [self test];
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

- (void)test {
    User *user = [User new];
    user.userId = 1;
    user.username = @"Jane Doe";
    user.isStaff = YES;
    user.skills = [NSMutableArray new];
    Skill *skill = [Skill new];
    skill.name = @"2D Art";
    [user.skills addObject:skill];
    Software *software = [Software new];
    software.name = @"Houdini";
    user.software = [NSMutableArray new];
    [user.software addObject:software];
    SampleProject *proj = [SampleProject new];
    proj.sampleProjectId = 1;
    proj.url = @"https://example.com";
    proj.smallerSquareCoverURL = @"https://example.com/cover.jpg";
    proj.title = @"Example project";
    user.sampleProjects = [NSMutableArray new];
    [user.sampleProjects addObject:proj];
    [self insertUser:user];
}

- (int)insertUser:(User *)user {
    // user_json: {"_id": 123, "username": "Foo"}
    // "2D Animation": {"_id": 1, "users": [123]} // db["2D Animation"].update({"_id": 1}, {"$push": {"users": 123}})
    // FIXME: insert docs to user, skills
    bson_error_t err;
    bson_t *user_doc = constructUserBSON(user, &err);
    return EXIT_SUCCESS;
}

bson_t *constructUserBSON(User *user, bson_error_t *err) {
    int user_id = (int)user.userId;
    int i = 0;
    bson_t skills;
    bson_t skills_doc;
    bson_t software;
    bson_t software_doc;
    bson_t sample_project;
    bson_t sample_project_doc;
    int skills_len = (int)user.skills.count;
    int software_len = (int)user.software.count;
    int sample_project_len = (int)user.sampleProjects.count;
    const char *key;
    char buf[16];
    size_t keylen;
    char *str;
    bson_t *user_doc = BCON_NEW("_id", BCON_INT64(user_id),
                                "username", BCON_UTF8([user.username UTF8String]),
                                "large_avatar_url", BCON_UTF8([user.largeAvatarURL UTF8String]),
                                "small_cover_url", BCON_UTF8([user.smallCoverURL UTF8String]),
                                "is_staff", BCON_BOOL(user.isStaff),
                                "pro_member", BCON_BOOL(user.isProMember),
                                "artstation_profile_url", BCON_UTF8([user.artstationProfileURL UTF8String]),
                                "likesCount", BCON_INT64((int64_t)user.likesCount),
                                "follower_count", BCON_INT64((int64_t)user.followersCount),
                                "available_full_time", BCON_BOOL(user.isAvailableFullTime),
                                "available_contract", BCON_BOOL(user.isAvailableContract),
                                "available_freelance", BCON_BOOL(user.isAvailableFreelance),
                                "location", BCON_UTF8([user.location UTF8String]),
                                "full_name", BCON_UTF8([user.fullName UTF8String]),
                                "headline", BCON_UTF8([user.headline UTF8String]),
                                "followed", BCON_BOOL(user.isFollowed),
                                "following_back", BCON_BOOL(user.isFollowingBack));
    // Append skills
    BSON_APPEND_ARRAY_BEGIN(user_doc, "skills", &skills);
    for (i = 0; i < skills_len; ++i) {
        keylen = bson_uint32_to_string(i, &key, buf, sizeof buf);
        bson_append_document_begin(&skills, key, (int)keylen, &skills_doc);
        BSON_APPEND_UTF8(&skills_doc, "skill_name", [user.skills[i].name UTF8String]);
        bson_append_document_end(&skills, &skills_doc);
    }
    bson_append_array_end(user_doc, &skills);
    // Append software
    key = NULL;
    keylen = 0;
    BSON_APPEND_ARRAY_BEGIN(user_doc, "software", &software);
    for (i = 0; i < software_len; ++i) {
        keylen = bson_uint32_to_string(i, &key, buf, sizeof buf);
        bson_append_document_begin(&software, key, (int)keylen, &software_doc);
        BSON_APPEND_UTF8(&software_doc, "software_name", [user.software[i].name UTF8String]);
        bson_append_document_end(&software, &software_doc);
    }
    bson_append_array_end(user_doc, &software);
    // Append sample projects
    key = NULL;
    keylen = 0;
    BSON_APPEND_ARRAY_BEGIN(user_doc, "sample_projects", &sample_project);
    for (i = 0; i < sample_project_len; ++i) {
        keylen = bson_uint32_to_string(i, &key, buf, sizeof buf);
        bson_append_document_begin(&sample_project, key, (int)keylen, &sample_project_doc);
        BSON_APPEND_INT64(&sample_project_doc, "_id", (int64_t)user.sampleProjects[i].sampleProjectId);
        BSON_APPEND_UTF8(&sample_project_doc, "smaller_square_cover_url", [user.sampleProjects[i].smallerSquareCoverURL UTF8String]);
        BSON_APPEND_UTF8(&sample_project_doc, "url", [user.sampleProjects[i].url UTF8String]);
        BSON_APPEND_UTF8(&sample_project_doc, "title", [user.sampleProjects[i].title UTF8String]);
        bson_append_document_end(&sample_project, &sample_project_doc);
    }
    bson_append_array_end(user_doc, &sample_project);
    str = bson_as_canonical_extended_json(user_doc, NULL);
    MONGOC_INFO("user doc: %s", str);
    bson_free(str);
    return user_doc;
}

@end
