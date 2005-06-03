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

#import "SafariKeywords.h"
#import "MethodSwizzling.h"
#import "Debug.h"
#import "NSString_SKAdditions.h"

// use %s as placeholder to be compatible with Mozilla keywords
#define PLACEHOLDER @"%s"

// fixed by Daniel Salber, http://daniel.salber.name/
@implementation NSObject (SafariKeywords)
-(id)SK_URLWithSearchCriteria:(id)criteria
{
    // call the original method in case it does more than it seems to do, or in case somebody else swizzled it too
    id url = [self SK_URLWithSearchCriteria:criteria];
    return [SafariKeywords rewriteURL:url];
}
@end

@implementation NSSearchFieldCell (SafariKeywords)
-(void)SK_setPlaceholderString:(NSString *)originalPlaceholder
{
    if([originalPlaceholder isEqualToString:@"Google"] && [self respondsToSelector:@selector(SK_setPlaceholderString:)]){
	[self SK_setPlaceholderString:@"SafariKeywords"];
    }
}
@end

@implementation SafariKeywords
+(void) load
{
    if(![[[NSBundle mainBundle] bundleIdentifier] isEqualTo:@"com.apple.Safari"]){ return; }
    NSLog(@"successfully loaded %@", [[NSBundle bundleForClass:self] bundlePath]);
    
    MethodSwizzle(NSClassFromString(@"GoogleSearchChannel"), @selector(URLWithSearchCriteria:), @selector(SK_URLWithSearchCriteria:));
    // overwrites the search bar's default string with SK
    MethodSwizzle(NSClassFromString(@"SearchFieldCell"), @selector(setPlaceholderString:), @selector(SK_setPlaceholderString:));
    // override the title of the "Google Search" menu item in the "View" menu
    // todo: localize (Google Search is Google Suche in german, e.g.)
    [[[[[[[NSApp mainMenu] itemWithTitle:@"Edit"] submenu] itemWithTitle:@"Find"] submenu] itemWithTitle:@"Google Search…"] setTitle:@"SafariKeywords"];
}

+(NSDictionary *)prefs
{
    return [[NSUserDefaults standardUserDefaults] persistentDomainForName:SK_BUNDLE_IDENTIFIER];
}

+(BOOL)isEnabled
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    BOOL enabled = [[[SafariKeywords prefs] objectForKey:@"enabled"] boolValue];
    debug(@"isEnabled returning: %@", (enabled) ? @"YES" : @"NO");
    return enabled;
}

+(NSArray *)extractUserInputFromGoogleUrl:(NSURL *)googleUrl
{
    // this is the url that would be loaded if we wouldn't interfere
    // something like http://www.google.com/search?q=blah blah blubb&lang=en
    NSString *theURL = [[googleUrl absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // cut off trailing arguments
    NSMutableString *userInput = [NSMutableString stringWithString:[[theURL componentsSeparatedByString:@"&"] objectAtIndex:0]];
    // cut off leading host, script name, etc.
    [userInput setString:[[userInput componentsSeparatedByString:@"?q="] objectAtIndex:1]];
    // replace all + with spaces
    [userInput setString:[[userInput componentsSeparatedByString:@"+"] componentsJoinedByString:@" "]];
    // trim whitespace
    [userInput setString:[userInput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    // compress double blanks
    while([userInput replaceOccurrencesOfString:@"  " withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [userInput length])]);
    
    NSArray *result = [userInput componentsSeparatedByString:@" "];
    debug(@"extractUserInputFromGoogleUrl: returning %@", result);
    return result;
}

+(NSString *)targetUrlForKeyword:(NSString *)keyword
{
    NSDictionary *keywordDictionary = [[SafariKeywords prefs] objectForKey:@"shortcuts"];
    NSString *targetUrl = [keywordDictionary objectForKey:keyword];
    NSString *result = ([targetUrl isEmpty]) ? nil : targetUrl;
    debug(@"targetUrlForKeyword: returning %@", result);
    return result;
}

+(NSString *)targetUrlForCustomDefaultKeyword
{
    NSString *customDefaultKeyword = [[SafariKeywords prefs] objectForKey:@"default"];
    NSString *result = (customDefaultKeyword) ? [SafariKeywords targetUrlForKeyword:customDefaultKeyword] : nil;
    debug(@"targetUrlForCustomDefaultKeyword returning %@", result);
    return result;
}

+(NSString *)expandPlaceholdersInUrl:(NSString *)url withValues:(NSArray *)values
{
    NSArray *urlComponents = [url componentsSeparatedByString:PLACEHOLDER];
    int placeholders = [urlComponents count] - 1;
    
    if(placeholders < 1 || [values count] < 1){ 
	return url; 
    }
    
    int words = [values count];

    NSMutableString *expanded = [NSMutableString stringWithString:@""];

    int i, j;
    for(i=0; i < placeholders; i++){
	[expanded appendString:[urlComponents objectAtIndex:i]];
	if(i < words){
	    [expanded appendString:[values objectAtIndex:i]];
	}
	// at the last iteration, append leftover words from query
	if(i == placeholders-1){
	    for(j=i+1; j < words; j++){
		[expanded appendString:@" "];
		[expanded appendString:[values objectAtIndex:j]];
	    }
	}
    }
    // bugfix by Tyler Rosewood
    if(words >= placeholders){
	[expanded appendString:[urlComponents objectAtIndex:placeholders]];
    }
    debug(@"expandPlaceholdersInUrl:withValues: returning %@", expanded);
    return expanded;
}

+(CFStringEncoding)encodingForUrl:(NSString *)url
{
    // default
    CFStringEncoding encoding = kCFStringEncodingUTF8;
    NSString *ianaName = @"utf-8";
    
    // check for marker in url
    NSString *markerString = @"&skenc=";
    NSRange marker = [url rangeOfString:markerString];
    if(marker.location != NSNotFound){
	// for available names, see http://www.iana.org/assignments/character-sets , e.g. iso-8859-1
	ianaName = [url substringFromIndex:marker.location+marker.length];
	if([ianaName containsString:@"&"]){
	    ianaName = [url substringToString:@"&"];
	}
	
	// TODO: CFStringConvertIANACharSetNameToEncoding seems to crash Safari on some systems
	// add try/catch-block
	CFStringEncoding convertedEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)ianaName);
	if(convertedEncoding != kCFStringEncodingInvalidId){
	    encoding = convertedEncoding;
	}
	else{
	    NSLog(@"SafariKeywords: Invalid charset %@ specified", ianaName);
	}
	// remove marker from destination URL
	url = [url stringByRemovingString:[markerString stringByAppendingString:ianaName]];
    }
    // now guess encoding by url
    else{
	// check for "de" in host, e.g. heise.de, de.php.net, www.de.php.net, etc.
	NSString *host = [[NSURL URLWithString:(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url , CFSTR("#"), NULL, kCFStringEncodingUTF8)] host];
	NSArray *hostNames = [host componentsSeparatedByString:@"."];
	if([hostNames indexOfObject:@"de"] != NSNotFound){
	    //debug(@"found de in domain %@, using iso encoding", host);
	    ianaName = @"iso-8859-1";
	    encoding = kCFStringEncodingISOLatin1;
	}
    }
    return encoding;
}

+(NSURL *)urlWithString:(NSString *)url encoding:(CFStringEncoding)encoding
{
    NSString *encoded;
    // # has special meaning in URLs and should not be urlencoded
    encoded = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, CFSTR("#"), NULL, encoding);
    if(!encoded){
	NSLog(@"SafariKeywords: Could not urlencode with specified encoding. Falling back to UTF-8.");
	encoded = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, CFSTR("#"), NULL, kCFStringEncodingUTF8);
    }
    NSURL * result = [NSURL URLWithString:encoded];
    debug(@"urlWithString:encoding: returning %@", result);
    return result;
}

+(NSURL *)rewriteURL:(NSURL *)originalURL
{
    //// make sure we're  supposed to run at all
    
    // AFAIK, this method is only called when the searchbar is used, so the URL is always google.
    // If it isn't, we should not modify the URL at all
    if(![[originalURL host] isEqualToString:@"www.google.com"]){
        return originalURL;
    }
    
    // check user defaults wether we're enabled
    if(![SafariKeywords isEnabled]){
	return originalURL;
    }
    
    //// reconstruct what was typed into the search field (userInput)
    NSMutableArray *userInputArray = [NSMutableArray arrayWithArray:[SafariKeywords extractUserInputFromGoogleUrl:originalURL]];
        
    
    //// the first word in userInputArray is the shortcut
    NSString *keyword = [userInputArray objectAtIndex:0];
    
    if([keyword isEmpty]){
        debug(@"leaving URL unmodified, because keyword is empty");
        return originalURL;
    }
    
    //// get the target url for this shortcut from prefs (dest)
    NSString *targetUrl = [SafariKeywords targetUrlForKeyword:keyword];

    if(!targetUrl){
	//// if the target url is empty, use a custom default shortcut
	if(![SafariKeywords targetUrlForCustomDefaultKeyword]){
	    debug(@"leaving URL unmodified, because %@ is not a keyword and no default keyword was found", keyword);
	    return originalURL;
	}
	//// if that isn't set, return the original url
	targetUrl = [SafariKeywords targetUrlForCustomDefaultKeyword];
	debug(@"using custom default keyword with target URL: ", targetUrl);
    }
    else{
	// remove keyword if the first word was one
	[userInputArray removeObjectAtIndex:0];
    }
    
    // now userInputArray contains what was typed in the search bar minus the keyword
    
    NSString *theQuery = [userInputArray componentsJoinedByString:@" "];
    if([theQuery isEmpty] && [targetUrl containsString:PLACEHOLDER]){
        debug(@"leaving URL unmodified, because query is nil and dest requires placeholders");
        return originalURL;
    }
    
    //// replace placeholders in target url with words from user input
    targetUrl = [SafariKeywords expandPlaceholdersInUrl:targetUrl withValues:userInputArray];
    
    //// figure out the proper encoding: first check wether specified, if not, guess
    CFStringEncoding encoding = [SafariKeywords encodingForUrl:targetUrl];
    
    //// url encode
    NSURL *result = [SafariKeywords urlWithString:targetUrl encoding:encoding];
    debug(@"rewriteUrl: returning %@", result);
    return result;
}
@end


