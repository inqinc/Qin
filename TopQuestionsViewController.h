//
//  TopQuestionsViewController.h
//  Yoke
//
//  Created by Abhijit on 6/17/13.
//  Copyright (c) 2013 Abhijit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPopoverController.h"
#import "FPTableController.h"
#import "AppDelegate.h"

enum TOPWEBSERVICE_TYPE
{
    TOPQUESTIONLIST = 1,
    TOPSUBMITANS = 2
};
enum POPOVER_TYPE
{
    SORTING = 1,
    TRENDING = 2,
    QTAGS = 3
};
enum TRENDING_TYPE
{
    LASTONEDAY = 1,
    LASTWEEK = 2,
    LASTMONTH = 3,
    LASTYEAR = 4
};
@interface TopQuestionsViewController : UIViewController<UISearchBarDelegate,FPPopoverControllerDelegate, FPTableControllerDelegate,WebserviceDelegate,RTLabelDelegate>
{
    NSMutableArray *questionArray;
    IBOutlet UILabel *lblTopQs;
    IBOutlet UILabel *lblHideQuestion;
    IBOutlet UITableView *tblTopQuestion;
    FPPopoverController *popover;
    
    id HUD;
	WebService *service;
    AppDelegate *appDelegate;
    int webserviceType;
    int currentPage;
    int totalPage;
    NSNumberFormatter *numberFormatter;
    IBOutlet UITextField *txtSearch;
    BOOL isSearching;
    NSMutableArray *arBuffer;
    NSInteger fontSize;
    NSInteger popOverType;
    IBOutlet UILabel *lblTrending;
    NSMutableArray *arrQtags;
}
@property (nonatomic,retain) NSDictionary *dictQuestionDetail;
@property (nonatomic,assign) NSInteger answeredIndex;
@property (nonatomic,assign) NSString *strAnswered;
@property (nonatomic,retain) NSMutableArray *questionArray;
@property (nonatomic,assign) BOOL isKeywordSort,isPostDateSort,isTakerSort;

-(void)showActivity;
-(void)hideActivity;
-(void)callQuestionListService;
-(void)callSubmitAnswerService:(NSString*)questionID answer:(NSString*)ansYesNo;

-(IBAction)btnNOAction:(id)sender;
-(IBAction)btnYESAction:(id)sender;
-(IBAction)sortingAction:(id)sender;
-(IBAction)btnLogoutAction:(id)sender;
-(IBAction)btnClearAction:(id)sender;
-(IBAction)btnHideAction:(id)sender;
-(IBAction)btnTrendingAction:(id)sender;
@end
