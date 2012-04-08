//
//  ViewController.m
//  Compatibility
//
//  Created by Loïs Di Qual on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"
#import "structures.h"

@implementation ViewController
@synthesize leftFace;
@synthesize rightFace;
@synthesize affinityLabel;
@synthesize leftCameraView;
@synthesize rightCameraView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  NSLog(@"View did load");
  leftPoints = malloc(3 * sizeof(CGPoint));
  rightPoints = malloc(3 * sizeof(CGPoint));
  leftCaptured = false;
  rightCaptured = false;
  affinityLabel.hidden = TRUE;
  leftSubViews = [NSMutableArray array];
  rightSubViews = [NSMutableArray array];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"Screen touched");
  UITouch *touch = [touches anyObject];
  
  //NSLog(@"%p left:%p right:%p", [touch view], leftFace, rightFace);
  
  if ([touch view] == leftFace || [touch view] == rightFace) {
    shootingFace = [touch view];
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
  }
  
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  NSLog(@"Image chosen");
  // Access the uncropped image from info dictionary
  UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
  
  CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                            context:nil
                                            options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                                                                forKey:CIDetectorAccuracy]];
  
  CIImage* ciImage = [CIImage imageWithCGImage:image.CGImage];
  
  NSLog(@"Detecting eyes");
  NSDictionary* imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:6]
                                                           forKey:CIDetectorImageOrientation];
  NSArray* features = [detector featuresInImage:ciImage options:imageOptions];
  [picker dismissViewControllerAnimated:TRUE completion:nil];
  
  if ([features count] == 0) {
    NSLog(@"Nothing detected, aborting...");
    [self recognitionError];
  } else {
    NSLog(@"Face detected, loading image...");
    [self faceRecognized:image feature:[features objectAtIndex:0]];
  }
}

- (void)recognitionError {
  NSLog(@"Recognition Error");
}

/*
 * Returns [(float *)ratio, (CGRect)cropRectangle, (CGPoint *)newPoints]
 */
- (CenteredImageInfo)centerImage:(UIImage *)image
              withDetectedPoints:(CGPoint *)points
                         andView:(UIView *)view {
  
  CGPoint *newPoints = malloc(3 * sizeof(CGPoint));
  
  //NSLog(@"left: %f %f, right: %f %f", points[0].x, points[0].y, points[1].x, points[1].y);
  float faceWidth = points[1].x - points[0].x;
  //NSLog(@"Face width:%f", faceWidth);
  
  float faceRatio = ((view.frame.size.width * 2) / 3) / faceWidth;
  //NSLog(@"Face ratio:%f", faceRatio);
  
  float yDelta = ((view.frame.size.height / 10) * 4) - points[0].y * faceRatio;
  float xDelta = ((view.frame.size.width * 2) / 3) - points[0].x * faceRatio;
  
  //NSLog(@"xDelta: %f yDelta: %f", xDelta, yDelta);
  for (int i=0; i<3; i++) {
    newPoints[i].x = points[i].x * faceRatio + xDelta;
    newPoints[i].y = points[i].y * faceRatio + yDelta;
  }
  
  CGRect cropRect = CGRectMake(-xDelta + view.frame.origin.x, -yDelta, view.frame.size.width, view.frame.size.height);
  
  CenteredImageInfo infos = {
    faceRatio,
    cropRect,
    newPoints
  };
  return infos;
}

- (void)faceRecognized:(UIImage *)image feature:(CIFaceFeature *)feature
{  
  UIImageView *imageView = ((UIImageView *)shootingFace);
  
  //NSLog(@"leftEye: %d rightEye: %d", feature.hasLeftEyePosition, feature.hasRightEyePosition);
  NSLog(@"Computing detected points");
  CGPoint *points = (imageView == leftFace) ? leftPoints : rightPoints;
  //NSLog(@"left: %f %f  right:%f %f", points[0].x, points[0].y, points[1].x, points[1].y);
  
  points[0] = CGPointMake(feature.leftEyePosition.y, feature.leftEyePosition.x);
  points[1] = CGPointMake(feature.rightEyePosition.y, feature.rightEyePosition.x);
  points[2] = CGPointMake(feature.mouthPosition.y, feature.mouthPosition.x);
  
  //NSLog(@"left: %f %f  right:%f %f", points[0].x, points[0].y, points[1].x, points[1].y);
  
  NSLog(@"Computing centered image infos");
  CenteredImageInfo infos = [self centerImage:image
                           withDetectedPoints:points
                                      andView:imageView];
  
  //NSLog(@"ratio:%f rect: %f %f %f %f", infos.ratio, infos.cropRect.origin.x, infos.cropRect.origin.y, infos.cropRect.size.width, infos.cropRect.size.height);
  
  NSLog(@"Resizing image");
  CGSize newSize = CGSizeMake(image.size.width * infos.ratio, image.size.height * infos.ratio);
  UIImage *resizedImage = [ViewController imageWithImage:image scaledToSize:newSize];
  
  NSLog(@"Putting image on imageView");
  CGImageRef imageRef = CGImageCreateWithImageInRect([resizedImage CGImage], infos.cropRect);
  ((UIImageView *)shootingFace).image = [UIImage imageWithCGImage:imageRef];
  
  if (imageView == leftFace) {
    leftCameraView.hidden = TRUE;
    free(leftPoints);
    leftPoints = infos.newPoints;
    leftImage = image;
    leftCaptured = true;
  } else {
    rightCameraView.hidden = TRUE;
    free(rightPoints);
    rightPoints = infos.newPoints;
    rightImage = image;
    rightCaptured = true;
  }
  
  if (leftCaptured && rightCaptured) {
    [self compute];
  }
}

- (void)compute {
  NSLog(@"Computing face widths");
  float leftFaceWidth = fmax(leftPoints[0].x, leftPoints[1].x) - fmin(leftPoints[0].x, leftPoints[1].x) + 25;
  float rightFaceWidth = fmax(rightPoints[0].x, rightPoints[1].x) - fmin(rightPoints[0].x, rightPoints[1].x) + 25;
  [self drawPoints:leftPoints faceWidth:leftFaceWidth withColor:[UIColor blueColor] side:0];
  [self drawPoints:rightPoints faceWidth:rightFaceWidth withColor:[UIColor redColor] side:1];
  
  NSLog(@"Computing affinity");
  float vecLeftGD[2] = {
    leftPoints[1].x - leftPoints[0].x,
    leftPoints[1].y - leftPoints[0].y
  };
  float vecLeftGM[2] = {
    leftPoints[2].x - leftPoints[0].x,
    leftPoints[2].y - leftPoints[0].y
  };
  float vecRightGD[2] = {
    rightPoints[1].x - rightPoints[0].x,
    rightPoints[1].y - rightPoints[0].y
  };
  float vecRightGM[2] = {
    rightPoints[2].x - rightPoints[0].x,
    rightPoints[2].y - rightPoints[0].y
  };
  
  float leftProj = (vecLeftGD[0] * vecLeftGM[0] + vecLeftGD[1] * vecLeftGM[1])
                    / pow(sqrtf(powf(vecLeftGD[0], 2) + powf(vecLeftGD[1], 2)), 2);
  float rightProj = (vecRightGD[0] * vecRightGM[0] + vecRightGD[1] * vecRightGM[1])
                    / pow(sqrtf(powf(vecRightGD[0], 2) + powf(vecRightGD[1], 2)), 2);
  
  float percent = (1 - fabs(leftProj - rightProj)) * 100;
  
  NSLog(@"Affinity: %f", percent);
  affinityLabel.hidden = FALSE;
  affinityLabel.text = [NSString stringWithFormat:@"%d%%", (int)percent];
}

- (void)drawPoints:(CGPoint[3])points faceWidth:(float)faceWidth withColor:(UIColor *)color side:(int)side {
  
  NSMutableArray *subViews = (side == 1) ? rightSubViews : leftSubViews;
  for (UIView *view in subViews) {
    [view removeFromSuperview];
  }
  
  for (int i=0; i<3; i++) {
    //NSLog(@"%f %f", points[i].x, points[i].y);
    UIView* eyeView = [[UIView alloc] initWithFrame:CGRectMake(points[i].x-faceWidth*0.15, points[i].y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
    [eyeView setBackgroundColor:[color colorWithAlphaComponent:0.3]];
    [eyeView setCenter:points[i]];
    eyeView.layer.cornerRadius = faceWidth*0.15;
    [subViews addObject:eyeView];
    [self.view addSubview:eyeView];
  }
}

+ (UIImage*)imageWithImage:(UIImage*)image 
              scaledToSize:(CGSize)newSize;
{
  UIGraphicsBeginImageContext( newSize );
  [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
  UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return newImage;
}

- (void)viewDidUnload
{
  [self setLeftFace:nil];
  [self setRightFace:nil];
  [self setAffinityLabel:nil];
  [self setLeftCameraView:nil];
  [self setRightCameraView:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
      return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
      return YES;
  }
}

- (IBAction)cameraPress:(id)sender {
}
@end
