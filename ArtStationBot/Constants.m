//
//  Constants.m
//  ArtStationBot
//
//  Created by jsloop on 01/08/19.
//

#import "Constants.h"

static NSString *_seedURL;
static NSString *_csrfURL;
static NSString *_contentTypeJSON;
static NSString *_host;
static NSString *_filterFieldsFrag;
static NSString *_searchUsers;
static NSString *_csrfTokenHeader;
static NSString *_cfCSRFTokenHeader;
static NSUInteger _maxUserLimit;
static NSString *_serviceName;

@implementation Constants

@dynamic serviceName;

+ (void)initialize {
    if (self == [self class]) {
        [self bootstrap];
    }
}

+ (void)bootstrap {
    _seedURL = @"https://artstation.com/";
    _csrfURL = [NSString stringWithFormat:@"%@api/v2/csrf_protection/token.json", _seedURL];
    _contentTypeJSON = @"application/json";
    _host = @"artstation.com";
    _filterFieldsFrag = @"api/v2/search/users/filter_fields.json";
    _searchUsers = @"api/v2/search/users.json";
    _csrfTokenHeader = @"PUBLIC-CSRF-TOKEN";
    _cfCSRFTokenHeader = @"x-csrf-token";
    _maxUserLimit = 15;
    _serviceName = @"artstationbot";
}

+ (NSString *)seedURL {
    return _seedURL;
}

+ (NSString *)csrfTokenURL {
    return _csrfURL;
}

+ (NSString *)contentTypeJSON {
    return _contentTypeJSON;
}

+ (NSString *)domain {
    return _host;
}

+ (NSString *)filterListFragment {
    return _filterFieldsFrag;
}

+ (NSString *)filterListURL {
    return [NSString stringWithFormat:@"%@%@", _seedURL, _filterFieldsFrag];
}

+ (NSString *)searchUsersURL {
    return [NSString stringWithFormat:@"%@%@", _seedURL, _searchUsers];
}

+ (NSString *)csrfTokenHeader {
    return _csrfTokenHeader;
}

+ (NSString *)cloudFlareCSRFTokenHeader {
    return _cfCSRFTokenHeader;
}

+ (NSUInteger)maxUserLimit {
    return _maxUserLimit;
}

+ (NSString *)serviceName {
    return _serviceName;
}

@end

@implementation ASNotification
static NSString *_sendMessage = @"sendMessage";
static NSString *_sendMessageACK = @"sendMessageACK";
static NSString *_settingsTableViewShouldReload = @"settingsTableViewShouldReload";
static NSString *_dashboardTableViewShouldReload = @"dashboardTableViewShouldReload";
static NSString *_crawlerDidPause = @"crawlerDidPause";
static NSString *_messengerDidPause = @"messengerDidPause";

@dynamic sendMessage;
@dynamic sendMessageACK;
@dynamic settingsTableViewShouldReload;
@dynamic dashboardTableViewShouldReload;
@dynamic crawlerDidPause;
@dynamic messengerDidPause;

+ (NSString *)sendMessage {
    return _sendMessage;
}

+ (NSString *)sendMessageACK {
    return _sendMessageACK;
}

+ (NSString *)settingsTableViewShouldReload {
    return _settingsTableViewShouldReload;
}

+ (NSString *)dashboardTableViewShouldReload {
    return _dashboardTableViewShouldReload;
}

+ (NSString *)crawlerDidPause {
    return _crawlerDidPause;
}

+ (NSString *)messengerDidPause {
    return _messengerDidPause;
}

@end
