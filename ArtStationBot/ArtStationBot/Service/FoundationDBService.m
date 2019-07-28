//
//  FoundationDBService.m
//  ArtStationBot
//
//  Created by jsloop on 23/07/19.
//

#import "FoundationDBService.h"
#import "ArtStationBot-Swift.h"

#define NSLog(FORMAT, ...) fprintf(stderr, "%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#ifdef DEBUG
#   define debug(...) NSLog(__VA_ARGS__)
#   define info(...) NSLog(__VA_ARGS__)
#   define error(...) NSLog(__VA_ARGS__)
#else
#   define info(...) NSLog(__VA_ARGS__)
#   define error(...) NSLog(__VA_ARGS__)
#endif

@implementation FoundationDBService {
    NSString *_configPath;
    NSString *_config;
    FDBDatabase *_db;
}

@synthesize configPath = _configPath;
@synthesize db = _db;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self bootstrap];
        [self initDB];
        [self transactionReadVersion];
    }
    return self;
}

- (void)bootstrap {
    self.configPath = [Utils getFoundationDBClusterConfigPath];
}

- (void)initDB {
    fdb_select_api_version_impl(FDB_API_VERSION, FDB_API_VERSION);
    fdb_setup_network();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        fdb_run_network();
    });
    FDBDatabase *db = nil;
    fdb_error_t err =  fdb_create_database([self.configPath UTF8String], &db);
    self.db = db;
    debug(@"%d", err);
}

- (void)transactionReadVersion {
    FDBTransaction *tran;
    fdb_error_t err = fdb_database_create_transaction(self.db, &tran);
    debug(@"%d", err);
    FDBFuture *f = fdb_transaction_get_read_version(tran);
    err = fdb_future_block_until_ready(f);
    debug(@"%d", err);
    int64_t version = 0;
    err = fdb_future_get_version(f, &version);
    debug(@"%d", err);
    debug(@"%lld", version);
    fdb_future_destroy(f);
    fdb_transaction_destroy(tran);
}

@end
