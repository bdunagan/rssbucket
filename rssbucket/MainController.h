//
//  MainController.h
//  rssbucket
//
// Copyright 2008 Brian Dunagan (brian@bdunagan.com)
//
// MIT License
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "BDSourceListController.h"

@interface MainController : NSObject
{
	// Main View
	IBOutlet NSSplitView *sourceListSplitView;
	IBOutlet NSSplitView *itemsSplitView;
	IBOutlet NSTableView *sourceList;
	IBOutlet NSTableView *itemsView;
	IBOutlet WebView *webView;
	IBOutlet NSSegmentedControl *addRemoveButtons;
	IBOutlet NSMenuItem *removeMenuItem;
	IBOutlet BDSourceListController *sourceListController;
	
	// Add Feed Sheet
	IBOutlet NSPanel *addFeedSheet;
	IBOutlet NSTextField *urlField;
	IBOutlet NSButton *addFeedButton;
	IBOutlet NSImageView *validateIcon;
	
	// Data
	IBOutlet NSArrayController *feeds;
	IBOutlet NSArrayController *feedItems;
	BOOL _isUpdatingFeeds;
	NSThread *_updateThread;
}

- (NSArrayController *)feeds;
- (void)updateWebView;

- (IBAction)updateFeeds:(id)sender;
- (BOOL)addFeedToList:(NSString *)feedString;
- (void)loadUrlIntoWebView:(NSURL *)url;
- (IBAction)openURLInBrowser:(id)sender;
- (IBAction)clickAddRemoveButtons:(id)sender;
- (IBAction)clickRemoveFeed:(id)sender;
- (IBAction)clickResetDefaults:(id)sender;
- (void)setRemoveFeed:(BOOL)isEnabled;

// Add Feed Sheet
- (IBAction)clickAddFeed:(id)sender;
- (IBAction)okAddFeed:(id)sender;
- (IBAction)cancelAddFeed:(id)sender;

@end
