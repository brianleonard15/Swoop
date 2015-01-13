//
//  ChatController.h
//  Swoop
//
//  Created by Brian on 1/12/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessages.h"


@class ChatController;

@protocol JSQDemoViewControllerDelegate <NSObject>

- (void)didDismissJSQDemoViewController:(ChatController *)vc;

@end




@interface ChatController : JSQMessagesViewController <UIActionSheetDelegate>

@property (nonatomic, strong) QBChatDialog *dialog;
@property (nonatomic, strong) QBUUser *user;
@property (nonatomic, strong) NSString *alias;

@property (weak, nonatomic) id<JSQDemoViewControllerDelegate> delegateModal;

@property (strong, nonatomic) DemoModelData *demoData;


@end
