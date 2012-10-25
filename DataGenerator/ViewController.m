//
//  ViewController.m
//  DataGenerator
//
//  Created by buza on 10/22/12.
//  Copyright (c) 2012 buzamoto. All rights reserved.
//

#import "ViewController.h"
#import "MyDocument.h"

@interface ViewController()
@property(nonatomic, strong) NSURL *cloudDocFileURL;
@property(nonatomic, strong) NSURL *iCloudBaseURL;
@property(nonatomic, strong) MyDocument *myDocument;
@end

@implementation ViewController

@synthesize cloudDocFileURL;
@synthesize iCloudBaseURL;
@synthesize myDocument;

- (void)initializeiCloudAccessWithCompletion:(void (^)(BOOL available)) completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.iCloudBaseURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        completion(self.iCloudBaseURL != nil);
        
    });
}

- (void)viewDidLoad
{
    self.iCloudBaseURL = nil;
    
    [self initializeiCloudAccessWithCompletion:^(BOOL available) {
        
        BOOL _iCloudAvailable = available;
        
        if (!_iCloudAvailable)
        {
            DLog(@"iCloud not available. Please check your project settings/entitlements.");
        } else
        {
            [self createCloudDoc];
        }
    }];
    
    [super viewDidLoad];
}


- (NSURL *)getDocURL:(NSString *)filename
{
    if(self.iCloudBaseURL)
    {
        NSURL *docsDir = [self.iCloudBaseURL URLByAppendingPathComponent:@"Documents" isDirectory:YES];
        return [docsDir URLByAppendingPathComponent:filename];
    } else return nil;
}

-(IBAction) updateCloudDoc:(id)sender
{
    //Generate a new random value that we'll use to update our document with.
    NSString *newTitle = [NSString stringWithFormat:@"%lld", arc4random() % 4294967296];

    //Since we've already created our document and sent it to the cloud, we just use the
    //cloud url as the source of our document.
    MyDocument *mydoc = [[MyDocument alloc] initWithFileURL:self.cloudDocFileURL];

    //Open our cloud document.
    [mydoc openWithCompletionHandler:^(BOOL success) {
        
        //Change the title.
        [mydoc setTitle:newTitle];
        
        //Re-save.
        [mydoc saveToURL:self.cloudDocFileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success)
        {
             if (!success)
             {
                 DLog(@"Failed to save updated document.");
                 return;
             } else
             {
                 //To ensure our changes are recognized by iCloud, we must close the document.
                 [mydoc closeWithCompletionHandler:^(BOOL success) {
                     if (!success) {
                         DLog(@"Failed to close document. %@", self.cloudDocFileURL );
                     } else
                     {
                         DLog(@"Successfully updated document. %@", self.cloudDocFileURL );
                     }
                 }];
             }
         }];
    }];
}

-(void) createCloudDoc
{
    //Generate a random filename for our UIDocument instance that we'll save to iCloud.
    NSString *randomSuffix = [NSString stringWithFormat:@"%lld", arc4random() % 4294967296];
    NSString *cloudFileName = cloudFileName = [NSString stringWithFormat:@"%@.skt", randomSuffix];

    //We generate our local document in the cloud document directory so that we don't have to
    //deal with cleaning up any existing files if our user changes iCloud accounts. The contents
    //of the cloud document directory are cleared when the account changes. Also, to make sure
    //our temporary file isn't automatically backed up, we append the .nosync designation.
    NSURL *fileURL = [self getDocURL:[NSString stringWithFormat:@"%@.nosync", cloudFileName]];
    NSURL *fileURLRemote = [self getDocURL:cloudFileName];
    self.cloudDocFileURL = fileURLRemote;
    
    //When we create document instances, they get saved locally before we move them to the
    //cloud. We shouldn't ever see the local files remaining after we create and move our
    //document to iCloud.
    if([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]])
    {
        NSCAssert(NO, @"Local file exists. This shouldn't happen.");
        return;
    }
    
    //Create an instance of our UIDocument subclass with the local URL.
    MyDocument *mydoc = [[MyDocument alloc] initWithFileURL:fileURL];
    [mydoc setTitle:randomSuffix];
    
    //Remember the URL of our document in the cloud so we can open and make changes
    //to it later.
    self.cloudDocFileURL = fileURLRemote;
    
    //Create our local file.
    [mydoc saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success)
    {
         if (!success)
         {
             DLog(@"Failed to create file at %@", fileURL);
             return;
         } else
         {
             //To ensure our changes are recognized by iCloud, we must close the document.
             [mydoc closeWithCompletionHandler:^(BOOL success) {
                 
                 // Check status
                 if (!success) {
                     DLog(@"Failed to close %@", fileURL);
                 } else
                 {
                     NSError * error;
                     NSFileManager *fm = [[NSFileManager alloc] init];
                     BOOL success = [fm setUbiquitous:YES itemAtURL:fileURL destinationURL:fileURLRemote error:&error];
                     if(error || !success)
                     {
                         DLog(@"Failed to move %@. error %@", fileURL, error);
                     } else if (success)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                             message:@"Doc sent to iCloud."
                                                                            delegate:nil
                                                                   cancelButtonTitle:@"OK"
                                                                   otherButtonTitles:nil];
                             [alert show];
                             
                         });
                     }
                 }
             }];
         }
     }];
}

@end
