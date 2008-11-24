//
//  BDLinkArrowCell.m
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

#import "BDLinkArrowCell.h"
#import "MainController.h"

@implementation BDLinkArrowCell

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self)
	{
		// Set up link arrow.
		linkArrow = [[NSButtonCell alloc] init];
		[linkArrow setButtonType:NSSwitchButton];
		[linkArrow setBezelStyle:NSSmallSquareBezelStyle];
		[linkArrow setImagePosition:NSImageRight];
		[linkArrow setTitle:@""];
		[linkArrow setBordered:NO];
		[linkArrow setImage:[NSImage imageNamed:NSImageNameFollowLinkFreestandingTemplate]];
		[linkArrow setAlternateImage:[NSImage imageNamed:NSImageNameFollowLinkFreestandingTemplate]];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
}

- (void)setLinkVisible:(BOOL)isVisible
{
	isLinkVisible = isVisible;
}

- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView
{
	NSRect textRect = NSMakeRect(aRect.origin.x, aRect.origin.y, aRect.size.width - 18, aRect.size.height);
	linkRect = NSMakeRect(aRect.origin.x + aRect.size.width - 12, aRect.origin.y, 12, aRect.size.height);

	// Draw text.
	[super drawInteriorWithFrame:textRect inView:controlView];

	// Draw link arrow.
	if (isLinkVisible)
		[linkArrow drawInteriorWithFrame:linkRect inView:controlView];
}

// 10.5+ method
- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	NSPoint p = [[[NSApp  mainWindow] contentView] convertPoint:[event locationInWindow] toView:controlView];
	if (p.x > linkRect.origin.x && p.x < (linkRect.origin.x + linkRect.size.width))
	{
		// Hit the link.
		[[NSApp delegate] openURLInBrowser:nil];
		return NSCellHitContentArea | NSCellHitEditableTextArea;
	}
	else
	{
		return NSCellHitNone;
	}
}

@end
