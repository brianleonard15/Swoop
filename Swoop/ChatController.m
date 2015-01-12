//
//  ChatController.m
//  Swoop
//
//  Created by Brian on 1/12/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

//
//  СhatViewController.m
//  sample-chat
//
//  Created by Igor Khomenko on 10/18/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "ChatController.h"
#import "ChatMessageTableViewCell.h"

@interface ChatController () <UITableViewDelegate, UITableViewDataSource, QBActionStatusDelegate>

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, weak) IBOutlet UITextField *messageTextField;
@property (nonatomic, weak) IBOutlet UIButton *sendMessageButton;
@property (nonatomic, weak) IBOutlet UITableView *messagesTableView;
@property (nonatomic, strong) QBChatRoom *chatRoom;

- (IBAction)sendMessage:(id)sender;


@end

@implementation ChatController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.messages = [NSMutableArray array];
    self.messagesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // Set keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    // Set chat notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidReceiveMessageNotification:)
                                                 name:kNotificationDidReceiveNewMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatRoomDidReceiveMessageNotification:)
                                                 name:kNotificationDidReceiveNewMessageFromRoom object:nil];
    
    // Set title
    //QBUUser *recipient = [LocalStorageService shared].usersAsDictionary[@(self.user.ID)];
    self.title = self.alias;
    
    // get messages history
    NSMutableDictionary *extendedRequest = [NSMutableDictionary new];
    extendedRequest[@"occupants_ids[in]"] = @(self.user.ID);
    
    [QBChat dialogsWithExtendedRequest:extendedRequest delegate:self];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.chatRoom leaveRoom];
    self.chatRoom = nil;
}

-(BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

#pragma mark
#pragma mark Actions

- (IBAction)sendMessage:(id)sender{
    if(self.messageTextField.text.length == 0){
        return;
    }
    
    // create a message
    QBChatMessage *message = [[QBChatMessage alloc] init];
    message.text = self.messageTextField.text;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"save_to_history"] = @YES;
    [message setCustomParameters:params];

        // send message
        message.recipientID = [self.dialog recipientID];
        message.senderID = [LocalStorageService shared].currentUser.ID;
        
        [[ChatService instance] sendMessage:message];
        
        // save message
        [self.messages addObject:message];
        
    
    // Reload table
    [self.messagesTableView reloadData];
    if(self.messages.count > 0){
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.messages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    // Clean text field
    [self.messageTextField setText:nil];
}


#pragma mark
#pragma mark Chat Notifications

- (void)chatDidReceiveMessageNotification:(NSNotification *)notification{
    
    QBChatMessage *message = notification.userInfo[kMessage];
    if(message.senderID != self.dialog.recipientID){
        return;
    }
    
    // save message
    [self.messages addObject:message];
    
    // Reload table
    [self.messagesTableView reloadData];
    if(self.messages.count > 0){
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.messages count]-1 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)chatRoomDidReceiveMessageNotification:(NSNotification *)notification{
    QBChatMessage *message = notification.userInfo[kMessage];
    NSString *roomJID = notification.userInfo[kRoomJID];
    
    if(![self.chatRoom.JID isEqualToString:roomJID]){
        return;
    }
    
    // save message
    [self.messages addObject:message];
    
    // Reload table
    [self.messagesTableView reloadData];
    if(self.messages.count > 0){
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.messages count]-1 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ChatMessageCellIdentifier = @"ChatMessageCellIdentifier";
    
    ChatMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ChatMessageCellIdentifier];
    if(cell == nil){
        cell = [[ChatMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ChatMessageCellIdentifier];
    }
    
    QBChatAbstractMessage *message = self.messages[indexPath.row];
    //
    [cell configureCellWithMessage:message];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    QBChatAbstractMessage *chatMessage = [self.messages objectAtIndex:indexPath.row];
    CGFloat cellHeight = [ChatMessageTableViewCell heightForCellWithMessage:chatMessage];
    return cellHeight;
}


#pragma mark
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark
#pragma mark Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)note
{
    [UIView animateWithDuration:0.3 animations:^{
        self.messageTextField.transform = CGAffineTransformMakeTranslation(0, -215);
        self.sendMessageButton.transform = CGAffineTransformMakeTranslation(0, -215);
        self.messagesTableView.frame = CGRectMake(self.messagesTableView.frame.origin.x,
                                                  self.messagesTableView.frame.origin.y,
                                                  self.messagesTableView.frame.size.width,
                                                  self.messagesTableView.frame.size.height-219);
    }];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    [UIView animateWithDuration:0.3 animations:^{
        self.messageTextField.transform = CGAffineTransformIdentity;
        self.sendMessageButton.transform = CGAffineTransformIdentity;
        self.messagesTableView.frame = CGRectMake(self.messagesTableView.frame.origin.x,
                                                  self.messagesTableView.frame.origin.y,
                                                  self.messagesTableView.frame.size.width,
                                                  self.messagesTableView.frame.size.height+219);
    }];
}


#pragma mark -
#pragma mark QBActionStatusDelegate

// QuickBlox API queries delegate
- (void)completedWithResult:(Result *)result{
    if (result.success && [result isKindOfClass:[QBDialogsPagedResult class]]) {
        QBDialogsPagedResult *pagedResult = (QBDialogsPagedResult *)result;
        //
        NSArray *dialogs = pagedResult.dialogs;
        self.dialog = dialogs[0];
        [QBChat messagesWithDialogID:self.dialog.ID extendedRequest:nil delegate:self];
        NSLog(@"00000000000000000000000000000000000000");
        
    }
    else if (result.success && [result isKindOfClass:QBChatHistoryMessageResult.class]) {
        QBChatHistoryMessageResult *res = (QBChatHistoryMessageResult *)result;
        NSArray *messages = res.messages;
        [self.messages addObjectsFromArray:[messages mutableCopy]];
        [self.messagesTableView reloadData];
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        NSLog(@"---------------------------------");
    }
    else{
        NSLog(@"11111111111111111111111111111");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errors"
                                                        message:[[result errors] componentsJoinedByString:@","]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
        [alert show];
    }
}





@end

