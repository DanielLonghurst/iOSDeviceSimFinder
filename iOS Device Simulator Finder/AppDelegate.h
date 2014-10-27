//
//  AppDelegate.h
//  iOS Device Simulator Finder
//
//  Created by Daniel Longhurst on 10/22/14.
//  Copyright (c) 2014 InVision Automation, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
   IBOutlet NSTableView *theTableView;
   NSMutableArray* dirEntries;
   NSURL *directoryURL;
}
- (IBAction)RefreshTable:(id)sender;

- (IBAction)finderButtonPressed:(id)sender;
- (IBAction)finderDocsButtonPressed:(id)sender;
@end

