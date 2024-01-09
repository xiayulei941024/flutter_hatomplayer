#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <Flutter/Flutter.h>

typedef void(^FrameUpdateCallback)(void);

@interface HatomOpenGLYUV : NSObject<FlutterTexture>
/// 初始化参数
- (instancetype)initWithSize:(CGSize)size
         frameUpdateCallback:(FrameUpdateCallback)callback;
/// 从原始数据里取出YUV数据，渲染到纹理
- (void)dataWithData:(void *)data
               width:(CGFloat)width
               heigh:(CGFloat)height;
/// 释放纹理
- (void)dispose;

@end
