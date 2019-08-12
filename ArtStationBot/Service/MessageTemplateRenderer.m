//
//  MessageTemplateRenderer.m
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

#import "MessageTemplateRenderer.h"

static NSString * const _fullNameKey = @"${user.fullName}";
static NSString * const _usernameKey = @"${user.username}";
static NSString * const _emailKey = @"${user.email}";
static NSString * const _skillNameKey = @"${skill.name}";
static NSString * const _profileURLKey = @"${user.profileURL}";
static NSString * const _senderNameKey = @"${sender.name}";
static NSString * const _senderURLKey = @"${sender.url}";
static NSString * const _senderEmailKey = @"${sender.email}";
static NSString * const _pattern = @"(\\$\\{([a-z|.|A-Z|0-9]+)\\})+";
static NSRegularExpression *_regex;

@implementation MessageTemplateField
@end

@implementation MessageTemplateRenderer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self bootstrap];
    }
    return self;
}

- (void)bootstrap {
    _regex = [NSRegularExpression regularExpressionWithPattern:_pattern options:0 error:nil];
    self.fieldsTable = [NSMutableDictionary new];
}

- (void)setTemplateValue:(MessageTemplateField *)field {
    [self.fieldsTable setValue:field.fullNameOfUser forKey:_fullNameKey];
    [self.fieldsTable setValue:field.usernameOfUser forKey:_usernameKey];
    [self.fieldsTable setValue:field.emailOfUser forKey:_emailKey];
    [self.fieldsTable setValue:field.profileURLOfUser forKey:_profileURLKey];
    [self.fieldsTable setValue:field.skillName forKey:_skillNameKey];
    [self.fieldsTable setValue:field.nameOfSender forKey:_senderNameKey];
    [self.fieldsTable setValue:field.urlOfSender forKey:_senderURLKey];
    [self.fieldsTable setValue:field.emailOfSender forKey:_senderEmailKey];
}

- (NSString *)renderTemplate:(NSString *)message {
    NSString *ptn;
    NSArray *keys = [self.fieldsTable allKeys];
    for (ptn in keys) {
        message = [self replaceString:ptn replacementValue:[self.fieldsTable valueForKey:ptn] inTemplate:message];
    }
    return message;
}

- (NSArray *)matchPattern:(NSRegularExpression *)regex inString:(NSString *)string {
    return [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
}

- (NSString *)replaceString:(NSString *)string replacementValue:(NSString *)value inTemplate:(NSString *)template {
    return [template stringByReplacingOccurrencesOfString:string withString:value];
}

@end
