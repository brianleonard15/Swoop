//
//  ViewController.m
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import "DialogsController.h"

@interface DialogsController () <UITableViewDelegate, UITableViewDataSource, QBActionStatusDelegate>

@property (nonatomic, strong) NSMutableArray *dialogs;
@property (nonatomic, weak) IBOutlet UITableView *dialogsTableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSMutableArray *animals;
@property (nonatomic, strong) NSMutableArray *colors;


@end

@implementation DialogsController


- (void)viewDidLoad {
    
    [super viewDidLoad];
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
        [QBChat dialogsWithExtendedRequest:nil delegate:self];
    }
}



#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dialogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DialogCell"];
    
    QBChatDialog *chatDialog = self.dialogs[indexPath.row];
    cell.tag  = indexPath.row;
    
    NSInteger recipientID = chatDialog.recipientID;
    //QBUUser *recipient = [LocalStorageService shared].usersAsDictionary[@(chatDialog.recipientID)];
    UILabel *userLabel = (UILabel *)[cell viewWithTag:100];
    int animalID = ((int)recipientID) % self.animals.count;
    int colorID = ((int)recipientID) % self.colors.count;
    userLabel.text = [NSString stringWithFormat:@"%@ %@", self.colors[colorID], self.animals[animalID]];
    
    UILabel *snippetLabel = (UILabel *)[cell viewWithTag:101];
    snippetLabel.text = chatDialog.lastMessageText;
    
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:102];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:chatDialog.lastMessageDate];
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
        
        QBGeneralResponsePage *pagedRequest = [QBGeneralResponsePage responsePageWithCurrentPage:0 perPage:100];
        //
        NSSet *dialogsUsersIDs = pagedResult.dialogsUsersIDs;
        //
        NSLog(@"helloooooo");
        [QBRequest usersWithIDs:[dialogsUsersIDs allObjects] page:pagedRequest successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            
            [LocalStorageService shared].users = users;
            //
            [self.dialogsTableView reloadData];
            NSLog(@"heeeeerre");
            [self.activityIndicator stopAnimating];
            
        } errorBlock:nil];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
