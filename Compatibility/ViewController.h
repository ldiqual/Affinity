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
}
@property (weak, nonatomic) IBOutlet UIImageView *leftFace;
@property (weak, nonatomic) IBOutlet UIImageView *rightFace;
- (IBAction)cameraPress:(id)sender;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)faceRecognized:(UIImage *)image feature:(CIFaceFeature *)feature;
- (void)recognitionError;
- (void)compute;
- (void)drawTriangle:(CGPoint[3])points faceWidth:(float)faceWidth withColor:(UIColor *)color;

+ (UIImage*)imageWithImage:(UIImage*)image 
              scaledToSize:(CGSize)newSize;
@end
