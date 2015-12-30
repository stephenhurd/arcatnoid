//
//  GameScene.m
//  Arcatnoid
//
//  Created by Stephen Hurd on 4/21/15.
//  Copyright (c) 2015 Stephen Hurd. All rights reserved.
// 

#import "GameScene.h"
#import "GameOverScene.h"

// Object category names
static NSString* ballCategoryName = @"ball";
static NSString* paddleCategoryName = @"paddle";
static NSString* blockCategoryName = @"block";
static NSString* blockNodeCategoryName = @"blockNode";
static NSString* powerLaserCategoryName = @"powerLaser";
static NSString* laserBeamCategoryName = @"laserBeam";


// Collision type bitmasks

static const uint32_t ballCategory  = 0x1 << 0;
static const uint32_t bottomCategory = 0x1 << 1;
static const uint32_t paddleCategory = 0x1 << 2;
static const uint32_t blockCategory = 0x1 << 3;
static const uint32_t laserBeamCategory = 0x1 << 4;
static const uint32_t topCategory = 0x1 << 5;
static const uint32_t powerLaserCategory = 0x1 << 6;
static const uint32_t powerSlowCategory = 0x1 << 7;
static const uint32_t powerPlayerCategory = 0x1 << 8;

@interface GameScene()

@property (nonatomic) BOOL isFingerOnPaddle;
@property (nonatomic) BOOL isPowerLaser;
@property (nonatomic) BOOL isPowerSlow;


@property (nonatomic) int remainingLives;

@property (nonatomic) int ballSpeed;
@property (nonatomic) int oldBallSpeed;

// Sound Effects
@property (strong, nonatomic) SKAction *ball_paddle;
@property (strong, nonatomic) SKAction *ball_block;
@property (strong, nonatomic) SKAction *laser;

@property (strong, nonatomic) UITextView *livesView;

@end

@implementation GameScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        self.remainingLives = 2;
        self.ballSpeed = 350;
        self.oldBallSpeed = 350;
        self.isPowerLaser = NO;
        self.isPowerSlow = NO;
        
        self.physicsWorld.contactDelegate = self;
        SKSpriteNode* background = [SKSpriteNode spriteNodeWithImageNamed:@"Background.png"];
        background.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self addChild:background];
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        
        SKPhysicsBody* borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody = borderBody;
        self.physicsBody.friction = 0.0f;
        self.physicsBody.collisionBitMask = 8;
        
        // Add paddle
        
        SKSpriteNode* paddle = [[SKSpriteNode alloc] initWithImageNamed: @"paddle.png"];
        paddle.name = paddleCategoryName;
        paddle.position = CGPointMake(CGRectGetMidX(self.frame), paddle.frame.size.height * .6f);
        [self addChild:paddle];
        
        CGSize paddleSize = CGSizeMake(paddle.frame.size.width, paddle.frame.size.height);
        paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:paddleSize];
        paddle.physicsBody.restitution = 0.1f;
        paddle.physicsBody.friction = 0.4f;
        paddle.physicsBody.dynamic = NO;
        
        // Create the ball
        
        SKSpriteNode* ball = [SKSpriteNode spriteNodeWithImageNamed: @"Ball.png"];
        ball.name = ballCategoryName;
        ball.position = CGPointMake(self.frame.size.width/3, 2*self.frame.size.height/3);
        [self addChild:ball];
        
        // Set ball physics
        
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.frame.size.width/2];
        ball.physicsBody.friction = 0.0f;
        ball.physicsBody.restitution = 1.0f;
        ball.physicsBody.linearDamping = 0.0f;
        ball.physicsBody.allowsRotation = YES;
        ball.physicsBody.dynamic = YES;
        
        [ball.physicsBody applyImpulse:CGVectorMake(10.0f, -6.0f)];
        
        // Add bottom
        
        CGRect bottomRect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 1);
        SKNode* bottom = [SKNode node];
        bottom.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:bottomRect];
        [self addChild:bottom];
        
        bottom.physicsBody.categoryBitMask = bottomCategory;
        bottom.physicsBody.collisionBitMask = 8;
        
        // Add top
        
        CGRect topRect = CGRectMake(self.frame.origin.x,  self.frame.size.height - 1, self.frame.size.width, 1);
        SKNode* top = [SKNode node];
        top.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:topRect];
        [self addChild:top];
        
        top.physicsBody.categoryBitMask = topCategory;
        top.physicsBody.collisionBitMask = 64;
        top.physicsBody.contactTestBitMask = laserBeamCategory;
        
        // Set life info
        
        self.remainingLives = 2;
        
        ball.physicsBody.categoryBitMask = ballCategory;
        paddle.physicsBody.categoryBitMask = paddleCategory;
        paddle.physicsBody.collisionBitMask = 1;
        
        ball.physicsBody.contactTestBitMask = bottomCategory | blockCategory | paddleCategory;
        ball.physicsBody.collisionBitMask = 8;
        
        
        
        
        
        
        
        // Define the demo level layout
        
        int numberOfBlocks = 11;
        int rows = 8;
        SKSpriteNode* sizeBlock = [SKSpriteNode spriteNodeWithImageNamed:@"block_red.png"];
        int blockWidth = sizeBlock.size.width;
        int blockHeight = sizeBlock.size.height;
        float padding = 0.0f;
        
        // Calculate the x position
        float xOffset = (self.frame.size.width - (blockWidth * numberOfBlocks + padding * (numberOfBlocks-1))) / 2;
        
        // Create the blocks and add them to the scene
        for (int j = 1; j <= rows; j++) {
            for (int i = 1; i <= numberOfBlocks; i++) {
                SKSpriteNode* block;
                if (i < 4 || i > 8) {
                    if (j == 1) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_yellow.png"];
                    } else if (j == 2) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_pink.png"];
                    } else if (j == 3) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_blue.png"];
                    } else if (j == 4) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_red.png"];
                    } else if (j == 5) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_green.png"];
                    } else if (j == 6) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_cyan.png"];
                    } else if (j == 7) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_orange.png"];
                    } else { // 8th row
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_white.png"];
                    }
                } else {
                    if (j == 1) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_white.png"];
                    } else if (j == 2) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_orange.png"];
                    } else if (j == 3) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_cyan.png"];
                    } else if (j == 4) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_green.png"];
                    } else if (j == 5) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_red.png"];
                    } else if (j == 6) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_blue.png"];
                    } else if (j == 7) {
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_pink.png"];
                    } else { // 8th row
                        block = [SKSpriteNode spriteNodeWithImageNamed:@"block_yellow.png"];
                    }
                }
                
                
                block.position = CGPointMake((i-0.5f)*block.frame.size.width + (i-1)*padding + xOffset, self.frame.size.height - (6+j)*blockHeight);
                if (i != 4 && i != 8) {
                    block.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:block.frame.size];
                    block.physicsBody.allowsRotation = NO;
                    block.physicsBody.friction = 0.0f;
                    block.name = blockCategoryName;
                    block.physicsBody.restitution = 0.0f;
                    block.physicsBody.categoryBitMask = blockCategory;
                    block.physicsBody.collisionBitMask = 2;
                    block.physicsBody.dynamic = NO;
                    [self addChild:block];
                }
            }
        }
        
        self.ball_block = [SKAction playSoundFileNamed:@"block_hit.mp3" waitForCompletion:NO];
        
        self.ball_paddle = [SKAction playSoundFileNamed:@"paddle_hit.mp3" waitForCompletion:NO];
        
        self.laser = [SKAction playSoundFileNamed:@"laser.mp3" waitForCompletion:NO];
        
    }
    
    return self;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    
    UITouch* touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    
    SKPhysicsBody* body = [self.physicsWorld bodyAtPoint:touchLocation];
    if (body && [body.node.name isEqualToString: paddleCategoryName]) {
        self.isFingerOnPaddle = YES;
        if (self.isPowerLaser) {
            [self runAction:self.laser];
            SKSpriteNode* beam = [SKSpriteNode spriteNodeWithImageNamed:@"laser_beam.png"];
            beam.position = CGPointMake(body.node.frame.origin.x + body.node.frame.size.width/2, body.node.frame.origin.y + body.node.frame.size.height);
            beam.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:beam.frame.size];
            beam.physicsBody.allowsRotation = NO;
            beam.physicsBody.friction = 0.0f;
            beam.name = laserBeamCategoryName;
            beam.physicsBody.restitution = 0.0f;
            beam.physicsBody.categoryBitMask = laserBeamCategory;
            beam.physicsBody.contactTestBitMask = blockCategory;
            beam.physicsBody.collisionBitMask = 32;
            beam.physicsBody.dynamic = YES;
            
            [self addChild:beam];
            [beam.physicsBody applyImpulse:CGVectorMake(0.0f, 2.0f)];
            
            
        }
    }
    
}

-(void)didBeginContact:(SKPhysicsContact*)contact {
    
    // Grab local variables for two physics bodies
    SKPhysicsBody* firstBody;
    SKPhysicsBody* secondBody;
    
    // Assign the two physics bodies so that the one with the lower category is always stored in firstBody
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // Ball hits bottom -- game over
    if (firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == bottomCategory && firstBody.node != nil) {
        if (self.remainingLives == 0) {
            [self.livesView removeFromSuperview];
            
            GameOverScene* gameOverScene = [[GameOverScene alloc] initWithSize:self.frame.size playerWon:NO];
            [self.view presentScene:gameOverScene];
        } else {
            // remove lives, spawn new ball
            [firstBody.node removeFromParent];
            self.remainingLives --;
            self.livesView.text = [NSString stringWithFormat:@"x %d", self.remainingLives];
            
            // new ball
            SKSpriteNode* ball = [SKSpriteNode spriteNodeWithImageNamed: @"Ball.png"];
            ball.name = ballCategoryName;
            ball.position = CGPointMake(self.frame.size.width/3, 2*self.frame.size.height/3);
            [self addChild:ball];
            
            // Set ball physics
            ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.frame.size.width/2];
            ball.physicsBody.friction = 0.0f;
            ball.physicsBody.restitution = 1.0f;
            ball.physicsBody.linearDamping = 0.0f;
            ball.physicsBody.allowsRotation = YES;
            ball.physicsBody.dynamic = YES;
            ball.physicsBody.categoryBitMask = ballCategory;
            ball.physicsBody.contactTestBitMask = bottomCategory | blockCategory | paddleCategory;
            ball.physicsBody.collisionBitMask = 8;
            [ball.physicsBody applyImpulse:CGVectorMake(10.0f, -6.0f)];
        }
    }
    
    // Laser hits top // kill laser
    if (firstBody.categoryBitMask == laserBeamCategory && secondBody.categoryBitMask == topCategory) {
        [firstBody.node removeFromParent];
    }
    
    // Ball hits block -- remove the block
    if (firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == blockCategory) {
        [self runAction:self.ball_block];
        self.ballSpeed += 4;
        CGPoint oldBlockLoc = CGPointMake(secondBody.node.frame.origin.x + secondBody.node.frame.size.width/2, secondBody.node.frame.origin.y + secondBody.node.frame.size.height/2);
        [secondBody.node removeFromParent];
        
        
        // Check if we should spawn a powerup
        int r = rand()%30+1;
        if (r >= 5 && r <= 7) {
            
            SKSpriteNode* powerUp = [SKSpriteNode spriteNodeWithImageNamed:@"power_laser.png"];
            powerUp.position = oldBlockLoc;
            powerUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:powerUp.frame.size];
            if (r == 5) {
                powerUp.texture = [SKTexture textureWithImageNamed:@"power_laser.png"];
                powerUp.physicsBody.categoryBitMask = powerLaserCategory;
            } else if (r == 6) {
                powerUp.texture = [SKTexture textureWithImageNamed:@"power_slow.png"];
                powerUp.physicsBody.categoryBitMask = powerSlowCategory;
            } else if (r == 7) {
                powerUp.texture = [SKTexture textureWithImageNamed:@"power_player.png"];
                powerUp.physicsBody.categoryBitMask = powerPlayerCategory;
            }
            powerUp.physicsBody.allowsRotation = NO;
            powerUp.physicsBody.friction = 0.0f;
            powerUp.name = powerLaserCategoryName;
            powerUp.physicsBody.restitution = 0.0f;
            powerUp.physicsBody.contactTestBitMask = paddleCategory | bottomCategory | blockCategory;
            powerUp.physicsBody.collisionBitMask = 4;
            powerUp.physicsBody.dynamic = YES;
            
            [self addChild:powerUp];
            [powerUp.physicsBody applyImpulse:CGVectorMake(0.0f, -2.0f)];
        }
        if ([self isGameWon]) {
            [self.livesView removeFromSuperview];
            GameOverScene* gameWonScene = [[GameOverScene alloc] initWithSize:self.frame.size playerWon:YES];
            [self.view presentScene:gameWonScene];
        }
    }
    
    // Laser Beam hits block -- kill block and beam
    if (firstBody.categoryBitMask == blockCategory && secondBody.categoryBitMask == laserBeamCategory) {
        if (secondBody.node != nil && firstBody.node != nil) {
            [secondBody.node removeFromParent];
            [firstBody.node removeFromParent];
            self.ballSpeed += 4;
        }
        if ([self isGameWon]) {
            GameOverScene* gameWonScene = [[GameOverScene alloc] initWithSize:self.frame.size playerWon:YES];
            [self.view presentScene:gameWonScene];
        }
    }
    
    // Ball hits paddle -- set the angle of deflection
    
    
    if (firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == paddleCategory) {
        [self runAction:self.ball_paddle];
        SKNode *paddleNode = secondBody.node;
        CGFloat paddleLoc = paddleNode.position.x;
        CGFloat contactX = contact.contactPoint.x;
        CGFloat contactPointOnPaddle = contactX - paddleLoc;
        
        // Check that reflection isn't too shallow
        CGFloat yVelocity = firstBody.velocity.dy;
        if (yVelocity < 500) yVelocity = 500;
        
        // Set new angular velocity based on x-coordinate of collision
        firstBody.velocity = CGVectorMake(0.0f, yVelocity);             // dampen x
        [firstBody applyImpulse:(CGVectorMake(contactPointOnPaddle*.15, 0.0f))];    // set x
    }
    
    // Laser power-up hits paddle
    if (firstBody.categoryBitMask == paddleCategory && secondBody.categoryBitMask == powerLaserCategory) {
        NSLog(@"test");
        [secondBody.node removeFromParent];
        // Go to laser mode
        [self unpower];
        SKSpriteNode* paddleNode = (SKSpriteNode*) firstBody.node;
        paddleNode.texture = [SKTexture textureWithImageNamed:@"paddle_laser.png"];
        [self powerLaser];
    }
    
    // Laser power-up hits bottom
    if (firstBody.categoryBitMask == bottomCategory && secondBody.categoryBitMask == powerLaserCategory) {
        [secondBody.node removeFromParent];
    }
    
    
    // Slow power-up hits paddle
    if (firstBody.categoryBitMask == paddleCategory && secondBody.categoryBitMask == powerSlowCategory) {
        NSLog(@"test");
        
        [secondBody.node removeFromParent];
        [self unpower];
        [self powerSlow];
    }
    
    // Slow power-up hits bottom
    if (firstBody.categoryBitMask == bottomCategory && secondBody.categoryBitMask == powerSlowCategory) {
        [secondBody.node removeFromParent];
    }
    
    
    // 1-Up power-up hits paddle
    if (firstBody.categoryBitMask == paddleCategory && secondBody.categoryBitMask == powerPlayerCategory) {
        NSLog(@"test");
        
        [secondBody.node removeFromParent];
        [self unpower];
        self.remainingLives ++;
        self.livesView.text = [NSString stringWithFormat:@"x %i", self.remainingLives];
    }
    
    // 1-Up power-up hits bottom
    if (firstBody.categoryBitMask == bottomCategory && secondBody.categoryBitMask == powerPlayerCategory) {
        [secondBody.node removeFromParent];
    }
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    // Check whether user tapped paddle
    if (self.isFingerOnPaddle) {
        // Get touch location
        UITouch* touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInNode:self];
        CGPoint previousLocation = [touch previousLocationInNode:self];
        
        SKSpriteNode* paddle = (SKSpriteNode*)[self childNodeWithName: paddleCategoryName];
        // Calculate new position along x for paddle
        int paddleX = paddle.position.x + (touchLocation.x - previousLocation.x);
        // Limit x so that the paddle will not leave the screen to left or right
        paddleX = MAX(paddleX, paddle.size.width/2);
        paddleX = MIN(paddleX, self.size.width - paddle.size.width/2);
        // Update position of paddle
        paddle.position = CGPointMake(paddleX, paddle.position.y);
    }
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    self.isFingerOnPaddle = NO;
}


// Count remaining blocks, return true if none left
-(BOOL)isGameWon {
    int numberOfBricks = 0;
    for (SKNode* node in self.children) {
        if ([node.name isEqual: blockCategoryName]) {
            numberOfBricks++;
        }
    }
    return numberOfBricks <= 0;
}

-(void)powerLaser {
    self.isPowerLaser = YES;
}

-(void)powerSlow {
    self.isPowerSlow = YES;
    self.oldBallSpeed = self.ballSpeed;
    self.ballSpeed = 200;
}

// Shut off all power-ups
-(void)unpower {
    if (self.isPowerSlow) {
        self.ballSpeed = self.oldBallSpeed;
    }
    self.isPowerLaser = NO;
    self.isPowerSlow = NO;
}

-(void)didMoveToView:(SKView *)view {
    self.livesView = [[UITextView alloc]initWithFrame:CGRectMake(40, 5, 80, 40)];
    self.livesView.text = [NSString stringWithFormat:@"x %i", self.remainingLives];
    self.livesView.textColor = [UIColor yellowColor];
    self.livesView.backgroundColor = [UIColor clearColor];
    self.livesView.font = [UIFont systemFontOfSize:17.0];
    self.livesView.editable = NO;
    self.livesView.selectable = NO;
    [self.view addSubview:self.livesView];
    
    UIImageView *lives_icon = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 24, 24)];
    [lives_icon setImage:[UIImage imageNamed:@"lives_icon.png"]];
    [self.view addSubview:lives_icon];
}


-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    SKNode* ball = [self childNodeWithName: ballCategoryName];
    CGVector currentVelocity = ball.physicsBody.velocity;
    //NSLog(@"y velocity: %f", currentVelocity.dy);
    CGFloat magnitude = sqrt(currentVelocity.dx*currentVelocity.dx + currentVelocity.dy*currentVelocity.dy);
    if (magnitude != self.ballSpeed) {
        CGVector normalizedVelocity = CGVectorMake(currentVelocity.dx/magnitude, currentVelocity.dy/magnitude);
        ball.physicsBody.velocity = CGVectorMake(normalizedVelocity.dx*self.ballSpeed, normalizedVelocity.dy*self.ballSpeed);
    }
}

@end