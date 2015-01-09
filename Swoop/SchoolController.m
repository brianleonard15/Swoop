//
//  ViewController.m
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import "SchoolController.h"

@interface SchoolController ()

@end

@implementation SchoolController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.searchResults = [NSMutableArray array];
    
    // Path to the plist (in the application bundle)
    NSString *path = [[NSBundle mainBundle] pathForResource:
                      @"colleges" ofType:@"plist"];
    
    // Build the array from the plist
    self.colleges = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    NSDictionary *result = [self.searchResults objectAtIndex:indexPath.row];
    cell.textLabel.text = [result objectForKey:@"College"];
    return cell;
}

- (void)filterResults:(NSString *)searchTerm {
    
    //[self.searchResults removeAllObjects];
    [self.searchResults setArray:self.colleges];
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"College contains[c] %@", searchTerm];
    [self.searchResults filterUsingPredicate:resultPredicate];
}



- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterResults:searchString];
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.searchResults count];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
