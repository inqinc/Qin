//
//  LocalFeedViewController.h
//  Yoke
//
//  Created by Abhijit on 6/17/13.
//  Copyright (c) 2013 Abhijit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPopoverController.h"
#import "FPTableController.h"
#import "AppDelegate.h"
enum WEBSERVICE_TYPE
{
    QUESTIONLIST = 1,
    SUBMITANS = 2
};

@interface LocalFeedViewController : UIViewController<UITableViewDataSource,FPPopoverControllerDelegate, FPTableControllerDelegate,WebserviceDelegate,RTLabelDelegate>
{
    FPPopoverController *popover;
    IBOutlet UILabel *lblLocalFeed;
    IBOutlet UILabel *lblPostQuestion;
    IBOutlet UILabel *lblHideQuestion;
    IBOutlet UITableView *tblLocalFeed;
    id HUD;
	WebService *service;
    AppDelegate *appDelegate;
    int webserviceType;
    NSMutableArray *questionArray;
    NSNumberFormatter *numberFormatter;
    NSInteger fontSize;
    IBOutlet UIView *searchView;
    IBOutlet UITextField *txtSearch;
    NSMutableArray *arBuffer;
    BOOL isSearching;
}
@property (nonatomic,retain) NSDictionary *dictQuestionDetail;
@property(nonatomic,retain) NSMutableArray *questionArray;
@property (nonatomic,assign) BOOL isQtagPressed;
@property (nonatomic,assign) NSInteger answeredIndex;
@property (nonatomic,assign) NSString *strAnswered;
@property (nonatomic,assign) BOOL isKeywordSort,isPostDateSort,isTakerSort;
-(void)showActivity;
-(void)hideActivity;
-(void)callQuestionListService;
-(void)callSubmitAnswerService:(NSString*)questionID answer:(NSString*)ansYesNo;

-(IBAction)btnPostAction:(id)sender;
-(IBAction)sortingAction:(id)sender;
-(IBAction)btnNOAction:(id)sender;
-(IBAction)btnYESAction:(id)sender;
-(IBAction)btnLogoutAction:(id)sender;
-(IBAction)btnHideAction:(id)sender;
-(IBAction)btnClearAction:(id)sender;
@end
