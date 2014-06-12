//
//  BouncerViewController.m
//  Bouncer
//
//  Created by Kevin on 12/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "BouncerViewController.h"
#import <CoreMotion/CoreMotion.h>
@interface BouncerViewController ()
@property (nonatomic, strong)UIView * redBlock;
@property (nonatomic, strong)UIView * blackBlock;

// The following is strong because anything don't have
@property (nonatomic, strong) UIDynamicAnimator* animator;

//These are weak because the animator have strong pointers to them
@property (nonatomic, weak) UICollisionBehavior * collider;
@property (nonatomic, weak) UIGravityBehavior * gravity;
@property (nonatomic, weak) UIDynamicItemBehavior * elastic;
@property (nonatomic, strong) CMMotionManager * motionManager;
//score
@property (nonatomic, weak) UILabel * scoreLabel;
@property (nonatomic)double lastScore;
@property (nonatomic)double maxScore;
@property (nonatomic) double blackBlockDistanceTravelled;
@property (nonatomic , strong) NSDate * lastRecordBlackBlockTravelling;
@property (nonatomic) double cumulativeBlackBlockTravelTime;
@property (nonatomic, weak) UIDynamicItemBehavior* blackBlockTracker;
@property (nonatomic, weak) UICollisionBehavior * scoreBoundary;
@property (nonatomic) CGPoint scoreBoundaryCenter;
@property (nonatomic, weak) UIDynamicItemBehavior * quicksand; // slow down the business man XD

@end
@implementation BouncerViewController

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self resumeGame];
}
-(void) viewDidLoad
{
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * note){
                                                      [self pauseGame];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * note){
                                                      [self resumeGame];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * note){
                                                      [self resetElasticity];
                                                  }];
    
    
    
}

-(void) viewWillDisappear:(BOOL)animated
{
    [self viewWillDisappear:animated];
    [self resumeGame];
}

-(BOOL) isPaused
{
    return !self.motionManager.isAccelerometerActive;
}
-(void)tap{
    if ([self isPaused]) {
        [self resumeGame];
    } else{
        [self pauseGame];
    }
}

static CGSize SQUARE_DIMENSIONS  = {40,40};

-(UIView *)addBlockOffsetFromCenterBy: (UIOffset )offset{
    // Designing the red block
    
    CGPoint blockCenter = CGPointMake(CGRectGetMidX(self.view.bounds) + offset.horizontal, CGRectGetMidY(self.view.bounds) + offset.vertical);
        CGRect square = CGRectMake(blockCenter.x-SQUARE_DIMENSIONS.width/2, blockCenter.y-SQUARE_DIMENSIONS.height/2, SQUARE_DIMENSIONS.width, SQUARE_DIMENSIONS.height);
        UIView * squareView = [[UIView alloc] initWithFrame:square];

    // Put the red Block on screen

    [self.view addSubview:squareView];

    
    
    return squareView;
}

-(void) pauseGame
{
    [self.motionManager stopAccelerometerUpdates ];
    [self pauseScoring];
    self.gravity.gravityDirection = CGVectorMake(0, 0);  // at start we have no gravity going on
    self.quicksand.resistance = 10.0;

    



}

-(void) resumeGame
{
    self.quicksand.resistance = 0;

    if (! self.redBlock)
    {

        self.redBlock = [self addBlockOffsetFromCenterBy:UIOffsetMake(-100, 0)];
        self.redBlock.backgroundColor = [UIColor redColor];
        self.blackBlock = [self addBlockOffsetFromCenterBy:UIOffsetMake(+100, 0)];
        self.blackBlock.backgroundColor = [UIColor blackColor];
        
        [self.collider addItem:self.redBlock ];
        [self.elastic addItem:self.redBlock ];
        [self.gravity addItem:self.redBlock ];
        [self.quicksand addItem:self.redBlock];
        [self.quicksand addItem:self.blackBlock];
        
        [self.collider addItem:self.blackBlock ];
        //[self.elastic addItem:self.blackBlock ];
        //[self.gravity addItem:self.blackBlock ];
    }
    
    self.gravity.gravityDirection = CGVectorMake(0, 0);  // at start we have no gravity going on
    if ([self.motionManager isAccelerometerAvailable]) {
        if(!self.motionManager.isAccelerometerActive){
            
            [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                CGFloat x = accelerometerData.acceleration.x;
                CGFloat y = accelerometerData.acceleration.y;
                switch (self.interfaceOrientation) {
                    case UIInterfaceOrientationLandscapeRight:
                        self.gravity.gravityDirection = CGVectorMake(-y, -x);

                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        self.gravity.gravityDirection = CGVectorMake(y, x);
                        
                        break;
                    case UIInterfaceOrientationPortrait:
                        self.gravity.gravityDirection = CGVectorMake(x, -y);
                        
                        break;

                    case UIInterfaceOrientationPortraitUpsideDown:
                        self.gravity.gravityDirection = CGVectorMake(-x, y);
                        
                        break;

                }
                [self updateScore];

            }];
        }
    }else
    {
        [self alert:@"Your device doesn't have accelerometer"];
    }
    
}



-(void)alert:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:@"Erreur"
                                message:msg
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil
      , nil] show];
}
#pragma  mark - Animation
- (UIDynamicAnimator *)animator
{
    if (!_animator){
        UIDynamicAnimator * animator = [[UIDynamicAnimator alloc]initWithReferenceView:self.view ];
        self.animator = animator;
    }
    
    return  _animator;
}

#define UPDATES_PER_SECOND 100
-(CMMotionManager *) motionManager
{
    if (!_motionManager)
    {
        CMMotionManager * motionManager = [[CMMotionManager alloc] init];
        motionManager.accelerometerUpdateInterval = 1/UPDATES_PER_SECOND;
        _motionManager = motionManager;
    }
    return _motionManager;
}


// We'll need to custom that (with the real gravity with Core Motion)
-(UIGravityBehavior *)gravity{
    if (!_gravity) {
        UIGravityBehavior * gravity = [[UIGravityBehavior alloc] init];
        [self.animator addBehavior:gravity];
        self.gravity = gravity;
    }
    return _gravity;
    
    
}
- (UICollisionBehavior *)collider{
    if (!_collider)
    {
        UICollisionBehavior * collider = [[UICollisionBehavior alloc ]  init];
        collider.translatesReferenceBoundsIntoBoundary = YES;
        [self.animator addBehavior:collider];
        self.collider = collider ;
    }
    return _collider;
}

- (UIDynamicItemBehavior *) elastic
{
    if (!_elastic)
    {
        UIDynamicItemBehavior * elastic  = [[UIDynamicItemBehavior alloc] init];
        elastic.elasticity = 1.0;
        [self.animator addBehavior:elastic];
        self.elastic  = elastic;
        [self resetElasticity];
    }
    return _elastic;
}
-(UIDynamicItemBehavior *) quicksand {
    if (!_quicksand) {
        UIDynamicItemBehavior * quicksand = [[UIDynamicItemBehavior alloc] init];
        quicksand.resistance = 0;
        [self.animator addBehavior:quicksand];
        self.quicksand = quicksand;
    }
    
    return _quicksand ;
}

-(void) resetElasticity
{
    
    NSNumber *elasticity  = [[NSUserDefaults standardUserDefaults] valueForKey:@"Settings_elasticity"];
    if (elasticity) {
        self.elastic.elasticity = [elasticity floatValue];
    }else{
        self.elastic.elasticity = 1.0;
    }
    
}
#pragma mark - Scorekeeping

- (void)updateScore
{
    if (self.lastRecordBlackBlockTravelling) {
        self.cumulativeBlackBlockTravelTime -= [self.lastRecordBlackBlockTravelling timeIntervalSinceNow];
        double score = self.blackBlockDistanceTravelled / self.cumulativeBlackBlockTravelTime;
        if (score > self.maxScore) self.maxScore = score;
        if ((score != self.lastScore) || ![self.scoreLabel.text length]) {
            self.scoreLabel.textColor = [UIColor blackColor];
            self.scoreLabel.text = [NSString stringWithFormat:@"%.0f\n%.0f", score, self.maxScore];
            [self updateScoreBoundary];
        } else if (!CGPointEqualToPoint(self.scoreLabel.center, self.scoreBoundaryCenter)) {
            [self updateScoreBoundary];
        }
    } else {
        [self.animator addBehavior:self.blackBlockTracker];
        self.scoreLabel.text = nil;
    }
    self.lastRecordBlackBlockTravelling = [NSDate date];
}

- (void)pauseScoring
{
    self.lastRecordBlackBlockTravelling = nil;
    self.scoreLabel.text = @"Paused";
    self.scoreLabel.textColor = [UIColor lightGrayColor];
    [self.animator removeBehavior:self.blackBlockTracker];
}

- (void)resetScore
{
    self.blackBlockDistanceTravelled = 0;
    self.lastRecordBlackBlockTravelling = nil;
    self.cumulativeBlackBlockTravelTime = 0;
    self.maxScore = 0;
    self.lastScore = 0;
    self.scoreLabel.text = @"";
}

- (UILabel *)scoreLabel
{
    if (!_scoreLabel) {
        UILabel *scoreLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
        scoreLabel.font = [scoreLabel.font fontWithSize:64];
        scoreLabel.textAlignment = NSTextAlignmentCenter;
        scoreLabel.numberOfLines = 2;
        scoreLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [self.view insertSubview:scoreLabel atIndex:0];
        _scoreLabel = scoreLabel;
    }
    return _scoreLabel;
}

- (void)updateScoreBoundary
{
    CGSize scoreSize = [self.scoreLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.scoreLabel.font}];
    self.scoreBoundaryCenter = self.scoreLabel.center;
    CGRect scoreRect = CGRectMake(self.scoreBoundaryCenter.x-scoreSize.width/2,
                                  self.scoreBoundaryCenter.y-scoreSize.height/2,
                                  scoreSize.width,
                                  scoreSize.height);
    [self.scoreBoundary removeBoundaryWithIdentifier:@"Score"];
    [self.scoreBoundary addBoundaryWithIdentifier:@"Score"
                                          forPath:[UIBezierPath bezierPathWithRect:scoreRect]];
}

- (UICollisionBehavior *)scoreBoundary
{
    if (!_scoreBoundary) {
        UICollisionBehavior *scoreBoundary = [[UICollisionBehavior alloc] initWithItems:@[self.redBlock, self.blackBlock]];
        [self.animator addBehavior:scoreBoundary];
        _scoreBoundary = scoreBoundary;
    }
    return _scoreBoundary;
}

- (UIDynamicBehavior *)blackBlockTracker
{
    if (!_blackBlockTracker) {
        UIDynamicItemBehavior *blackBlockTracker = [[UIDynamicItemBehavior alloc] initWithItems:@[self.blackBlock]];
        [self.animator addBehavior:blackBlockTracker];
        __weak BouncerViewController *weakSelf = self;
        __block CGPoint lastKnownBlackBlockCenter = self.blackBlock.center;
        blackBlockTracker.action = ^{
            CGFloat dx = weakSelf.blackBlock.center.x - lastKnownBlackBlockCenter.x;
            CGFloat dy = weakSelf.blackBlock.center.y - lastKnownBlackBlockCenter.y;
            weakSelf.blackBlockDistanceTravelled += sqrt(dx*dx+dy*dy);
            lastKnownBlackBlockCenter = weakSelf.blackBlock.center;
        };
        _blackBlockTracker = blackBlockTracker;
    }
    return _blackBlockTracker;
}


@end
