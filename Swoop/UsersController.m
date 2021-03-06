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
#import "ChatController.h"

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
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    cell.backgroundColor = [UIColor clearColor];
}
- (void)viewDidLoad
{
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
    
    self.users = [NSMutableArray array];
    self.selectedUsers = [NSMutableArray array];
    self.paginator = [[UsersPaginator alloc] initWithPageSize:10 delegate:self];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.users = [NSMutableArray array];
    
    [self.activityIndicator startAnimating];
    
    [self setupTableViewFooter];
    
    // Fetch 10 users
    [self.paginator fetchFirstPageWithFullName:[LocalStorageService shared].currentUser.fullName];
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
        int animalID = ((int)user.ID) % self.animals.count;
        int colorID = ((int)user.ID) % self.colors.count;
        NSString *alias = [NSString stringWithFormat:@"%@ %@", self.colors[colorID], self.animals[animalID]];
        ChatController *destinationViewController = [segue destinationViewController];
        
        destinationViewController.user = user;
        destinationViewController.alias = alias;

    }
}


#pragma mark
#pragma mark Paginator

- (void)fetchNextPageWithFullName:(NSString *)fullName
{
    [self.paginator fetchNextPageWithFullName:fullName];
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
    
    UIView *onlineCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    onlineCircle.layer.cornerRadius = (onlineCircle.bounds.size.height/2);
    onlineCircle.backgroundColor = [UIColor grayColor];
    if ([user.customData isEqualToString:@"online"]) {
        onlineCircle.backgroundColor = [UIColor greenColor];
    }
    cell.accessoryView = onlineCircle;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // when reaching bottom, load a new page
    if (scrollView.contentOffset.y == scrollView.contentSize.height - scrollView.bounds.size.height){
        // ask next page only if we haven't reached last page
        if(![self.paginator reachedLastPage]){
            // fetch next page of results
            [self fetchNextPageWithFullName:[LocalStorageService shared].currentUser.fullName];
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
