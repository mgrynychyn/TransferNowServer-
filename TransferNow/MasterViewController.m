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
#import "MGNetwork.h"
#import "Conversion.h"
#import "FileTableViewCell.h"

#define START_SECTION 0

//static NSString * aboutDirectory = @"tap to view Documents directory";
static NSString * downloaded = @"downloaded";

static NSString * initial = @"Disconnected";

@interface MasterViewController ()<NSStreamDelegate, MGNetworkDelegate, TableHeaderViewDelegate>
@property NSMutableArray *objects;
@property NSString *currentDirectory;
@property (strong, nonatomic) UILabel *downloadLabel;
@property (strong, nonatomic) UILabel *monitorLabel;

@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UILabel *monitorSubLabel;
@property (nonatomic, assign, readwrite) NSUInteger streamOpenCount;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@property TableHeaderView *initialView;

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
    self.network=[MGNetwork network];
    self.network.delegate=self;
    self.network.streamDelegate=self;
//    [self.network startBrowser];
//    [self configureHeaderView];
    self.initialView=[[TableHeaderView alloc] initWithFrame:self.tableView.frame];
   
    self.initialView.delegate=self;
    self.tableView.tableHeaderView =self.initialView;
    self.tableView.backgroundColor=[UIColor lightGrayColor];
//    [self configureDownloadCell];
    
//    self.index=-2;
//    [self configureStartCell];
    self.objects=[NSMutableArray array];
    self.title=initial;
    
    [FileTableViewCell setDownloadButton];
    [[FileTableViewCell downloadButton] addTarget:self
                                         action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchDown];
   
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark in place of "buttonSelected" - button delegate's methods

-(void) startBrowser{
    
    if(self.network!=nil)
            [self.network startBrowser];

}


-(void) stopBrowser{
    
      [self.network stopBrowser];
    
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
             cell.textLabel.text = @"Documents";

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
                
                if([cell viewWithTag:BUTTON_TAG]!=nil && [FileTableViewCell downloadIndexPath]==nil)
                    [[FileTableViewCell downloadButton] removeFromSuperview];
                
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
//        NSLog(@"DidSelectRow  outputStream status %lu",self.network.outputStream.streamStatus);
        if(indexPath.section==START_SECTION){
           
            [self send:'A'];
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
     //    tableView.allowsSelection=NO;
    }

}


// MGNetworkDelegate
- (void) didFindService{
    
    if(self.network.netService!=nil){
        
        self.title=self.network.netService.name;
/*        [_activityIndicator stopAnimating];
        [_activityIndicator removeFromSuperview];
        [_monitorLabel removeFromSuperview];
        [_button removeFromSuperview];*/

        self.tableView.tableHeaderView =[[UIView alloc] initWithFrame:CGRectZero];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:YES];
//        [self.tableView reloadData];
 //       self.monitorLabel.text=self.network.netService.name;
 //       self.monitorSubLabel.text=aboutDirectory;
 //       [self.activityIndicator stopAnimating];
 //       [self.tableView reloadData];
 
    }
    
}

- (void) didRemoveService{
    
//    self.monitorLabel.text=serviceLabel;
//    self.monitorSubLabel.text=serviceLabel2;
    self.title=initial;
 //   [self configureHeaderView];
    if(self.initialView!=nil)
        self.tableView.tableHeaderView=self.initialView;
//    [self.button setTitle:stopButton forState:UIControlStateNormal];
   
//    [self addBrowsingIndicator];
//    self.tableView.tableHeaderView=self.headerView;
    [self.objects removeAllObjects];
//     [self.activityIndicator startAnimating];
    self.currentDirectory=@"";
    self.streamOpenCount=0;
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
            
            if ((self.streamOpenCount == 2) && (self.network.netService!=nil)){
               
                    NSLog(@"Streams open completed");
                [self didFindService];
               
               
            }
        } break;
    
       
        case NSStreamEventHasSpaceAvailable: {
            
            assert(stream == self.network.outputStream);
            
            NSLog(@"Has space available");
            
            if(self.fileOutputStream!=nil && (self.fileOutputStream.streamStatus!=NSStreamStatusOpen)){
                [self errorOccurred];

            }
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            
            uint8_t     b[4096];
            uint8_t     d[8192];
            NSInteger   bytesRead;
            
            assert(stream == self.network.inputStream);
            if(self.isDir)
                bytesRead = [self.network.inputStream read:d maxLength:sizeof(d)];
            else
                bytesRead = [self.network.inputStream read:b maxLength:sizeof(b)];
            NSLog(@"Bytes read %ld", (long)bytesRead);
            

            if(bytesRead>0){
                if(self.isDir)
                    
                    [self processData:d size:bytesRead];
                
                else{
                     static NSInteger allWrittenBytes=0;
                     NSInteger bytesWritten=0;
  /*                  if(self.fileOutputStream.streamStatus!=NSStreamStatusOpen){
                       
                        [self.fileOutputStream open];
                        NSLog(@"File status %lu",self.fileOutputStream.streamStatus);
                    }*/

            
                    bytesWritten = [self.fileOutputStream write:b maxLength:(size_t)bytesRead];
                    allWrittenBytes+=bytesWritten;
                    NSLog(@"Written %zd bytes.", (ssize_t) bytesWritten);
                    NSLog(@"All Written %zd bytes.", (ssize_t) allWrittenBytes);
                    if(allWrittenBytes>=((MyFile *)self.objects[self.index]).size){
                        [self closeFileOutputStream];
                        NSLog(@"End of file");
                        allWrittenBytes=0;
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
            break;
    }
}

- (void)send:(uint8_t)message
{
    [FileTableViewCell setSelectedIndexPath:nil];
    [FileTableViewCell setDownloadIndexPath:nil];
    
        if ( [self.network.outputStream hasSpaceAvailable] ) {
            if(message=='A'){
                self.isDir=YES;
                self.index=-1;
                
            }
            else{
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
            
            NSInteger   bytesWritten;
        
            bytesWritten = [self.network.outputStream write:&message maxLength:sizeof(message)];
            NSLog(@"Sent %u", message);
        }
    
}

- (void) processData:( const  char* )data size:(NSInteger)bytesRead
{
//    NSString *dirString=@"";
    NSIndexPath *indexPath;
    if(self.index>-1){
        self.currentDirectory=[[self.currentDirectory stringByAppendingString:((MyFile *)self.objects[self.index]).name] stringByAppendingString:@"/"];
        indexPath=[NSIndexPath indexPathForRow:self.index inSection:1];
    }
    else{
        self.currentDirectory=@"Documents/";
        indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//  dirString=[dirString initWithUTF8String:data];
    NSString *dirString=[NSString stringWithCharacters:data length:bytesRead];
    
    NSLog(@"dirString  %@", dirString);
//    dirString=[dirString initWithBytes:data length:bytesRead encoding:NSUTF8StringEncoding ];
    NSArray *ar= [[NSArray alloc] initWithArray:[dirString componentsSeparatedByString:@":"]];
    if(self.objects)
        [self.objects removeAllObjects];
    else
        self.objects=[NSMutableArray array];
    
    NSUInteger i=0;
    do {
        MyFile *mf=[[MyFile alloc] initWithName:ar[i++]];
        if(mf!=nil){
            mf.isDirectory=[(NSString *)ar[i++] boolValue];
            if(!mf.isDirectory){
        
                 mf.size=[(NSString *)ar[i++] longLongValue];
            }
            [self.objects addObject:mf];
        }
    } while (i<ar.count-1);
    
  
    [self.tableView reloadData];
    self.tableView.allowsSelection=YES;
    
}

- (NSURL *)documentDirectoryURL
{
    NSURL *documentDirectory=[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    return documentDirectory ;//URLByAppendingPathComponent:@"ShoppingList.property"];
}

-(void) buttonSelected:(UIButton *)sender{
    
    if([FileTableViewCell downloadIndexPath]!=nil)
        [self send:[FileTableViewCell downloadIndexPath].row ];
}
/*
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
*/
-(void) updateLocalFilesView{
   
    UITabBarController *tabBarController=[self tabBarController];
    LocalFilesViewController *localFilesViewController= [[(UINavigationController *)[[tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
    localFilesViewController.notify=!localFilesViewController.notify;
    ((MyFile * )self.objects[self.index]).isDownloaded=YES;
    NSIndexPath *indexPath=[NSIndexPath indexPathForItem:self.index inSection:1];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    self.tableView.allowsSelection=YES;
    
    
}

-(void) errorOccurred{
    self.tableView.allowsSelection=YES;
    [self closeFileOutputStream];
    NSIndexPath *indexPath=[NSIndexPath indexPathForItem:self.index inSection:1];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
}
@end
