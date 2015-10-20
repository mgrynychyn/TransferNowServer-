//
//  LocalFilesViewController.m
//  FTAndMail
//
//  Created by Maria Grynychyn on 1/13/15.
//  Copyright (c) 2015 Maria Grynychyn. All rights reserved.
//

#import "LocalFilesViewController.h"
//#import <MessageUI/MessageUI.h>
#import "Conversion.h"


@interface LocalFilesViewController ()
@property NSMutableArray *files;

@property (strong, nonatomic) UIPopoverController *activityPopover;
@end


@implementation LocalFilesViewController

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    /*  UITableViewCell *serviceCellView=(UITableViewCell*)[self.tableView viewWithTag:24];
     [self configureServiceCell:serviceCellView];*/
    
  //  [self setTitle:@"Local files"];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    if(self.files==nil)
        self.files=[self filesList];
    [self addObserver:self forKeyPath:@"notify" options:0 context:&self->_notify];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(self.files!=nil)
        return self.files.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    NSString *urlString=[NSString string];
    cell = [tableView dequeueReusableCellWithIdentifier:@"Locals"];    
    if(self.files!=nil && self.files.count>=indexPath.row){
        NSNumber *size;
        cell.textLabel.text =  [urlString stringByAppendingString:[self.files[indexPath.row] lastPathComponent]] ;
        [self.files[indexPath.row] getResourceValue:&size forKey:@"NSURLFileSizeKey" error:nil];
        cell.detailTextLabel.text=[Conversion numberToString:[size longValue]];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
   [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.files[indexPath.row]] applicationActivities:nil];

   [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
   
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSError *err=nil;
        [[NSFileManager defaultManager] removeItemAtURL:(NSURL *)self.files[indexPath.row] error:&err];
       
           
        [self.files removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (NSMutableArray* )filesList
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *myURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    NSArray* files = [fileManager contentsOfDirectoryAtURL:myURL
                                includingPropertiesForKeys:nil
                                                   options:0   error:&error];
    
    return [[NSMutableArray alloc ] initWithArray:files];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_notify) {
        if([keyPath isEqual:@"notify"]){
            self.files=[self filesList];
            [self.tableView reloadData];
        }
    }
    else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }

}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"notify" context:&self->_notify];
}

@end
