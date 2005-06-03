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

#import <Foundation/Foundation.h>

/*
    This class represents a mozilla-style keyword, consisting of a title
    and URL. A typical example would be a keyword with title "img" and
    URL "http://images.google.com/images?q=%s".
    The URL usually contains a placeholder string "%s".
*/

#define KEYWORD_ERROR_DOMAIN  @"KEYWORD_ERROR_DOMAIN"
#define KEYWORD_BLANK_TITLE      10001
#define KEYWORD_BLANKS_IN_TITLE  10002
#define KEYWORD_BLANKS_IN_URL    10003
#define KEYWORD_NO_HTTP_IN_URL   10004

@interface SKKeyword : NSObject {
    NSString *title;
    NSString *url;
}

+ (SKKeyword *)keywordWithTitle:(NSString *)newTitle andUrl:(NSString *)newUrl;
-(BOOL)validateTitle:(id *)value error:(NSError **)outError;
-(BOOL)validateUrl:(id *)value error:(NSError **)outError;
-(id)copyWithZone:(NSZone *)zone;
-(BOOL)isEqual:(SKKeyword *)other;
// accessors
-(NSString *)title;
-(void)setTitle:(NSString *)newValue;
-(NSString *)url;
-(void)setUrl:(NSString *)newValue;

@end
