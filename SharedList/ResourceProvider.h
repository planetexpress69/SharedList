//
//  ResourceProvider.h
//  SharedList
//
//  Created by Martin Kautz on 21.01.16.
//  Copyright © 2016 JAKOTA Design Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResourceProvider : NSObject
//--------------------------------------------------------------------------------------------------
@property (nonatomic, strong) NSDictionary      *theRecourceDictionary;
//--------------------------------------------------------------------------------------------------
+ (ResourceProvider *)sharedInstance;
//--------------------------------------------------------------------------------------------------
@end
