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

@property (nonatomic, strong) UIDynamicAnimator* animator;
@property (nonatomic, weak) UICollisionBehavior * collider;
@property (nonatomic, weak) UIGravityBehavior * gravity;
@property (nonatomic, weak) UIDynamicItemBehavior * elastic;
@property (nonatomic, strong) CMMotionManager * motionManager;
@end
@implementation BouncerViewController

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startGame];
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
-(void) startGame
{
    self.redBlock = [self addBlockOffsetFromCenterBy:UIOffsetMake(0, 0)];
    self.redBlock.backgroundColor = [UIColor redColor];
    [self.collider addItem:self.redBlock ];
    [self.elastic addItem:self.redBlock ];
    [self.gravity addItem:self.redBlock ];
    
    if ([self.motionManager isAccelerometerAvailable]) {
        if([self.motionManager isAccelerometerActive]){
            
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

#define UPDATES_PER_SECOND 10
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
    }
    return _elastic;
}




@end
