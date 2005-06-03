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

#import "SKPreferencesModule.h"
#import "SKPreferences.h"
#import "SKKeyword.h"
#import "Debug.h"

@implementation SKPreferencesModule

+(SKPreferencesModule *)sharedInstance
{
    static SKPreferencesModule *module;
    if(!module){
	module = [[self alloc] init];
    }
    return module;
}

-(id)init
{
    if(self = [super init]){
	keywordsArray = [[[NSMutableArray alloc] init] retain];
    }
    return self;
}

-(void) loadKeywords
{
    NSDictionary *domain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:SK_BUNDLE_IDENTIFIER];
    [self setEnabled:[[domain objectForKey:@"enabled"] boolValue]];
    NSDictionary *aDict =  [domain objectForKey:@"shortcuts"];
    NSEnumerator *theEnum = [aDict keyEnumerator];
    NSString *defaultTitle =  [domain objectForKey:@"default"];
    
    NSString *title;
    SKKeyword *keyword;
    while(title = [theEnum nextObject]){
	keyword = [SKKeyword keywordWithTitle:title andUrl:[aDict objectForKey:title]];
	[self insertObject:keyword inKeywordsArrayAtIndex:0];
	if([title isEqualToString:defaultTitle]){
	    [self setDefaultKeyword:keyword];
	}
    }
    
    if(![self countOfKeywordsArray])
	[self restoreDefaults];
}

-(unsigned int)countOfKeywordsArray 
{
    return [keywordsArray count]; 
}

-(id)objectInKeywordsArrayAtIndex:(unsigned int)index 
{
    return [keywordsArray objectAtIndex:index]; 
}

-(void)insertObject:(id)anObject inKeywordsArrayAtIndex:(unsigned int)index
{
    [keywordsArray insertObject:anObject atIndex:index]; 
    [self saveKeywords];
}

-(void)removeObjectFromKeywordsArrayAtIndex:(unsigned int)index
{
    [keywordsArray removeObjectAtIndex:index]; 
    [self saveKeywords];
    if(![self countOfKeywordsArray])
	[self restoreDefaults];
}


-(void)replaceObjectInKeywordsArrayAtIndex:(unsigned int)index withObject:(id)anObject
{
    [keywordsArray replaceObjectAtIndex:index withObject:anObject];
    [self saveKeywords];
}

-(NSMutableArray *)keywordsArray 
{ 
    return keywordsArray; 
}

-(void)setKeywordsArray:(NSMutableArray *)newKeywordsArray
{
    if (keywordsArray != newKeywordsArray){
        [keywordsArray release];
        keywordsArray = [[newKeywordsArray mutableCopy] retain];
    }
    
    [self saveKeywords];
    if([self countOfKeywordsArray] == 0){
	[self restoreDefaults];
    }
}

-(NSSize)minSize {
    return NSMakeSize(562, 414);
}

// title displayed in prefs panel
-(NSString *)titleForIdentifier:(NSString *)identifier
{
    return @"Keywords";
}

/**
 * Image to display in the preferences toolbar
 */
-(NSImage *) imageForPreferenceNamed:(NSString *)aName
{
    return [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"GeneralPreferences"]] autorelease];
}

/**
 * Override to return the name of the relevant nib
 */
-(NSString *) preferencesNibName
{
    return  @"SKPrefsPanel";
}

-(NSView *)viewForPreferenceNamed:(NSString *)aName {
     if(_preferencesView == nil) {
	[NSBundle loadNibNamed:[self preferencesNibName] owner:self];
     }
     return _preferencesView;
}

-(void) awakeFromNib 
{
    [self loadKeywords];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(keywordsArrayHasChanged) 
	name:@"keywordsArrayHasChanged" object:nil 
	suspensionBehavior:NSNotificationSuspensionBehaviorDrop];
 }
 
-(void) keywordsArrayHasChanged
{
   [self saveKeywords];
}

-(SKKeyword *)defaultKeyword
{
    return (defaultKeyword) ? defaultKeyword : [SKKeyword keywordWithTitle:@"google" andUrl:@"http://www.google.com/search?q=%@&ie=UTF-8&oe=UTF-8"];
}
-(void)setDefaultKeyword:(SKKeyword *)newValue
{
    if(newValue != defaultKeyword){
	[defaultKeyword release];
	defaultKeyword = [newValue retain];
	[self saveKeywords];
    }
}

-(void) saveKeywords
{
    // tell the array controller to commit all changes. if validation fails (e.g. user entered URL not starting with
    // "http://" and then pressed "Save"), we abort saving.
    // todo: maybe notify user that changes were not saved?
    if(![arrayController commitEditing]){
	debug(@"[arrayController commitEditing] returned NO");
	return;
    }
    
    NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithCapacity:[self countOfKeywordsArray]];
    
    int i;
    for(i=0; i < [self countOfKeywordsArray]; i++){
	SKKeyword *content = [self objectInKeywordsArrayAtIndex:i];
	[aDict setObject:[content url] forKey:[content title]];
    }

    NSArray *objects = [NSArray arrayWithObjects:aDict, [NSNumber numberWithBool:[self enabled]], [[self defaultKeyword] title], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"shortcuts", @"enabled", @"default", nil];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionaryWithObjects:objects forKeys:keys] forName:SK_BUNDLE_IDENTIFIER];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)enabled
{
    return enabled;
}

-(void)setEnabled:(BOOL)newValue
{
    if(enabled != newValue){
	enabled = newValue;

	[[NSUserDefaults standardUserDefaults] synchronize];
	NSDictionary *aDict =  [[[NSUserDefaults standardUserDefaults] persistentDomainForName:SK_BUNDLE_IDENTIFIER] objectForKey:@"shortcuts"];
	NSArray *objects = [NSArray arrayWithObjects:aDict, [NSNumber numberWithBool:[self enabled]], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"shortcuts", @"enabled", nil];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionaryWithObjects:objects forKeys:keys] forName:SK_BUNDLE_IDENTIFIER];
	[[NSUserDefaults standardUserDefaults] synchronize];
    }
}

/**
* Called when we relinquish ownership of the preferences panel.
 */
-(void)moduleWillBeRemoved
{
    [self saveKeywords];
}

-(IBAction)help:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL URLWithString:SK_HELP_URL]]
	withAppBundleIdentifier:@"com.apple.Safari"
	options:NSWorkspaceLaunchDefault
	additionalEventParamDescriptor:nil
	launchIdentifiers:nil];
}

-(NSColor *)textColor
{
    return ([self enabled]) ? [NSColor blackColor] : [NSColor lightGrayColor];
}

-(void)restoreDefaults
{
    NSBeginAlertSheet(@"Restore factory defaults?", @"Don't restore", @"Restore", 
		      nil, [[SKPreferences sharedPreferences] preferencesPanel], self, 
		      @selector(restoreSheetDidEnd:returnCode:contextInfo:), NULL, NULL, 
		      @"You removed the all keywords. Do you want to restore the factory defaults?");
}

-(void)restoreSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    // if user clicks default button "Don't restore", ignore
    if(returnCode == NSAlertDefaultReturn){
	return;
    }
    
    debug(@"restoreSheetDidEnd called");
    
    NSString *defaultShortcutsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultKeywords" ofType:@"plist"];
    NSDictionary *defaultShortcutDict = [NSDictionary dictionaryWithContentsOfFile:defaultShortcutsPath];
    
    if(!defaultShortcutDict){
	NSBeginAlertSheet(@"An Error has occurred", @"OK", nil, 
		   nil, [[SKPreferences sharedPreferences] preferencesPanel], self, 
		   nil, NULL, NULL, 
		   @"The DefaultShortcuts file seems to be corrupted.");
	return;
    }
    
    NSEnumerator *enumerator = [defaultShortcutDict keyEnumerator];
    NSString *key;

    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:10];
    SKKeyword *keyword;
    while(key = [enumerator nextObject]){
	keyword = [SKKeyword keywordWithTitle:key andUrl:[defaultShortcutDict objectForKey:key]];
	[newArray insertObject:keyword atIndex:0];
    }
    [self setKeywordsArray:newArray];
}

-(void) dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"keywordsArrayHasChanged" object:nil]; 
    [keywordsArray release];
    [defaultKeyword release];
    [super dealloc];
}

@end

