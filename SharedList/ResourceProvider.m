//
//  ResourceProvider.m
//  SharedList
//
//  Created by Martin Kautz on 21.01.16.
//  Copyright © 2016 JAKOTA Design Group. All rights reserved.
//

#import "ResourceProvider.h"

@implementation ResourceProvider
//----------------------------------------------------------------------------------------------------------------------
#pragma mark - Init
//----------------------------------------------------------------------------------------------------------------------
+ (instancetype)sharedInstance
{
    static ResourceProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ResourceProvider alloc] init];
        [sharedInstance loadData];
    });
    return sharedInstance;
}


- (void)loadData {

    if (self.theRecourceDictionary == nil) {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1

            NSURL *URL = [NSURL URLWithString:@"http://www.teambender.de/apps/de-teambender-SharedList/resources.json"];
            NSError *readingError;
            NSError *parsingError;

            NSData *data = [NSData dataWithContentsOfURL:URL options:NSDataReadingUncached error:&readingError];

            if (!readingError) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parsingError];
                if (!parsingError) {
                    dispatch_async(dispatch_get_main_queue(), ^{ // 2
                        self.theRecourceDictionary = dict;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ResourceDictDidChange" object:nil];
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{ // 2
                    NSLog(@"readingError: %@", [readingError localizedDescription]);
                });
            }
            
        });
        
    }
}

@end
