//
//  ViewController.h
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UsersController : UIViewController

@property (nonatomic, strong) NSString *college;
@property (strong, nonatomic) QBChatDialog *createdDialog;
@property (strong, nonatomic) IBOutlet UILabel *schoolLabel;

@end

