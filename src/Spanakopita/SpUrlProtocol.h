//
//  SpUrlLoader.h
//  Spanakopita
//
//  Created by Niko Matsakis on 1/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SP_SCHEME @"sp"

@interface SpUrlProtocol : NSURLProtocol {
	BOOL stop;
}

@end
