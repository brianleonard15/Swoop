//
//  ViewController.h
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SchoolController : UIViewController

@property (nonatomic, strong) NSMutableArray *colleges;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

