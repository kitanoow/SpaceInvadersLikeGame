//
//  MyScene.m
//  SpaceInvadersLikeGame
//
//  Created by kitano on 2014/01/22.
//  Copyright (c) 2014年 kitano. All rights reserved.
//

#import "MyScene.h"

enum
{
    kDragNone,  //初期値
    kDragStart, //Drag開始
    kDragEnd,   //Drag終了
};
enum {
    kMoveRight = 0,
    kMoveLeft ,
};

#define kEnemyCategoryMask  0x1<<0
#define kPlayerCategoryMask 0x1<<1
#define kWallCategoryMask   0x1<<1 | 0x1<<0

//ミサイル
#define kPlayerContactMask  0x1<<0
#define kEnemyContactMask   0x1<<1

@implementation MyScene
{
    CFTimeInterval lastMoveTime;
    CFTimeInterval lastAttackTime;
    int status;
    int playerstatus;
    NSMutableArray *attackEnemyList;
    SKSpriteNode *player;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        attackEnemyList = [[NSMutableArray alloc] init];
        
        for(int i=0;i<4;i++) {
            [self setUpWall:30 + i*70];
        }
        [self setUpPlayer];
        [self setUpEnemy];
        
        self.physicsWorld.contactDelegate = self;

    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        SKNode *node = [self nodeAtPoint:location];
        if(node != nil && [node.name isEqualToString:@"player"]) {
            playerstatus = kDragStart;
            break;
        }
        [self attack:CGPointMake(player.position.x, player.position.y + 10)
             bitMask:kPlayerContactMask
            moveToPoint:CGPointMake(player.position.x,  player.position.y + 10 + self.frame.size.height)
         attackColor:[SKColor blueColor]
         ];
    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(playerstatus == kDragStart ){
        UITouch *touch = [touches anyObject];
        CGPoint touchPos = [touch locationInNode:self];
        player.position = CGPointMake(touchPos.x, player.position.y);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(playerstatus == kDragStart ){
        playerstatus = kDragEnd;
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if(contact.bodyA.node.physicsBody.categoryBitMask == kEnemyCategoryMask) {
        [attackEnemyList removeObject:contact.bodyA.node];
    } else if(contact.bodyB.node.physicsBody.categoryBitMask == kEnemyCategoryMask) {
        [attackEnemyList removeObject:contact.bodyB.node];
    }
    [contact.bodyA.node removeFromParent];
    [contact.bodyB.node removeFromParent];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    [self checkMoveStatus];
    [self moveEnemy:currentTime];
    [self attackFromEnemy:currentTime];
}


-(void)checkMoveStatus
{
    [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.x > 300 && status == kMoveRight) {
            status = kMoveLeft;
            [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
                node.position = CGPointMake(node.position.x, node.position.y-10);
            }];
        } else if(node.position.x < 30 && status == kMoveLeft) {
            status = kMoveRight;
            [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
                node.position = CGPointMake(node.position.x, node.position.y-10);
            }];
        }
     }];
}

-(void)moveEnemy:(CFTimeInterval)currentTime
{
    if(lastMoveTime + 1.5 >= currentTime) return;
    [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
        if(status == kMoveRight) {
            node.position = CGPointMake(node.position.x+10, node.position.y);
        } else {
            node.position = CGPointMake(node.position.x-10, node.position.y);
        }
        
    }];
    lastMoveTime = currentTime;
}


-(void)attackFromEnemy:(CFTimeInterval)currentTime
{
    if(lastAttackTime + 1.0 >= currentTime) return;
    NSUInteger enemyIndex = arc4random_uniform([attackEnemyList count]);
    SKNode* enemy = attackEnemyList[enemyIndex];
    CGPoint location = enemy.position;
    CGPoint moveToPoint = CGPointMake(location.x, location.y - self.frame.size.height );
    [self attack:location bitMask:kEnemyContactMask moveToPoint:moveToPoint attackColor:[SKColor redColor]];
    lastAttackTime = currentTime;
}

-(void)attack:(CGPoint)location bitMask:(uint32_t)bitMask moveToPoint:(CGPoint)moveToPoint attackColor:(SKColor*)attackColor
{
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithColor:attackColor size:CGSizeMake(5,5)];
    sprite.position = location;
    sprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:sprite.size];
    sprite.physicsBody.dynamic = YES;
    sprite.physicsBody.contactTestBitMask = bitMask;
    SKAction* bulletAction = [SKAction sequence:@[[SKAction moveTo:moveToPoint duration:1.0],
                                                  [SKAction removeFromParent]]];
    [sprite runAction:bulletAction];
    [self addChild:sprite];
    
    
}

-(void)setUpEnemy
{
    
    for(int i=0;i<5;i++) {
        for(int j=0;j<5;j++) {
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
            sprite.size = CGSizeMake(30,21);
            sprite.position =CGPointMake(50+ j*35, 300 + i*25);
            sprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:sprite.size];
            sprite.physicsBody.categoryBitMask = kEnemyCategoryMask;
            sprite.physicsBody.dynamic = NO;
            sprite.name = @"enemy";
            [self addChild:sprite];
            [attackEnemyList addObject:sprite];
        }
    }
}

-(void) setUpPlayer{
    player = [SKSpriteNode spriteNodeWithColor:[SKColor blueColor] size:CGSizeMake(30,10)];
    player.position =CGPointMake(160, 20);
    player.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:player.size];
    player.physicsBody.categoryBitMask = kPlayerCategoryMask;
    player.physicsBody.dynamic = NO;
    player.name = @"player";
    [self addChild:player];
}


-(void) setUpWall:(int)pos_x
{
    for(int i=0;i<10;i++) {
        int start_j = 0;
        int end_j = 10;
        if( i == 0 || i == 9 ) { start_j = 2;end_j = 7;}
        if( i == 1 || i == 8 ) { start_j = 2;end_j = 8;}
        if( i == 2 || i == 7 ) { start_j = 2;end_j = 9;}
        if( i == 3 || i == 6 ) { start_j = 4;end_j = 10;}
        if( i == 4 || i == 5 ) { start_j = 5;end_j = 10;}
        for(int j=start_j;j<end_j;j++) {
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithColor:[SKColor grayColor] size:CGSizeMake(5,5)];
            sprite.position =CGPointMake(pos_x+i*5, 50 + j*5);
            sprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:sprite.size];
            sprite.physicsBody.categoryBitMask =  kWallCategoryMask;
            sprite.physicsBody.dynamic = NO;
            [self addChild:sprite];
        }
    }
    
}

@end
