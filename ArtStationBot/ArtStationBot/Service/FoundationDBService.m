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
static const char *appName = "artstationbot";
static const char *skills_coll_name = "skills";
static const char *users_coll_name = "users";
static const char *software_coll_name = "software";
static const char *availabilities_coll_name = "availabilities";
static const char *countries_coll_name = "countries";

static mongoc_uri_t *mongouri;
static mongoc_client_t *client;
static mongoc_database_t *database;
static mongoc_collection_t *skills_coll;
static mongoc_collection_t *users_coll;
static mongoc_collection_t *software_coll;
static mongoc_collection_t *availabilities_coll;
static mongoc_collection_t *countries_coll;
static FoundationDBService *fdb;

@interface FoundationDBService ()
@property (atomic, readwrite) dispatch_queue_t dispatchQueue;
@property (nonatomic, readwrite) NSArray<Country *> *countries;
@property (nonatomic, readwrite) NSArray<Skill *> *skills;
@end

@implementation FoundationDBService {
    NSString *_configPath;
    NSString *_config;
    char *_docLayerURL;
}

@synthesize configPath = _configPath;

+ (void)initialize {
    if (self == [self class]) {
        fdb = [FoundationDBService new];
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
    mongoc_collection_destroy(skills_coll);
    mongoc_collection_destroy(users_coll);
    mongoc_collection_destroy(software_coll);
    mongoc_collection_destroy(availabilities_coll);
    mongoc_collection_destroy(countries_coll);
    mongoc_database_destroy(database);
    mongoc_uri_destroy(mongouri);
    mongoc_client_destroy(client);
    mongoc_cleanup();
}

- (bool)fail:(bson_error_t)err {
    MONGOC_ERROR("DB error: code: %d, msg: %s" , err.code, err.message);
    return false;
}

- (void)bootstrap {
    self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    NSString *url = [Utils getDocLayerURL];
    _docLayerURL = (char *)[url UTF8String];
}

- (bool)initDocLayer {
    bson_error_t err;
    mongoc_init();
    mongouri = mongoc_uri_new_with_error(_docLayerURL, &err);
    if (!mongouri) return [self fail:err];
    client = mongoc_client_new_from_uri(mongouri);
    if (!client) return [self fail:err];
    mongoc_client_set_appname(client, appName);
    database = mongoc_client_get_database(client, dbName);
    skills_coll = mongoc_client_get_collection(client, dbName, skills_coll_name);
    users_coll = mongoc_client_get_collection(client, dbName, users_coll_name);
    software_coll = mongoc_client_get_collection(client, dbName, software_coll_name);
    availabilities_coll = mongoc_client_get_collection(client, dbName, availabilities_coll_name);
    countries_coll = mongoc_client_get_collection(client, dbName, countries_coll_name);
    return true;
}

#pragma mark Read

- (void)getUsersWithOffset:(NSUInteger)userId limit:(NSUInteger)limit callback:(void (^) (NSArray<User *> *))callback {
    dispatch_async(self.dispatchQueue, ^{
        mongoc_cursor_t *cursor;
        const bson_t *doc;
        bson_t *query = BCON_NEW("_id", "{", "$gte", BCON_INT64((int64_t)userId), "}");
        bson_t *opts = BCON_NEW("limit", BCON_INT64((int64_t)limit));
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
            MONGOC_INFO("str: %s", str);
            data = [NSData dataWithBytes:str length:(NSUInteger)strlen(str)];
            userDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            user = [self constructUserFromDictionary:userDict];
            debug(@"user obj: %@", user);
            if (user) [users addObject:user];
            debug(@"user dict: %@", userDict);
            bson_free(str);
        }
        bson_destroy(query);
        mongoc_cursor_destroy(cursor);
        callback(users);
    });
}

#pragma mark Insert

- (void)insertFilters:(Filters *)filters callback:(void (^)(BOOL))callback {
    self.countries = filters.countries;
    self.skills = filters.skills;
    dispatch_async(self.dispatchQueue, ^{
        BOOL isSuccess = YES;
        bool ret;
        if ([filters.skills count] > 0) {
            debug(@"Upserting skills");
            ret = [self upsertSkills:filters.skills];
            if (!ret) isSuccess = NO;
        }
        if ([filters.software count] > 0) {
            debug(@"Upserting software");
            ret = [self upsertSoftware:filters.software];
            if (!ret) isSuccess = NO;
        }
        if ([filters.availabilities count] > 0) {
            debug(@"Upserting availabilities");
            ret = [self upsertAvailabilities:filters.availabilities];
            if (!ret) isSuccess = NO;
        }
        if ([filters.countries count] > 0) {
            debug(@"Upserting countries");
            ret = [self upsertCountries:filters.countries];
            if (!ret) isSuccess = NO;
        }
        debug(@"Filters upsert complete");
        callback(isSuccess);
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
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(skills_coll, &opts);
    bson_destroy(&opts);
    for (skill in skills) {
        skill_doc = constructSKillBSON(skill, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_INT64((int64_t)skill.skillId)), skill_doc, true);
        bson_destroy(skill_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
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
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(software_coll, &opts);
    bson_destroy(&opts);
    for (sw in software) {
        sw_doc = constructSoftwareBSON(sw, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_INT64((int64_t)sw.softwareId)), sw_doc, true);
        bson_destroy(sw_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
    bson_destroy(&reply);
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
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(availabilities_coll, &opts);
    bson_destroy(&opts);
    for (availability in availabilities) {
        availability_doc = constructAvailabilityBSON(availability, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_UTF8([availability.availabilityId UTF8String])), availability_doc, true);
        bson_destroy(availability_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
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
    mongoc_bulk_operation_t *bulk = mongoc_collection_create_bulk_operation_with_opts(countries_coll, &opts);
    bson_destroy(&opts);
    for (country in countries) {
        country_doc = constructCountryBSON(country, true);
        mongoc_bulk_operation_update_one(bulk, BCON_NEW("_id", BCON_UTF8([country.countryId UTF8String])), country_doc, true);
        bson_destroy(country_doc);
    }
    ret = mongoc_bulk_operation_execute(bulk, &reply, &err);
    bson_destroy(&reply);
    mongoc_bulk_operation_destroy(bulk);
    if (!ret) [self fail:err];
    return true;
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

/** Inserts user info to `user` collection and a reference to the `user` to `skills["skill name"].users` collection. */
- (bool)insertUser:(User *)user {
    // db.users.insert({"_id": 123, "username": "Jane Doe", ..})
    // db.skills["2D Art"].users.insert({"_id": 1, "messaged": false, "message_info": []})
    bson_error_t err;
    // users
    bson_t *user_doc = constructUserBSON(self, user);
    bson_t reply;
    int skills_len = (int)user.skills.count;
    int i = 0;
    // skills
    mongoc_collection_t *skill_user_coll;
    bson_t *skill_user_doc;
    char *skill_coll_name = NULL;
    char *skill_name = NULL;
    bool ret = mongoc_collection_insert_one(users_coll, user_doc, NULL, &reply, &err);
    bson_destroy(&reply);
    bson_destroy(user_doc);
    if (!ret) {
        if (err.code == MONGOC_ERROR_DUPLICATE_KEY) {
            MONGOC_INFO("Document with %d already exists. Ignoring...", (int)user.userId);
        } else {
            [self fail:err];
        }
    }
    // Insert succeeded. Update the skills collections.
    for(i = 0; i < skills_len; i++) {
        skill_name = (char *)[user.skills[i].name UTF8String];
        skill_coll_name = (char *)[[NSString stringWithFormat:@"skills.%s.users", skill_name] UTF8String];
        skill_user_coll = mongoc_client_get_collection(client, dbName, skill_coll_name);
        skill_user_doc = BCON_NEW("_id", BCON_INT64(user.userId),
                                  "messaged", BCON_BOOL(NO),
                                  "message_info", "[","]");
        ret = mongoc_collection_insert_one(skill_user_coll, skill_user_doc, NULL, NULL, &err);
        bson_destroy(skill_user_doc);
        if (!ret) {
            if (err.code == MONGOC_ERROR_DUPLICATE_KEY) {
                MONGOC_INFO("User with id: %d already exists for skill: %s. Ignoring...", (int)user.userId, skill_name);
            } else {
                [self fail:err];
            }
        }
    }
    return true;
}

# pragma mark Model

- (User *)constructUserFromDictionary:(NSDictionary *)dict {
    User *user = [User new];
    id val;
    user.userId = (NSUInteger)[[(NSMutableDictionary *)[dict valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
    val = (NSString *)[dict valueForKey:@"username"];
    if (val != [NSNull null]) user.username = val;
    val = (NSString *)[dict valueForKey:@"large_avatar_url"];
    if (val != [NSNull null]) user.largeAvatarURL = val;
    val = (NSString *)[dict valueForKey:@"small_avatar_url"];
    if (val != [NSNull null]) user.smallCoverURL = val;
    val = [dict valueForKey:@"is_staff"];
    user.isStaff = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"pro_member"];
    user.isProMember = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = (NSString *)[dict valueForKey:@"artstation_profile_url"];
    if (val != [NSNull null]) user.artstationProfileURL = val;
    user.likesCount = (NSUInteger)[[(NSMutableDictionary *)[dict valueForKey:@"likes_count"] objectForKey:@"$numberLong"] integerValue];
    user.followersCount = (NSUInteger)[[(NSMutableDictionary *)[dict valueForKey:@"follower_count"] objectForKey:@"$numberLong"] integerValue];
    val = [dict valueForKey:@"available_full_time"];
    user.isAvailableFullTime = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"available_contract"];
    user.isAvailableContract = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"available_freelance"];
    user.isAvailableFreelance = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = (NSString *)[dict valueForKey:@"location"];
    if (val != [NSNull null]) user.location = val;
    val = (NSString *)[dict valueForKey:@"full_name"];
    if (val != [NSNull null]) user.fullName = val;
    val = (NSString *)[dict valueForKey:@"headline"];
    if (val != [NSNull null]) user.headline = val;
    val = [dict valueForKey:@"followed"];
    user.isFollowed = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"following_back"];
    user.isFollowingBack = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = (NSString *)[dict valueForKey:@"country"];
    if (val != [NSNull null]) {
        NSString *countryId = (NSString *)val;
        if (countryId) {
            Country *country = [[self.countries filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"countryId == %@", countryId]] firstObject];
            if (country) user.country = country;
        }
    }
    NSMutableDictionary *hm;
    // Construct sample projects
    NSMutableArray *sampleProjects = (NSMutableArray *)[dict objectForKey:@"sample_projects"];
    if ([sampleProjects count] > 0) {
        SampleProject *proj;
        user.sampleProjects = [NSMutableArray new];
        for (hm in sampleProjects) {
            proj = [SampleProject new];
            proj.sampleProjectId = (NSUInteger)[[(NSMutableDictionary *)[hm valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
            val = [hm valueForKey:@"smaller_square_cover_url"];
            if (val != [NSNull null]) proj.smallerSquareCoverURL = val;
            val = [hm valueForKey:@"url"];
            if (val != [NSNull null]) proj.url = val;
            val = [hm valueForKey:@"title"];
            if (val != [NSNull null]) proj.title = val;
            [user.sampleProjects addObject:proj];
        }
    }
    // Construct skills
    NSMutableArray *skillsArr = (NSMutableArray *)[dict objectForKey:@"skills"];
    if ([skillsArr count] > 0) {
        Skill *skill;
        user.skills = [NSMutableArray new];
        for (hm in skillsArr) {
            skill = [Skill new];
            skill.skillId = (NSUInteger)[[(NSMutableDictionary *)[hm valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
            val = [hm valueForKey:@"skill_name"];
            if (val != [NSNull null]) skill.name = val;
            [user.skills addObject:skill];
        }
    }
    // Construct software
    NSMutableArray *software = (NSMutableArray *)[dict objectForKey:@"software"];
    if ([software count] > 0) {
        user.software = [NSMutableArray new];
        Software *sw;
        for (hm in software) {
            sw = [Software new];
            sw.softwareId = (NSUInteger)[[(NSMutableDictionary *)[hm valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
            val = [hm valueForKey:@"software_name"];
            if (val != [NSNull null]) sw.name = val;
            [user.software addObject:sw];
        }
    }
    return user;
}

- (Country * _Nullable)countryFromLocation:(NSString *)location {
    NSArray *locArr = [location componentsSeparatedByString:@", "];
    NSString *countryName;
    NSArray<Country *> *countryArr;
    Country *country;
    if ([locArr count] > 0) {
        countryName = (NSString *)[locArr lastObject];
        countryArr = [self.countries filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", countryName]];
        if ([countryArr count] >= 1) {
            country = [countryArr firstObject];
        }
    }
    return country;
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
                                "follower_count", BCON_INT64((int64_t)user.followersCount),
                                "available_full_time", BCON_BOOL(user.isAvailableFullTime),
                                "available_contract", BCON_BOOL(user.isAvailableContract),
                                "available_freelance", BCON_BOOL(user.isAvailableFreelance),
                                "location", BCON_UTF8([user.location UTF8String]),
                                "full_name", BCON_UTF8([user.fullName UTF8String]),
                                "headline", BCON_UTF8([user.headline UTF8String]),
                                "followed", BCON_BOOL(user.isFollowed),
                                "following_back", BCON_BOOL(user.isFollowingBack));
    // Add country
    Country *country = [fdb countryFromLocation:user.location];
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
    MONGOC_INFO("user doc: %s", str);
    bson_free(str);
    return user_doc;
}

@end
