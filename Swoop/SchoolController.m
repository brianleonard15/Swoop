//
//  ViewController.m
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import "SchoolController.h"
#import "MainController.h"

@interface SchoolController () <UISearchResultsUpdating, UISearchBarDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results

@end

@implementation SchoolController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Path to the plist (in the application bundle)
    NSString *path = [[NSBundle mainBundle] pathForResource:
                      @"colleges" ofType:@"plist"];
    
    // Build the array from the plist
    self.colleges = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    // Create a mutable array to contain products for the search results table.
    self.searchResults = [NSMutableArray arrayWithCapacity:[self.colleges count]];
    
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    self.searchController.searchResultsUpdater = self;
    
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    NSArray *sourceArray = self.searchController.active ? self.searchResults : self.colleges;
    
    UIViewController *destinationController = segue.destinationViewController;
    NSString *college = [sourceArray[indexPath.row] objectForKey:@"College"];
    ((MainController *)destinationController).college = college;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.searchController.active) {
        return [self.searchResults count];
    } else {
        return [self.colleges count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CollegeCell";
    
    // Dequeue a cell from self's table view.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    /*  If the requesting table view is the search controller's table view, configure the cell using the search results array, otherwise use the product array.
     */
    NSString *college;
    
    if (self.searchController.active) {
        college = [[self.searchResults objectAtIndex:indexPath.row] objectForKey:@"College"];
    } else {
        college = [[self.colleges objectAtIndex:indexPath.row] objectForKey:@"College"];
    }
    
    cell.textLabel.text = college;
    return cell;
}


#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchString = [self.searchController.searchBar text];
    
    // Update the filtered array based on the search text and scope.
    if ((searchString == nil) || [searchString length] == 0) {
        // If there is no search string
        self.searchResults = [self.colleges mutableCopy];
        return;
    }
    
    
    [self.searchResults removeAllObjects]; // First clear the filtered array.
    
    /*  Search the main list for products whose name matches searchText; add items that match to the filtered array.
     */
    [self.searchResults setArray:self.colleges];
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(College contains[c] %@) OR (State contains[c] %@)", searchString, searchString];
    [self.searchResults filterUsingPredicate:resultPredicate];
    
    [self.tableView reloadData];
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
