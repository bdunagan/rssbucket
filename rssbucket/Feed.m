//
//  Feed.m
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

#import "Feed.h"
#import "FeedItem.h"

@implementation Feed

- (id)init
{
	return [self initWithUrl:@""];
}

- (id)initWithUrl:(NSURL *)url
{
    if (self = [super init])
    {
		_feedItems = [[NSMutableArray alloc] init];
	
        _properties = [[NSMutableDictionary alloc] init];
		[_properties setValue:url forKey:@"url"];
		[_properties setValue:[NSDate date] forKey:@"date"];

		NSImage *icon = [NSImage imageNamed:NSImageNameNetwork];
		[icon setSize:NSMakeSize(16, 16)];
		[_properties setValue:icon forKey:@"icon"];

		NSLog(@"adding feed: %@", url);
		BOOL isValid = [self updateFeed];
		if (!isValid)
		{
			NSLog(@"adding feed %@ failed", url);
			return nil;
		}
    }
    return self;
}

- (void)dealloc
{
	[_feedItems release];
	[_properties release];
    [super dealloc];
}

- (NSMutableDictionary *)properties
{
    return _properties;
}

- (void)setProperties:(NSDictionary *)newProperties
{
	[_properties release];
	_properties = [[NSMutableDictionary alloc] initWithDictionary:newProperties];
}

- (NSMutableArray *)feedItems
{
	return _feedItems;
}
	
- (void)setFeedItems:(NSDictionary *)newFeedItems
{
	[_feedItems release];
	_feedItems = [[NSMutableDictionary alloc] initWithDictionary:newFeedItems];
}

- (BOOL)updateFeed
{
	@try
	{
		
		NSURL *url = [_properties objectForKey:@"url"];

		NSError *error;
		NSXMLDocument *feedContents = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error] autorelease];

		NSXMLNode *titleNode = [[[feedContents rootElement] nodesForXPath:@"/rss[1]/channel[1]/title[1]" error:&error] objectAtIndex:0];
		NSString *title = [titleNode stringValue];
		[_properties setValue:title forKey:@"title"];

		NSXMLNode *descNode = [[[feedContents rootElement] nodesForXPath:@"/rss[1]/channel[1]/description[1]" error:&error] objectAtIndex:0];
		NSString *description = [descNode stringValue];
		[_properties setValue:description forKey:@"description"];

		NSXMLNode *siteNode = [[[feedContents rootElement] nodesForXPath:@"/rss[1]/channel[1]/link[1]" error:&error] objectAtIndex:0];
		NSString *site = [siteNode stringValue];
		[_properties setValue:site forKey:@"site"];

		NSArray *itemNodes = [[feedContents rootElement] nodesForXPath:@"/rss[1]/channel[1]/item" error:&error];
		NSEnumerator *itemNodesEnum = [itemNodes objectEnumerator];
		NSXMLNode *itemNode;
		while (itemNode = [itemNodesEnum nextObject])
		{
			NSString *title = [[[itemNode nodesForXPath:@"title[1]" error:&error] objectAtIndex:0] stringValue];
			NSString *description = [[[itemNode nodesForXPath:@"description[1]" error:&error] objectAtIndex:0] stringValue];
			NSURL *url = [[[NSURL alloc] initWithString:[[[itemNode nodesForXPath:@"link[1]" error:&error] objectAtIndex:0] stringValue]] autorelease];
			NSDate *date = [NSDate dateWithNaturalLanguageString:[[[itemNode nodesForXPath:@"pubDate[1]" error:&error] objectAtIndex:0] stringValue]];

			FeedItem *item = [[[FeedItem alloc] init] autorelease];
			NSMutableDictionary *properties = [[[NSMutableDictionary alloc] init] autorelease];
			[properties setValue:title forKey:@"title"];
			[properties setValue:description forKey:@"description"];
			[properties setValue:url forKey:@"url"];
			[properties setValue:date forKey:@"date"];
			[item setProperties:properties];

			// Add missing items to list.
			if (![_feedItems containsObject:item])
			{
				[_feedItems addObject:item];
			}
		}
		[error release];

		// Fetch the favicon.
		NSString *faviconUrl = [[_properties valueForKey:@"site"] stringByAppendingString:@"/favicon.ico"];
		NSImage *icon = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:faviconUrl]];
		if (icon != nil)
		{
			[icon setSize:NSMakeSize(16, 16)];
			[_properties setValue:icon forKey:@"icon"];
			[icon release];
		}
		
		return YES;
	}
	@catch (NSException * e) {
		NSLog(@"feed failed to load");
	}

	// Let's say it failed.
	return NO;
}

@end
