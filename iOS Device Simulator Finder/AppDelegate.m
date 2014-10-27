//
//  AppDelegate.m
//  iOS Device Simulator Finder
//
//  Created by Daniel Longhurst on 10/22/14.
//  Copyright (c) 2014 InVision Automation, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ATTableCellView.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
   return YES;
}

- (IBAction)RefreshTable:(id)sender
{
//   NSUInteger nCols = [theTableView.tableColumns count];
   
   NSURL *libraryDirectoryURL = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask][0];
   
   directoryURL = [[NSURL URLWithString:@"Developer/CoreSimulator/Devices/" relativeToURL:libraryDirectoryURL] absoluteURL];
   dirEntries = [self GetSubDirectoriesAtUrl:directoryURL];
   
   theTableView.dataSource = self;
   theTableView.delegate = self;
   
   [theTableView removeAllToolTips];
   [theTableView reloadData];
}

- (NSMutableArray *)GetSubDirectoriesAtUrl:(NSURL *)searchUrl
{
   NSMutableArray *foundDirectories;
   NSArray *keys = [NSArray arrayWithObjects:
                    NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey, nil];
   
   NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
                                        enumeratorAtURL:searchUrl
                                        includingPropertiesForKeys:keys
                                        options:(NSDirectoryEnumerationSkipsPackageDescendants |
                                                 NSDirectoryEnumerationSkipsHiddenFiles |
                                                 NSDirectoryEnumerationSkipsSubdirectoryDescendants)
                                        errorHandler:^(NSURL *url, NSError *error) {
                                           // Handle the error.
                                           // Return YES if the enumeration should continue after the error.
                                           return YES;
                                        }];
   
   foundDirectories = [NSMutableArray new];
   
   for (NSURL *url in enumerator) {
      
      // Error checking is omitted for clarity.
      
      NSNumber *isDirectory = nil;
      [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
      
      if ([isDirectory boolValue]) {
         
         NSString *localizedName = nil;
         [url getResourceValue:&localizedName forKey:NSURLLocalizedNameKey error:NULL];
         
         NSNumber *isPackage = nil;
         [url getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
         
         if ([isPackage boolValue]) {
            //            NSLog(@"Package at %@", localizedName);
         }
         else {
            //NSLog(@"Directory at %@", localizedName);
            [foundDirectories addObject:localizedName];
         }
      }
   }
   
   return foundDirectories;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   // Insert code here to initialize your application
   
   [[theTableView.tableColumns[0] headerCell] setStringValue:@"Device Type"];
   [[theTableView.tableColumns[1] headerCell] setStringValue:@"OS Version"];
   [[theTableView.tableColumns[2] headerCell] setStringValue:@"Guid"];
   
   [self RefreshTable:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
   // Insert code here to tear down your application
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
   return dirEntries.count;
}


- (int)FindFvMobileInFolder:(NSURL *)searchUrl
               InstalledURL: (NSURL**)FVMobileUrl
{
   bool FvMobileFound = false;
   
   NSMutableArray *appDirList = [self GetSubDirectoriesAtUrl:searchUrl];
   
   for (NSString *appDirName in appDirList)
   {
      NSURL *pTestUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/FVMobileiOS.app",
                                             [searchUrl absoluteString], appDirName]];

      FvMobileFound = [[NSFileManager defaultManager] fileExistsAtPath:[pTestUrl path]];
      
      if (FvMobileFound)
      {
         *FVMobileUrl = [pTestUrl URLByDeletingLastPathComponent];
         
         break;
      }
   }
   
   return FvMobileFound;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
   // Get an existing cell with the MyView identifier if it exists
   NSUInteger colIdx = [tableView.tableColumns indexOfObject:tableColumn];
   NSObject *result = nil;
   if (colIdx == 3)
   {
      result = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
      
      if (result == nil)
      {
         // Create the new NSTextField with a frame of the {0,0} with the width of the table.
         // Note that the height of the frame is not really relevant, because the row height will modify the height.
         result = [[ATTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
      }
   }
   else if (colIdx == 4)
   {
      result = [tableView makeViewWithIdentifier:@"DocsButtonCell" owner:self];
      
      if (result == nil)
      {
         // Create the new NSTextField with a frame of the {0,0} with the width of the table.
         // Note that the height of the frame is not really relevant, because the row height will modify the height.
         result = [[ATTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
      }
   }
   else
   {
      result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
      
      if (result == nil)
         // Create the new NSTextField with a frame of the {0,0} with the width of the table.
         // Note that the height of the frame is not really relevant, because the row height will modify the height.
         result = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
   }
   
   NSString *theGUID = [dirEntries objectAtIndex:row];
   
   // There is no existing cell to reuse so create a new one
   if (result != nil) {
      
      if (colIdx == 0)
      {
        
         // The identifier of the NSTextField instance is set to MyView.
         // This allows the cell to be reused.
         ((NSTextField*)result).identifier = @"col1";
         
         NSURL *pListUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/device.plist", [directoryURL absoluteString] ,theGUID]];
         NSPropertyListFormat format;
         NSString *errorDesc = nil;
         NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:[pListUrl path]];
         NSDictionary *devicePList = (NSDictionary *)[NSPropertyListSerialization
                                                      propertyListFromData:plistXML
                                                      mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                      format:&format
                                                      errorDescription:&errorDesc];
         if (!devicePList) {
            NSLog(@"Error reading plist: %@, format: %d", errorDesc, (int)format);
         }
         
         NSString *deviceName = [devicePList valueForKey:@"name"];
         
         
         // result is now guaranteed to be valid, either as a reused cell
         // or as a new cell, so set the stringValue of the cell to the
         // nameArray value at row
         ((NSTextField*)result).stringValue = deviceName;
      }
      else if (colIdx == 1)
      {
         // The identifier of the NSTextField instance is set to MyView.
         // This allows the cell to be reused.
         ((NSTextField*)result).identifier = @"col3";
         
         
         NSURL *pListUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/device.plist", [directoryURL absoluteString] ,theGUID]];
         NSPropertyListFormat format;
         NSString *errorDesc = nil;
         NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:[pListUrl path]];
         NSDictionary *devicePList = (NSDictionary *)[NSPropertyListSerialization
                                                      propertyListFromData:plistXML
                                                      mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                      format:&format
                                                      errorDescription:&errorDesc];
         if (!devicePList) {
            NSLog(@"Error reading plist: %@, format: %d", errorDesc, (int)format);
         }
         
         NSString *deviceRuntime = [devicePList valueForKey:@"runtime"];
         
         // result is now guaranteed to be valid, either as a reused cell
         // or as a new cell, so set the stringValue of the cell to the
         // nameArray value at row
         ((NSTextField*)result).stringValue =  deviceRuntime;
      }
      else if (colIdx == 2)
      {
         // The identifier of the NSTextField instance is set to MyView.
         // This allows the cell to be reused.
         ((NSTextField*)result).identifier = @"col2";
         
         // result is now guaranteed to be valid, either as a reused cell
         // or as a new cell, so set the stringValue of the cell to the
         // nameArray value at row
         ((NSTextField*)result).stringValue =  theGUID;
      }
      else if (colIdx == 3)
      {
         //         ATTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];

         // nothing special to do, just return the item
      }
      else if (colIdx == 4)
      {
         bool FvMobileFound = false;
         
         NSURL* deviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/data/Applications/", [directoryURL absoluteString] ,theGUID]];
         NSURL *FVMobileUrl = nil;
         
         FvMobileFound = [self FindFvMobileInFolder:deviceUrl InstalledURL:&FVMobileUrl];
         
         if (! FvMobileFound)
         {
            // iOS 8 differs in location
            deviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/data/Containers/Data/Application/", [directoryURL absoluteString] ,theGUID]];
            FvMobileFound = [self FindFvMobileInFolder:deviceUrl InstalledURL:&FVMobileUrl];
            
            if (! FvMobileFound)
               result = nil;
         }
      }
      else
      {
         ((NSTextField*)result).stringValue = @"";
      }
      
   }
   
   // Return the result
   return result;
}

- (IBAction)finderButtonPressed:(id)sender
{
   NSInteger row = [theTableView rowForView:sender];
   
   NSString *theGUID = [dirEntries objectAtIndex:row];
   NSURL *pdeviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", [directoryURL absoluteString] ,theGUID]];
   
   
   [[NSWorkspace sharedWorkspace] selectFile:[pdeviceUrl path] inFileViewerRootedAtPath:nil];
}

- (IBAction)finderDocsButtonPressed:(id)sender
{
   NSInteger row = [theTableView rowForView:sender];
   
   NSString *theGUID = [dirEntries objectAtIndex:row];

   //   NSURL *pFvMobileDocsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/data/Applications/8F416173-D4AD-497B-9A2E-00ED785B2CDD/Documents", [directoryURL absoluteString] ,theGUID]];
   
   bool FvMobileFound = false;
   
   NSURL* searchUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/data/Applications/", [directoryURL absoluteString] ,theGUID]];
   NSURL *FVMobileUrl = nil;
   
   FvMobileFound = [self FindFvMobileInFolder:searchUrl InstalledURL:&FVMobileUrl];
   
   if (!FvMobileFound)
   {
      // try for iOS 8 location
      searchUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/data/Containers/Data/Application/", [directoryURL absoluteString] ,theGUID]];
      FvMobileFound = [self FindFvMobileInFolder:searchUrl InstalledURL:&FVMobileUrl];
   }

   if (FvMobileFound)
   {
      NSURL *pFvMobileDocsUrl  = [NSURL URLWithString:[NSString stringWithFormat:@"%@/Documents", [FVMobileUrl absoluteString]]];
   
      [[NSWorkspace sharedWorkspace] selectFile:[pFvMobileDocsUrl path] inFileViewerRootedAtPath:nil];
   }

}


@end
