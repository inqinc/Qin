//
//  LocalFeedViewController.m
//  Yoke
//
//  Created by Abhijit on 6/17/13.
//  Copyright (c) 2013 Abhijit. All rights reserved.
//

#import "LocalFeedViewController.h"
#import "QuestinViewCell.h"
#import "PostQuestionViewController.h"
#import "CommentViewController.h"
#import "MainTabbarController.h"

@interface LocalFeedViewController ()

@end

@implementation LocalFeedViewController
@synthesize isKeywordSort,isPostDateSort,isTakerSort;
@synthesize answeredIndex,strAnswered,isQtagPressed;
@synthesize dictQuestionDetail;

@synthesize questionArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getList) name:KQUESTIONPOSTEDNOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goToMergeView:) name:KCLICKEDFROMLOGNOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getList) name:KMERGEUPDATEDNOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getLocalFeedList) name:KQUESTIONANSWEREDNOTIFICATION object:nil];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    arBuffer = [[NSMutableArray alloc] init];
    appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    questionArray = [[NSMutableArray alloc] init];
    [lblLocalFeed setFont:[UIFont fontWithName:CABIN_BOLD size:22.0]];
    [lblPostQuestion setFont:[UIFont fontWithName:CABIN_REGULAR size:15.0]];
    [lblHideQuestion setFont:[UIFont fontWithName:CABIN_REGULAR size:11.0]];
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[NSLocale currentLocale]];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setUsesSignificantDigits:NO];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setMinimumFractionDigits:0];
    [numberFormatter setGroupingSeparator:@""];
    fontSize = 14;
    
    if([appDelegate isNetWorkAvailable])
        [self performSelector:@selector(callQuestionListService) withObject:nil afterDelay:0.5];
    else
        [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
    
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    appDelegate.strActiveQuestionID = @"0";
}
#pragma mark - Custom Methods
-(void)getLocalFeedList
{
    if([self.tabBarController selectedIndex])
    {
        if([appDelegate isNetWorkAvailable])
            [self callQuestionListService];
    }
}
-(void)getList
{
    if([appDelegate isNetWorkAvailable])
        [self callQuestionListService];
}
-(CGFloat)getHeight:(NSString*)str
{
    fontSize = 14.0;
    CGSize maximumSize = CGSizeMake(226, 9999);
    UIFont *myFont = [UIFont fontWithName:CABIN_REGULAR size:fontSize];
    CGSize myStringSize = [str sizeWithFont:myFont
                          constrainedToSize:maximumSize
                              lineBreakMode:NSLineBreakByCharWrapping];
    while (myStringSize.height > 50) {
        fontSize--;
        myFont = [UIFont fontWithName:CABIN_REGULAR size:fontSize];
        myStringSize = [str sizeWithFont:myFont
                       constrainedToSize:maximumSize
                           lineBreakMode:NSLineBreakByCharWrapping];
        if(fontSize==12)
            break;
    }
    return myStringSize.height;
}
-(void)reloadTableWithScore:(NSArray*)arrRecord
{
    if([self.strAnswered isEqualToString:@"0"])
    {
        int total = [[self.dictQuestionDetail valueForKey:@"TotalTakers"]intValue];
        total++;
        [self.dictQuestionDetail setValue:[NSString stringWithFormat:@"%d",total] forKey:@"TotalTakers"];
        int totalNO = [[self.dictQuestionDetail valueForKey:@"TotalNo"]intValue];
        totalNO++;
        [self.dictQuestionDetail setValue:[NSString stringWithFormat:@"%d",totalNO] forKey:@"TotalNo"];
    }
    else
    {
        int total = [[self.dictQuestionDetail valueForKey:@"TotalTakers"]intValue];
        total++;
        [self.dictQuestionDetail setValue:[NSString stringWithFormat:@"%d",total] forKey:@"TotalTakers"];
        int totalNO = [[self.dictQuestionDetail valueForKey:@"TotalYes"]intValue];
        totalNO++;
        [self.dictQuestionDetail setValue:[NSString stringWithFormat:@"%d",totalNO] forKey:@"TotalYes"];

    }
    if(isSearching)
        [arBuffer replaceObjectAtIndex:self.answeredIndex withObject:self.dictQuestionDetail];
    else
        [self.questionArray replaceObjectAtIndex:self.answeredIndex withObject:self.dictQuestionDetail];
    
    [tblLocalFeed reloadRowsAtIndexPaths:arrRecord withRowAnimation:UITableViewRowAnimationNone];

}
-(void)reloadTable:(NSArray*)arrRecord
{
    [tblLocalFeed reloadRowsAtIndexPaths:arrRecord withRowAnimation:UITableViewRowAnimationNone];
    [self performSelector:@selector(reloadTableWithScore:) withObject:arrRecord afterDelay:0.7];
}
#pragma mark - Webservice Methods
-(void)callQuestionListService
{
    NSString *strLatitude = [NSString stringWithFormat:@"%f",appDelegate.latitude];
    NSString *strLongitude = [NSString stringWithFormat:@"%f",appDelegate.longitude];
    
    webserviceType = QUESTIONLIST;
    if(service)
        service = nil;
    [self showActivity];
    service = [[WebService alloc] init];
	service.webserviceDelegate = self;
    NSString *strUserID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:strUserID,@"UserId",strLatitude,@"Latitude",strLongitude,@"Longitude",nil];
    [service jsonRESTWebServiceMethod:@"QuestionList" WithParameter:dict];
}
-(void)callSubmitAnswerService:(NSString*)questionID answer:(NSString*)ansYesNo
{
    webserviceType = SUBMITANS;
    if(service)
        service = nil;
//    [self showActivity];
    service = [[WebService alloc] init];
	service.webserviceDelegate = self;
    NSString *strUserID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:strUserID,@"UserId",questionID,@"QuestionId",ansYesNo,@"Answer",nil];
    [service jsonRESTWebServiceMethod:@"SubmitAnswer" WithParameter:dict];
}
-(void)showActivity {
    
	[self hideActivity];
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	[HUD setLabelText:@"Loading..."];
	[HUD show:YES];
}


-(void)hideActivity {
	if(HUD){
		[HUD hide:YES];
		[HUD removeFromSuperview];
		HUD = nil;
	}
}
#pragma mark -
#pragma mark Webservice call back Methods


-(void)connectionError:(NSError*)err {
	[self hideActivity];
	if(service){
		service = nil;
	}
	[UIAlertView showInfo:[err localizedDescription] WithTitle:ALERTNAME Delegate:nil];
}


-(void)connectionFinish:(WebService*)webservice response:(NSData*)data {
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    NSMutableDictionary *dict = nil;
    if(webserviceType==QUESTIONLIST)
    {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            dict=(NSMutableDictionary *)obj;
        }
        if (dict) {
            if([[dict objectForKey:@"status"] isEqualToString:@"QuestionList_1"])
            {
//                self.questionArray = [dict objectForKey:@"data"];
//                [tblLocalFeed reloadData];
                [self.questionArray removeAllObjects];
                for(NSMutableDictionary *dictList in [dict objectForKey:@"data"])
                {
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] ];
                    
                    NSDate *myDate = [df dateFromString: [dictList valueForKey:@"PostedDate"]];
                    [dictList setObject:myDate forKey:@"PostedDate"];
                    
//                    int index = [self.questionArray count];
                    if([[NSUserDefaults standardUserDefaults] boolForKey:@"HideAnsweredQuestion"])
                    {
                        if(![[dictList valueForKey:@"Answered"] integerValue])
                            [self.questionArray addObject:dictList];
                    }
                    else
                        [self.questionArray addObject:dictList];
//                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:index inSection:0];
//                    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
                    //[tblLocalFeed insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationNone];
                }
                [tblLocalFeed reloadData];
            }
            else
            {
                [UIAlertView showInfo:[dict objectForKey:@"message"] WithTitle:ALERTNAME Delegate:nil];
            }
        }
        else {
//            [UIAlertView showInfo:@"No data found" WithTitle:ALERTNAME Delegate:nil];
        }
        [self hideActivity];
        if(service)
            service = nil;
    }
    else if(webserviceType==SUBMITANS)
    {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            dict=(NSMutableDictionary *)obj;
        }
        if (dict) {
            if([[dict objectForKey:@"status"] isEqualToString:@"SubmitAnswer_1"])
            {
            //    [UIAlertView showInfo:[dict objectForKey:@"message"] WithTitle:ALERTNAME Delegate:self];
                if([appDelegate isNetWorkAvailable])
                {
//                    [self callQuestionListService];
                    AnsweredQuestion();
                }
                else
                    [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
            }
            else
            {
                [UIAlertView showInfo:[dict objectForKey:@"message"] WithTitle:ALERTNAME Delegate:nil];
            }
        }
        else {
//            [UIAlertView showInfo:@"No data found" WithTitle:ALERTNAME Delegate:nil];
        }
        [self hideActivity];
        if(service)
            service = nil;
        
    }
}
#pragma mark - Alertview delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==5)
    {
        if(!buttonIndex)
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"dntShowAgain"];
    }
    else
    {
        if([appDelegate isNetWorkAvailable])
        {
            [self callQuestionListService];
            AnsweredQuestion();
        }
        else
            [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
    }    
}

#pragma mark - Action Methods
-(IBAction)btnClearAction:(id)sender
{
    self.isQtagPressed = NO;
    [searchView removeFromSuperview];
    isSearching = NO;
    txtSearch.text = @"";
    [txtSearch resignFirstResponder];
    [tblLocalFeed reloadData];
}

-(IBAction)btnHideAction:(id)sender
{
    if(!self.isQtagPressed)
    {
        [txtSearch becomeFirstResponder];
        self.isQtagPressed = YES;
        isSearching = YES;
        searchView.frame = CGRectMake(0, 43, 276, 44);
        [self.view addSubview:searchView];
    }
    else
    {
        [self btnClearAction:nil];
    }
/*    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"keyword"
                                                                 ascending:self.isKeywordSort selector:@selector(localizedStandardCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [self.questionArray sortedArrayUsingDescriptors:sortDescriptors];
    if(self.questionArray)
    {
        [self.questionArray removeAllObjects];
        self.questionArray = nil;
    }
    self.questionArray=[sortedArray mutableCopy];
    [tblLocalFeed reloadData];
    if(self.isKeywordSort)
        self.isKeywordSort = NO;
    else
        self.isKeywordSort = YES;*/

}
-(IBAction)btnLogoutAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"IsLoggedIn"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"HideAnsweredQuestion"];
    [self.tabBarController.navigationController popViewControllerAnimated:YES];
}
-(IBAction)btnPostAction:(id)sender
{
    PostQuestionViewController *postQsObj = [[PostQuestionViewController alloc] initWithNibName:@"PostQuestionViewController" bundle:[NSBundle mainBundle]];
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    [transition setType:kCATransitionFade];
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [self.navigationController.view.layer addAnimation:transition forKey:@"SwitchToView"];
    [self.navigationController pushViewController:postQsObj animated:NO];
}
-(IBAction)sortingAction:(id)sender
{
    FPTableController *controller = [[FPTableController alloc] initWithStyle:UITableViewStylePlain];
    controller.isSorting = YES;
    controller.arrList = [NSMutableArray arrayWithObjects:@"    clear Ans. Q's",@"    post date",@"    # of takers",@"    Logout", nil];
    controller._delegate = self;
    popover = [[FPPopoverController alloc] initWithViewController:controller];
    
    popover.arrowDirection = FPPopoverArrowDirectionAny;
    popover.tint = FPPopoverDefaultTint;
    popover.contentSize = CGSizeMake(200, 160);
    
    //sender is the UIButton view
    [popover presentPopoverFromView:sender];
}
-(IBAction)btnNOAction:(id)sender
{
    NSDictionary *dictData ;//= [self.self.questionArray objectAtIndex:[sender tag]];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:[sender tag]];
    else
        dictData = [self.questionArray objectAtIndex:[sender tag]];
    if([[dictData valueForKey:@"Answered"] integerValue])
    {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"dntShowAgain"])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERTNAME message:@"You’ve already Q’ed in on this one. Tap Q to open or tap on the Qtag to search." delegate:self cancelButtonTitle:@"Don't show again" otherButtonTitles:@"OK", nil];
            alert.tag = 5;
            [alert show];
            return;
        }
        else
            return;
//        [UIAlertView showInfo:@"You’ve already Q’ed in on this one. Tap Q to open or tap on the Qtag to search." WithTitle:ALERTNAME Delegate:nil];
    }
    else
    {
        if([appDelegate isNetWorkAvailable])
        {
//        NSMutableDictionary *dictQuestion = [[NSMutableDictionary alloc] initWithDictionary:dictData];
        [dictData setValue:@"1" forKey:@"Answered"];
        [dictData setValue:@"0" forKey:@"UserAnswered"];
//        int total = [[dictData valueForKey:@"TotalTakers"]intValue];
//        total++;
//        [dictData setValue:[NSString stringWithFormat:@"%d",total] forKey:@"TotalTakers"];
//        int totalNO = [[dictData valueForKey:@"TotalNo"]intValue];
//        totalNO++;
//        [dictData setValue:[NSString stringWithFormat:@"%d",totalNO] forKey:@"TotalNo"];
        if(isSearching)
            [arBuffer replaceObjectAtIndex:[sender tag] withObject:dictData];
        else
            [self.questionArray replaceObjectAtIndex:[sender tag] withObject:dictData];
//        [self.questionArray replaceObjectAtIndex:[sender tag] withObject:dictQuestion];
        
        NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
        NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
        [self performSelector:@selector(reloadTable:) withObject:rowsToReload afterDelay:0.0];
//        [tblLocalFeed reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
        
        
            self.dictQuestionDetail = dictData;
            self.strAnswered = @"0";
            self.answeredIndex = [sender tag];
            [self callSubmitAnswerService:[dictData valueForKey:@"question_id"] answer:@"0"];
        }
        else
            [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
    }
}
-(IBAction)btnYESAction:(id)sender
{
    NSDictionary *dictData ;//= [self.self.questionArray objectAtIndex:[sender tag]];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:[sender tag]];
    else
        dictData = [self.questionArray objectAtIndex:[sender tag]];
    if([[dictData valueForKey:@"Answered"] integerValue])
    {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"dntShowAgain"])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERTNAME message:@"You’ve already Q’ed in on this one. Tap Q to open or tap on the Qtag to search." delegate:self cancelButtonTitle:@"Don't show again" otherButtonTitles:@"OK", nil];
            alert.tag = 5;
            [alert show];
            return;
        }
        else
            return;
//        [UIAlertView showInfo:@"You’ve already Q’ed in on this one. Tap Q to open or tap on the Qtag to search." WithTitle:ALERTNAME Delegate:nil];
    }
    else
    {
        if([appDelegate isNetWorkAvailable])
        {
//        NSMutableDictionary *dictQuestion = [[NSMutableDictionary alloc] initWithDictionary:dictData];
        [dictData setValue:@"1" forKey:@"Answered"];
        [dictData setValue:@"1" forKey:@"UserAnswered"];
//        int total = [[dictData valueForKey:@"TotalTakers"]intValue];
//        total++;
//        [dictData setValue:[NSString stringWithFormat:@"%d",total] forKey:@"TotalTakers"];
//        int totalNO = [[dictData valueForKey:@"TotalYes"]intValue];
//        totalNO++;
//        [dictData setValue:[NSString stringWithFormat:@"%d",totalNO] forKey:@"TotalYes"];
        if(isSearching)
            [arBuffer replaceObjectAtIndex:[sender tag] withObject:dictData];
        else
            [self.questionArray replaceObjectAtIndex:[sender tag] withObject:dictData];
//        [self.questionArray replaceObjectAtIndex:[sender tag] withObject:dictQuestion];
        
        NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
        NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
        [self performSelector:@selector(reloadTable:) withObject:rowsToReload afterDelay:0.0];
//        [tblLocalFeed reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
        
            self.dictQuestionDetail = dictData;
            self.strAnswered = @"1";
            self.answeredIndex = [sender tag];
            [self callSubmitAnswerService:[dictData valueForKey:@"question_id"] answer:@"1"];
        }
        else
            [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
    }

}

#pragma mark - FPPopoverController Delegate

- (void)presentedNewPopoverController:(FPPopoverController *)newPopoverController
          shouldDismissVisiblePopover:(FPPopoverController*)visiblePopoverController
{
    [popover dismissPopoverAnimated:YES];
}

- (void)popoverControllerDidDismissPopover:(NSString*)index{
    switch ([index integerValue]) {
        case 0:
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HideAnsweredQuestion"];
            NSMutableArray *arrTemp = [[NSMutableArray alloc] init];
            for(NSDictionary *dict in self.questionArray)
            {
                if([[dict valueForKey:@"Answered"] integerValue])
                    [arrTemp addObject:dict];
            }
            for(NSDictionary *dict in arrTemp)
                [self.questionArray removeObject:dict];
            [tblLocalFeed reloadData];

            break;
        }
        case 1:
        {
            NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"PostedDate"
                                                                         ascending:self.isPostDateSort];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
            if(isSearching)
            {
                NSArray *sortedArray = [arBuffer sortedArrayUsingDescriptors:sortDescriptors];
                arBuffer=[sortedArray mutableCopy];
            }
            else
            {
                NSArray *sortedArray = [self.questionArray sortedArrayUsingDescriptors:sortDescriptors];
                self.questionArray=[sortedArray mutableCopy];
            }
            [tblLocalFeed reloadData];
            if(self.isPostDateSort)
                self.isPostDateSort = NO;
            else
                self.isPostDateSort = YES;
            break;
        }
        case 2:
        {
            NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"TotalTakers" ascending:self.isTakerSort comparator:^(id obj1, id obj2) {
                if ([obj1 integerValue] > [obj2 integerValue]) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                if ([obj1 integerValue] < [obj2 integerValue]) {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedSame;
            }];
             NSArray *sortDescriptors = [NSArray arrayWithObject: sorter];
            if(isSearching)
            {
                NSArray *sortedArray = [arBuffer sortedArrayUsingDescriptors:sortDescriptors];
                arBuffer=[sortedArray mutableCopy];
            }
            else
            {
                NSArray *sortedArray = [self.questionArray sortedArrayUsingDescriptors:sortDescriptors];
                self.questionArray=[sortedArray mutableCopy];
            }
            [tblLocalFeed reloadData];
            if(self.isTakerSort)
                self.isTakerSort = NO;
            else
                self.isTakerSort = YES;
            break;
        }
        case 3:
        {
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"IsLoggedIn"];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"HideAnsweredQuestion"];
            [self.tabBarController.navigationController popViewControllerAnimated:YES];
            break;
        }
        default:
            break;
    }
    [popover dismissPopoverAnimated:YES];
    
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(isSearching)
        return [arBuffer count];
    else
        return [self.questionArray count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dictData ;//= [self.self.questionArray objectAtIndex:indexPath.row];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:indexPath.row];
    else
        dictData = [self.questionArray objectAtIndex:indexPath.row];
    
    NSString *strQuestion = [NSString stringWithFormat:@"%@%@",[dictData valueForKey:@"question"],[dictData valueForKey:@"keyword"]];
    if([[dictData valueForKey:@"Answered"] integerValue])
        return 97+[self getHeight:strQuestion]; //return 105+[self getHeight:strQuestion];
    else
        return 59+[self getHeight:strQuestion]; //return 67+[self getHeight:strQuestion];
}
#pragma mark -
#pragma mark UITableview Delegate Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *nibname = @"QuestinViewCell";
    NSString *nibname1 = @"AnsweredQuestionViewCell";
    QuestinViewCell *cell ;
    AnsweredQuestionVewCell *answeredCell;
    NSString *strHTML;
    NSDictionary *dictData ;//= [self.questionArray objectAtIndex:indexPath.row];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:indexPath.row];
    else
        dictData = [self.questionArray objectAtIndex:indexPath.row];
    NSString *strQuestion = [NSString stringWithFormat:@"%@%@",[dictData valueForKey:@"question"],[dictData valueForKey:@"keyword"]];
    NSMutableDictionary *dictQuestion = [NSMutableDictionary dictionary];
    
    [self getHeight:strQuestion];
    NSArray *keywordArr = [[dictData valueForKey:@"keyword"] componentsSeparatedByString:@","];
    if([keywordArr count]>1)
    {
        strHTML = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=%d color='#454545'>%@</font> ",fontSize,[dictData valueForKey:@"question"]];
        int temp = 0;
        for(NSString *strKeyword in keywordArr)
        {
            if(!temp)
            {
                strHTML = [strHTML stringByAppendingString:[NSString stringWithFormat:@"<a href='%@'><font face='Cabin-Regular' size=%d color='#6f0da1'>%@</font></a>",strKeyword,fontSize,strKeyword]];
                temp++;
            }
            else
            {
                strHTML = [strHTML stringByAppendingString:[NSString stringWithFormat:@"<a href='%@'><font face='Cabin-Regular' size=%d color='#6f0da1'>,%@</font></a>",strKeyword,fontSize,strKeyword]];
            }
        }
    }
    else
        strHTML = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=%d color='#454545'>%@</font> <a href='%@'><font face='Cabin-Regular' size=%d color='#6f0da1'>%@</font></a>",fontSize,[dictData valueForKey:@"question"],[dictData valueForKey:@"keyword"],fontSize,[dictData valueForKey:@"keyword"]];
    
    
    
    if([[dictData valueForKey:@"Answered"] integerValue])
    {
        answeredCell = [AnsweredQuestionVewCell dequeOrCreateInTable:tableView withNibName:nibname1];
        [answeredCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if([[dictData valueForKey:@"UserAnswered"]integerValue])
        {
            [answeredCell.btnYES setImage:[UIImage imageNamed:@"ans_btn_yes_sel"] forState:UIControlStateNormal];
            [answeredCell.btnNO setImage:[UIImage imageNamed:@"ans_btn_no"] forState:UIControlStateNormal];
        }
        else
        {
            [answeredCell.btnNO setImage:[UIImage imageNamed:@"ans_btn_no_sel"] forState:UIControlStateNormal];
            [answeredCell.btnYES setImage:[UIImage imageNamed:@"ans_btn_yes"] forState:UIControlStateNormal];
        }
        [answeredCell.viewQuestion setFrame:CGRectMake(47, 0, 226, 96+[self getHeight:strQuestion])];
        [answeredCell.lblQuestion setFrame:CGRectMake(0, 5, 226, [self getHeight:strQuestion]+8)];
        
        [dictQuestion setObject:strHTML forKey:@"text"];
        //[answeredCell.lblNOPercentage setFrame:CGRectMake(3, 50, 118, 21)];

        [answeredCell.btnNO setTag:indexPath.row];
        [answeredCell.btnYES setTag:indexPath.row];
        [answeredCell.btnNO addTarget:self action:@selector(btnNOAction:) forControlEvents:UIControlEventTouchUpInside];
        [answeredCell.btnYES addTarget:self action:@selector(btnYESAction:) forControlEvents:UIControlEventTouchUpInside];
        
        if([[dictData valueForKey:@"TotalTakers"]integerValue]>1)
            [answeredCell.lblTackers setText:[NSString stringWithFormat:@"%@ Takers",[dictData valueForKey:@"TotalTakers"]]];
        else
            [answeredCell.lblTackers setText:[NSString stringWithFormat:@"%@ Taker",[dictData valueForKey:@"TotalTakers"]]];

        float totalTakers = [[dictData valueForKey:@"TotalTakers"] floatValue];
        float totalNO = [[dictData valueForKey:@"TotalNo"] floatValue];
        float totalYES = [[dictData valueForKey:@"TotalYes"] floatValue];
        
        float noValue = 0;
        float yesValue = 0;
        if(totalTakers!=0)
        {
            noValue = (totalNO/totalTakers)*100;
            yesValue = (totalYES/totalTakers)*100;
        }
//        NSString *strNO = [NSString stringWithFormat:@"%.2f",noValue];
//        NSString *strYes = [NSString stringWithFormat:@"%.2f",yesValue];

        NSString *strNOValue;
       
        NSString *strNO = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:noValue]];
        NSString *strYes = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:yesValue]];

        NSRange range = [strNO rangeOfString:@"."];
        
        if (!range.length)
            strNOValue = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=14 color='#980000'>%@</font><font face='Cabin-Regular' size=14 color='#980000'>%@</font>",[[strNO componentsSeparatedByString:@"."]objectAtIndex:0],@"%"];
        else
            strNOValue = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=14 color='#980000'>%@.</font><font face='Cabin-Regular' size=11 color='#454545'>%@</font><font face='Cabin-Regular' size=14 color='#980000'>%@</font>",[[strNO componentsSeparatedByString:@"."]objectAtIndex:0],[[strNO componentsSeparatedByString:@"."]objectAtIndex:1],@"%"];
        
        range = [strYes rangeOfString:@"."];
        NSString *strYESValue;
        if (!range.length)
            strYESValue = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=14 color='#0000FF'>%@</font><font face='Cabin-Regular' size=14 color='#0000FF'>%@</font>",[[strYes componentsSeparatedByString:@"."]objectAtIndex:0],@"%"];
        else
            strYESValue = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=14 color='#0000FF'>%@.</font><font face='Cabin-Regular' size=11 color='#454545'>%@</font><font face='Cabin-Regular' size=14 color='#0000FF'>%@</font>",[[strYes componentsSeparatedByString:@"."]objectAtIndex:0],[[strYes componentsSeparatedByString:@"."]objectAtIndex:1],@"%"];
        if([[dictData valueForKey:@"TotalNo"]integerValue])
        {
            answeredCell.lblNOVoters.hidden = NO;
            [answeredCell.lblNOPercentage setHidden:NO];
            [answeredCell.lblNOVoters setText:[NSString stringWithFormat:@"%@ - 's",[dictData valueForKey:@"TotalNo"]]];
            [answeredCell.lblNOPercentage setText:strNOValue];
            answeredCell.lblNOPercentage.lineSpacing = 0.0;
        }
        else
        {
            answeredCell.lblNOVoters.hidden = YES;
            [answeredCell.lblNOPercentage setHidden:YES];
        }
        if([[dictData valueForKey:@"TotalYes"]integerValue])
        {
            answeredCell.lblYESVoters.hidden = NO;
            [answeredCell.lblYESPercentage setHidden:NO];
            [answeredCell.lblYESVoters setText:[NSString stringWithFormat:@"%@ + 's",[dictData valueForKey:@"TotalYes"]]];
            [answeredCell.lblYESPercentage setText:strYESValue];
            answeredCell.lblYESPercentage.lineSpacing = 0.0;
        }
        else
        {
            answeredCell.lblYESVoters.hidden = YES;
            [answeredCell.lblYESPercentage setHidden:YES];
        }
        

        float noWidth = (206*noValue)/100;
        float yesWidth = (206*yesValue)/100;
        float variableNo = 0.0;
        float variableYes = 0.0;
        if(!noWidth && yesWidth)
            variableYes = 6.0;
        if(!yesWidth && noWidth)
            variableNo = 6.0;
        [answeredCell.imgNO setFrame:CGRectMake(7, answeredCell.imgNO.frame.origin.y, noWidth+variableNo, 13)];
        [answeredCell.imgYES setFrame:CGRectMake(116-(103-noWidth)-variableYes, answeredCell.imgNO.frame.origin.y, yesWidth+variableYes, 13)];
        if(answeredCell.imgNO.center.x<=28)
        {
            answeredCell.lblNOVoters.center = CGPointMake(28, answeredCell.lblNOVoters.center.y);
            answeredCell.lblNOPercentage.center = CGPointMake(28, answeredCell.lblNOPercentage.center.y);
        }
        else
        {
            answeredCell.lblNOVoters.center = CGPointMake(answeredCell.imgNO.center.x, answeredCell.lblNOVoters.center.y);
            answeredCell.lblNOPercentage.center = CGPointMake(answeredCell.imgNO.center.x, answeredCell.lblNOPercentage.center.y);
        }
        if(answeredCell.imgYES.center.x>=199)
        {
            answeredCell.lblYESVoters.center = CGPointMake(199, answeredCell.lblYESVoters.center.y);
            answeredCell.lblYESPercentage.center = CGPointMake(199, answeredCell.lblYESPercentage.center.y);
        }
        else
        {
            answeredCell.lblYESVoters.center = CGPointMake(answeredCell.imgYES.center.x, answeredCell.lblYESVoters.center.y);
            answeredCell.lblYESPercentage.center = CGPointMake(answeredCell.imgYES.center.x, answeredCell.lblYESPercentage.center.y);
        }
        
        
        [answeredCell.lblQuestion setDelegate:self];
        [answeredCell.lblQuestion setText:[dictQuestion objectForKey:@"text"]];
        answeredCell.lblQuestion.lineSpacing = 0.0;
        
        return answeredCell;
    }
    else
    {
        cell = [QuestinViewCell dequeOrCreateInTable:tableView withNibName:nibname];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [cell.viewQuestion setFrame:CGRectMake(47, 0, 226, 58+[self getHeight:strQuestion])];
        [cell.lblQuestion setFrame:CGRectMake(0, 5, 226, ([self getHeight:strQuestion]+8))];

        
        [dictQuestion setObject:strHTML forKey:@"text"];
        
        [cell.lblTackers setFont:[UIFont fontWithName:CABIN_REGULAR size:12.0]];
        [cell.btnNO setTag:indexPath.row];
        [cell.btnYES setTag:indexPath.row];

        [cell.btnNO addTarget:self action:@selector(btnNOAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnYES addTarget:self action:@selector(btnYESAction:) forControlEvents:UIControlEventTouchUpInside];
        if([[dictData valueForKey:@"TotalTakers"]integerValue]>1)
            [cell.lblTackers setText:[NSString stringWithFormat:@"%@ Takers",[dictData valueForKey:@"TotalTakers"]]];
        else
            [cell.lblTackers setText:[NSString stringWithFormat:@"%@ Taker",[dictData valueForKey:@"TotalTakers"]]];

        [cell.lblQuestion setDelegate:self];
        [cell.lblQuestion setText:[dictQuestion objectForKey:@"text"]];
        cell.lblQuestion.lineSpacing = 0.0;
        
        return cell;
    }
    
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dictData ;
    if(isSearching)
        dictData = [[NSMutableDictionary alloc] initWithDictionary:[arBuffer objectAtIndex:indexPath.row]];
    else
        dictData = [[NSMutableDictionary alloc] initWithDictionary:[self.questionArray objectAtIndex:indexPath.row]];
    if([[dictData valueForKey:@"Answered"] integerValue])
    {
        CommentViewController *commentViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:[NSBundle mainBundle]];
        commentViewController.dictQuestionDetail = dictData;
        appDelegate.strActiveQuestionID = [dictData valueForKey:@"question_id"];
        [self.navigationController pushViewController:commentViewController animated:YES];
    }
}

#pragma mark - RTLable delegate
- (void)rtLabel:(id)rtLabel didSelectLinkWithKeyWord:(NSString*)keyword
{
//    if(!self.isQtagPressed)
//        return;
    [searchView removeFromSuperview];
    [txtSearch becomeFirstResponder];
    self.isQtagPressed = YES;
    isSearching = YES;
    searchView.frame = CGRectMake(0, 43, 276, 44);
    [self.view addSubview:searchView];
    
    keyword  = [keyword stringByReplacingOccurrencesOfString:@"," withString:@""];
    keyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(![keyword length])
        return;
    txtSearch.text = keyword;
    NSLog(@"%@",keyword);
    [txtSearch becomeFirstResponder];
    [self setTableWithPosition:txtSearch];
}
#pragma mark - Search Methods
-(void)setTableWithPosition: (UITextField *)textField{
    isSearching = YES;
    [arBuffer removeAllObjects];
    
    for (int i=0; i<[self.questionArray count]; i++) {
		NSDictionary *dict = [self.questionArray objectAtIndex:i];
		BOOL result = NO;
        NSString *strSearch = [txtSearch.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([strSearch length])
        {
            result = [[[dict objectForKey:@"keyword"]capitalizedString] hasPrefix: [strSearch capitalizedString]];
//            if([[[dict objectForKey:@"keyword"]capitalizedString] rangeOfString:[strSearch capitalizedString]].location != NSNotFound)
//            {
//                if (![arBuffer containsObject:dict]) {
//                    [arBuffer addObject:dict];
//                }
//            }
            NSArray *arrSearch = [strSearch componentsSeparatedByString:@","];
            for(NSString *strTag in arrSearch)
            {
                NSString *strTagTemp = [strTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                if([[[dict objectForKey:@"keyword"]capitalizedString] rangeOfString:[strTagTemp capitalizedString]].location != NSNotFound)
                {
                    if (![arBuffer containsObject:dict]) {
                        [arBuffer addObject:dict];
                    }
                }
            }
        }
        else
        {
            [arBuffer addObject:dict];
        }
	}
    [tblLocalFeed reloadData];
}
#pragma mark - UITextField Delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [txtSearch resignFirstResponder];
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(setTableWithPosition:)
                                                 name: UITextFieldTextDidChangeNotification object:textField];
    
}


-(void)goToMergeView:(NSNotification*)notification
{
    [self.tabBarController setSelectedIndex:0];
    NSDictionary *dictData = [[notification userInfo] objectForKey:kQuestionData];
    NSArray *arrViewController = [self.tabBarController.navigationController viewControllers];
    for(UIViewController *viewcontroller in arrViewController)
    {
        if([viewcontroller isKindOfClass:[MainTabbarController class]])
        {
            MainTabbarController *mainTabCtrl = (MainTabbarController*)viewcontroller;
            [mainTabCtrl.tabImageView setImage:[UIImage imageNamed:@"mainbar_0"]];
            break;
        }
    }
//    NSLog(@"%@",[[notification userInfo] objectForKey:kQuestionData]);
    arrViewController = [self.navigationController viewControllers];
    for(UIViewController *viewcontroller in arrViewController)
    {
        if([viewcontroller isKindOfClass:[CommentViewController class]])
        {
            [self.navigationController popToRootViewControllerAnimated:NO];
            break;
        }
    }
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:[NSBundle mainBundle]];
    commentViewController.dictQuestionDetail = dictData;
    appDelegate.strActiveQuestionID = [dictData valueForKey:@"question_id"];
    [self.navigationController pushViewController:commentViewController animated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
