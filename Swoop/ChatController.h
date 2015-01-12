//
//  ChatController.h
//  Swoop
//
//  Created by Brian on 1/12/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatController : UIViewController

@property (nonatomic, strong) QBChatDialog *dialog;
@property (nonatomic, strong) QBUUser *user;
@property (nonatomic, strong) NSString *alias;

@end
