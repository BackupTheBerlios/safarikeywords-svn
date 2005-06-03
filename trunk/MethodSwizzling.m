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

#import </usr/include/objc/objc-class.h>
#import "MethodSwizzling.h"
#import "Debug.h"

// lifted from: http://www.cocoadev.com/index.pl?MethodSwizzling
void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel)
{
    // First, look for the methods
    Method orig_method = class_getInstanceMethod(aClass, orig_sel);
    if (orig_method == nil){
	debug(@"Could not swizzle method %@ and method %@ on class %@: method %@ not found", NSStringFromSelector(orig_sel), NSStringFromSelector(alt_sel), aClass, NSStringFromSelector(orig_sel));
    }

    Method alt_method  = class_getInstanceMethod(aClass, alt_sel);
    if (alt_method == nil){ 
	debug(@"Could not swizzle method %@ and method %@ on class %@: method %@ not found", NSStringFromSelector(orig_sel), NSStringFromSelector(alt_sel), aClass, NSStringFromSelector(alt_sel));
    }
    
    // both found, so swizzle them
    char *temp1;
    IMP temp2;
    
    temp1 = orig_method->method_types;
    orig_method->method_types = alt_method->method_types;
    alt_method->method_types = temp1;
    
    temp2 = orig_method->method_imp;
    orig_method->method_imp = alt_method->method_imp;
    alt_method->method_imp = temp2;
    
    debug(@"Sucessfully swizzled method %@ and method %@ on class %@", NSStringFromSelector(orig_sel), NSStringFromSelector(alt_sel), aClass);
}