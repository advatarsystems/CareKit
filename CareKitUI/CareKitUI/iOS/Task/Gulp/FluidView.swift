//
//  File.swift
//  
//
//  Created by Johan Sellström on 2022-10-16.
//
/* TODO: Finish rewrite
import UIKit
import CoreMotion

enum Direction {
    case left
    case right
}

class FluidView: UIView {
    
    /// Changes the fill color of the wave animation
    public var fillColor: UIColor
    
    /// Changes the stroke color of the wave animation
    public var strokColor: UIColor
    
    /// Changes how frequently the vertical fill animation will happen
    public var fillRepeatCount: CGFloat

    /// Provides a way to increase or decrese the side of the stroke around the wave animation
    public var lineWidth: CGFloat
    
    /// Boolean to determine whether you want the fill animation to return to it's initial state
    public var fillAutoReverse: Bool

    /// TimeInterval to determine the total duration of a complete fill (0% - 100%)
    public var fillDuration: TimeInterval
    
    /// Changes the interval between Max and Min the random function will use
    public var  amplitudeIncrement: Int
    
    /// Changes the maximum wave crest
    public var  maxAmplitude: Int

    ///  Changes the minimum wave crest
    public var minAmplitude: Int
    
    /// Notification message string for tilt animations
    public static let kBAFluidViewCMMotionUpdate: String = "FluidViewCMMotionUpdate"
    
    
    private var startElevation: NSNumber
    
    private var rootView: UIView
    
    private var rollLayer: CALayer?
    private var lineLayer: CAShapeLayer

    private var waveDirection: Direction
    
    private var roll: CGFloat
    private var rollOrientationAdjustment: CGFloat
    private var primativeStartElevation: Double
    
    private var animating = false
    
    private var startingAmplitude: Int
    
    private var amplitudeArray = [Int]()
    
    private var fillLevel: NSNumber
    private var initialFill: Bool
    private var waveLength: Int
    private var finalX: Int

    private var waveCrestAnimation: CAKeyframeAnimation
    private var orientation: UIDeviceOrientation
    private var waveCrestTimer: Timer

    
    /// Returns an object that can create the fluid animation with the given wave properties. This init function lets you adjust the wave crest properties.
    /// - Parameters:
    ///   - aRect: Frame for the fluid object to fill
    ///   - maxAmplitude: Max wave crest
    ///   - minAmplitude: Min wave crest
    ///   - amplitudeIncrement: Lets you chose the interval between Max and Min the random function will use
    public init(frame: CGRect, fillColor: UIColor, strokColor: UIColor, fillRepeatCount: CGFloat, lineWidth: CGFloat, fillAutoReverse: Bool, fillDuration: TimeInterval, amplitudeIncrement: Int, maxAmplitude: Int, minAmplitude: Int) {
        super.init(frame: frame)
        self.fillColor = fillColor
        self.strokColor = strokColor
        self.fillRepeatCount = fillRepeatCount
        self.lineWidth = lineWidth
        self.fillAutoReverse = fillAutoReverse
        self.fillDuration = fillDuration
        self.amplitudeIncrement = amplitudeIncrement
        self.maxAmplitude = maxAmplitude
        self.minAmplitude = minAmplitude
    }
    /// Returns an object that can create the fluid animation with the given wave properties. This init function lets you adjust starting elevation. The other parameters have default values.
    /// - Parameters:
    /// - startElevation: The starting point of the fluid animation
    public init(frame: CGRect, startElevation: NSNumber) {
        super.init(frame: frame)
        
    }
    
   
     /// Returns an object that can create the fluid animation with the given wave properties. This init function lets you adjust all the wave crest and fluid properties.
    /// - Parameters:
    ///  - aRect: Frame for the fluid object to fill
     /// - aMaxAmplitude: Max wave crest
     /// - aMinAmplitude: Min wave crest
     /// - aAmplitudeIncrement: Lets you chose the interval between Max and Min the random function will use
     /// - aStartElevation: The starting point of the fluid animation
     
    public init(frame: CGRect, maxAmplitude: Int, minAmplitude: Int, amplitudeIncrement: Int, aStartElevation: NSNumber) {
        super.init(frame: frame)
        self.maxAmplitude = maxAmplitude
        self.minAmplitude = minAmplitude
        self.amplitudeIncrement = amplitudeIncrement
        
    }
    
    /// This method can set all the default values prior to start of animation
    public init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    /// This method lets you choose to what level you want the fluidVIew to increase or decrease to (based on starting elevation)
    /// - Parameters:
    /// - fillPercentage: Determines the percentage to fill to (decimal number)
    public func fillTo(fillPercentage: NSNumber) {
        
    }
    
    /// This method lets you keep the fluid view at it's starting elevation, but creates the wave crest animation
    public func keepStationary() {
        
    }
    
    
    func getBezierPathValues() -> [CGFloat] {
        //creating wave starting point
        let startPoint = CGPoint(x: 0.0, y: 0.0)
        
        //grabbing random amplitude to shrink/grow to
        let random = Int(arc4random_uniform(UInt32(self.amplitudeArray.count)))
        let index: NSNumber = NSNumber(integerLiteral: random)
        
        let finalAmplitude = amplitudeArray[index.intValue]
        var values = [CGPath]()
        
        //shrinking
        if self.startingAmplitude >= finalAmplitude {
            var j = self.startingAmplitude
            while j >= self.startingAmplitude {
                
                var line = UIBezierPath()
                //create a UIBezierPath along distance
                line.move(to: startPoint)
                
                var tempAmplitude = j
                var i = self.waveLength/2
                while i <= self.finalX {
                    line.addQuadCurve(to: CGPoint(x: startPoint.x+CGFloat(i), y: startPoint.y), controlPoint: CGPoint(x: startPoint.x+CGFloat(i)-CGFloat(Double(self.waveLength)/4.0), y: startPoint.y + CGFloat(tempAmplitude)))
                    tempAmplitude = -tempAmplitude
                    i += self.waveLength/2
                }
                let p1 = CGPoint(x: CGFloat(self.finalX) , y: 5.0*CGRectGetHeight(self.rootView.frame) -  CGFloat(self.maxAmplitude))
                line.addLine(to: p1)
                let p2 = CGPoint(x: 0.0, y: 5.0*CGRectGetHeight(self.rootView.frame) -  CGFloat(self.maxAmplitude))
                line.addLine(to: p2)
                line.close()
                values.append(line.cgPath)
                j -= self.amplitudeIncrement
            }
        }
        
        //growing
        else { // FIXME: What is the difference?
            var j = self.startingAmplitude
            while j <= finalAmplitude {
                //create a UIBezierPath along distance
                var line = UIBezierPath()
                line.move(to: startPoint)
                var tempAmplitude = j
                var i = self.waveLength/2
                while i <= self.finalX {
                    line.addQuadCurve(to: CGPoint(x: startPoint.x+CGFloat(i), y: startPoint.y), controlPoint: CGPoint(x: startPoint.x+CGFloat(i)-CGFloat(Double(self.waveLength)/4.0), y: startPoint.y + CGFloat(tempAmplitude)))
                    tempAmplitude = -tempAmplitude
                    i += self.waveLength/2
                    
                }
                
                let p1 = CGPoint(x: CGFloat(self.finalX) , y: 5.0*CGRectGetHeight(self.rootView.frame) -  CGFloat(self.maxAmplitude))
                line.addLine(to: p1)
                let p2 = CGPoint(x: 0.0, y: 5.0*CGRectGetHeight(self.rootView.frame) -  CGFloat(self.maxAmplitude))
                line.addLine(to: p2)
                line.close()
                values.append(line.cgPath)
                j+=self.amplitudeIncrement
            }
            
        }
    }
    
    @objc func updateWaveCrestAnimation() {
        //Wave Crest animation
        self.lineLayer.removeAnimation(forKey: "waveCrestAnimation")
        self.waveCrestAnimation.values = getBezierPathValues()
        self.lineLayer.add(self.waveCrestAnimation, forKey: "waveCrestAnimation")
    }
    
    /// This methods starts all the desired animations
    public func startAnimation() {
        if !self.animating {
            self.startingAmplitude = self.maxAmplitude
            //Phase Shift Animation
            var horizontalAnimation: CAKeyframeAnimation = CAKeyframeAnimation.init(keyPath: "position.x")
            horizontalAnimation.values = [self.lineLayer.position.x-CGFloat(self.waveLength*2), self.lineLayer.position.x-CGFloat(self.waveLength)]
            // horizontalAnimation.values = @[@(self.lineLayer.position.x-self.waveLength*2),@(self.lineLayer.position.x-self.waveLength)];
                
                
            horizontalAnimation.duration = 1.0
            horizontalAnimation.repeatCount = .greatestFiniteMagnitude
            horizontalAnimation.isRemovedOnCompletion = false
            horizontalAnimation.fillMode = CAMediaTimingFillMode.forwards
            self.lineLayer.add(horizontalAnimation, forKey: "horizontalAnimation")
                
            //Wave Crest Animations
            self.waveCrestAnimation = CAKeyframeAnimation.init(keyPath: "path")
            
            self.waveCrestAnimation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeIn)
            
            
            self.waveCrestAnimation.values = getBezierPathValues()
            self.waveCrestAnimation.duration = 0.5;
            self.waveCrestAnimation.isRemovedOnCompletion = false
            self.waveCrestAnimation.fillMode = CAMediaTimingFillMode.forwards;
            self.waveCrestAnimation.delegate = self;
            
            self.waveCrestTimer  = Timer.scheduledTimer(timeInterval: self.waveCrestAnimation.duration,
                                                     target: self,
                                                     selector: #selector(updateWaveCrestAnimation),
                                                     userInfo: nil,
                                                     repeats: true)
            self.waveCrestTimer.fire()
          
            //check if we're adding tiltAnimations, otherwise add straight to view
            if self.roll != 0.0 {
                startTiltAnimation()
            } else {
                self.layer.addSublayer(self.lineLayer)
            }
                
            self.animating = true
            
        }

    }
    
    
    private func addTiltAnimations(note: NSNotification) {
        
        //grab data for roll from the notification
        //computing roll leads to a more stable value
        //http://stackoverflow.com/q/19239482/1408431
        guard let data = note.userInfo?["data"] as? CMDeviceMotion else {
            fatalError()
        }
        //CMDeviceMotion *data = [[note userInfo] valueForKey:@"data"];
        var roll: CGFloat = atan2(data.gravity.y, data.gravity.x) + (90.0 * Double.pi) / 180.0;
        
        //limiting tilt
        if roll + self.rollOrientationAdjustment < -1.0 {
            roll = -1.0
        } else if roll + self.rollOrientationAdjustment > 1.0 {
            roll = 1.0
        }
        
        self.roll = roll
        
        //change wave direction if we're tilting in a different direction
        let oldDirection  = self.waveDirection
        self.waveDirection = (self.roll > -0.2) ? .right:.left
        if self.waveDirection != oldDirection {
            updateHorizontalAnimation()
        }
        addRotationAnimation()
        
    }
    /// This methods starts all the desired animations
    public func startTiltAnimation() {
        //linelayer can't be manipulated without changing it's anchor point
        //instead we put the linelayer in a layer we can change the anchor point on
        if self.rollLayer == nil {
            //creating layer which will rotate
            self.rollLayer = CALayer()
            //add linelayer to this layer now
            self.rollLayer?.addSublayer(self.lineLayer)
            layer.addSublayer(rollLayer!)
        }
        
        self.rollLayer!.frame = self.bounds;
        //listen for the device manager
        NotificationCenter.default.addObserver(self, selector: #selector(addTiltAnimations), name: FluidView.kBAFluidViewCMMotionUpdate, object: nil)

    }
    
    /// This methods stops all the desired animations
    public func stopAnimation() {
        if let timer = self.waveCrestTimer {
            timer.invalidate()
            self.waveCrestTimer = nil
        }
        self.lineLayer.removeAnimation(forKey: "horizontalAnimation")
        self.lineLayer.removeAnimation(forKey: "waveCestAnimation")
        if self.roll != 0.0 {
            NotificationCenter.default.removeObserver(self, name: FluidView.kBAFluidViewCMMotionUpdate, object: nil)
            self.rollLayer?.removeAnimation(forKey: self.rollLayer)
           
        }
        self.waveCrestAnimation =  nil;
        self.animating = false
    }

    
    private func keepStationary() {
        self.fillRepeatCount = 0
        self.fillAutoReverse = false
        self.lineLayer.removeAnimation(forKey: "verticalAnimation")
    }

    private func updateStartElevation(startElevation: NSNumber) {
        self.startElevation = startElevation;
        frame = self.lineLayer.frame;
        frame.origin.y = CGRectGetHeight(self.rootView.frame)*((1.0-CGFloat(startElevation.floatValue)))
        self.lineLayer.frame = frame;
        self.primativeStartElevation = startElevation.doubleValue
    }


}
 



- (void)fillTo:(NSNumber*)fillPercentage {
    float fillDifference = fabs(fillPercentage.floatValue-self.fillLevel.floatValue);
    if(fillDifference == 0){
        //no change
        return;
    }
    self.fillLevel = fillPercentage;
    CAKeyframeAnimation *verticalAnimation =
    [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
    float finalPosition;
    finalPosition = (1.0 - fillPercentage.doubleValue)*CGRectGetHeight(self.bounds);
    
    //bit hard to define a hard endpoint with the dynamic waves
    if ([self.fillLevel  isEqual: @1.0]){
        finalPosition = finalPosition - 2*self.maxAmplitude;
    }
    else if (self.fillLevel.doubleValue > 0.98) {
        finalPosition = finalPosition - self.maxAmplitude;
    }
    
    
    //fill animation
    //the animation glitches because the horizontal x of the layer is never in the same spot at the end of the animation. We can use the presentation layer to get the current x. This isn't what the presentation layer is for, but can't find a way to make a smooth transition.
    CALayer *initialLayer = self.lineLayer;
    
    if (!self.initialFill) {
        initialLayer = self.lineLayer.presentationLayer;
    }
    
    verticalAnimation.values = @[@(initialLayer.position.y),@(finalPosition)];
    verticalAnimation.duration = self.fillDuration*fillDifference;
    verticalAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    verticalAnimation.autoreverses = self.fillAutoReverse;
    verticalAnimation.repeatCount = self.fillRepeatCount;
    verticalAnimation.removedOnCompletion = NO;
    verticalAnimation.fillMode = kCAFillModeForwards;
    [self.lineLayer addAnimation:verticalAnimation forKey:@"verticalAnimation"];
    self.initialFill = NO;
}

#pragma mark - Private

- (void)updateStartElevation:(NSNumber *)startElevation {
    self.startElevation = startElevation
    CGRect frame = self.lineLayer.frame
    frame.origin.y = CGRectGetHeight(self.rootView.frame)*((1.0-CGFloat(startElevation.floatValue)))
    self.lineLayer.frame = frame
    self.primativeStartElevation = startElevation.doubleValue;
    
}

- (void)reInitializeLayer {
    //This method occurs when the device is rotated
    
    self.rootView = [self.window.subviews objectAtIndex:0];
    if (!self.rootView) {
        self.rootView = self;
        while (self.rootView.superview != nil) {
            self.rootView = self.rootView.superview;
        }
    }
    
    //values that need to be adjusted due to change in width
    self.waveLength = CGRectGetWidth(self.rootView.frame);
    self.finalX = 5*self.waveLength;
    
    //creating the linelayer/rollLayer frame to fit new orientation
    self.lineLayer.anchorPoint = CGPointMake(0, 0)
    CGRect frame = CGRectMake(0, CGRectGetHeight(self.bounds), self.finalX, CGRectGetHeight(self.rootView.frame));
    self.lineLayer.frame = frame;
    
    //need to grab the presentation again as a base
    self.initialFill = YES;
    
    //for some reason I can't access _startElevation, but a primitive can be accessed. Right now
    //all this does is redo the elevation adjustment due to change in height of device
    self.startElevation = @(self.primativeStartElevation);
    
    
    //the animation for fill will have to repeat as the height as changed
    if (![self.fillLevel isEqual:@0]) {
        [self fillTo:self.fillLevel];
    }
}

- (void)updateWaveCrestAnimation {
    
    //Wave Crest animation
    [self.lineLayer removeAnimationForKey:@"waveCrestAnimation"];
    self.waveCrestAnimation.values = [self getBezierPathValues];
    [self.lineLayer addAnimation:self.waveCrestAnimation forKey:@"waveCrestAnimation"];
    
}

- (void)addTiltAnimations:(NSNotification *)note {
    
    //grab data for roll from the notification
    //computing roll leads to a more stable value
    //http://stackoverflow.com/q/19239482/1408431
    CMDeviceMotion *data = [[note userInfo] valueForKey:@"data"];
    CGFloat roll = atan2(data.gravity.y, data.gravity.x) + (90 * M_PI) / 180;
    
    //limiting tilt
    if((roll + self.rollOrientationAdjustment)< -1){
        roll = -1;
    } else if((roll + self.rollOrientationAdjustment)     > 1){
        roll = 1;
    }
    self.roll = roll;
    
    //change wave direction if we're tilting in a different direction
    BAFLUIDVIEWHORIZONTALDIRECTION oldDirection = self.waveDirection;
    self.waveDirection = (self.roll > -0.2) ? BAFLUIDVIEWHORIZONTALDIRECTIONRIGHT:BAFLUIDVIEWHORIZONTALDIRECTIONLEFT;
    if((self.waveDirection != oldDirection)){
        [self updateHorizontalAnimation];
    }
    
    [self addRotationAnimation];
}

- (void) addRotationAnimation {
    
    //tilt relative to the phone
    CALayer *presentationLayer = self.rollLayer.presentationLayer;
    CATransform3D zRotation = CATransform3DMakeRotation(-(self.roll+self.rollOrientationAdjustment)*0.7, 0, 0, 1.0);
    CABasicAnimation *animateZRotation;
    animateZRotation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animateZRotation.fromValue = [NSValue valueWithCATransform3D:presentationLayer.transform];
    animateZRotation.toValue = [NSValue valueWithCATransform3D:zRotation];
    animateZRotation.duration = 0.4;
    animateZRotation.fillMode = kCAFillModeForwards;
    animateZRotation.removedOnCompletion = NO;
    [self.rollLayer addAnimation:animateZRotation forKey:@"tiltAnimation"];
}

- (void)updateHorizontalAnimation {
    
    //shift from current position to start of reverse direction
    CABasicAnimation *initialHorizontalAnimation =
    [CABasicAnimation animationWithKeyPath:@"position.x"];
    
    CALayer* presentationLayer = self.lineLayer.presentationLayer;
    initialHorizontalAnimation.fromValue =@(presentationLayer.position.x);
    initialHorizontalAnimation.toValue = @(-self.waveLength*2);
    initialHorizontalAnimation.removedOnCompletion = NO;
    initialHorizontalAnimation.fillMode = kCAFillModeForwards;
    initialHorizontalAnimation.duration = (self.waveLength+presentationLayer.position.x)/self.waveLength;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        
        //phaseshift repeating animation
        CABasicAnimation *repeatingHorizontalAnimation =
        [CABasicAnimation animationWithKeyPath:@"position.x"];
        repeatingHorizontalAnimation.fromValue =@(self.lineLayer.position.x-self.waveLength*2);
        if(self.waveDirection==BAFLUIDVIEWHORIZONTALDIRECTIONLEFT){
            repeatingHorizontalAnimation.toValue = @(self.lineLayer.position.x-self.waveLength);
            
        } else {
            repeatingHorizontalAnimation.toValue = @(self.lineLayer.position.x-self.waveLength*3);
        }
        
        repeatingHorizontalAnimation.duration = 1.0;
        repeatingHorizontalAnimation.repeatCount = HUGE;
        repeatingHorizontalAnimation.removedOnCompletion = NO;
        repeatingHorizontalAnimation.fillMode = kCAFillModeForwards;
        [self.lineLayer addAnimation:repeatingHorizontalAnimation forKey:@"horizontalAnimation"];
    }];
    [self.lineLayer addAnimation:initialHorizontalAnimation forKey:@"horizontalAnimation"];
    [CATransaction commit];
    
}
// FIXME: Check details
/*
- (NSArray*)getBezierPathValues {
    //creating wave starting point
    CGPoint startPoint;
    startPoint = CGPointMake(0,0);
    
    //grabbing random amplitude to shrink/grow to
    NSNumber *index = [NSNumber numberWithInt:arc4random_uniform((u_int32_t)self.amplitudeArray.count)];
    
    NSInteger finalAmplitude = [[self.amplitudeArray objectAtIndex:index.intValue] intValue];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    //shrinking
    if (self.startingAmplitude >= finalAmplitude) {
        for (NSInteger j = self.startingAmplitude; j >= finalAmplitude; j-=self.amplitudeIncrement) {
            //create a UIBezierPath along distance
            UIBezierPath* line = [UIBezierPath bezierPath];
            [line moveToPoint:CGPointMake(startPoint.x, startPoint.y)];
            
            NSInteger tempAmplitude = j;
            for (NSInteger i = self.waveLength/2; i <= self.finalX; i+=self.waveLength/2) {
                [line addQuadCurveToPoint:CGPointMake(startPoint.x + i,startPoint.y) controlPoint:CGPointMake(startPoint.x + i - (self.waveLength/4),startPoint.y + tempAmplitude)];
                tempAmplitude = -tempAmplitude;
            }
            
            [line addLineToPoint:CGPointMake(self.finalX, 5*CGRectGetHeight(self.rootView.frame) - self.maxAmplitude)];
            [line addLineToPoint:CGPointMake(0, 5*CGRectGetHeight(self.rootView.frame) - self.maxAmplitude)];
            [line closePath];
            
            [values addObject:(id)line.CGPath];
        }
    }
    
    //growing
    else{
        for (NSInteger j = self.startingAmplitude; j <= finalAmplitude; j+=self.amplitudeIncrement) {
            //create a UIBezierPath along distance
            UIBezierPath* line = [UIBezierPath bezierPath];
            [line moveToPoint:CGPointMake(startPoint.x, startPoint.y)];
            
            NSInteger tempAmplitude = j;
            for (NSInteger i = self.waveLength/2; i <= self.finalX; i+=self.waveLength/2) {
                [line addQuadCurveToPoint:CGPointMake(startPoint.x + i,startPoint.y) controlPoint:CGPointMake(startPoint.x + i -(self.waveLength/4),startPoint.y + tempAmplitude)];
                tempAmplitude = -tempAmplitude;
            }
            
            [line addLineToPoint:CGPointMake(self.finalX, 5*CGRectGetHeight(self.rootView.frame) - self.maxAmplitude)];
            [line addLineToPoint:CGPointMake(0, 5*CGRectGetHeight(self.rootView.frame) - self.maxAmplitude)];
            [line closePath];
            
            [values addObject:(id)line.CGPath];
        }
        
        
    }
    
    self.startingAmplitude = finalAmplitude;
    
    return [NSArray arrayWithArray:values];
    
}
*/


- (NSArray*)createAmplitudeOptions {
    NSMutableArray *tempAmplitudeArray = [[NSMutableArray alloc] init];
    for (NSInteger i = self.minAmplitude; i <= self.maxAmplitude; i+= self.amplitudeIncrement) {
        [tempAmplitudeArray addObject:[NSNumber numberWithInteger:i]];
    }
    return tempAmplitudeArray;
}

extension FluidView: CAAnimationDelegate {
    
}
 */
