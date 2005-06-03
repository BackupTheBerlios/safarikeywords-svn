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
#import "NSPreferences.h"
#import "DNDArrayController.h"
#import "SKKeyword.h"

/*
    This class represents a preference panel for Safari
 */

@interface SKPreferencesModule : NSPreferencesModule 
{
    BOOL enabled;
    NSMutableArray *keywordsArray;
    SKKeyword *defaultKeyword;
    // required so we can tell the arrayController to commit changes
    IBOutlet DNDArrayController *arrayController;
}
+(SKPreferencesModule *)sharedInstance;

// action methods
-(IBAction)help:(id)sender;

// private methods
-(void)restoreDefaults;
-(void)restoreSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

-(void) loadKeywords;
-(void) saveKeywords;

// KVO-compatible accessors

-(BOOL)enabled;
-(void)setEnabled:(BOOL)newValue;

-(SKKeyword *)defaultKeyword;
-(void)setDefaultKeyword:(SKKeyword *)newValue;

-(unsigned int)countOfKeywordsArray;
-(id)objectInKeywordsArrayAtIndex:(unsigned int)index;
-(void)insertObject:(id)anObject inKeywordsArrayAtIndex:(unsigned int)index;
-(void)removeObjectFromKeywordsArrayAtIndex:(unsigned int)index;
-(void)replaceObjectInKeywordsArrayAtIndex:(unsigned int)index withObject:(id)anObject;

-(NSMutableArray *)keywordsArray;
-(void)setKeywordsArray:(NSMutableArray *)newKeywordsArray;

-(NSColor *)textColor; // the tableColumns' text color is bound to this

@end
