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

#import "SKPreferences.h"
#import "SKPreferencesModule.h"

@implementation SKPreferences
+(void) load {
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualTo:@"com.apple.Safari"]){ 
	[self poseAsClass:[NSPreferences class]];
    }
}

+(SKPreferences *)sharedPreferences {
    static BOOL	added = NO;
    id	preferences = [super sharedPreferences];

    if(preferences != nil && !added){
        added = YES;
	id prefsModule = [SKPreferencesModule sharedInstance];
        [preferences addPreferenceNamed:[prefsModule titleForIdentifier:nil] owner:prefsModule];
    }
    
    return preferences;
}

-(NSWindow *)preferencesPanel
{
    return _preferencesPanel;
}
@end

 