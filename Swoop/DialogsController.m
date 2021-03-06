//
//  ViewController.m
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import "DialogsController.h"
#import "NSDate+NVTimeAgo.h"
#import "ChatController.h"

@interface DialogsController () <UITableViewDelegate, UITableViewDataSource, QBActionStatusDelegate>

@property (nonatomic, strong) NSMutableArray *dialogs;
@property (nonatomic, strong) NSDictionary *dialogDict;
@property (nonatomic, weak) IBOutlet UITableView *dialogsTableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSMutableArray *animals;
@property (nonatomic, strong) NSMutableArray *colors;


@end

@implementation DialogsController
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    cell.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault]; //UIImageNamed:@"transparent.png"
    self.navigationController.navigationBar.shadowImage = [UIImage new];////UIImageNamed:@"transparent.png"
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.schoolLabel.text = [LocalStorageService shared].currentUser.fullName;
    // Path to the plist (in the application bundle)
    NSString *animalPath = [[NSBundle mainBundle] pathForResource:
                            @"animals" ofType:@"plist"];
    NSString *colorPath = [[NSBundle mainBundle] pathForResource:
                           @"colors" ofType:@"plist"];
    
    // Build the array from the plist
    self.animals = [[[NSMutableArray alloc] initWithContentsOfFile:animalPath]valueForKey:@"Animal"];
    self.colors = [[[NSMutableArray alloc] initWithContentsOfFile:colorPath]valueForKey:@"Color"];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if([LocalStorageService shared].currentUser != nil){
        [self.activityIndicator startAnimating];
        
        // get dialogs
        NSMutableDictionary *extendedRequest = [NSMutableDictionary new];
        extendedRequest[@"sort_desc"] = @"last_message_date_sent";
        [QBChat dialogsWithExtendedRequest:extendedRequest delegate:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showChat"]) {
        NSIndexPath *indexPath = [self.dialogsTableView indexPathForSelectedRow];
        QBUUser *user = [LocalStorageService shared].users[indexPath.row];
        int animalID = ((int)user.ID) % self.animals.count;
        int colorID = ((int)user.ID) % self.colors.count;
        NSString *alias = [NSString stringWithFormat:@"%@ %@", self.colors[colorID], self.animals[animalID]];
        ChatController *destinationViewController = [segue destinationViewController];
        
        destinationViewController.user = user;
        destinationViewController.alias = alias;
        
    }
}


#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[LocalStorageService shared].users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DialogCell"];
    
    cell.tag  = indexPath.row;
    QBUUser *recipientUser = [LocalStorageService shared].users[indexPath.row];
    QBChatDialog *chatDialog = [LocalStorageService shared].dialogDictionary[recipientUser];
    NSInteger recipientID = recipientUser.ID;
    //QBUUser *recipient = [LocalStorageService shared].usersAsDictionary[@(chatDialog.recipientID)];
    UILabel *userLabel = (UILabel *)[cell viewWithTag:100];
    int animalID = ((int)recipientID) % self.animals.count;
    int colorID = ((int)recipientID) % self.colors.count;
    userLabel.text = [NSString stringWithFormat:@"%@ %@", self.colors[colorID], self.animals[animalID]];
    
    UILabel *snippetLabel = (UILabel *)[cell viewWithTag:101];
    snippetLabel.text = chatDialog.lastMessageText;
    
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:102];
    NSString *dateString = [chatDialog.lastMessageDate formattedAsTimeAgo];
    dateLabel.text = dateString;
    
    
    

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark QBActionStatusDelegate

// QuickBlox API queries delegate
- (void)completedWithResult:(Result *)result{
    if (result.success && [result isKindOfClass:[QBDialogsPagedResult class]]) {
        QBDialogsPagedResult *pagedResult = (QBDialogsPagedResult *)result;
        //
        NSArray *dialogs = pagedResult.dialogs;
        self.dialogs = [dialogs mutableCopy];
        
        NSArray *recipientIDs = [self.dialogs valueForKeyPath:@"recipientID"];
        
        QBGeneralResponsePage *pagedRequest = [QBGeneralResponsePage responsePageWithCurrentPage:0 perPage:100];
        
        [QBRequest usersWithIDs:recipientIDs page:pagedRequest successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            
            
            
            [LocalStorageService shared].dialogDictionary = [NSDictionary dictionaryWithObjects:self.dialogs forKeys:users];
            NSLog(@"asdfkljasdfkajklsdfkjlasdfkjlasdfkjlasdflkjaskdlfjasdfljkasdfkjaksdjlfkjalsdfkljadskfljkladsfjklakldsfadksfkljasdkjlfjkasdkflljkadskfkadsflkadjksljkd %@", [LocalStorageService shared].dialogDictionary);
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.fullName == %@",[LocalStorageService shared].currentUser.fullName];
            
            NSArray *filteredArray = [users filteredArrayUsingPredicate:predicate];
            [LocalStorageService shared].users = filteredArray;
            
            
            [self.dialogsTableView reloadData];
            [self.activityIndicator stopAnimating];
            
        } errorBlock:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
