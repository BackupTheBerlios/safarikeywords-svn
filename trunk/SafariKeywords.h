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

#import <WebKit/WebKit.h>

@interface NSObject (SafariKeywords)
- (id)SK_URLWithSearchCriteria:(id)criteria;
@end

@interface NSSearchFieldCell (SafariKeywords)
- (void)SK_setPlaceholderString:(NSString *)originalPlaceholder;
@end

/*
    This is our bundle's principal class, which gets loaded first and
    replaces some methods used internally by Safari with our
    "enhanced" versions.
    It also provides the method that rewrites the URLs.
*/
@interface SafariKeywords : NSObject 
{
}
+ (void) load;
+ (NSURL *)rewriteURL:(NSURL *)originalURL;
@end
