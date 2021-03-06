//
//  ADViewPhotoViewController.m
//  AVFoundationCamera
//
//  Created by 陈 爱彬 on 13-10-8.
//  Copyright (c) 2013年 陈 爱彬. All rights reserved.
//

#import "ADViewPhotoViewController.h"
#import "UIImage+OpenCV.h"

#import "opencv2/opencv.hpp"
#import "ADContours.h"
#import "ADPreviewView.h"
@interface ADViewPhotoViewController ()
@property(nonatomic,strong)UIImageView *photoImageView;
@property(nonatomic,strong)ADPreviewView *drawView;
@end

@implementation ADViewPhotoViewController
@synthesize photoImage = _photoImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //预览图片
    NSLog(@"图片宽高%f,%f",_photoImage.size.width,_photoImage.size.height);
    self.photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _photoImage.size.width/3.38, _photoImage.size.height/3.38)];
    _photoImageView.image = _photoImage;
    [self.view addSubview:_photoImageView];
    
    
    self.drawView = [[ADPreviewView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.frame.size.height)];
    _drawView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:_drawView];
    
    // Do any additional setup after loading the view.
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    backBtn.frame = CGRectMake(10, 10, 100, 100);
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backToCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    UIButton *processBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    processBtn.frame = CGRectMake(backBtn.frame.origin.x + backBtn.frame.size.width + 50, backBtn.frame.origin.y, 100, 100);
    [processBtn setTitle:@"矫正" forState:UIControlStateNormal];
    [processBtn addTarget:self action:@selector(processImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:processBtn];
    
    UIImageWriteToSavedPhotosAlbum(_photoImage, self, nil, NULL);
    
}

- (void)backToCamera
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)processImage
{
    UIImage *processImage = [self getDesimageWithTransformFromSourceImage:_photoImage];
    
    UIImageWriteToSavedPhotosAlbum(processImage, self, nil, NULL);

    
//    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
//                                                                imageDataSampleBuffer,
//                                                                kCMAttachmentMode_ShouldPropagate);
//    
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    NSLog(@"SCATTO: Inizio salvataggio in library...");
//    [library writeImageToSavedPhotosAlbum:[processImage CGImage] metadata:exifAttachments_dictionary completionBlock:^(NSURL *newURL, NSError *error) {
//        if (error){
//            NSLog(@"SCATTO: Salvataggio in library: ERRORE");
//        } else {
//            NSLog(@"SCATTO: Salvataggio in library: OK");
//            [self loadNewestPhoto];
//        }
//    }];
    
    NSLog(@"pro %f, %f", processImage.size.width, processImage.size.height);
    _photoImageView.frame = CGRectMake((self.view.bounds.size.width - processImage.size.width/3.38)/2, (self.view.bounds.size.height - processImage.size.height/3.38)/2,processImage.size.width/3.38 ,processImage.size.height/3.38);
    _photoImageView.image = processImage;
    
}
- (UIImage *)getDesimageWithTransformFromSourceImage:(UIImage *)srcImage
{
    using namespace cv;
    
    int lowThreshold = 100;
    int ratio = 3;
    int kernel_size = 3;
    
    // 转换图像格式，这时候图像被旋转90度
    Mat srcFrmae = [srcImage CVMat2];
    
    //    NSLog(@"yuanshi size: %f, %f , %f, %f", resultImage2.size.width, resultImage2.size.height, srcImage.size.width, srcImage.size.height);

    Mat grayFrame,output,lastFrame, largeFrame, tempFrame;
    
    NSLog(@"yuanshi size: %f, %f , %d, %d", srcImage.size.width, srcImage.size.height, srcFrmae.size().width, srcFrmae.size().height);
    
    
    //图像旋转90度，变正
    transpose(srcFrmae,tempFrame);
    flip(tempFrame,largeFrame,1);
    
    NSLog(@"bianhua size: %d, %d , %d, %d", largeFrame.size().width, largeFrame.size().height, srcFrmae.size().width, srcFrmae.size().height);
    
    //把图像缩小，用来做轮廓检测
    resize(largeFrame, lastFrame, cv::Size(320,568));
    
    //打印图像尺寸
    //  Convert captured frame to grayscale  灰度图
    cvtColor(lastFrame, grayFrame,COLOR_RGB2GRAY);
    
    //使用Canny算法进行边缘检测,返回图像即是二值单通道的图
    Canny(grayFrame, output,
          lowThreshold,
          lowThreshold * ratio,
          kernel_size);
    
    //使用 findContours 找轮廓
    vector<vector<cv::Point>> contours;
    findContours(output, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    
    double area, maxArea = 0;
    int maxIdx = 0;
    
    for( int i = 0; i< contours.size(); i++ )
    {
        
        //找到面积最大的
        area = fabs(contourArea(contours[i]));
        if(area > maxArea)
        {
            maxIdx = i;
            maxArea = area;
        }
    }
    
    vector<cv::Point> approxCurve;
    //将vector转换成Mat型，此时的Mat还是列向量，只不过是2个通道的列向量而已
    Mat contourMat = Mat(contours[maxIdx]);
    double eps = contours[maxIdx].size() * 0.05;
    approxPolyDP(contourMat, approxCurve, eps, YES);
    
    NSLog(@"多边形逼近后的顶点数是%ld %f",approxCurve.size(), eps);
    if (approxCurve.size() != 4)
    {
        return nil;
    }
    
    cv::Point2f src[4];
    cv::Point2f dst[4];
    cv::Point2f lin[4];
    Point2f lines[4];
    Point2f ends[2];
    
    //将找到的顶点存入缓存
    for(int i=0; i<4; i++)
    {
        src[i] = approxCurve[i];
        NSLog(@"啦啦啦啦逼近的四个顶点分别是%d %d",approxCurve[i].x,approxCurve[i].y);
        
    }
    
    //计算各边的长度
    float agl[4] = {0}, offset = 0, maxOffset = 0;
    
    for(int i = 0;i < 4;i++){
        agl[i] = [self angle:src[i] second:src[(i+1)%4] third:src[(i+2)%4]];
        NSLog(@"------------angle: %f", agl[i]);
        
        offset += abs(agl[i] - 90);
        
        if (abs(agl[i] - 90) > maxOffset) {
            maxOffset = abs(agl[i] - 90);
        }
        
        
        
    }
    
    
    
    offset /= 4;
    
    
    
    //计算各边的长度
    float a[4] = {0};
    
    for(int i = 0;i < 4;i++){
        a[i] = ceilf([self distanceFromPointX:src[i] distanceToPointY:src[(i + 1)%4]]);
    }
    
    float averageDistance1 = (a[0] + a[2])/2;
    float averageDistance2 = (a[1] + a[3])/2;
    
    //寻找左上角顶点
    if (averageDistance1 < averageDistance2) {
        if ((src[0].y + src[1].y) < (src[2].y + src[3].y)) {
            
            if (src[0].x < src[1].x) {
                lin[0] = src[0];
                lin[1] = src[1];
                lin[2] = src[2];
                lin[3] = src[3];
                
            }
            else{
                lin[0] = src[1];
                lin[1] = src[0];
                lin[2] = src[3];
                lin[3] = src[2];
                
            }
        }
        
        else{
            
            if (src[2].x < src[3].x) {
                lin[0] = src[2];
                lin[1] = src[3];
                lin[2] = src[0];
                lin[3] = src[1];
                
            }
            else{
                lin[0] = src[3];
                lin[1] = src[2];
                lin[2] = src[1];
                lin[3] = src[0];
                
            }
            
        }
        
    }
    
    else {
        if ((src[0].y + src[3].y) < (src[1].y + src[2].y)) {
            if (src[0].x < src[3].x) {
                lin[0] = src[0];
                lin[1] = src[3];
                lin[2] = src[2];
                lin[3] = src[1];
                
            }
            else{
                lin[0] = src[3];
                lin[1] = src[0];
                lin[2] = src[1];
                lin[3] = src[2];
                
            }
            
        }
        else{
            
            if (src[1].x < src[2].x) {
                lin[0] = src[1];
                lin[1] = src[2];
                lin[2] = src[3];
                lin[3] = src[0];
                
            }
            else{
                lin[0] = src[2];
                lin[1] = src[1];
                lin[2] = src[0];
                lin[3] = src[3];
                
            }
            
        }
        
        
    }
    
    //从缩略图的坐标系转到正常大小
    lin[0].x =ceilf(lin[0].x * 3.38) ;
    lin[0].y = ceilf(lin[0].y * 3.38);
    
    lin[1].x = ceilf(lin[1].x * 3.38) ;
    lin[1].y = ceilf(lin[1].y * 3.38) ;
    
    lin[2].x = ceilf(lin[2].x * 3.38);
    lin[2].y = ceilf(lin[2].y * 3.38);
    
    lin[3].x = ceilf(lin[3].x * 3.38) ;
    lin[3].y = ceilf(lin[3].y * 3.38) ;
    
    //计算长边和短边
    float b[4] = {0};
    
    for(int i = 0;i < 4;i++){
        
        agl[i] = [self angle:lin[i] second:lin[(i+1)%4] third:lin[(i+2)%4]];
        NSLog(@"------------angle: %f", agl[i]);
        
        NSLog(@"行的顶点分别是  %f  %f  %f",lin[i].x,lin[i].y ,agl[i]);
        
        
        //计算直线方程
        lines[i] = [self linearEquation:lin[i] with:lin[(i+1)%4]];
    }
    
    Point2f newLines[2], newPoints[2], newEnds[2];
    
    NSLog(@"消失点！！！！");
    
    ends[0] = [self endPoint:lines[0] with:lines[2]];
    ends[1] = [self endPoint:lines[1] with:lines[3]];
    
    //球两个消失点
    if (ends[0].x > lin[0].x) {
        newEnds[0].x = lin[0].x + 1920;
    }else{
        newEnds[0].x = lin[0].x - 1920;
    }
    newEnds[0].y = lin[0].y;
    
    if (ends[1].y > lin[0].y) {
        newEnds[1].y = lin[0].y + 1920;
    }else{
        newEnds[1].y = lin[0].y - 1920;
    }
    newEnds[1].x = lin[0].x;
    
    
    
    newLines[0] = [self linearEquation:lin[0] with:newEnds[0]];
    newLines[1] = [self linearEquation:lin[0] with:newEnds[1]];
    
    newPoints[0] = [self endPoint:newLines[0] with:lines[1]];
    newPoints[1] = [self endPoint:newLines[1] with:lines[2]];
    
    
    float longSide, shortSide;
    
    shortSide = ceilf([self distanceFromPointX:lin[0] distanceToPointY:newPoints[0]]);
    longSide = ceilf([self distanceFromPointX:lin[0] distanceToPointY:newPoints[1]]);
    
    NSLog(@"-----长边 %f 短边 %f 比例 %f", longSide, shortSide, longSide/shortSide);
    
    for(int i = 0;i < 4;i++){
        b[i] = [self distanceFromPointX:lin[i] distanceToPointY:lin[(i + 1)%4]];
        
        NSLog(@"---------边长 %f", b[i]);
        
    }
    
    float averageDistance3 = ceilf((b[0] + b[2])/2);
    float averageDistance4 = ceilf((b[1] + b[3])/2);
    
    NSLog(@"---------angle %f side %f %f rate %f", agl[3], b[2], b[3], b[2]/b[3 ]);
    
    NSLog(@"---------offset %f", offset);
    
    NSLog(@"---------max offset %f", maxOffset);
    
    NSLog(@"---------rate %f", averageDistance4/averageDistance3);
    
    NSLog(@"---------e %f", powf(averageDistance4/averageDistance3 - 0.63183, 1/offset));
    
    float ce = powf(1.008 + offset/1000 - 2*sqrtf(maxOffset)/1000, offset);
    
    NSLog(@"---------ce %f", ce);
    
    NSLog(@"---------a %f", averageDistance4/averageDistance3 - ce);
    
    averageDistance4 = averageDistance3* (1 + averageDistance4/averageDistance3 - ce);
    
    //计算正矩形
    dst[0].x = lin[0].x;
    dst[0].y = lin[0].y;
    
    dst[1].x = lin[0].x + averageDistance3  ;
    dst[1].y = lin[0].y ;
    
    dst[2].x = dst[1].x;
    dst[2].y = dst[1].y  + averageDistance4 ;
    
    dst[3].x = lin[0].x;
    dst[3].y = lin[0].y  + averageDistance4 ;
    
    for(int i = 0;i < 4;i++){
        
        NSLog(@"ahuanhuanhou 行的顶点分别是 %d  %f  %f",i, dst[i].x,dst[i].y);
    }
    
    //计算各边的长度
    
    for(int i = 0;i < 4;i++){
        agl[i] = [self angle:dst[i] second:dst[(i+1)%4] third:dst[(i+2)%4]];
        NSLog(@"------------angle: %f", agl[i]);
    }
    
    Mat dstImg;    //通过4个点得到变换矩阵,然后进行变换
//    Mat outImg;
    Mat warpMat = getPerspectiveTransform(lin,dst);
    
    NSLog(@"SIZE: %d, %d", largeFrame.size().width, largeFrame.size().height);
    warpPerspective(largeFrame, dstImg, warpMat, largeFrame.size());
    
    // cvLaplace(&dstImg, &outImg);
    
//        line(largeFrame, dst[0], dst[1], Scalar(255,0,0), 20);
//        line(largeFrame, dst[1], dst[2], Scalar(0,255,0), 20);
//        line(largeFrame, dst[2], dst[3], Scalar(0,0,255), 20);
//        line(largeFrame, dst[3], dst[0], Scalar(255,255,255), 20);
//    
//        line(largeFrame, lin[0], lin[1], Scalar(0,0,255), 20);
//        line(largeFrame, lin[1], lin[2], Scalar(0,0,255), 20);
//        line(largeFrame, lin[2], lin[3], Scalar(0,0,255), 20);
//        line(largeFrame, lin[3], lin[0], Scalar(0,0,255), 20);
    
    //裁剪ROI区域
    IplImage ipl_img = dstImg;
    cvSetImageROI(&ipl_img, cvRect(dst[0].x + 25, dst[0].y + 25, averageDistance3-50, averageDistance4-50));
    cvCreateImage(cvSize(averageDistance3-50,averageDistance4-50),ipl_img.depth,4);
    
    IplImage *dstOut = cvCreateImage(cvSize(averageDistance3-50, averageDistance4-50),ipl_img.depth,4);
    cvSetZero(dstOut);
    
    //    cvCopy(&ipl_img,dstOut);
    cvCopy(&ipl_img, dstOut);
    cvResetImageROI(&ipl_img);
    
    
    Mat outImage = dstOut;
    Mat temp;
    
    cvtColor(outImage, temp, COLOR_RGB2GRAY);
//
////    threshold(outImage, outImage, 100, 255, CV_THRESH_BINARY);
//    
//    morphologyEx(outImage,outImage,MORPH_CLOSE,Mat(3,3,CV_8U),Point2d(-1,-1),5);
//
////    dilate(outImage, outImage, Mat(3,3,CV_8U,cv::Scalar(1)), Point2d(-1,-1), 1);
//    erode(temp, temp, Mat(2,10,CV_8U,cv::Scalar(1)), Point2d(-1,-1), 2);
////
    Canny(temp, temp,
          1,
          500,
          3);
    
    
    vector<Vec4i> hhlines;
    HoughLinesP( temp, hhlines, 1, CV_PI/180, 50, 20);
    
    NSLog(@"hough find %zu", hhlines.size());
    
//    for( size_t i = 0; i < hhlines.size(); i++ )
//    {
//        line( outImage, Point2i(hhlines[i][0], hhlines[i][1]),
//             Point2i(hhlines[i][2], hhlines[i][3]), Scalar(255,255,255  ), 2 );
//    }
    
    
    //使用 findContours 找轮廓
//    vector<vector<cv::Point>> newContours;
//    findContours(temp, newContours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
//    
//    NSLog(@"COUNT %zu", newContours.size());
//    
////    vector<cv::Point> newApproxCurve;
////    
////    //将vector转换成Mat型，此时的Mat还是列向量，只不过是2个通道的列向量而
//    
//    for( int i = 0; i< contours.size(); i++ )
//    {
////        double eps2 = newContours[i].size() * 0.05;
////        approxPolyDP(newContours[i], newContours[i], eps2, YES);
//        
//        minAreaRect(newContours[i]);
//        
////        if (newContours[i].size() != 4) {
////            newContours.pop_back();
////        }
//    }
//    
//    drawContours(outImage, newContours, -1, Scalar(255), 2);
    
//    threshold(outImage, outImage, 50, 255, CV_THRESH_BINARY);
    
//    cvtColor(outImage, outImage, COLOR_RGB2GRAY);
//    threshold(outImage, outImage, 175, 255, CV_THRESH_BINARY);

    
//    dilate(outImage, outImage, Mat(3,3,CV_8U,cv::Scalar(1)), Point2d(-1,-1), 1);
    erode(outImage, outImage, Mat(16,2,CV_8U,cv::Scalar(1)), Point2d(-1,-1), 5);
    
    Canny(outImage, outImage,
          50,
          150,
          3);
    

    UIImage *resultImage = [UIImage imageWithCVMat:outImage];
    
    NSLog(@"bianlede size: %f, %f ", resultImage.size.width, resultImage.size.height);
    
    lastFrame.release();
    grayFrame.release();
    output.release();
    srcFrmae.release();
    outImage.release();
    dstImg.release();
    warpMat.release();
    largeFrame.release();
    tempFrame.release();
    
    contours.clear();
    
    
    return resultImage;
    
}

void UnsharpMask(const IplImage* src, IplImage* dst, float amount=80, float radius=5, uchar threshold=0, int contrast=100)
{
    if(!src)return ;
    
    int imagewidth = src->width;
    int imageheight = src->height;
    int channel = src->nChannels;
    
    IplImage* blurimage = cvCreateImage(cvSize(imagewidth,imageheight), src->depth, channel);
    IplImage* DiffImage = cvCreateImage(cvSize(imagewidth,imageheight), 8, channel);
    
    //原图的高对比度图像
    IplImage* highcontrast = cvCreateImage(cvSize(imagewidth,imageheight), 8, channel);
    AdjustContrast(src, highcontrast, contrast);
    
    //原图的模糊图像
    cvSmooth(src, blurimage, CV_GAUSSIAN, radius);
    
    //原图与模糊图作差
    for (int y=0; y<imageheight; y++)
    {
        for (int x=0; x<imagewidth; x++)
        {
            CvScalar ori = cvGet2D(src, y, x);
            CvScalar blur = cvGet2D(blurimage, y, x);
            CvScalar val;
            val.val[0] = abs(ori.val[0] - blur.val[0]);
            val.val[1] = abs(ori.val[1] - blur.val[1]);
            val.val[2] = abs(ori.val[2] - blur.val[2]);
            
            cvSet2D(DiffImage, y, x, val);
        }
    }
    
    //锐化
    for (int y=0; y<imageheight; y++)
    {
        for (int x=0; x<imagewidth; x++)
        {
            CvScalar hc = cvGet2D(highcontrast, y, x);
            CvScalar diff = cvGet2D(DiffImage, y, x);
            CvScalar ori = cvGet2D(src, y, x);
            CvScalar val;
            
            for (int k=0; k<channel; k++)
            {
                if (diff.val[k] > threshold)
                {
                    //最终图像 = 原始*(1-r) + 高对比*r
                    val.val[k] = ori.val[k] *(100-amount) + hc.val[k] *amount;
                    val.val[k] /= 100;
                }
                else
                {
                    val.val[k] = ori.val[k];
                }
            }
            cvSet2D(dst, y, x, val);
        }
    }
    cvReleaseImage(&blurimage);
    cvReleaseImage(&DiffImage);
}
//调整图像的对比度，contrast的范围[-255,255]
void AdjustContrast(const IplImage* src, IplImage* dst, int contrast)
{
    if (!src)return ;
    
    int imagewidth = src->width;
    int imageheight = src->height;
    int channel = src->nChannels;
    
    //求原图均值
    CvScalar mean = {0,0,0,0};
    for (int y=0; y<imageheight; y++)
    {
        for (int x=0; x<imagewidth; x++)
        {
            for (int k=0; k<channel; k++)
            {
                CvScalar ori = cvGet2D(src, y, x);
                for (int k=0; k<channel; k++)
                {
                    mean.val[k] += ori.val[k];
                }
            }
        }
    }
    for (int k=0; k<channel; k++)
    {
        mean.val[k] /= imagewidth * imageheight;
    }
    
    //调整对比度
    if (contrast <= -255)
    {
        //当增量等于-255时，是图像对比度的下端极限，此时，图像RGB各分量都等于阀值，图像呈全灰色，灰度图上只有1条线，即阀值灰度；
        for (int y=0; y<imageheight; y++)
        {
            for (int x=0; x<imagewidth; x++)
            {
                cvSet2D(dst, y, x, mean);
            }
        }
    }
    else if(contrast > -255 &&  contrast <= 0)
    {
        //(1)nRGB = RGB + (RGB - Threshold) * Contrast / 255
        // 当增量大于-255且小于0时，直接用上面的公式计算图像像素各分量
        //公式中，nRGB表示调整后的R、G、B分量，RGB表示原图R、G、B分量，Threshold为给定的阀值，Contrast为处理过的对比度增量。
        for (int y=0; y<imageheight; y++)
        {
            for (int x=0; x<imagewidth; x++)
            {
                CvScalar nRGB;
                CvScalar ori = cvGet2D(src, y, x);
                for (int k=0; k<channel; k++)
                {
                    nRGB.val[k] = ori.val[k] + (ori.val[k] - mean.val[k]) *contrast /255;
                }
                cvSet2D(dst, y, x, nRGB);
            }
        }
    }
    else if(contrast >0 && contrast <255)
    {
        //当增量大于0且小于255时，则先按下面公式(2)处理增量，然后再按上面公式(1)计算对比度：
        //(2)、nContrast = 255 * 255 / (255 - Contrast) - 255
        //公式中的nContrast为处理后的对比度增量，Contrast为给定的对比度增量。
        
        CvScalar nRGB;
        int nContrast = 255 *255 /(255 - contrast) - 255;
        
        for (int y=0; y<imageheight; y++)
        {
            for (int x=0; x<imagewidth; x++)
            {
                CvScalar ori = cvGet2D(src, y, x);
                for (int k=0; k<channel; k++)
                {
                    nRGB.val[k] = ori.val[k] + (ori.val[k] - mean.val[k]) *nContrast /255;
                }
                cvSet2D(dst, y, x, nRGB);
            }
        }
    }
    else
    {
        //当增量等于 255时，是图像对比度的上端极限，实际等于设置图像阀值，图像由最多八种颜色组成，灰度图上最多8条线，
        //即红、黄、绿、青、蓝、紫及黑与白；
        for (int y=0; y<imageheight; y++)
        {
            for (int x=0; x<imagewidth; x++)
            {
                CvScalar rgb;
                CvScalar ori = cvGet2D(src, y, x);
                for (int k=0; k<channel; k++)
                {
                    if (ori.val[k] > mean.val[k])
                    {
                        rgb.val[k] = 255;
                    }
                    else
                    {
                        rgb.val[k] = 0;
                    }
                }
                cvSet2D(dst, y, x, rgb);
            }
        }
    }
}



#pragma mark - 对四个点进行处理
- (void)processFourvertexsWith
{
    
}
#pragma mark - 计算两个坐标点之间的距离
-(float)distanceFromPointX:(cv::Point2f )start distanceToPointY:(cv::Point2f)end{
    float distance;
    CGFloat xDist = (end.x - start.x);
    CGFloat yDist = (end.y - start.y);
    distance = sqrt((xDist * xDist) + (yDist * yDist));
    return distance;
}

-(float)angle:(cv::Point2f)first second:(cv::Point2f)second third:(cv::Point2f)third
{
    double cosfi = 0, fi = 0, norm = 0, pi = 3.141592653589793;
    double dsx = first.x - second.x;
    double dsy = first.y - second.y;
    double dex = third.x - second.x;
    double dey = third.y - second.y;
    cosfi = dsx * dex + dsy * dey;
    norm = (dsx * dsx + dsy * dsy) * (dex * dex + dey * dey);
    cosfi /= sqrt(norm);
    if (cosfi >= 1.0) return 0;
    if (cosfi <= -1.0) return pi;
    fi = acos(cosfi);
    if (180 * fi / pi < 180)
    {
        return 180 * fi / pi;
    }
    else
    {
        return 360 - 180 * fi / pi;
    }
}

-(cv::Point2f)linearEquation:(cv::Point2f)p1 with:(cv::Point2f)p2{
    
    cv::Point2f res;
    
    if (p1.x == p2.x) {
        res.x = p1.x;
        res.y = 0;
    }else{
        //球斜率
        res.x = (p1.y - p2.y)/(p1.x - p2.x);
        
        
        //球截距
        res.y = p1.y - res.x * p1.x;
    }
    
    
    
    NSLog(@"----斜率 %f 截距 %f", res.x, res.y);
    return res;
    
}

-(cv::Point2f)endPoint:(cv::Point2f)p1 with:(cv::Point2f)p2{
    
    cv::Point2f res;
    
    if (p1.y == 0) {
        res.x = p1.x;
        res.y = p2.x*res.x + p2.y;
    }else if(p2.y == 0){
        res.x = p2.x;
        res.y = p1.x*res.x + p1.y;
    }else{
        //球x
        res.x = (p1.y - p2.y)/(p2.x - p1.x);
        
        //球y
        res.y = p1.x*res.x + p1.y;
    }
    
    
    
    NSLog(@"----x %f y %f", res.x, res.y);
    return res;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
