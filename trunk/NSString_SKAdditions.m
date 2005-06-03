/*
 *  GNU General Public License
 *  
 *  SafariKeywords is copyright (C) 2005 Ralph Poellath
 *  
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "NSString_SKAdditions.h"
#import <Foundation/Foundation.h>

@implementation NSString (SKAdditions)
-(NSString *)stringByRemovingString:(NSString *)aStr
{
    int i;
    NSString *result = nil;
    NSArray *components = [self componentsSeparatedByString:aStr];
    
    if([components count] > 0){
	result = [components objectAtIndex:0];
	for(i=1; i < [components count]; i++){
	    result = [result stringByAppendingString:[components objectAtIndex:i]];
	}
    }
    
    return result;
}

-(NSString *)stringByReplacingString:(NSString *)aStr withString:(NSString *)bStr
{
    int i;
    NSString *result = nil;
    NSArray *components = [self componentsSeparatedByString:aStr];
    
    if([components count] > 0){
	result = [components objectAtIndex:0];
	for(i=1; i < [components count]; i++){
	    result = [result stringByAppendingString:[components objectAtIndex:i]];
	    result = [result stringByAppendingString:bStr];
	}
    }
    
    return result;
}

-(BOOL)containsString:(NSString *)aStr
{
    return ([self rangeOfString:aStr].location != NSNotFound);
}

-(BOOL)containsString:(NSString *)aStr range:(NSRange)aRange
{
    return [[self substringWithRange:aRange] containsString:aStr];
}

-(NSString *)substringToString:(NSString *)aStr
{
    NSString *result = nil;
    if([self containsString:aStr]){
	int index = [self rangeOfString:aStr].location;
	result = [self substringFromIndex:index];
    }
    return result;
}

-(BOOL)isEmpty
{
    return (self == nil || [self isEqualToString:@" "] || [self isEqualToString:@""]);
}
@end
