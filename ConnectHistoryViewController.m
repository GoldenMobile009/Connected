//
//  ConnectHistoryViewController.m
//  coNNected
//
//  Created by Frank Mao on 2/9/2014.
//  Copyright (c) 2014 mazoic. All rights reserved.
//
#import "NSDate+InternetDateTime.h"
#import "ConnectHistoryViewController.h"
#import "MBProgressHUD.h"

@interface ConnectHistoryViewController ()

@property (nonatomic, strong) NSArray * items;

@end

@implementation ConnectHistoryViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.rowHeight = 60;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
//    SMQuery * userQuery = [[SMQuery alloc] initWithSchema:@"connect"];
//    [userQuery where:@"creator" isEqualTo:[AppDelegate currentLoggedUserPhoneNumber]];
//    [[[SMClient defaultClient] dataStore] performQuery:userQuery
//                                             onSuccess:^(NSArray *results) {
//                                                 
//                                                 
//                                                 self.items = results;
//                                                 
//                                                 [self.tableView reloadData];
//                                                 
//                                                 
//                                                 [MBProgressHUD hideHUDForView:self.view animated:YES];
//                                                 
//                                             } onFailure:^(NSError *error) {
//                                                 NSLog(@"query connect history error: %@", [error localizedDescription]);
//                                                 
//                                                 [MBProgressHUD hideHUDForView:self.view animated:YES];
//                                             }
//     ];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 
    // Return the number of rows in the section.
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier  ];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    NSDictionary * item =  self.items[indexPath.row];
    NSDate * createdDate = [NSDate dateWithTimeIntervalSince1970:[item[@"createddate"] doubleValue] / 1000];
    cell.detailTextLabel.text =  [NSString stringWithFormat:@"%@",   [createdDate formattedStringUsingFormat:@"yyyy-MM-dd HH:mm"]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [item[@"member_name_list"] componentsJoinedByString:@", "]];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
