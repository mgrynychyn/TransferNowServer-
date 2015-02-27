//
//  MasterViewController.m
//  FTAndMail
//
//  Created by Maria Grynychyn on 12/10/14.
//  Copyright (c) 2014 Maria Grynychyn. All rights reserved.
//

#import "MasterViewController.h"

#import "LocalFilesViewController.h"
#import "MyFile.h"

#define START_SECTION 0
static NSString * bonjourType = @"_bft._tcp.";
static NSString * serviceLabel =@"Start DocumentServer on your computer";
static NSString * serviceLabel2 =@"and turn WIFI on";
static NSString * aboutDirectory = @"tap to view Documents directory";
static NSString * downloaded = @"downloaded";

@interface MasterViewController ()<NSStreamDelegate, NSNetServiceBrowserDelegate>
@property NSMutableArray *objects;
@property NSString *currentDirectory;
@property (strong, nonatomic) UILabel *monitorLabel;
@property (strong, nonatomic) UILabel *monitorSubLabel;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong, readwrite) NSNetService *netService;
@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  browser;
@property (strong, nonatomic) UITableViewCell *serviceCell;
@property (strong, nonatomic) UITableViewCell *fileCell;
@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *        fileOutputStream;
@property (nonatomic, assign, readwrite) NSUInteger             streamOpenCount;

@property BOOL isDir;
@property NSInteger index;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
   
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
     [self startBrowser];
    [self configureStartCell];

    self.objects=[NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureStartCell{
    
    UITableViewCell *cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Service"];
    
   
//    CGRect frame = CGRectMake(20.0, 0.0, 200.0, 40.0);
    CGRect frame = CGRectMake(20.0, 0.0, 200.0, 25.0);
    _monitorLabel = [[UILabel alloc] initWithFrame:frame];
    _monitorLabel.text=serviceLabel;
    _monitorLabel.adjustsFontSizeToFitWidth=YES;
   
//    _monitorLabel.baselineAdjustment=0;
    
    frame = CGRectMake(20.0, 26, 150.0, 15.0);
    _monitorSubLabel = [[UILabel alloc] initWithFrame:frame];
    _monitorSubLabel.text=serviceLabel2;
    _monitorSubLabel.adjustsFontSizeToFitWidth=YES;
    _monitorSubLabel.baselineAdjustment=UIBaselineAdjustmentNone;
    
//    CGPoint point=CGPointMake(264.0, 22.0);
     CGPoint point=CGPointMake(300.0, 22.0);
    _activityIndicator=[[UIActivityIndicatorView alloc] init];
    _activityIndicator.activityIndicatorViewStyle= UIActivityIndicatorViewStyleWhite;
    _activityIndicator.center= point;
    [cell addSubview:_monitorLabel];
    [cell addSubview:_monitorSubLabel];
    [cell addSubview:_activityIndicator];
    self.serviceCell=cell;
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section==START_SECTION)
        return 1;
    if(self.objects!=nil)
        return self.objects.count;
    else
        return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section==START_SECTION)
        return nil;
    else
        return self.currentDirectory;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    
    if (indexPath.section==START_SECTION) {
 
        cell=self.serviceCell;
        if([_monitorLabel.text isEqualToString:serviceLabel]){
 
            [_activityIndicator startAnimating];
        }
    }
    else {
        
        MyFile *object = self.objects[indexPath.row];
        
        if(object.isDirectory){
                cell= [tableView dequeueReusableCellWithIdentifier:@"Directory" forIndexPath:indexPath];
         //       cell.textLabel.text = object.name;
        }
        else {
            
            if(object.isDownloaded){
                cell= [tableView dequeueReusableCellWithIdentifier:@"Downloaded" forIndexPath:indexPath];
                cell.detailTextLabel.text=downloaded;
            }
            
            else
                cell= [tableView dequeueReusableCellWithIdentifier:@"File" forIndexPath:indexPath];
            
        }
        cell.textLabel.text = object.name;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
   
    if(indexPath.section==START_SECTION){
        self.isDir=YES;
        [self send:'A'];
        self.index=-1;
        self.currentDirectory=@"Documents/";
    }
    
    else{
        if(!(((MyFile *)self.objects[indexPath.row]).isDownloaded))
            [self sendRequest:indexPath.row];
        
    }
    
}
//NSNetServices

- (void)startBrowser
// See comment in header.
{
    
    self.browser = [[NSNetServiceBrowser alloc] init];
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:bonjourType inDomain:@"local"];
    
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
    NSLog(@"Removed service");
    assert(service != nil);
    if ((self.netService!=nil) && [service isEqual:self.netService])
        self.netService=nil;
    if ( ! moreComing ){
       [self closeStreams];
    
        self.monitorLabel.text=serviceLabel;
        self.monitorSubLabel.text=serviceLabel2;
        self.objects=nil;
        self.currentDirectory=@"";
        [self.tableView reloadData];
    }
    
}

- (void) disableConnection{
    [self closeStreams];
    
    self.monitorLabel.text=serviceLabel;
    self.monitorSubLabel.text=serviceLabel2;
    self.objects=nil;
    self.currentDirectory=@"";
    [self.tableView reloadData];
    
    
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(self.netService == nil);
    assert(service!=nil);
    // Add the service to our array (unless its our own service).
    
    self.netService=service;
    
   if ( ! moreComing )
   {
    [self connectToService:self.netService];
    self.monitorLabel.text=service.name;
    self.monitorSubLabel.text=aboutDirectory;
    [self.activityIndicator stopAnimating];
    
   }
}

- (void)stopBrowser
// See comment in header.
{
    [self.browser stop];
    self.browser = nil;    

}

- (void)connectToService:(NSNetService *)service
{
    BOOL                success;
    NSInputStream *     inStream;
    NSOutputStream *    outStream;
    
    assert(service != nil);
    
    assert(self.inputStream == nil);
    assert(self.outputStream == nil);
    
    success = [service getInputStream:&inStream outputStream:&outStream];
    if (  success ) {
       
//        NSLog(@"Connect to service success");
        self.inputStream  = inStream;
        self.outputStream = outStream;
        
        [self openStreams];
    }
}

- (void)openStreams
{
    assert(self.inputStream != nil);            // streams must exist but aren't open
    assert(self.outputStream != nil);
    
    [self.inputStream  setDelegate:self];
    [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream  open];
    
    [self.outputStream setDelegate:self];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
}

- (void)closeStreams
{
    assert( (self.inputStream != nil) == (self.outputStream != nil) );      // should either have both or neither
    if (self.inputStream != nil) {
        
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
        
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
    }
    self.streamOpenCount=0;
}

- (void)closeFileOutputStream
{
    [self.fileOutputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.fileOutputStream close];
    
    self.fileOutputStream = nil;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
#pragma unused(stream)
    
    switch(eventCode) {
            
        case NSStreamEventOpenCompleted: {
             self.streamOpenCount += 1;
            NSLog(@"%lu streams open",(unsigned long)self.streamOpenCount);
        //    if(self.streamOpenCount==2)
         //       [self deregister];
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            
            assert(stream == self.outputStream);
            
            NSLog(@"Has space available");
            // do nothing
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            
            uint8_t     b[4096];
            NSInteger   bytesRead;
            
            assert(stream == self.inputStream);
            bytesRead = [self.inputStream read:b maxLength:sizeof(b)];
            NSLog(@"Bytes read %ld", (long)bytesRead);
            

            if(bytesRead>0){
                if(self.isDir)
                    
                    [self processData:b size:bytesRead];
                
                else{
                     NSInteger bytesWritten=0;
                    if(self.fileOutputStream.streamStatus!=NSStreamStatusOpen){
                       
                       
                        [self.fileOutputStream open];
                    }
 /*                   if(b[bytesRead-1] == 4){
                        if(bytesRead>1)
                            bytesWritten = [self.fileOutputStream write:b maxLength:(size_t)bytesRead-1];
                        [self closeFileOutputStream];
                        [self updateLocalFilesView];
                        
                    }
                    else*/
            
                        bytesWritten = [self.fileOutputStream write:b maxLength:(size_t)bytesRead];
                        NSLog(@"Written %zd bytes.", (ssize_t) bytesWritten);
                    if(self.inputStream.streamStatus != NSStreamStatusReading){
                        [self closeFileOutputStream];
                        NSLog(@"End of file");
                        
                        [self updateLocalFilesView];
                    }
                                    }
            }
            
        }   break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Error occured");
            break;
        case NSStreamEventEndEncountered: {
            //      [self closeFileOutputStream];
            NSLog(@"Stream closed");
        } break;
        default:
            assert(NO);
            // fall through
       
    }
}

- (void)send:(uint8_t)message
{
    NSLog(@"Stream status on \"send\" %lu", (unsigned long)self.outputStream.streamStatus);
        
        if(self.streamOpenCount == 2)
        if ( [self.outputStream hasSpaceAvailable] ) {
            NSInteger   bytesWritten;
        
            bytesWritten = [self.outputStream write:&message maxLength:sizeof(message)];
            NSLog(@"Sent %u", message);
        }
    
}

- (void) processData:( const  char* )data size:(NSInteger)bytesRead
{
//    NSString *dirString=@"";
    if(self.index>-1)
         self.currentDirectory=[[self.currentDirectory stringByAppendingString:((MyFile *)self.objects[self.index]).name] stringByAppendingString:@"/"];
//  dirString=[dirString initWithUTF8String:data];
    NSString *dirString=[NSString stringWithCharacters:data length:bytesRead];
    
    NSLog(@"dirString  %@", dirString);
//    dirString=[dirString initWithBytes:data length:bytesRead encoding:NSUTF8StringEncoding ];
    NSArray *ar= [[NSArray alloc] initWithArray:[dirString componentsSeparatedByString:@","]];
    if(self.objects)
        [self.objects removeAllObjects];
    else
        self.objects=[NSMutableArray array];
    
    NSUInteger i=0;
    do {
        MyFile *mf=[[MyFile alloc] initWithName:ar[i++]];
        if(mf!=nil){
            mf.isDirectory=[(NSString *)ar[i++] boolValue];
            if(!mf.isDirectory)
                 mf.size=[(NSString *)ar[i++] longLongValue];
            [self.objects addObject:mf];
        }
    } while (i<ar.count-1);
    
  
    [self.tableView reloadData];
}

- (NSURL *)documentDirectoryURL
{
    NSURL *documentDirectory=[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    return documentDirectory ;//URLByAppendingPathComponent:@"ShoppingList.property"];
}


- (void) sendRequest:(NSUInteger)index {
    
//    [self setDirectoryViewController:controller];
    self.isDir=((MyFile *)self.objects[index]).isDirectory;
    self.index=index;
    if(!self.isDir){
        NSURL *fileURL=[[self documentDirectoryURL] URLByAppendingPathComponent:((MyFile *)self.objects[self.index]).name];
        
        
        NSError *error=nil;
        NSFileManager *fm=[NSFileManager defaultManager];
        if([fm fileExistsAtPath:[fileURL relativePath]]){
            //     NSLog(@"File exists");
            [fm removeItemAtURL:fileURL error:&error];
        }
        
        self.fileOutputStream = [NSOutputStream outputStreamWithURL:fileURL append:YES];
        
    }
    [self send:index];
}

-(void) updateLocalFilesView{
    UITabBarController *tabBarController=[self tabBarController];
    LocalFilesViewController *localFilesViewController= [[(UINavigationController *)[[tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
    localFilesViewController.notify=!localFilesViewController.notify;
    ((MyFile * )self.objects[self.index]).isDownloaded=YES;
    NSIndexPath *indexPath=[NSIndexPath indexPathForItem:self.index inSection:1];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
}


@end
