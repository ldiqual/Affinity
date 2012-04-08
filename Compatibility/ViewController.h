//
//  ViewController.h
//  Compatibility
//
//  Created by Loïs Di Qual on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
  UIView * shootingFace;
  CGPoint *leftPoints;
  CGPoint *rightPoints;
  BOOL leftCaptured;
  BOOL rightCaptured;
  UIImage *leftImage;
  UIImage *rightImage;
  NSMutableArray *leftSubViews;
  NSMutableArray *rightSubViews;
}
@property (weak, nonatomic) IBOutlet UIImageView *leftFace;
@property (weak, nonatomic) IBOutlet UIImageView *rightFace;
@property (weak, nonatomic) IBOutlet UILabel *affinityLabel;
@property (weak, nonatomic) IBOutlet UIImageView *leftCameraView;
@property (weak, nonatomic) IBOutlet UIImageView *rightCameraView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *leftSpinner;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *rightSpinner;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)faceRecognized:(UIImage *)image feature:(CIFaceFeature *)feature;
- (void)recognitionError;
- (void)compute;
- (void)drawPoints:(CGPoint[3])points faceWidth:(float)faceWidth withColor:(UIColor *)color side:(int)side;

+ (UIImage*)imageWithImage:(UIImage*)image 
              scaledToSize:(CGSize)newSize;
@end
