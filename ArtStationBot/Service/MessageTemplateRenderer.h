//
//  MessageTemplateRenderer.h
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

NS_ASSUME_NONNULL_BEGIN

@interface MessageTemplateField : NSObject
@property (nonatomic, readwrite) NSString *fullNameOfUser;
@property (nonatomic, readwrite) NSString *usernameOfUser;
@property (nonatomic, readwrite) NSString *emailOfUser;
@property (nonatomic, readwrite) NSString *skillName;
@property (nonatomic, readwrite) NSString *profileURLOfUser;
@property (nonatomic, readwrite) NSString *nameOfSender;
@property (nonatomic, readwrite) NSString *urlOfSender;
@property (nonatomic, readwrite) NSString *emailOfSender;
@end

@interface MessageTemplateRenderer : NSObject
@property (nonatomic, readwrite) NSMutableDictionary *fieldsTable;
- (instancetype)init;
- (void)setTemplateValue:(MessageTemplateField *)field;
- (NSString *)renderTemplate: (NSString *)message;
@end

NS_ASSUME_NONNULL_END
