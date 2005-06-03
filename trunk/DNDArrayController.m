#import <Cocoa/Cocoa.h>;
#import "DNDArrayController.h"

NSString *MovedRowsType = @"MOVED_ROWS_TYPE";
NSString *CopiedRowsType = @"COPIED_ROWS_TYPE";

@implementation DNDArrayController

-(int)numberOfRowsInTableView:(id)tableView
{
    return 0;
}

-(id)tableView:(id)tableView objectValueForTableColumn:(id)tableColumn row:(id)row;
{
    return nil;
}

-(id)lastEditedObject
{
    return lastEditedObject;
}

-(void)setLastEditedObject:(id)someObject
{
    [lastEditedObject release];
    lastEditedObject = [someObject copy];
}

-(void)objectDidBeginEditing:(id)editor
{
    [self setLastEditedObject:[[self arrangedObjects] objectAtIndex:[self selectionIndex]]];
    [super objectDidBeginEditing:editor];
}

-(void)objectDidEndEditing:(id)editor
{
    if(![[[self arrangedObjects] objectAtIndex:[self selectionIndex]] isEqual:[self lastEditedObject]]){
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"keywordsArrayHasChanged"object:nil];
    }
    [super objectDidEndEditing:editor];
}

-(void)awakeFromNib
{
    // register for drag and drop
    [tableView registerForDraggedTypes: [NSArray arrayWithObjects:CopiedRowsType, MovedRowsType, NSURLPboardType, nil]];
    [tableView setAllowsMultipleSelection:YES];
}



- (BOOL)tableView:(NSTableView *)tv
		writeRows:(NSArray*)rows
	 toPasteboard:(NSPasteboard*)pboard
{
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:CopiedRowsType, MovedRowsType, nil];
	
	/*
	 If the number of rows is not 1, then we only support our own types.
	 If there is just one row, then try to create an NSURL from the url
	 value in that row.  If that's possible, add NSURLPboardType to the
	 list of supported types, and add the NSURL to the pasteboard.
	 */
	if ([rows count] != 1)
	{
		[pboard declareTypes:typesArray owner:self];
	}
	else
	{
		// Try to create an URL
		// If we can, add NSURLPboardType to the declared types and write
		//the URL to the pasteboard; otherwise declare existing types
		int row = [[rows objectAtIndex:0] intValue];
		NSString *urlString = [[[self arrangedObjects] objectAtIndex:row] valueForKey:@"url"];
		NSURL *url;
		if (urlString && (url = [NSURL URLWithString:urlString]))
		{
			typesArray = [typesArray arrayByAddingObject:NSURLPboardType];	
			[pboard declareTypes:typesArray owner:self];
			[url writeToPasteboard:pboard];	
		}
		else
		{
			[pboard declareTypes:typesArray owner:self];
		}
	}
	
    // add rows array for local move
    [pboard setPropertyList:rows forType:MovedRowsType];
	
	// create new array of selected rows for remote drop
    // could do deferred provision, but keep it direct for clarity
	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rows count]];    
	NSEnumerator *rowEnumerator = [rows objectEnumerator];
	NSNumber *idx;
	while (idx = [rowEnumerator nextObject])
	{
		[rowCopies addObject:[[self arrangedObjects] objectAtIndex:[idx intValue]]];
	}
	// setPropertyList works here because we're using dictionaries, strings,
	// and dates; otherwise, archive collection to NSData...
	[pboard setPropertyList:rowCopies forType:CopiedRowsType];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
	{
		dragOp =  NSDragOperationMove;
    }
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}



- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op
{
    if (row < 0)
	{
		row = 0;
	}
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
    {
		NSArray *rows = [[info draggingPasteboard] propertyListForType:MovedRowsType];
		NSIndexSet  *indexSet = [self indexSetFromRows:rows];
		
		[self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
		
		// set selected rows to those that were just moved
		// Need to work out what moved where to determine proper selection...
		int rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
		
		NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
		indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		[self setSelectionIndexes:indexSet];
		
		return YES;
    }
	
	// Can we get rows from another document?  If so, add them, then return.
	NSArray *newRows = [[info draggingPasteboard] propertyListForType:CopiedRowsType];
	if (newRows)
	{
		NSRange range = NSMakeRange(row, [newRows count]);
		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		
		[self insertObjects:newRows atArrangedObjectIndexes:indexSet];
		// set selected rows to those that were just copied
		[self setSelectionIndexes:indexSet];
		return YES;
    }
	
	// Can we get an URL?  If so, add a new row, configure it, then return.
	NSURL *url = [NSURL URLFromPasteboard:[info draggingPasteboard]];
	if (url)
	{
		id newObject = [self newObject];	
		[self insertObject:newObject atArrangedObjectIndex:row];
		// "new" -- returned with retain count of 1
		[newObject release];
		[newObject takeValue:[url absoluteString] forKey:@"url"];
		//[newObject takeValue:[NSCalendarDate date] forKey:@"date"];
		// set selected rows to those that were just copied
		[self setSelectionIndex:row];
		return YES;		
	}
    return NO;
}



-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet 
									   toIndex:(unsigned)index
{
    unsigned off1 = 0, off2 = 0;
    
    unsigned currentIndex = [indexSet firstIndex];
    while (currentIndex != NSNotFound)
    {
		unsigned i = currentIndex;
		
		if (i < index)
		{
			i -= off1++;
			[self insertObject:[[self arrangedObjects] objectAtIndex:i] atArrangedObjectIndex:index];
			[self removeObjectAtArrangedObjectIndex:i];
		}
		else
		{
			[self insertObject:[[self arrangedObjects] objectAtIndex:i] atArrangedObjectIndex:index+off2++];
			[self removeObjectAtArrangedObjectIndex:i+1];
		}
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
}


- (NSIndexSet *)indexSetFromRows:(NSArray *)rows
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *rowEnumerator = [rows objectEnumerator];
    NSNumber *idx;
    while (idx = [rowEnumerator nextObject])
    {
		[indexSet addIndex:[idx intValue]];
    }
    return indexSet;
}


- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet
{
    unsigned currentIndex = [indexSet firstIndex];
    int i = 0;
    while (currentIndex != NSNotFound)
    {
		if (currentIndex < row) { i++; }
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}

@end


/*
  Copyright (c) 2004, Apple Computer, Inc., all rights reserved.

 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
