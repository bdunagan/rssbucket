//
//  MainController.m
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

#import "MainController.h"
#import "Feed.h"
#import "FeedItem.h"
#import "BDLinkArrowCell.h"

// Update every 10 minutes.
static int UPDATE_FEED_INTERVAL = 600;
#define DEFAULTS_KEY @"feeds"

@implementation MainController

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		_isUpdatingFeeds = NO;
		
		// Trigger update timer periodically.
		[NSTimer scheduledTimerWithTimeInterval:UPDATE_FEED_INTERVAL
										 target:self
									   selector:@selector(updateFeeds:)
									   userInfo:nil
										repeats:YES];
	}
	return self;
}

- (void)awakeFromNib
{
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Check user defaults.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *defaultFeeds = [defaults arrayForKey:DEFAULTS_KEY];
	if (defaultFeeds == nil)
	{
		// No stored defaults. Use the default ones.
		defaultFeeds = [NSArray arrayWithObjects:@"http://feeds.feedburner.com/TechCrunch", @"http://www.tuaw.com/rss.xml", @"http://www.appleinsider.com/appleinsider.rss", nil];
	}
	
	// Add default feeds.
	NSEnumerator *feedEnumerator = [defaultFeeds objectEnumerator];
	NSString *feedString;
	while (feedString = [feedEnumerator nextObject])
	{
		[self addFeedToList:feedString];
	}

	// Update.
	[self updateFeeds:nil];
	[sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	// Update user defaults.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *feedStrings = [NSMutableArray array];
	NSEnumerator *feedEnumerator = [[feeds arrangedObjects] objectEnumerator];
	Feed *feed;
	while (feed = [feedEnumerator nextObject])
	{
		[feedStrings addObject:[[feed valueForKeyPath:@"properties.url"] absoluteString]];
	}
	if ([feedStrings count] > 0)
	{
		[defaults setObject:feedStrings forKey:DEFAULTS_KEY];
	}
	
	return NSTerminateNow;
}

//
// Properties
//

- (NSArrayController *)feeds
{
	return feeds;
}

//
// UI Methods
//

- (IBAction)clickAddRemoveButtons:(id)sender
{
	int segmentIndex = [sender selectedSegment];
	[sender setSelected:NO forSegment:segmentIndex];
	if (segmentIndex == 0)
	{
		// Add
		[self clickAddFeed:nil];
	}
	else
	{
		// Remove
		[self clickRemoveFeed:nil];
	}
}

- (IBAction)clickAddFeed:(id)sender
{
	// Null out any lingering data.
	[validateIcon setImage:nil];
	[urlField setStringValue:@""];

	[NSApp beginSheet:addFeedSheet
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)clickRemoveFeed:(id)sender
{
	[feeds removeObjects:[feeds selectedObjects]];

	// Reload source list.
	[sourceList reloadData];
	if ([sourceList selectedRow] < 0)
	{
		[sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}

	// Disable remove buttons if no feeds.
	if ([[feeds arrangedObjects] count] == 0)
	{
		[self setRemoveFeed:NO];
	}
}

- (IBAction)clickResetDefaults:(id)sender
{
	// Update user defaults to the defaults.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *defaultFeeds = [NSArray arrayWithObjects:@"http://feeds.feedburner.com/TechCrunch", @"http://www.tuaw.com/rss.xml", @"http://www.appleinsider.com/appleinsider.rss", nil];
	[defaults setObject:defaultFeeds forKey:DEFAULTS_KEY];

	// Remove current feeds.
	[feeds removeObjects:[feeds arrangedObjects]];
	
	// Add default feeds.
	NSEnumerator *feedEnumerator = [defaultFeeds objectEnumerator];
	NSString *feedString;
	while (feedString = [feedEnumerator nextObject])
	{
		[self addFeedToList:feedString];
	}
	
	// Update.
	[self updateFeeds:nil];
	[sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (IBAction)okAddFeed:(id)sender
{
	NSString *feedString = [urlField stringValue];
	BOOL isAdded = [self addFeedToList:feedString];
	if (isAdded)
	{
		[NSApp endSheet:addFeedSheet];
		[addFeedSheet orderOut:self];
		[sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:[feeds selectionIndex]] byExtendingSelection:NO];

		// Enable remove buttons just in case.
		[self setRemoveFeed:YES];
	}
	else
	{
		[validateIcon setImage:[NSImage imageNamed:NSImageNameInvalidDataFreestandingTemplate]];
	}
}

- (IBAction)cancelAddFeed:(id)sender
{
	[NSApp endSheet:addFeedSheet];
    [addFeedSheet orderOut:self];
}

- (IBAction)openURLInBrowser:(id)sender
{
	if ([[feedItems selectedObjects] count] > 0)
	{
		// Load selected item into WebView.
		FeedItem *selectedItem = [[feedItems selectedObjects] objectAtIndex:0];
		NSURL *url = [[[selectedItem properties] objectForKey:@"url"] copy];
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
}

- (IBAction)updateFeeds:(id)sender
{
	// Ensure the update thread is a singleton.
	if (_updateThread == nil || [_updateThread isFinished])
	{
		[_updateThread release];
		_updateThread = [[NSThread alloc] initWithTarget:self selector:@selector(_updateFeeds) object:nil];
		[_updateThread start];
	}
}

//
// Methods
//

- (void)_updateFeeds
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[self setRemoveFeed:NO];

	NSLog(@"updating feeds");
	NSArray *feedArray = [feeds arrangedObjects];
	NSEnumerator *feedEnumerator = [feedArray objectEnumerator];
	Feed *feed;
	while (feed = [feedEnumerator nextObject])
	{
		[feed updateFeed];
	}
	
	[self setRemoveFeed:YES];
	
	[pool release];
}

- (BOOL)addFeedToList:(NSString *)feedString
{
	NSURL *feedUrl = [NSURL URLWithString:feedString];
	Feed *feed = [[[Feed alloc] initWithUrl:feedUrl] autorelease];
	if (feed != nil)
	{
		[feeds addObject:feed];
		[sourceList reloadData];
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)loadUrlIntoWebView:(NSURL *)url
{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)updateWebView
{
	if ([[feedItems selectedObjects] count] > 0)
	{
		// Load selected item into WebView.
		FeedItem *selectedItem = [[feedItems selectedObjects] objectAtIndex:0];
		NSURL *url = [[selectedItem properties] objectForKey:@"url"];
		[self loadUrlIntoWebView:url];
	}
}

- (void)setRemoveFeed:(BOOL)isEnabled
{
	[addRemoveButtons setEnabled:isEnabled forSegment:1];
	[removeMenuItem setEnabled:isEnabled];
}

//
// TableView delegates
//

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier] isEqualToString:@"Title"])
	{
		// Set title.
		FeedItem *currentFeedItem = [[feedItems arrangedObjects] objectAtIndex:rowIndex];
		[aCell setTitle:[currentFeedItem valueForKeyPath:@"properties.title"]];
		
		// Set link arrow visibility.
		[aCell setLinkVisible:([aTableView selectedRow] == rowIndex)];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateWebView];
}

//
// SplitView delegates
//

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	if (sender == sourceListSplitView && offset == 0)
	{
		return 300;
	}
	else
	{
		return proposedMax;
	}
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	if (sender == sourceListSplitView && offset == 0)
	{
		return 150;
	}
	else if (sender == itemsSplitView && offset == 0)
	{
		return 100;
	}
	else
	{
		return proposedMin;
	}
}

@end
