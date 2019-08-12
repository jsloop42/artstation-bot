//
//  ASTableView.m
//  ArtStationBot
//
//  Created by jsloop on 11/08/19.
//

#import "ASTableViewBuilder.h"

@implementation ASTableViewBuilder {
    NSScrollView *_scrollView;
    NSTableView *_tableView;
    NSTextField *_cellTextField;
}

@synthesize tableView = _tableView;

- (NSScrollView *)tableViewWithView:(NSView *)view columns:(NSUInteger)columns columnNames:(NSMutableArray *)columnNames {
    _scrollView = [[NSScrollView alloc] initWithFrame:view.bounds];
    [_scrollView setBorderType:NSBezelBorder];
    self.tableView = [[NSTableView alloc] initWithFrame:view.bounds];
    NSTableColumn *col;
    NSInteger i = 0;
    for (i = 0; i < columns; i++) {
        col = [[NSTableColumn alloc] initWithIdentifier:[columnNames objectAtIndex:i]];
        if (i == 2) {
            [col setWidth: NSApp.mainWindow.frame.size.width - 672];
        } else if (i == 1) {
            [col setWidth:320];
        } else {
            [col setWidth:100];
        }
        [[col headerCell] setStringValue:[columnNames objectAtIndex:i]];
        [_tableView addTableColumn:col];
    }
    [_tableView setUsesAlternatingRowBackgroundColors:YES];
    [_tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
    [_tableView setRowHeight:23.0];
    [_tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
    [_tableView setAutoresizesSubviews:YES];
    [_tableView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:NO];
    [_scrollView setAutoresizesSubviews:YES];
    [_scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_scrollView setDocumentView:_tableView];

    return _scrollView;
}

@end


