//
//  BDDateTransformer.m
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

#import "BDDateTransformer.h"

@implementation BDDateTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(NSDate *)date
{
	// Initialize the formatter.
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	
	// Initialize the calendar and flags.
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
	NSCalendar *calendar = [NSCalendar currentCalendar];

	// Create reference date for supplied date.
	NSDateComponents *comps = [calendar components:unitFlags fromDate:date];
	[comps setHour:0];
	[comps setMinute:0];
	[comps setSecond:0];
	NSDate *suppliedDate = [calendar dateFromComponents:comps];
	
	// Iterate through the eight days (tomorrow, today, and the last six).
	int i;
	for (i = -1; i < 7; i++)
	{
		// Initialize reference date.
		comps = [calendar components:unitFlags fromDate:[NSDate date]];
		[comps setHour:0];
		[comps setMinute:0];
		[comps setSecond:0];
		[comps setDay:[comps day] - i];
		NSDate *referenceDate = [calendar dateFromComponents:comps];
		// Get week day (starts at 1).
		int weekday = [[calendar components:unitFlags fromDate:referenceDate] weekday] - 1;
		
		if ([suppliedDate compare:referenceDate] == NSOrderedSame && i == -1)
		{
			// Tomorrow
			return [NSString stringWithString:@"Tomorrow"];
		}
		else if ([suppliedDate compare:referenceDate] == NSOrderedSame && i == 0)
		{
			// Today's time (like iPhone Mail)
			[formatter setDateStyle:NSDateFormatterNoStyle];
			[formatter setTimeStyle:NSDateFormatterShortStyle];
			return [formatter stringFromDate:date];
		}
		else if ([suppliedDate compare:referenceDate] == NSOrderedSame && i == 1)
		{
			// Today
			return [NSString stringWithString:@"Yesterday"];
		}
		else if ([suppliedDate compare:referenceDate] == NSOrderedSame)
		{
			// Day of the week
			NSString *day = [[formatter weekdaySymbols] objectAtIndex:weekday];
			return day;
		}
	}
	
	// It's not in those eight days.
	NSString *defaultDate = [formatter stringFromDate:date];
	return defaultDate;
}

@end
