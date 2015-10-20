//
//  MasterViewController.m
//  FTAndMail
//
//  Created by Maria Grynychyn on 12/10/14.
//  Copyright (c) 2014 Maria Grynychyn. All rights reserved.
//

#import "MasterViewController.h"
#import "TableHeaderView.h"
#import "LocalFilesViewController.h"
#import "MyFile.h"

#import "Conversion.h"
#import "FileTableViewCell.h"

#define START_SECTION 0

static NSString * downloaded = @"downloaded";
static uint8_t documents=225;
static uint8_t quit=255;
static NSString * initial = @"Disconnected";
static NSString * connected = @"Connected";

@interface MasterViewController ()<FileServerDelegate, TableHeaderViewDelegate>
@property NSMutableArray *objects;
@property NSString *currentDirectory;
@property (strong, nonatomic) UILabel *downloadLabel;
@property (strong, nonatomic) UILabel *monitorLabel;
@property float progress;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UILabel *monitorSubLabel;
@property (nonatomic, assign, readwrite) NSUInteger streamOpenCount;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property NSString * serviceName;
@property TableHeaderView *initialView;
@property UIProgressView *downloadProgress;

@property (strong, nonatomic) UITableViewCell *serviceCell;

@property (nonatomic, strong, readwrite) NSOutputStream *        fileOutputStream;


@property BOOL isDir;
@property NSInteger index;
@end

@implementation MasterViewController

- (void)awakeFromNib {
    
    [super awakeFromNib];
   
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.network=[[FileServer alloc] init];
    self.network.delegate=self;

    self.initialView=[[TableHeaderView alloc] initWithFrame:self.tableView.frame];
   
    self.initialView.delegate=self;
    self.tableView.tableHeaderView =self.initialView;
    self.tableView.backgroundColor=[UIColor lightGrayColor];

    self.objects=[NSMutableArray array];
    self.title=initial;
    
    [FileTableViewCell setDownloadButton];
    [[FileTableViewCell downloadButton] addTarget:self
                                         action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchDown];
   
    self.downloadProgress=[[UIProgressView alloc] initWithFrame:CGRectMake(0,40, 81.5, 10)] ;
    self.downloadProgress.hidden=YES;
    self.downloadProgress.progressTintColor=[UIColor whiteColor];
    [[FileTableViewCell downloadButton] addSubview:self.downloadProgress];
    
     [self addObserver:self forKeyPath:@"progress" options:0 context:&self->_progress];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark in place of "buttonSelected" - button delegate's methods

-(void) startBrowser{
    
    if(self.network!=nil)
            [self.network start];

}


-(void) stopBrowser{
    
      [self.network stop];
    
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section==START_SECTION){
        if([self.title isEqual:initial])
            
            return 0;
        else
            return 1;
    }
    
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
 
 
        cell= [tableView dequeueReusableCellWithIdentifier:@"Directory" forIndexPath:indexPath];
             cell.textLabel.text = @"Base Directory";

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
            
            else{
                
                FileTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"File" forIndexPath:indexPath];
                
                if([cell viewWithTag:BUTTON_TAG]!=nil && [FileTableViewCell downloadIndexPath]==nil){
                    
                    [[FileTableViewCell downloadButton] removeFromSuperview];
                     [FileTableViewCell downloadButton].alpha=1;
                    self.downloadProgress.hidden=YES;
                }
                
                cell.indexPath=indexPath;
                cell.textLabel.text = object.name;
                cell.detailTextLabel.text=[Conversion numberToString:object.size];
                if(([FileTableViewCell downloadIndexPath] !=nil)&& [[FileTableViewCell downloadIndexPath]isEqual:indexPath]){
                    
                    [UIView animateWithDuration:0.5 animations:^{[cell animateBack] ; }];
                    [FileTableViewCell setDownloadIndexPath:nil];
                    
                }

                if([FileTableViewCell selectedIndexPath]!=nil && [[FileTableViewCell selectedIndexPath]isEqual:indexPath]){
                    
                    [cell addSubview:[FileTableViewCell downloadButton]];
                    [cell layoutIfNeeded];
                    
                    [UIView animateWithDuration:0.5 animations:^{  [cell animate] ;}];
                    
                    [FileTableViewCell setDownloadIndexPath:indexPath];
                    
                }
               // cell.detailTextLabel.text=[Conversion numberToString:object.size];
                return cell;
            }
            
            
        }
        cell.textLabel.text = object.name;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    if(self.network.outputStream.hasSpaceAvailable){

        if(indexPath.section==START_SECTION){
           
            [self send:documents];
        }
    
        else{
            
            if(((MyFile *)self.objects[indexPath.row]).isDownloaded){
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                return;
            }
            if(((MyFile *)self.objects[indexPath.row]).isDirectory)
                [self send:indexPath.row];
            else{
                if([FileTableViewCell selectedIndexPath]==nil){
                    
                    [FileTableViewCell setSelectedIndexPath:indexPath];
                    
                }
                else{
                    
                    [FileTableViewCell setSelectedIndexPath:nil];
                    
                }
                
                //[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:NO];
            }
        
        }
    
    }

}


- (void) didFindService{
    
    
        if(self.network.clientName!=nil)
            self.title=self.network.clientName;
        else
            self.title=connected;
    
        self.tableView.tableHeaderView =[[UIView alloc] initWithFrame:CGRectZero];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:YES];
 
   
    
}

- (void) didRemoveService{
 //Added
//    [self.network stop];
    [self.network closeStreams];
    self.title=initial;
 
    if(self.initialView!=nil)
        self.tableView.tableHeaderView=self.initialView;

    [self.objects removeAllObjects];

    self.currentDirectory=@"";
    self.streamOpenCount=0;
    
    //added 5/31
    self.tableView.allowsSelection=YES;
    
    //
    [self.tableView reloadData];
    
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
            assert(self.streamOpenCount <= 2);
            
            // Once both streams are open we hide the picker and the game is on.
            
            if (self.streamOpenCount == 2){
               
                
                [self didFindService];
               
               
            }
        } break;
    
       
        case NSStreamEventHasSpaceAvailable: {
            
            assert(stream == self.network.outputStream);
            
            
            if(self.fileOutputStream!=nil && (self.fileOutputStream.streamStatus!=NSStreamStatusOpen)){
                [self errorOccurred];
         //       NSLog(@"Error occurred while in \"Has space available\"");

            }
        } break;
            
        case NSStreamEventHasBytesAvailable: {
     //        uint8_t     b[4096];
            static uint8_t     d[8192];

            NSInteger   bytesRead;

            assert(stream == self.network.inputStream);

            if(self.isDir){
                bytesRead = [self.network.inputStream read:d maxLength:sizeof(d)];
                 if(bytesRead>0)
                      [self processData:(const unichar*)d size:bytesRead];
            }
            else{
                dispatch_async( dispatch_get_main_queue(), ^ {
                    
                    NSInteger bytesReadFromFile;
                    uint8_t     b[4096];
                    bytesReadFromFile = [self.network.inputStream read:b maxLength:sizeof(b)];
                   
                    if (bytesReadFromFile>0){
                        static NSInteger allWrittenBytes=0;
                        NSInteger bytesWritten=0;
                        
                        bytesWritten = [self.fileOutputStream write:b maxLength:(size_t)bytesReadFromFile];
                        
                        
                        allWrittenBytes+=bytesWritten;
                        self.progress=(((float)allWrittenBytes*100)/((MyFile *)self.objects[self.index]).size)/100;
  
                       
                      
                        if(allWrittenBytes>=((MyFile *)self.objects[self.index]).size){
                            [self closeFileOutputStream];
                          
                            allWrittenBytes=0;
                            [self updateLocalFilesView];
                        }

                    }
                    
                 });
                
            }
                
                       
        }   break;
            
        case NSStreamEventErrorOccurred:
            
          
            
            self.downloadProgress.hidden=YES;
            self.downloadProgress.progress=0;
            [self didRemoveService];
            break;
        case NSStreamEventEndEncountered:{
            
           ;
            
        }
            
        default:
            break;
    }
}

- (void)send:(uint8_t)message
{
    [FileTableViewCell setSelectedIndexPath:nil];
    [FileTableViewCell setDownloadIndexPath:nil];
    
        if ( [self.network.outputStream hasSpaceAvailable] ) {
            if(message==documents){
                self.isDir=YES;
                self.index=-1;
                
            }
            else{
                if(message!=quit){
 //               if((((MyFile *)self.objects[message]).isDownloaded))
 //                   return;
                    self.isDir=((MyFile *)self.objects[message]).isDirectory;
                    self.index=message;
                    if(!self.isDir){
                        NSURL *fileURL=[[self documentDirectoryURL] URLByAppendingPathComponent:((MyFile *)self.objects[self.index]).name];
                    
                    
                        NSError *error=nil;
                        NSFileManager *fm=[NSFileManager defaultManager];
                        if([fm fileExistsAtPath:[fileURL relativePath]]){
                        //     NSLog(@"File exists");
                            [fm removeItemAtURL:fileURL error:&error];
                        }
                    
                        self.fileOutputStream = [NSOutputStream outputStreamWithURL:fileURL append:YES];
                        [self.fileOutputStream open];
                    }
                }
            }
            
            NSInteger   bytesWritten;
        
            bytesWritten = [self.network.outputStream write:&message maxLength:sizeof(message)];
            self.tableView.allowsSelection=NO;
          
            
        }
       else {
            
            if(message!=quit){
                NSIndexPath *indexPath;
                if(message==documents )
                    indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
                else
                    indexPath=[NSIndexPath indexPathForRow:message inSection:1];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
            }
        }
}

- (void) processData:( const  unichar* )data size:(NSInteger)bytesRead
{
    static uint8_t     d[8192];
    
    NSMutableArray *ar;
    static NSUInteger saved=0;
    static NSUInteger length;
    
    NSIndexPath *indexPath;
    

    NSString *dirString;
    
    if(saved!=0){
        memcpy(d+saved,data,bytesRead);
        if(length>(bytesRead+saved)/2){
            saved+=bytesRead;
            return;
        }
        dirString=[NSString stringWithCharacters:d length:bytesRead+saved/2];
        saved=0;
        ar= [[NSMutableArray alloc] initWithArray:[dirString componentsSeparatedByString:@":"]];
    }
    else{
        if(self.index>-1){
            self.currentDirectory=[[self.currentDirectory stringByAppendingString:((MyFile *)self.objects[self.index]).name] stringByAppendingString:@"/"];
            indexPath=[NSIndexPath indexPathForRow:self.index inSection:1];
        }
        else{
            self.currentDirectory=@"Base directory/";
            indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
       //??? 
        dirString=[NSString stringWithCharacters:data length:bytesRead/2];
        
   //     NSLog(@"String received %@", dirString);
        
        ar= [[NSMutableArray alloc] initWithArray:[dirString componentsSeparatedByString:@":"]];
        if([ar[0] intValue]!=0){
            
           
 //       length=[(NSString *)ar[0] integerValue]-(((NSString *)ar[0]).length+1); changed on "empty directory" issue
        
            length=[(NSString *)ar[0] integerValue]+(((NSString *)ar[0]).length+1);
        
           
            if(length>bytesRead/2){
                memcpy(d, data+(((NSString *)ar[0]).length+1)*2, bytesRead-(((NSString *)ar[0]).length+1)*2);
                saved=bytesRead;
            
                return;
            }
        
            
        }
        [ar removeObjectAtIndex:0];    
    }
    [ar removeObjectAtIndex:ar.count-1 ];
    
//    dirString=[dirString initWithBytes:data length:bytesRead encoding:NSUTF8StringEncoding ];
 //   NSArray *ar= [[NSArray alloc] initWithArray:[dirString componentsSeparatedByString:@":"]];
    
        
    if(self.objects)
        [self.objects removeAllObjects];
    else
        self.objects=[NSMutableArray array];
    
    NSUInteger i=0;
   
    while (i<ar.count) {
        MyFile *mf=[[MyFile alloc] initWithName:ar[i++]];
        if(mf!=nil){
            mf.isDirectory=[(NSString *)ar[i++] boolValue];
            if(!mf.isDirectory){
        
                 mf.size=[(NSString *)ar[i++] longLongValue];
            }
            [self.objects addObject:mf];
        }
    }
    
  
    [self.tableView reloadData];
    self.tableView.allowsSelection=YES;
    
}

- (NSURL *)documentDirectoryURL
{
    NSURL *documentDirectory=[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    return documentDirectory ;
}

-(void) buttonSelected:(UIButton *)sender{
    
    if([FileTableViewCell downloadIndexPath]!=nil)
        [self send:[FileTableViewCell downloadIndexPath].row];
//    [FileTableViewCell downloading];
     self.progress=0;
   
     self.downloadProgress.hidden=NO;
    
}

-(void) updateLocalFilesView{
   
    UITabBarController *tabBarController=[self tabBarController];
    LocalFilesViewController *localFilesViewController= [[(UINavigationController *)[[tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
    localFilesViewController.notify=!localFilesViewController.notify;
    ((MyFile * )self.objects[self.index]).isDownloaded=YES;
    NSIndexPath *indexPath=[NSIndexPath indexPathForItem:self.index inSection:1];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    self.tableView.allowsSelection=YES;
    
    [[FileTableViewCell downloadButton] removeFromSuperview];
    [FileTableViewCell downloadButton].alpha=1;
    self.downloadProgress.hidden=YES;
    self.downloadProgress.progress=0;
}

-(void) errorOccurred{
    self.tableView.allowsSelection=YES;
    [self closeFileOutputStream];
    NSIndexPath *indexPath=[NSIndexPath indexPathForItem:self.index inSection:1];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_progress) {
        if([keyPath isEqual:@"progress"]){
              [self.downloadProgress setProgress:self.progress animated:YES];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

@end
