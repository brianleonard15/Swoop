//
//  ViewController.m
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import "UsersController.h"
#import "UsersPaginator.h"
#import "DialogsController.h"

@interface UsersController () <UITableViewDelegate, UITableViewDataSource, NMPaginatorDelegate, QBActionStatusDelegate>

@property (nonatomic, strong) NSMutableArray *dialogs;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *animals;
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic, strong) NSMutableArray *selectedUsers;
@property (nonatomic, weak) IBOutlet UITableView *usersTableView;
@property (nonatomic, strong) UsersPaginator *paginator;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation UsersController


#pragma mark
#pragma mark ViewController lyfe cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Path to the plist (in the application bundle)
    NSString *animalPath = [[NSBundle mainBundle] pathForResource:
                      @"animals" ofType:@"plist"];
    NSString *colorPath = [[NSBundle mainBundle] pathForResource:
                      @"colors" ofType:@"plist"];
    
    // Build the array from the plist
    self.animals = [[[NSMutableArray alloc] initWithContentsOfFile:animalPath]valueForKey:@"Animal"];
    self.colors = [[[NSMutableArray alloc] initWithContentsOfFile:colorPath]valueForKey:@"Color"];
    
    self.users = [NSMutableArray array];
    self.selectedUsers = [NSMutableArray array];
    self.paginator = [[UsersPaginator alloc] initWithPageSize:10 delegate:self];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.activityIndicator startAnimating];
    
    [self setupTableViewFooter];
    
    // Fetch 10 users
    [self.paginator fetchFirstPage];
}

- (IBAction)createDialog:(id)sender{
    
    
    QBChatDialog *chatDialog = [QBChatDialog new];
    
    NSMutableArray *selectedUsersIDs = [NSMutableArray array];
    NSMutableArray *selectedUsersNames = [NSMutableArray array];
    for(QBUUser *user in self.selectedUsers){
        [selectedUsersIDs addObject:@(user.ID)];
        [selectedUsersNames addObject:user.login == nil ? user.email : user.login];
    }
    chatDialog.occupantIDs = selectedUsersIDs;
    
    if(self.selectedUsers.count == 1){
        chatDialog.type = QBChatDialogTypePrivate;
    }else{
        chatDialog.name = [selectedUsersNames componentsJoinedByString:@","];
        chatDialog.type = QBChatDialogTypeGroup;
    }
    
    [QBChat createDialog:chatDialog delegate:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showChat"]) {
        NSIndexPath *indexPath = [self.usersTableView indexPathForSelectedRow];
        QBUUser *user = self.users[indexPath.row];
        NSMutableDictionary *extendedRequest = [NSMutableDictionary new];
        extendedRequest[@"occupants_ids[in]"] = @(user.ID);
    
        [QBChat dialogsWithExtendedRequest:extendedRequest delegate:self];
        ChatController *destinationViewController = (ChatController *)segue.destinationViewController;
        QBChatDialog *dialog = self.dialogs[0];
        destinationViewController.dialog = dialog;
    }
}


#pragma mark
#pragma mark Paginator

- (void)fetchNextPage
{
    [self.paginator fetchNextPage];
    [self.activityIndicator startAnimating];
}

- (void)setupTableViewFooter
{
    // set up label
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    footerView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor lightGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    self.footerLabel = label;
    [footerView addSubview:label];
    
    // set up activity indicator
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.center = CGPointMake(40, 22);
    activityIndicatorView.hidesWhenStopped = YES;
    
    self.activityIndicator = activityIndicatorView;
    [footerView addSubview:activityIndicatorView];
    
    self.usersTableView.tableFooterView = footerView;
}

- (void)updateTableViewFooter
{
    if ([self.paginator.results count] != 0){
        self.footerLabel.text = [NSString stringWithFormat:@"%lu results out of %ld",
                                 (unsigned long)[self.paginator.results count], (long)self.paginator.total];
    }else{
        self.footerLabel.text = @"";
    }
    
    [self.footerLabel setNeedsDisplay];
}


#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    
    QBUUser *user = (QBUUser *)self.users[indexPath.row];
    cell.tag = indexPath.row;
    UILabel *userLabel = (UILabel *)[cell viewWithTag:100];
    int animalID = ((int)user.ID) % self.animals.count;
    int colorID = ((int)user.ID) % self.colors.count;
    userLabel.text = [NSString stringWithFormat:@"%@ %@", self.colors[colorID], self.animals[animalID]];
    
    UIView *greenCircle = (UIView *)[cell viewWithTag:101];
    greenCircle.layer.cornerRadius = (greenCircle.bounds.size.height/2);

    return cell;
}




#pragma mark
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // when reaching bottom, load a new page
    if (scrollView.contentOffset.y == scrollView.contentSize.height - scrollView.bounds.size.height){
        // ask next page only if we haven't reached last page
        if(![self.paginator reachedLastPage]){
            // fetch next page of results
            [self fetchNextPage];
        }
    }
}


#pragma mark -
#pragma mark QBActionStatusDelegate

// QuickBlox API queries delegate
- (void)completedWithResult:(Result *)result{
    if (result.success && [result isKindOfClass:[QBChatDialogResult class]]) {
        // dialog created
        
//        QBChatDialogResult *dialogRes = (QBChatDialogResult *)result;
//        
//        DialogsController *dialogsController = self.navigationController.viewControllers[0];
//        dialogsController.createdDialog = dialogRes.dialog;
//        
//        [self.navigationController popViewControllerAnimated:YES];
        
    }
    if (result.success && [result isKindOfClass:[QBDialogsPagedResult class]]) {
        QBDialogsPagedResult *pagedResult = (QBDialogsPagedResult *)result;
        //
        NSArray *dialogs = pagedResult.dialogs;
        self.dialogs = [dialogs mutableCopy];
        
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errors"
                                                        message:[[result errors] componentsJoinedByString:@","]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
        [alert show];
    }
}



#pragma mark
#pragma mark NMPaginatorDelegate

- (void)paginator:(id)paginator didReceiveResults:(NSArray *)results
{
    // update tableview footer
    [self updateTableViewFooter];
    [self.activityIndicator stopAnimating];
    
    // reload table with users
    [self.users addObjectsFromArray:results];
    [self.usersTableView reloadData];
}

@end
