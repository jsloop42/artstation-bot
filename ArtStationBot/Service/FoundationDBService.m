//
//  FoundationDBService.m
//  ArtStationBot
//
//  Created by jsloop on 23/07/19.
//

#import "FoundationDBService.h"
#import "ArtStationBot-Swift.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "mongoc/mongoc.h"
#pragma clang diagnostic pop
#import "Constants.h"
//#import "bson/bcon.h"

static const char *dbName = "artstation";
static const char *skills_coll_name = "skills";
static const char *users_coll_name = "users";
static const char *software_coll_name = "software";
static const char *availabilities_coll_name = "availabilities";
static const char *countries_coll_name = "countries";
static const char *sender_coll_name = "senders";

static mongoc_uri_t *mongouri;
static mongoc_client_pool_t *pool;
static FoundationDBService *fdb;

@interface FoundationDBService ()
@property (atomic, readwrite) dispatch_queue_t dispatchQueue;
@end

@implementation FoundationDBService {
    NSString *_configPath;
    NSString *_config;
    char *_docLayerURL;
}

@synthesize configPath = _configPath;

+ (void)initialize {
    if (self == [self class]) {
        if (!fdb) fdb = [FoundationDBService new];
    }
}

+ (FoundationDBService *)shared {
    return fdb;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self bootstrap];
    }
    return self;
}

- (void)dealloc {
    mongoc_uri_destroy(mongouri);
    mongoc_client_pool_destroy(pool);
    mongoc_cleanup();
}

- (bool)fail:(bson_error_t)err {
    MONGOC_ERROR("DB error: code: %d, msg: %s" , err.code, err.message);
    return false;
}

- (void)bootstrap {
    self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    NSString *url = [Utils getDocLayerURL];
    _docLayerURL = (char *)[url UTF8String];
}

- (bool)initDocLayer {
    bson_error_t err;
    mongoc_init();
    mongouri = mongoc_uri_new_with_error(_docLayerURL, &err);
    if (!mongouri) return [self fail:err];
    pool = mongoc_client_pool_new(mongouri);
    return true;
}

#pragma mark Read

- (void)getUsersWithOffset:(NSUInteger)userId limit:(NSUInteger)limit callback:(void (^) (NSArray<User *> *users))callback {
    dispatch_async(self.dispatchQueue, ^{
        mongoc_cursor_t *cursor;
        const bson_t *doc;
        bson_t *query = BCON_NEW("_id", "{", "$gte", BCON_INT64((int64_t)userId), "}");
        bson_t *opts = BCON_NEW("limit", BCON_INT64((int64_t)limit));
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *users_coll = mongoc_client_get_collection(client, dbName, users_coll_name);
        cursor = mongoc_collection_find_with_opts(users_coll, query, opts, NULL);
        char *str;
        NSMutableArray<User *> *users = [NSMutableArray new];
        User *user;
        NSData *data;
        NSError *err;
        NSDictionary *userDict;
        while (mongoc_cursor_next(cursor, &doc)) {
            user = [User new];
            str = bson_as_canonical_extended_json(doc, NULL);
            //MONGOC_INFO("str: %s", str);
            data = [NSData dataWithBytes:str length:(NSUInteger)strlen(str)];
            bson_free(str);
            userDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            user = [ModelUtils.shared userFromDictionary:userDict convertType:ConvertTypeBSON];
            //debug(@"user obj: %@", user);
            if (user) [users addObject:user];
            //debug(@"user dict: %@", userDict);
        }
        mongoc_client_pool_push(pool, client);
        bson_destroy(query);
        mongoc_cursor_destroy(cursor);
        mongoc_collection_destroy(users_coll);
        callback(users);
    });
}

- (void)getUsersForSkill:(NSString *)skillName limit:(NSUInteger)limit isMessaged:(BOOL)isMessaged callback:(void (^) (NSArray<User *> *users))callback {
    dispatch_async(self.dispatchQueue, ^{
        mongoc_cursor_t *cursor;
        const bson_t *doc;
        bson_t *query = BCON_NEW("messaged", BCON_BOOL(isMessaged));
        bson_t *opts = BCON_NEW("limit", BCON_INT64((int64_t)limit));
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *users_coll = mongoc_client_get_collection(client, dbName, [[NSString stringWithFormat:@"skills.%@.users", skillName] UTF8String]);
        cursor = mongoc_collection_find_with_opts(users_coll, query, opts, NULL);
        char *str;
        NSMutableArray<User *> *users = [NSMutableArray new];
        User *user;
        NSData *data;
        NSError *err;
        NSDictionary *userDict;
        while (mongoc_cursor_next(cursor, &doc)) {
            user = [User new];
            str = bson_as_canonical_extended_json(doc, NULL);
            //MONGOC_INFO("str: %s", str);
            bson_free(str);
            data = [NSData dataWithBytes:str length:(NSUInteger)strlen(str)];
            userDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            user = [ModelUtils.shared userFromDictionary:userDict convertType:ConvertTypeBSON];
            if (user) [users addObject:user];
        }
        mongoc_client_pool_push(pool, client);
        bson_destroy(query);
        mongoc_cursor_destroy(cursor);
        mongoc_collection_destroy(users_coll);
        callback(users);
    });
}

- (void)getSkills:(void (^)(void))callback {
    dispatch_async(self.dispatchQueue, ^{
        mongoc_cursor_t *cursor;
        const bson_t *doc;
        char *str;
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *coll = mongoc_client_get_collection(client, dbName, skills_coll_name);
        bson_t query = BSON_INITIALIZER;
        cursor = mongoc_collection_find_with_opts(coll, &query, NULL, NULL);
        NSMutableArray<Skill *> *skills = [NSMutableArray new];
        NSError *err;
        NSMutableDictionary *dict;
        Skill *skill;
        while (mongoc_cursor_next(cursor, &doc)) {
            str = bson_as_canonical_extended_json(doc, NULL);
            dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:str length:strlen(str)] options:NSJSONReadingMutableContainers error:&err];
            bson_free(str);
            skill = [ModelUtils.shared skillFromDictionary:dict];
            [skills addObject:skill];
        }
        mongoc_client_pool_push(pool, client);
        bson_destroy(&query);
        mongoc_cursor_destroy(cursor);
        mongoc_collection_destroy(coll);
        StateData.shared.skills = skills;
        callback();
    });
}

- (void)getCrawlerState:(void(^)(CrawlerState *state))callback {
    dispatch_async(self.dispatchQueue, ^{
        Skill *skill;
        char *str;
        CrawlerState *state = [CrawlerState new];
        state.fetchState = [NSMutableDictionary new];
        NSError *err;
        NSMutableDictionary *dict;
        UserFetchState *userFetchState;
        for (skill in StateData.shared.skills) {
            mongoc_cursor_t *cursor;
            const bson_t *doc;
            mongoc_client_t *client = mongoc_client_pool_pop(pool);
            mongoc_collection_t *coll = mongoc_client_get_collection(client, dbName, [[NSString stringWithFormat:@"skills.%@", skill.name] UTF8String]);
            bson_t *query = BCON_NEW("_id", BCON_UTF8("crawl_state"));
            cursor = mongoc_collection_find_with_opts(coll, query, NULL, NULL);
            while (mongoc_cursor_next(cursor, &doc)) {
                str = bson_as_canonical_extended_json(doc, NULL);
                dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:str length:strlen(str)] options:NSJSONReadingMutableContainers error:&err];
                bson_free(str);
                userFetchState = [ModelUtils.shared userFetchStateFromDictionary:dict forSkill:skill];
                [state.fetchState setObject:userFetchState forKey:@(skill.skillId)];
            }
            mongoc_client_pool_push(pool, client);
            bson_destroy(query);
            mongoc_cursor_destroy(cursor);
            mongoc_collection_destroy(coll);
        }
        callback(state);
    });
}

- (void)getSenderDetails:(void(^)(NSMutableArray<SenderDetails *> *senders))callback {
    dispatch_async(self.dispatchQueue, ^{
        const bson_t *sender_doc;
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *sender_coll = mongoc_client_get_collection(client, dbName, sender_coll_name);
        bson_t query = BSON_INITIALIZER;
        mongoc_cursor_t *cursor = mongoc_collection_find_with_opts(sender_coll, &query, NULL, NULL);
        NSMutableArray<SenderDetails *> *senders = [NSMutableArray new];
        NSError *err;
        NSMutableDictionary *dict;
        SenderDetails *sender;
        char *str;
        while (mongoc_cursor_next(cursor, &sender_doc)) {
            str = bson_as_canonical_extended_json(sender_doc, NULL);
            dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:str length:strlen(str)] options:NSJSONReadingMutableContainers error:&err];
            sender = [ModelUtils.shared senderDetailsFromDictionary:dict];
            if (sender) [senders addObject:sender];
            bson_free(str);
        }
        mongoc_client_pool_push(pool, client);
        bson_destroy(&query);
        mongoc_cursor_destroy(cursor);
        mongoc_collection_destroy(sender_coll);
        callback(senders);
    });
}

#pragma mark Insert

- (void)insertFilters:(Filters *)filters callback:(void (^)(bool status))callback {
    StateData.shared.countries = filters.countries;
    StateData.shared.skills = filters.skills;
    bool __block isSuccess = true;
    NSLock *lock = [NSLock new];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_group_notify(group, self.dispatchQueue, ^{
        debug(@"Filters upsert complete");
        callback(isSuccess);
    });
    dispatch_async(self.dispatchQueue, ^{
        bool ret;
        if ([filters.skills count] > 0) {
            debug(@"Upserting skills");
            ret = [self upsertSkills:filters.skills];
            if (!ret) {
                [lock lock];
                isSuccess = false;
                [lock unlock];
            }
        }
        dispatch_group_leave(group);
    });
    dispatch_group_enter(group);
    dispatch_async(self.dispatchQueue, ^{
        bool ret;
        if ([filters.software count] > 0) {
            debug(@"Upserting software");
            ret = [self upsertSoftware:filters.software];
            if (!ret) {
                [lock lock];
                isSuccess = false;
                [lock unlock];
            }
        }
        dispatch_group_leave(group);
    });
    dispatch_group_enter(group);
    dispatch_async(self.dispatchQueue, ^{
        bool ret;
        if ([filters.availabilities count] > 0) {
            debug(@"Upserting availabilities");
            ret = [self upsertAvailabilities:filters.availabilities];
            if (!ret) {
                [lock lock];
                isSuccess = false;
                [lock unlock];
            }
        }
        dispatch_group_leave(group);
    });
    dispatch_async(self.dispatchQueue, ^{
        bool ret;
        if ([filters.countries count] > 0) {
            debug(@"Upserting countries");
            ret = [self upsertCountries:filters.countries];
            if (!ret) {
                [lock lock];
                isSuccess = false;
                [lock unlock];
            }
        }
    });
}

- (bool)upsertSkills:(NSMutableArray<Skill *> *)skills {
    Skill *skill;
    bson_t *skill_doc;
    bson_t reply;
    bson_error_t err;
    bool ret;
    bson_t opts = BSON_INITIALIZER;
    BSON_APPEND_BOOL(&opts, "ordered", false);
    mongoc_client_t *client = mongoc_client_pool_pop(pool);
    mongoc_collection_t *skills_coll = mongoc_client_get_collection(client, dbName, skills_coll_name);
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(skills_coll, &opts);
    bson_destroy(&opts);
    for (skill in skills) {
        skill_doc = constructSKillBSON(skill, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_INT64((int64_t)skill.skillId)), skill_doc, true);
        bson_destroy(skill_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
    mongoc_client_pool_push(pool, client);
    mongoc_collection_destroy(skills_coll);
    bson_destroy(&reply);
    mongoc_bulk_operation_destroy(bulk);
    if (!ret) [self fail:err];
    return true;
}

- (bool)upsertSoftware:(NSMutableArray<Software *> *)software {
    Software *sw;
    bson_t *sw_doc;
    bson_t reply;
    bson_error_t err;
    bool ret;
    bson_t opts = BSON_INITIALIZER;
    BSON_APPEND_BOOL(&opts, "ordered", false);
    mongoc_client_t *client = mongoc_client_pool_pop(pool);
    mongoc_collection_t *software_coll = mongoc_client_get_collection(client, dbName, software_coll_name);
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(software_coll, &opts);
    bson_destroy(&opts);
    for (sw in software) {
        sw_doc = constructSoftwareBSON(sw, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_INT64((int64_t)sw.softwareId)), sw_doc, true);
        bson_destroy(sw_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
    bson_destroy(&reply);
    mongoc_client_pool_push(pool, client);
    mongoc_collection_destroy(software_coll);
    mongoc_bulk_operation_destroy(bulk);
    if (!ret) [self fail:err];
    return true;
}

- (bool)upsertAvailabilities:(NSMutableArray<Availability *> *)availabilities {
    Availability *availability;
    bson_t *availability_doc;
    bson_t reply;
    bson_error_t err;
    bool ret;
    bson_t opts = BSON_INITIALIZER;
    BSON_APPEND_BOOL(&opts, "ordered", false);
    mongoc_client_t *client = mongoc_client_pool_pop(pool);
    mongoc_collection_t *availabilities_coll = mongoc_client_get_collection(client, dbName, availabilities_coll_name);
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(availabilities_coll, &opts);
    bson_destroy(&opts);
    for (availability in availabilities) {
        availability_doc = constructAvailabilityBSON(availability, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_UTF8([availability.availabilityId UTF8String])), availability_doc, true);
        bson_destroy(availability_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
    mongoc_client_pool_push(pool, client);
    mongoc_collection_destroy(availabilities_coll);
    bson_destroy(&reply);
    mongoc_bulk_operation_destroy(bulk);
    if (!ret) [self fail:err];
    return true;
}

- (bool)upsertCountries:(NSMutableArray<Country *> *)countries {
    Country *country;
    bson_t *country_doc;
    bson_t reply;
    bson_error_t err;
    bool ret;
    bson_t opts = BSON_INITIALIZER;
    BSON_APPEND_BOOL(&opts, "ordered", false);
    mongoc_client_t *client = mongoc_client_pool_pop(pool);
    mongoc_collection_t *countries_coll = mongoc_client_get_collection(client, dbName, countries_coll_name);
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(countries_coll, &opts);
    bson_destroy(&opts);
    for (country in countries) {
        country_doc = constructCountryBSON(country, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_UTF8([country.countryId UTF8String])), country_doc, true);
        bson_destroy(country_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
    mongoc_client_pool_push(pool, client);
    mongoc_collection_destroy(countries_coll);
    bson_destroy(&reply);
    mongoc_bulk_operation_destroy(bulk);
    if (!ret) [self fail:err];
    return true;
}

- (void)upsertSender:(SenderDetails *)sender callback:(void (^)(bool status))callback {
    dispatch_async(self.dispatchQueue, ^{
        bool status = true;
        bson_error_t err;
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *sender_coll = mongoc_client_get_collection(client, dbName, sender_coll_name);
        bson_t opts = BSON_INITIALIZER;
        BSON_APPEND_BOOL(&opts, "upsert", true);
        bson_t *sender_doc = BCON_NEW("$set", "{", "name", BCON_UTF8([sender.name UTF8String]),
                                      "contact_email", BCON_UTF8([sender.contactEmail UTF8String]),
                                      "url", BCON_UTF8([sender.url UTF8String]),
                                      "modified", BCON_DATE_TIME([Utils getTimestamp]), "}");
        bson_t *selector = BCON_NEW("_id", BCON_UTF8([sender.artStationEmail UTF8String]));
        bool ret = mongoc_collection_update_one(sender_coll, selector, sender_doc, &opts, NULL, &err);
        mongoc_client_pool_push(pool, client);
        if (!ret) {
            MONGOC_ERROR("Error updating sender details: %d, %s", err.code, err.message);
            status = false;
        }
        bson_destroy(selector);
        bson_destroy(sender_doc);
        mongoc_collection_destroy(sender_coll);
        callback(status);
    });
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
    user.location = @"Oxford, United Kingdom";
    [self insertUser:user];
}

- (void)insertUser:(User *)user {
    [self insertUser:user callback:nil];
}

/** Inserts user info to `user` collection and a reference to the `user` to `skills["skill name"].users` collection. */
- (void)insertUser:(User *)user callback:(void (^)(bool status))callback {
    // db.users.insert({"_id": 123, "username": "Jane Doe", ..})
    // db.skills["2D Art"].users.insert({"_id": 1, "messaged": false, "message_info": []})
    dispatch_async(self.dispatchQueue, ^{
        bool status = true;
        bson_error_t err;
        // users
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *user_coll = mongoc_client_get_collection(client, dbName, users_coll_name);
        bson_t *user_doc = constructUserBSON(self, user);
        bson_t reply;
        int skills_len = (int)user.skills.count;
        int i = 0;
        // skills
        mongoc_collection_t *skill_user_coll;
        bson_t *skill_user_doc;
        char *skill_coll_name = NULL;
        char *skill_name = NULL;
        bool ret = mongoc_collection_insert_one(user_coll, user_doc, NULL, &reply, &err);
        mongoc_client_pool_push(pool, client);
        mongoc_collection_destroy(user_coll);
        bson_destroy(&reply);
        bson_destroy(user_doc);
        if (!ret) {
            if (err.code == MONGOC_ERROR_DUPLICATE_KEY) {
                MONGOC_INFO("Document with %d already exists. Ignoring...", (int)user.userId);
            } else {
                MONGOC_ERROR("Error adding user. %d, %s", err.code, err.message);
                status = false;
            }
        }
        // Insert succeeded. Update the skills collections.
        for(i = 0; i < skills_len; i++) {
            skill_name = (char *)[user.skills[i].name UTF8String];
            skill_coll_name = (char *)[[NSString stringWithFormat:@"skills.%s.users", skill_name] UTF8String];
            mongoc_client_t *client = mongoc_client_pool_pop(pool);
            skill_user_coll = mongoc_client_get_collection(client, dbName, skill_coll_name);
            skill_user_doc = BCON_NEW("_id", BCON_INT64(user.userId),
                                      "messaged", BCON_BOOL(NO),
                                      "message_info", "[","]");
            ret = mongoc_collection_insert_one(skill_user_coll, skill_user_doc, NULL, NULL, &err);
            mongoc_client_pool_push(pool, client);
            bson_destroy(skill_user_doc);
            mongoc_collection_destroy(skill_user_coll);
            if (!ret) {
                if (err.code == MONGOC_ERROR_DUPLICATE_KEY) {
                    MONGOC_INFO("User with id: %d already exists for skill: %s. Ignoring...", (int)user.userId, skill_name);
                } else {
                    MONGOC_ERROR("Error adding user to skill. %d, %s", err.code, err.message);
                    status = false;
                }
            }
        }
        if (callback) callback(status);
    });
}

- (void)updateCrawlerState:(NSString *)skillName page:(NSUInteger)page totalCount:(NSUInteger)totalCount callback:(void (^)(bool status))callback {
    dispatch_async(self.dispatchQueue, ^{
        bool status = true;
        bson_error_t err;
        bson_t opts = BSON_INITIALIZER;
        BSON_APPEND_BOOL(&opts, "upsert", true);
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *coll = mongoc_client_get_collection(client, dbName, [[NSString stringWithFormat:@"skills.%@", skillName] UTF8String]);
        bson_t *state_doc = BCON_NEW("$set", "{",
                                     "page", BCON_INT64((int64_t)page),
                                     "total_count", BCON_INT64((int64_t)totalCount), "}");
        bson_t *selector = BCON_NEW("_id", BCON_UTF8("crawl_state"));
        bool ret = mongoc_collection_update_one(coll, selector, state_doc, &opts, NULL, &err);
        mongoc_client_pool_push(pool, client);
        if (!ret) {
            MONGOC_ERROR("Error updating crawler state: %d, %s", err.code, err.message);
            status = false;
        }
        bson_destroy(selector);
        bson_destroy(state_doc);
        mongoc_collection_destroy(coll);
        callback(status);
    });
}

- (void)updateMessage:(NSString *)message forSkill:(Skill *)skill callback:(void (^)(bool status))callback {
    dispatch_async(self.dispatchQueue, ^{
        bool status = true;
        bson_error_t err;
        bson_t opts = BSON_INITIALIZER;
        BSON_APPEND_BOOL(&opts, "upsert", true);
        mongoc_client_t *client = mongoc_client_pool_pop(pool);
        mongoc_collection_t *coll = mongoc_client_get_collection(client, dbName, skills_coll_name);
        bson_t *skill_doc = BCON_NEW("$set", "{", "message", BCON_UTF8([message UTF8String]), "}");
        bson_t *selector = BCON_NEW("_id", BCON_INT64((int64_t)skill.skillId));
        bool ret = mongoc_collection_update_one(coll, selector, skill_doc, &opts, NULL, &err);
        mongoc_client_pool_push(pool, client);
        if (!ret) {
            MONGOC_ERROR("Error updating skill message: %d, %s", err.code, err.message);
            status = false;
        }
        bson_destroy(selector);
        bson_destroy(skill_doc);
        mongoc_collection_destroy(coll);
        callback(status);
    });
}

#pragma mark BSON

bson_t *constructSKillBSON(Skill *skill, bool isUpdate) {
    return isUpdate ? BCON_NEW("$set", "{", "name", BCON_UTF8([skill.name UTF8String]), "}")
                    : BCON_NEW("_id", BCON_INT64((int64_t)skill.skillId), "name", BCON_UTF8([skill.name UTF8String]));
}

bson_t *constructSoftwareBSON(Software *software, bool isUpdate) {
    return isUpdate ? BCON_NEW("$set", "{", "name", BCON_UTF8([software.name UTF8String]), "icon_url", BCON_UTF8([software.iconURL UTF8String]), "}")
                    : BCON_NEW("_id", BCON_INT64((int64_t)software.softwareId), "name", BCON_UTF8([software.name UTF8String]),
                               "icon_url", BCON_UTF8([software.iconURL UTF8String]));
}

bson_t *constructAvailabilityBSON(Availability *availability, bool isUpdate) {
    return isUpdate ? BCON_NEW("$set", "{", "name", BCON_UTF8([availability.name UTF8String]), "}")
                    : BCON_NEW("_id", BCON_UTF8([availability.availabilityId UTF8String]), "name", BCON_UTF8([availability.name UTF8String]));
}

bson_t *constructCountryBSON(Country *country, bool isUpdate) {
    return isUpdate ? BCON_NEW("$set", "{", "name", BCON_UTF8([country.name UTF8String]), "}")
                    : BCON_NEW("_id", BCON_UTF8([country.countryId UTF8String]), "name", BCON_UTF8([country.name UTF8String]));
}

bson_t *constructUserBSON(FoundationDBService *fbd, User *user) {
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
    bson_t *user_doc = BCON_NEW("_id", BCON_INT64((int64_t)user_id),
                                "username", BCON_UTF8([user.username UTF8String]),
                                "large_avatar_url", BCON_UTF8([user.largeAvatarURL UTF8String]),
                                "small_cover_url", BCON_UTF8([user.smallCoverURL UTF8String]),
                                "is_staff", BCON_BOOL(user.isStaff),
                                "pro_member", BCON_BOOL(user.isProMember),
                                "artstation_profile_url", BCON_UTF8([user.artstationProfileURL UTF8String]),
                                "likes_count", BCON_INT64((int64_t)user.likesCount),
                                "followers_count", BCON_INT64((int64_t)user.followersCount),
                                "available_full_time", BCON_BOOL(user.isAvailableFullTime),
                                "available_contract", BCON_BOOL(user.isAvailableContract),
                                "available_freelance", BCON_BOOL(user.isAvailableFreelance),
                                "location", BCON_UTF8([user.location UTF8String]),
                                "full_name", BCON_UTF8([user.fullName UTF8String]),
                                "headline", BCON_UTF8([user.headline UTF8String]),
                                "followed", BCON_BOOL(user.isFollowed),
                                "following_back", BCON_BOOL(user.isFollowingBack));
    // Add country
    Country *country = [ModelUtils.shared countryFromLocation:user.location];  // NOTE: Country name does not match name from the filter's list
    if (country) BSON_APPEND_UTF8(user_doc, "country", [country.countryId UTF8String]);
    // Append skills
    BSON_APPEND_ARRAY_BEGIN(user_doc, "skills", &skills);
    for (i = 0; i < skills_len; ++i) {
        keylen = bson_uint32_to_string(i, &key, buf, sizeof(buf));
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
        keylen = bson_uint32_to_string(i, &key, buf, sizeof(buf));
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
        keylen = bson_uint32_to_string(i, &key, buf, sizeof(buf));
        bson_append_document_begin(&sample_project, key, (int)keylen, &sample_project_doc);
        BSON_APPEND_INT64(&sample_project_doc, "_id", (int64_t)user.sampleProjects[i].sampleProjectId);
        BSON_APPEND_UTF8(&sample_project_doc, "smaller_square_cover_url", [user.sampleProjects[i].smallerSquareCoverURL UTF8String]);
        BSON_APPEND_UTF8(&sample_project_doc, "url", [user.sampleProjects[i].url UTF8String]);
        BSON_APPEND_UTF8(&sample_project_doc, "title", [user.sampleProjects[i].title UTF8String]);
        bson_append_document_end(&sample_project, &sample_project_doc);
    }
    bson_append_array_end(user_doc, &sample_project);
    str = bson_as_canonical_extended_json(user_doc, NULL);
    bson_free(str);
    return user_doc;
}

@end
