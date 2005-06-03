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

#import "SKKeyword.h"

@implementation SKKeyword

+(SKKeyword *)keywordWithTitle:(NSString *)newTitle andUrl:(NSString *)newUrl
{
    SKKeyword *keyword = [[[SKKeyword alloc] init] autorelease];
    [keyword setTitle:newTitle];
    [keyword setUrl:newUrl];
    return keyword;
}

-(SKKeyword *)init
{
    if(self = [super init]){
	title = @"changeMe";
	url = @"http://";
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    [copy setTitle:[self title]];
    [copy setUrl:[self url]];
    return copy;
}

// validation methods

-(BOOL)validateTitle:(id *)value error:(NSError **)outError
{
    // disallow blank titles
    if([*value isEqualToString:@""]){
	NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:@"Title cannot be blank" forKey:NSLocalizedDescriptionKey];	
	NSError *error = [[[NSError alloc] initWithDomain:KEYWORD_ERROR_DOMAIN code:KEYWORD_BLANK_TITLE userInfo:userInfoDict] autorelease];
	*outError = error;
	return NO;
    }
    
    // disallow blanks in titles
    NSRange whitespace = [*value rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if(whitespace.location != NSNotFound){
	NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:@"Title cannot contain whitespace" forKey:NSLocalizedDescriptionKey];	
	NSError *error = [[[NSError alloc] initWithDomain:KEYWORD_ERROR_DOMAIN code:KEYWORD_BLANKS_IN_TITLE userInfo:userInfoDict] autorelease];
	*outError = error;
	return NO;
    }
    
    return YES;
}
-(BOOL)validateUrl:(id *)value error:(NSError **)outError
{
    // disallow blanks in urls
    NSRange whitespace = [*value rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if(whitespace.location != NSNotFound){
	NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:@"URL cannot contain whitespace" forKey:NSLocalizedDescriptionKey];	
	NSError *error = [[[NSError alloc] initWithDomain:KEYWORD_ERROR_DOMAIN code:KEYWORD_BLANKS_IN_URL userInfo:userInfoDict] autorelease];
	*outError = error;
	return NO;
    }
    
    // disallow urls that do not start with http://
    // this implicitly disalows blank urls
    if(![*value hasPrefix:@"http://"]){
	NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:@"URL must start with http://" forKey:NSLocalizedDescriptionKey];	
	NSError *error = [[[NSError alloc] initWithDomain:KEYWORD_ERROR_DOMAIN code:KEYWORD_NO_HTTP_IN_URL userInfo:userInfoDict] autorelease];
	*outError = error;
	return NO;
    }
    
    return YES;
}

-(BOOL)isEqual:(SKKeyword *)other
{
    return ([[self title] isEqualToString:[other title]] && [[self url] isEqualToString:[other url]]);
}

// KVC/KVO-compilant accessors

-(NSString *)title{
    return title;
}
-(void)setTitle:(NSString *)newValue
{
    if(title != newValue){
	[title release];
	title = [newValue retain];
    }
}

-(NSString *)url{
    return url;
}
-(void)setUrl:(NSString *)newValue
{
    if(url != newValue){
	[url release];
	url = [newValue retain];
    }
}

// displayed in default keyword drop-down
-(NSString *)description
{
    return title;
}

@end
