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

@interface ChatController () <QBActionStatusDelegate>

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) QBChatRoom *chatRoom;


@end

@implementation ChatController

/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.messages = [NSMutableArray array];
    
    self.title = @"JSQMessages";
    
    /**
     *  You MUST set your senderId and display name
     */
    self.senderId = [[NSNumber numberWithInteger:[LocalStorageService shared].currentUser.ID] stringValue];
    self.senderDisplayName = @"You";
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    
    self.showLoadEarlierMessagesHeader = YES;
    
    /**
     *  Create message bubble images objects.
     *
     *  Be sure to create your bubble images one time and reuse them for good performance.
     *
     */
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // Set chat notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidReceiveMessageNotification:)
                                                 name:kNotificationDidReceiveNewMessage object:nil];
    
    // Set title
    //QBUUser *recipient = [LocalStorageService shared].usersAsDictionary[@(self.user.ID)];
    self.title = self.alias;
    
    // get messages history
    NSMutableDictionary *extendedRequest = [NSMutableDictionary new];
    extendedRequest[@"occupants_ids[in]"] = @(self.user.ID);
    
    [QBChat dialogsWithExtendedRequest:extendedRequest delegate:self];
}






//  QBChatAbstractMessage *message = self.messages[indexPath.row];
//





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
        [self.collectionView reloadData];
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



#pragma mark - Actions

#pragma mark
#pragma mark Chat Notifications

- (void)chatDidReceiveMessageNotification:(NSNotification *)notification{
    
    //////////////////////////////////////////////////
    /**
     *  Show the typing indicator to be shown
     */
    self.showTypingIndicator = !self.showTypingIndicator;
    
    /**
     *  Scroll to actually view the indicator
     */
    [self scrollToBottomAnimated:YES];
    
    
    QBChatMessage *message = notification.userInfo[kMessage];
    if(message.senderID != self.dialog.recipientID){
        return;
    }
    
    
    
    
//    /**
//     *  Copy last sent message, this will be the new "received" message
//     */
//    JSQMessage *receivedMessage = [JSQMessage messageWithSenderId:
//                                   [[NSNumber numberWithInteger:message.senderID] stringValue]
//                                                      displayName:self.alias
//                                                             text:message.text];
    
    /**
     *  Allow typing indicator to show
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        
        /**
         *  Upon receiving a message, you should:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        // save message
        [self.messages addObject:message];
        [self finishReceivingMessageAnimated:YES];
        
        
    }
                   
    );
}




#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    // create a message
    QBChatMessage *message = [[QBChatMessage alloc] init];
    message.text = text;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"save_to_history"] = @YES;
    [message setCustomParameters:params];
    
    // send message
    message.recipientID = self.user.ID;
    message.senderID = [LocalStorageService shared].currentUser.ID;
    
    [[ChatService instance] sendMessage:message];
    
    [self.messages addObject:message];
    
    [self finishSendingMessageAnimated:YES];
}




#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QBChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    NSString *displayName;
    if (message.senderID == self.user.ID) {
        displayName = self.alias;
    }
    else {
        displayName = @"You";
    }

    JSQMessage *jsqMessage = [JSQMessage messageWithSenderId:
                                       [[NSNumber numberWithInteger:message.senderID] stringValue]
                                                          displayName:displayName
                                                                 text:message.text];

    return jsqMessage;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    QBChatMessage *message = [self.messages objectAtIndex:indexPath.item];

    if (message.senderID == self.user.ID) {
        return self.incomingBubbleImageData;
    }
    
    return self.outgoingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        QBChatMessage *message = [self.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.datetime];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    QBChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if (message.senderID != self.user.ID) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        QBChatMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if (previousMessage.senderID == message.senderID) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:self.alias];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    QBChatMessage *msg = [self.messages objectAtIndex:indexPath.item];

        if (msg.senderID == self.user.ID) {
            cell.textView.textColor = [UIColor whiteColor];
        }
        else {
            cell.textView.textColor = [UIColor blackColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };

    
    return cell;
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    QBChatMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
    if (currentMessage.senderID != self.user.ID) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        QBChatMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if (previousMessage.senderID == currentMessage.senderID) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}






@end

