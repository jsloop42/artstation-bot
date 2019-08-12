//
//  ASTableView.h
//  ArtStationBot
//
//  Created by jsloop on 11/08/19.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASTableViewBuilder : NSObject
@property (nonatomic, readwrite, retain) NSTableView *tableView;
- (NSScrollView *)tableViewWithView:(NSView *)view columns:(NSUInteger)columns columnNames:(NSMutableArray *)columnNames;
@end

NS_ASSUME_NONNULL_END
