//
//  TopQuestionsViewController.m
//  Yoke
//
//  Created by Abhijit on 6/17/13.
//  Copyright (c) 2013 Abhijit. All rights reserved.
//

#import "TopQuestionsViewController.h"
#import "QuestinViewCell.h"

@interface TopQuestionsViewController ()

@end

@implementation TopQuestionsViewController
@synthesize questionArray,answeredIndex,strAnswered;
@synthesize dictQuestionDetail;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList) name:KQUESTIONPOSTEDNOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList) name:KMERGEUPDATEDNOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList) name:KQUESTIONANSWEREDNOTIFICATION object:nil];
    }
    return self;
}
#pragma mark -  View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    arrQtags = [[NSMutableArray alloc] init];
    arBuffer = [[NSMutableArray alloc] init];
    questionArray = [[NSMutableArray alloc] init];
    appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [lblTopQs setFont:[UIFont fontWithName:CABIN_BOLD size:22.0]];
    [lblHideQuestion setFont:[UIFont fontWithName:CABIN_REGULAR size:11.0]];
    [lblTrending setFont:[UIFont fontWithName:CABIN_BOLD size:22.0]];
    lblTrending.text = @"Qtags";
    currentPage = 0;
    if([appDelegate isNetWorkAvailable])
        [self callQuestionListService];
    else
        [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[NSLocale currentLocale]];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setUsesSignificantDigits:NO];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setMinimumFractionDigits:0];
    [numberFormatter setGroupingSeparator:@""];
    fontSize = 14;
    // Do any additional setup after loading the view from its nib.
}
#pragma mark - Custom Methods
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
    
    [tblTopQuestion reloadRowsAtIndexPaths:arrRecord withRowAnimation:UITableViewRowAnimationNone];
    
}

-(void)reloadTable:(NSArray*)arrRecord
{
    [tblTopQuestion reloadRowsAtIndexPaths:arrRecord withRowAnimation:UITableViewRowAnimationNone];
    [self performSelector:@selector(reloadTableWithScore:) withObject:arrRecord afterDelay:0.7];
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
-(void)updateList
{
    if([appDelegate isNetWorkAvailable])
        [self callQuestionListService];
}
#pragma mark - Webservice Methods
-(void)callQuestionListService
{
    currentPage +=1;
    //    NSString *strPageNumber = [NSString stringWithFormat:@"%d",currentPage];
    webserviceType = TOPQUESTIONLIST;
    if(service)
        service = nil;
    [self showActivity];
    service = [[WebService alloc] init];
    service.webserviceDelegate = self;
    NSString *strUserID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:strUserID,@"UserId",nil];
    [service jsonRESTWebServiceMethod:@"TopQuestionList" WithParameter:dict];
}
-(void)callSubmitAnswerService:(NSString*)questionID answer:(NSString*)ansYesNo
{
    webserviceType = TOPSUBMITANS;
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
    if(webserviceType==TOPQUESTIONLIST)
    {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            dict=(NSMutableDictionary *)obj;
        }
        if (dict) {
            if([[dict objectForKey:@"status"] isEqualToString:@"TopQuestionList_1"])
            {
                [self.questionArray removeAllObjects];
                [arrQtags removeAllObjects];
                totalPage = [[dict objectForKey:@"TotalNoOfpages"] integerValue];
                for(NSMutableDictionary *dictList in [dict objectForKey:@"QuestionList"])
                {
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] ];

                    NSDate *myDate = [df dateFromString: [dictList objectForKey:@"PostedDate"]];
                    NSDate *modifieddate = [df dateFromString: [dictList objectForKey:@"ModifiedDate"]];

                    [dictList setObject:myDate forKey:@"PostedDate"];
                    [dictList setObject:modifieddate forKey:@"ModifiedDate"];
//                    int index = [self.questionArray count];
                    NSArray *arrKey = [[dictList valueForKey:@"Keyword"] componentsSeparatedByString:@","];
                    for(NSString *strKey in arrKey)
                    {
                        NSString *strKey1 = [strKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if([strKey1 length])
                        {
                            BOOL isAdded = NO;
                            for(NSString *strTag in arrQtags)
                            {
                                if([strTag caseInsensitiveCompare:strKey1]==NSOrderedSame)
                                {
                                    isAdded = YES;
                                    break;
                                }
                            }
                            if(!isAdded)
                                [arrQtags addObject:strKey1];
                        }
                    }
                    [self.questionArray addObject:dictList];
//                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:index inSection:0];
//                    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
//                    [tblTopQuestion insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationAutomatic];
                }
               // self.questionArray = [[dict objectForKey:@"QuestionList"] mutableCopy];
                [tblTopQuestion reloadData];
            }
            else
            {
                [UIAlertView showInfo:[dict objectForKey:@"message"] WithTitle:ALERTNAME Delegate:nil];
            }
        }
        else {
//            [UIAlertView showInfo:@"No data found" WithTitle:ALERTNAME Delegate:self];
        }
        [self hideActivity];
        if(service)
            service = nil;
    }
    else if(webserviceType==TOPSUBMITANS)
    {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            dict=(NSMutableDictionary *)obj;
        }
        if (dict) {
            if([[dict objectForKey:@"status"] isEqualToString:@"SubmitAnswer_1"])
            {
//                NSMutableDictionary *dictData ;//= [[NSMutableDictionary alloc] initWithDictionary:[self.questionArray objectAtIndex:self.answeredIndex]];
//                if(isSearching)
//                    dictData = [[NSMutableDictionary alloc] initWithDictionary:[arBuffer objectAtIndex:self.answeredIndex]];
//                else
//                    dictData = [[NSMutableDictionary alloc] initWithDictionary:[self.questionArray objectAtIndex:self.answeredIndex]];
//                [dictData setValue:@"1" forKey:@"Answer"];
//                [dictData setValue:self.strAnswered forKey:@"UserAnswered"];
//                int total = [[dictData valueForKey:@"TotalTakers"]intValue];
//                total++;
//                [dictData setValue:[NSString stringWithFormat:@"%d",total] forKey:@"TotalTakers"];
//                if([self.strAnswered isEqualToString:@"0"])
//                {
//                    int totalNO = [[dictData valueForKey:@"TotalNo"]intValue];
//                    totalNO++;
//                    [dictData setValue:[NSString stringWithFormat:@"%d",totalNO] forKey:@"TotalNo"];
//                }
//                else
//                {
//                    int totalYES = [[dictData valueForKey:@"TotalYes"]intValue];
//                    totalYES++;
//                    [dictData setValue:[NSString stringWithFormat:@"%d",totalYES] forKey:@"TotalYes"];
//                }
//                if(isSearching)
//                    [arBuffer replaceObjectAtIndex:self.answeredIndex withObject:dictData];
//                else
//                    [self.questionArray replaceObjectAtIndex:self.answeredIndex withObject:dictData];
//                [tblTopQuestion reloadData];
                
                AnsweredQuestion();
             //   [UIAlertView showInfo:[dict objectForKey:@"message"] WithTitle:ALERTNAME Delegate:self];
            }
            else
            {
                [UIAlertView showInfo:[dict objectForKey:@"message"] WithTitle:ALERTNAME Delegate:nil];
            }
        }
        else {
//            [UIAlertView showInfo:@"No data found" WithTitle:ALERTNAME Delegate:self];
        }
        [self hideActivity];
        if(service)
            service = nil;
        
    }
}

#pragma mark - Action Methods
-(IBAction)btnHideAction:(id)sender
{
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"Keyword"
                                                                 ascending:self.isKeywordSort selector:@selector(localizedStandardCompare:)];
    
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
    [tblTopQuestion reloadData];
    if(self.isKeywordSort)
        self.isKeywordSort = NO;
    else
        self.isKeywordSort = YES;
}

-(IBAction)btnClearAction:(id)sender
{
    isSearching = NO;
    txtSearch.text = @"";
    [txtSearch resignFirstResponder];
    [tblTopQuestion reloadData];
}

-(IBAction)btnLogoutAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"IsLoggedIn"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"HideAnsweredQuestion"];
    [self.tabBarController.navigationController popViewControllerAnimated:YES];
}
-(IBAction)btnNOAction:(id)sender
{
    NSDictionary *dictData ;//= [self.questionArray objectAtIndex:[sender tag]];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:[sender tag]];
    else
        dictData = [self.questionArray objectAtIndex:[sender tag]];
    if([[dictData valueForKey:@"Answer"] integerValue])
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
    }
//        [UIAlertView showInfo:@"You have already answered for this question." WithTitle:ALERTNAME Delegate:nil];
    else
    {
        if([appDelegate isNetWorkAvailable])
        {
            [dictData setValue:@"1" forKey:@"Answer"];
            [dictData setValue:@"0" forKey:@"UserAnswered"];
            //        int total = [[dictData valueForKey:@"TotalTakers"]intValue];
            //        total++;
            //        [dictData setValue:[NSString stringWithFormat:@"%d",total] forKey:@"TotalTakers"];
            //            int totalNO = [[dictData valueForKey:@"TotalNo"]intValue];
            //            totalNO++;
            //            [dictData setValue:[NSString stringWithFormat:@"%d",totalNO] forKey:@"TotalNo"];
            if(isSearching)
                [arBuffer replaceObjectAtIndex:[sender tag] withObject:dictData];
            else
                [self.questionArray replaceObjectAtIndex:[sender tag] withObject:dictData];
            
            NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
            NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
            [self performSelector:@selector(reloadTable:) withObject:rowsToReload afterDelay:0.0];
            
            //        [tblTopQuestion reloadData];
            
            self.dictQuestionDetail = dictData;
            
            self.strAnswered = @"0";
            self.answeredIndex = [sender tag];
            [self callSubmitAnswerService:[dictData valueForKey:@"QuestionId"] answer:@"0"];
        }
        else
            [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
    }
    
}
-(IBAction)btnYESAction:(id)sender
{
    NSDictionary *dictData ;//= [self.questionArray objectAtIndex:[sender tag]];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:[sender tag]];
    else
        dictData = [self.questionArray objectAtIndex:[sender tag]];
    if([[dictData valueForKey:@"Answer"] integerValue])
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
    }
//        [UIAlertView showInfo:@"You have already answered for this question." WithTitle:ALERTNAME Delegate:nil];
    else
    {
        if([appDelegate isNetWorkAvailable])
        {
            [dictData setValue:@"1" forKey:@"Answer"];
            [dictData setValue:@"1" forKey:@"UserAnswered"];
            //        int total = [[dictData valueForKey:@"TotalTakers"]intValue];
            //        total++;
            //        [dictData setValue:[NSString stringWithFormat:@"%d",total] forKey:@"TotalTakers"];
            //        int totalYES = [[dictData valueForKey:@"TotalYes"]intValue];
            //        totalYES++;
            //        [dictData setValue:[NSString stringWithFormat:@"%d",totalYES] forKey:@"TotalYes"];
            if(isSearching)
                [arBuffer replaceObjectAtIndex:[sender tag] withObject:dictData];
            else
                [self.questionArray replaceObjectAtIndex:[sender tag] withObject:dictData];
            
            NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
            NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
            [self performSelector:@selector(reloadTable:) withObject:rowsToReload afterDelay:0.0];
            
            //        [tblTopQuestion reloadData];
            
            
            self.dictQuestionDetail = dictData;
            self.strAnswered = @"1";
            self.answeredIndex = [sender tag];
            [self callSubmitAnswerService:[dictData valueForKey:@"QuestionId"] answer:@"1"];
        }
        else
            [UIAlertView showInfo:@"Please check your internet connection." WithTitle:ALERTNAME Delegate:nil];
    }
}
-(IBAction)sortingAction:(id)sender
{
    popOverType = SORTING;
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
-(IBAction)btnTrendingAction:(id)sender
{
    popOverType = TRENDING;
    FPTableController *controller = [[FPTableController alloc] initWithStyle:UITableViewStylePlain];
    controller.isSorting = NO;
    controller.arrList = [NSMutableArray arrayWithObjects:@"Qtags",@"since yesterday",@"by week",@"by month",@"by year", nil];
    controller._delegate = self;
    popover = [[FPPopoverController alloc] initWithViewController:controller];
    
    popover.arrowDirection = FPPopoverArrowDirectionAny;
    popover.tint = FPPopoverDefaultTint;
    popover.contentSize = CGSizeMake(200, 190);
    
    //sender is the UIButton view
    [popover presentPopoverFromView:sender];
}
#pragma mark - Alertview delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==5)
    {
        if(!buttonIndex)
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"dntShowAgain"];
    }
}
#pragma mark - FPPopoverController Delegate

- (void)presentedNewPopoverController:(FPPopoverController *)newPopoverController
          shouldDismissVisiblePopover:(FPPopoverController*)visiblePopoverController
{
    [popover dismissPopoverAnimated:YES];
}

- (void)popoverControllerDidDismissPopover:(NSString*)index{
    if(popOverType==SORTING)
    {
        switch ([index integerValue]) {
            case 0:
            {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HideAnsweredQuestion"];
                NSMutableArray *arrTemp = [[NSMutableArray alloc] init];
                for(NSDictionary *dict in questionArray)
                {
                    if([[dict valueForKey:@"Answer"] integerValue])
                        [arrTemp addObject:dict];
                }
                for(NSDictionary *dict in arrTemp)
                    [questionArray removeObject:dict];
                [tblTopQuestion reloadData];
                break;
            }
            case 1:
            {
                [txtSearch resignFirstResponder];
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
                [tblTopQuestion reloadData];
                if(self.isPostDateSort)
                    self.isPostDateSort = NO;
                else
                    self.isPostDateSort = YES;
                break;
            }
            case 2:
            {
                [txtSearch resignFirstResponder];
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
                [tblTopQuestion reloadData];
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
    }
    else if(popOverType==TRENDING)
    {
        if(![index integerValue])
        {
//            isSearching = NO;
//            txtSearch.text = @"";
//            [txtSearch resignFirstResponder];
//            [tblTopQuestion reloadData];
//            
//            isSearching = YES;
//            [tblTopQuestion reloadData];
            [popover dismissPopoverAnimated:YES];
            popOverType = QTAGS;
            FPTableController *controller = [[FPTableController alloc] initWithStyle:UITableViewStylePlain];
            controller.isSorting = NO;
            controller.isTrending = YES;

            controller.arrList = arrQtags;
            controller._delegate = self;
            popover = [[FPPopoverController alloc] initWithViewController:controller];
            
            popover.arrowDirection = FPPopoverArrowDirectionAny;
            popover.tint = FPPopoverDefaultTint;
            popover.contentSize = CGSizeMake(200, 200);
            
            //sender is the UIButton view
            [popover presentPopoverFromView:lblTrending];
            return;
        }
        isSearching = NO;
        txtSearch.text = @"";
        [txtSearch resignFirstResponder];
        [tblTopQuestion reloadData];
        NSMutableArray *arrTrending  = [[NSMutableArray alloc] init];
        NSDate *todayDate = [NSDate date];
        for(NSDictionary *dict in self.questionArray)
        {
            NSDate *postedDate  = [dict objectForKey:@"ModifiedDate"];
            NSTimeInterval secondsElapsed = [postedDate timeIntervalSinceDate:todayDate];
            switch ([index integerValue]) {
                case LASTONEDAY:
                {
                    lblTrending.text = @"since yesterday";

                    int hours = (abs(secondsElapsed)) / 3600;
                    if (hours >=0 && hours <= 24)
                        [arrTrending addObject:dict];
                    break;
                }
                case LASTWEEK:
                {
                    lblTrending.text = @"by week";
                    int hours = (abs(secondsElapsed)) / 3600;
                    if (hours >=0 && hours <= 168)
                        [arrTrending addObject:dict];
                    break;
                }
                case LASTMONTH:
                {
                    lblTrending.text = @"by month";
                    int hours = (abs(secondsElapsed)) / 3600;
                    if(hours>=0)
                    {
                        int day = hours/24;
                        if (day >=0 && day <= 30)
                            [arrTrending addObject:dict];
                    }

                    break;
                }
                case LASTYEAR:
                {
                    lblTrending.text = @"by year";
                    int hours = (abs(secondsElapsed)) / 3600;
                    if(hours>=0)
                    {
                        int day = hours/24;
                        int month = day/30;
                        if (month >=0 && month <= 12)
                            [arrTrending addObject:dict];
                    }
                    break;
                }
            }

        }
        NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"TotalTakers" ascending:NO comparator:^(id obj1, id obj2) {
            if ([obj1 integerValue] > [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            if ([obj1 integerValue] < [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        isSearching = YES;
        NSArray *sortDescriptors = [NSArray arrayWithObject: sorter];
        NSArray *sortedArray = [arrTrending sortedArrayUsingDescriptors:sortDescriptors];
        arBuffer=[sortedArray mutableCopy];
        [tblTopQuestion reloadData];
    }
    else
    {
        lblTrending.text = @"Qtags";
        txtSearch.text = [arrQtags objectAtIndex:[index integerValue]];
        isSearching = YES;
        [arBuffer removeAllObjects];
        
        for (int i=0; i<[questionArray count]; i++) {
            NSDictionary *dict = [questionArray objectAtIndex:i];
            BOOL result = NO;
            NSString *strSearch = [txtSearch.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if([strSearch length])
            {
                result = [[[dict objectForKey:@"Keyword"]capitalizedString] hasPrefix: [strSearch capitalizedString]];
                if([[[dict objectForKey:@"Keyword"]capitalizedString] rangeOfString:[strSearch capitalizedString]].location != NSNotFound)
                {
                    if (![arBuffer containsObject:dict]) {
                        [arBuffer addObject:dict];
                    }
                }
            }
            else
                [arBuffer addObject:dict];
        }
        [tblTopQuestion reloadData];
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
    NSDictionary *dictData ;//= [self.questionArray objectAtIndex:indexPath.row];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:indexPath.row];
    else
        dictData = [self.questionArray objectAtIndex:indexPath.row];
    NSString *strQuestion = [NSString stringWithFormat:@"%@%@",[dictData valueForKey:@"Question"],[dictData valueForKey:@"Keyword"]];
    if([[dictData valueForKey:@"Answer"] integerValue])
        return 97+[self getHeight:strQuestion]; //return 105+[self getHeight:strQuestion];
    else
        return 59+[self getHeight:strQuestion]; //return 67+[self getHeight:strQuestion];
   
}
#pragma mark -
#pragma mark UITableview Delegate Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *nibname = @"QuestinViewCell";
    NSString *nibname1 = @"AnsweredQuestionViewCell";
    NSString *strHTML;
    QuestinViewCell *cell ;
    AnsweredQuestionVewCell *answeredCell;
    NSDictionary *dictData ;//= [self.questionArray objectAtIndex:indexPath.row];
    if(isSearching)
        dictData = [arBuffer objectAtIndex:indexPath.row];
    else
        dictData = [self.questionArray objectAtIndex:indexPath.row];
    NSString *strQuestion = [NSString stringWithFormat:@"%@%@",[dictData valueForKey:@"Question"],[dictData valueForKey:@"Keyword"]];
    NSMutableDictionary *dictQuestion = [NSMutableDictionary dictionary];
//    NSString *strHTML = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=14 color='#454545'>%@</font> <a href='%@'><font face='Cabin-Regular' size=14 color='#6f0da1'>%@</font></a>",[dictData valueForKey:@"Question"],[dictData valueForKey:@"Keyword"],[dictData valueForKey:@"Keyword"]];
    [self getHeight:strQuestion];
    NSArray *keywordArr = [[dictData valueForKey:@"Keyword"] componentsSeparatedByString:@","];
    if([keywordArr count]>1)
    {
        strHTML = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=%d color='#454545'>%@</font> ",fontSize,[dictData valueForKey:@"Question"]];
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
        strHTML = [NSString stringWithFormat:@"<font face='Cabin-Regular' size=%d color='#454545'>%@</font> <a href='%@'><font face='Cabin-Regular' size=%d color='#6f0da1'>%@</font></a>",fontSize,[dictData valueForKey:@"Question"],[dictData valueForKey:@"Keyword"],fontSize,[dictData valueForKey:@"Keyword"]];
    
    [dictQuestion setObject:strHTML forKey:@"text"];
    if([[dictData valueForKey:@"Answer"] integerValue])
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
        
        NSString *strNO = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:noValue]];
        NSString *strYes = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:yesValue]];
        NSRange range = [strNO rangeOfString:@"."];
        NSString *strNOValue;
        
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
        [answeredCell.lblQuestion setText:[dictQuestion objectForKey:@"text"]];
        answeredCell.lblQuestion.lineSpacing = 0.0;
        answeredCell.lblQuestion.delegate = self;
        
//        if(!isSearching)
//        {
//            if (indexPath.row == self.questionArray.count-2) {
//                if (currentPage < totalPage) {
//                    [self callQuestionListService];
//                }
//            }
//        }
        return answeredCell;
    }
    else
    {
        cell = [QuestinViewCell dequeOrCreateInTable:tableView withNibName:nibname];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [cell.viewQuestion setFrame:CGRectMake(47, 0, 226, 58+[self getHeight:strQuestion])];
        [cell.lblQuestion setFrame:CGRectMake(0, 5, 226, ([self getHeight:strQuestion]+8))];
        
        [cell.lblTackers setFont:[UIFont fontWithName:CABIN_REGULAR size:12.0]];
        [cell.btnNO setTag:indexPath.row];
        [cell.btnYES setTag:indexPath.row];
        
        [cell.btnNO addTarget:self action:@selector(btnNOAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnYES addTarget:self action:@selector(btnYESAction:) forControlEvents:UIControlEventTouchUpInside];
        if([[dictData valueForKey:@"TotalTakers"]integerValue]>1)
            [cell.lblTackers setText:[NSString stringWithFormat:@"%@ Takers",[dictData valueForKey:@"TotalTakers"]]];
        else
            [cell.lblTackers setText:[NSString stringWithFormat:@"%@ Taker",[dictData valueForKey:@"TotalTakers"]]];
        
        [cell.lblQuestion setText:[dictQuestion objectForKey:@"text"]];
        cell.lblQuestion.lineSpacing = 0.0;
        cell.lblQuestion.delegate = self;
//        if(!isSearching)
//        {
//            if (indexPath.row == self.questionArray.count-2) {
//                if (currentPage < totalPage) {
//                    [self callQuestionListService];
//                }
//            }
//        }
        return cell;
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dictData ;//= [[NSMutableDictionary alloc] initWithDictionary:[self.questionArray objectAtIndex:indexPath.row]];
    if(isSearching)
        dictData = [[NSMutableDictionary alloc] initWithDictionary:[arBuffer objectAtIndex:indexPath.row]];
    else
        dictData = [[NSMutableDictionary alloc] initWithDictionary:[self.questionArray objectAtIndex:indexPath.row]];
    
    if([[dictData valueForKey:@"Answer"] integerValue])
    {
        [dictData setValue:[dictData valueForKey:@"Answer"] forKey:@"Answered"];
        [dictData setValue:[dictData valueForKey:@"Keyword"] forKey:@"keyword"];
        [dictData setValue:[dictData valueForKey:@"Question"] forKey:@"question"];
        [dictData setValue:[dictData valueForKey:@"QuestionId"] forKey:@"question_id"];
//        [dictData setValue:[dictData valueForKey:@"TotalTakers"] forKey:@"totalTakers"];
        ClickedFromLog(dictData);
    }
}
#pragma mark - RTLable delegate
- (void)rtLabel:(id)rtLabel didSelectLinkWithKeyWord:(NSString*)keyword
{
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
    
    for (int i=0; i<[questionArray count]; i++) {
		NSDictionary *dict = [questionArray objectAtIndex:i];
		BOOL result = NO;
        NSString *strSearch = [txtSearch.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([strSearch length])
        {
            result = [[[dict objectForKey:@"Keyword"]capitalizedString] hasPrefix: [strSearch capitalizedString]];
            
            NSArray *arrSearch = [strSearch componentsSeparatedByString:@","];
            for(NSString *strTag in arrSearch)
            {
                NSString *strTagTemp = [strTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                if([[[dict objectForKey:@"Keyword"]capitalizedString] rangeOfString:[strTagTemp capitalizedString]].location != NSNotFound)
                {
                    if (![arBuffer containsObject:dict]) {
                        [arBuffer addObject:dict];
                    }
                }
            }
            
//            if([[[dict objectForKey:@"Keyword"]capitalizedString] rangeOfString:[strSearch capitalizedString]].location != NSNotFound)
//            {
//                if (![arBuffer containsObject:dict]) {
//                    [arBuffer addObject:dict];
//                }
//            }
        }
        else
            [arBuffer addObject:dict];
	}
    [tblTopQuestion reloadData];
}

#pragma mark - UITextField Delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [txtSearch resignFirstResponder];
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    isSearching = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(setTableWithPosition:)
                                                 name: UITextFieldTextDidChangeNotification object:textField];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
