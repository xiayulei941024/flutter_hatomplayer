#import "HatomOpenGLYUV.h"
#import <stdatomic.h>
#import <libkern/OSAtomic.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>


#define FSH @"varying lowp vec2 TexCoordOut;\
\
uniform sampler2D SamplerY;\
uniform sampler2D SamplerU;\
uniform sampler2D SamplerV;\
\
void main(void)\
{\
mediump vec3 yuv;\
lowp vec3 rgb;\
\
yuv.x = texture2D(SamplerY, TexCoordOut).r;\
yuv.y = texture2D(SamplerU, TexCoordOut).r - 0.5;\
yuv.z = texture2D(SamplerV, TexCoordOut).r - 0.5;\
\
rgb = mat3( 1,       1,         1,\
0,       -0.39465,  2.03211,\
1.13983, -0.58060,  0) * yuv;\
\
gl_FragColor = vec4(rgb, 1);\
\
}"

#define VSH @"attribute vec4 position;\
attribute vec2 TexCoordIn;\
varying vec2 TexCoordOut;\
\
void main(void)\
{\
gl_Position = position;\
TexCoordOut = TexCoordIn;\
}"

enum AttribEnum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE,
    ATTRIB_COLOR,
};

enum TextureType
{
    TEXY = 0,
    TEXU,
    TEXV,
    TEXC
};

@interface HatomOpenGLYUV()
{
    FrameUpdateCallback      _callback;
    GLuint                  _framebuffer;
    
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef      _texture;
    CVPixelBufferRef          _target;
//    CGSize                    _contentSize;
    
    GLuint                  _renderBuffer;
    
    GLuint                  _program;
    
    GLuint                  _textureYUV[3];
    
    GLuint                  _videoW;
    
    GLuint                  _videoH;
}

@property (nonatomic, strong)  EAGLContext             *glContext;
@property (nonatomic, assign)  GLsizei                 viewScale;
@property (nonatomic, assign)  CGSize                 contentSize;
// 初始化纹理参数
- (void)setupYUVTexture;

- (BOOL)createFrameAndRenderBuffer;

- (void)destoryFrameAndRenderBuffer;
/// 加载着色器
- (void)loadShader;

- (GLuint)compileShader:(NSString*)shaderCode withType:(GLenum)shaderType;

- (void)render;

@end

@implementation HatomOpenGLYUV

- (instancetype)initWithSize:(CGSize)size
         frameUpdateCallback:(FrameUpdateCallback)callback {
    if (self = [super init]) {
        _callback = callback; // 初始视频帧回调
        _contentSize = size; // 默认视频画面宽高
    }
    return self;
}

- (void)doInit {
    // 1.创建OpenGL ES上下文，类型指定为OpenGL ES 2.0
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(!_glContext) return;
    // 2.把创建的OpenGL ES上下文 设置为当前的上下文
    BOOL isSuccess = [EAGLContext setCurrentContext:_glContext];
    if(!isSuccess) return;
    
    // 初始化纹理参数
    [self setupYUVTexture];
    /// 加载着色器
    [self loadShader];
    // 创建用于存放纹理的缓冲区
    [self createCVBufferWith:&_target withOutTexture:&_texture];
    // 修改像素保存时对齐的方式
    glPixelStorei(GL_UNPACK_ALIGNMENT, 2);
    // 使用程序对象作为当前渲染状态的一部分
    glUseProgram(_program);
    // 返回一个整数，表示程序对象中特定统一变量的位置
    GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
    GLuint textureUniformU = glGetUniformLocation(_program, "SamplerU");
    GLuint textureUniformV = glGetUniformLocation(_program, "SamplerV");
    // 给片段着色器中的uniform sampler2D 修饰的纹理变量赋值，只有该函数调用后,片元着色器中的texture2D()函数才能正确工作
    glUniform1i(textureUniformY, 0);
    glUniform1i(textureUniformU, 1);
    glUniform1i(textureUniformV, 2);
    [self initGLView];
}

- (CVPixelBufferRef)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _target;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_target)) {
        pixelBuffer = _target;
    }
    return pixelBuffer;
}

#pragma mark - 对外接口
/// 从原始数据里取出YUV数据，渲染到纹理
- (void)inputActualYUVData:(void *)data
                     width:(GLsizei)w
                    height:(GLsizei)h {
    @synchronized(self) {
        if (w != _videoW || h != _videoH) {
            [self doInit];
            [self inputResolutionWidth:w height:h];
        }
        [EAGLContext setCurrentContext:_glContext];
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_RED_EXT, GL_UNSIGNED_BYTE, data);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w/2, h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, data + w * h *5/4);

        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w/2, h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, data + w * h);
        [self render];
    }
}

- (void)inputResolutionWidth:(GLuint)width height:(GLuint)height
{
    _videoW = width;
    _videoH = height;
    void *blackData = malloc(width * height * 1.5);
    if(blackData)
        //bzero(blackData, width * height * 1.5);
        memset(blackData, 0x0, width * height * 1.5);
    [EAGLContext setCurrentContext:_glContext];
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height*5 /4);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height);
    free(blackData);
}

// 创建一块专门用于存放纹理的缓冲区(由CMMemoryPoolRef负责管理)，这样每次应用端传递纹理像素数据给GPU时，直接使用这个缓冲区中的内存，而不用重新创建。避免了重复创建，提高了效率。
- (void)createCVBufferWith:(CVPixelBufferRef *)target
            withOutTexture:(CVOpenGLESTextureRef *)texture {
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _glContext, NULL, &_textureCache);
    if (err) {
        return;
    }
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVPixelBufferCreate(kCFAllocatorDefault, self.contentSize.width, _contentSize.height, kCVPixelFormatType_32BGRA, attrs, target);
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, *target, NULL, GL_TEXTURE_2D, GL_RGBA, _contentSize.width, _contentSize.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, texture);
    CFRelease(empty);
    CFRelease(attrs);
}

- (void)clearUIView {
    [EAGLContext setCurrentContext:_glContext];
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)dispose {
    [self clearUIView];
//    CVPixelBufferRelease(_target);
}

#pragma mark - YUVTexture
/// 初始化纹理参数
- (void)setupYUVTexture {
    if (_textureYUV[TEXY]) {
        glDeleteTextures(3, _textureYUV);
    }
    // 为这3个纹理指定了3个不同的ID
    glGenTextures(3, _textureYUV);
    if (!_textureYUV[TEXY] || !_textureYUV[TEXU] || !_textureYUV[TEXV]) {
        return;
    }
    // 绑定纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    // 图象从纹理图象空间映射到帧缓冲图象空间(映射需要重新构造纹理图像,这样就会造成应用到多边形上的图像失真),这时就可用glTexParmeteri()函数来确定如何把纹理象素映射成像素
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)render {
    [EAGLContext setCurrentContext:_glContext];
    CGSize size = self.contentSize;
    glViewport(1, 1, size.width*_viewScale-2, size.height*_viewScale-2);
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat coordVertices[] = {
        
        0.0f,  0.0f,
        1.0f,  0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, 0, 0, coordVertices);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glFlush();
    if (_callback) {
        _callback();
    }
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

/// 从原始数据里取出YUV数据，渲染到纹理
- (void)dataWithData:(void *)data
               width:(CGFloat)width
               heigh:(CGFloat)height {
    unsigned char *a =  (unsigned char *)data;
    _contentSize = CGSizeMake(width, height);
    [self inputActualYUVData:a width:width height:height];
}

- (void)initGLView {
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized(self) {
            [EAGLContext setCurrentContext:weakSelf.glContext];
            [weakSelf destoryFrameAndRenderBuffer];
            // 绘图区域和创建缓冲区
            [weakSelf createFrameAndRenderBuffer];
        }
        
        // 绘图区域
        glViewport(1, 1, weakSelf.contentSize.width*weakSelf.viewScale - 2, weakSelf.contentSize.height*weakSelf.viewScale - 2);
    });
}

/// 绘图区域和创建缓冲区
- (BOOL)createFrameAndRenderBuffer {
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    // 将纹理附加到帧缓冲区上
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture), 0);
    
    glViewport(0, 0, _contentSize.width, _contentSize.height);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    }
    return YES;
}

- (void)destoryFrameAndRenderBuffer {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
    }
    
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    
    _framebuffer = 0;
    _renderBuffer = 0;
}

/// 加载着色器
- (void)loadShader {
    
    GLuint vertexShader = [self compileShader:VSH withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:FSH withType:GL_FRAGMENT_SHADER];
    
    _program = glCreateProgram();
    // 将着色器对象附加到program对象
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    // 将通用顶点属性索引与命名属性变量相关联
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXTURE, "TexCoordIn");
    // 连接一个program对象
    glLinkProgram(_program);
    
    GLint linkSuccess;
    // 从program对象返回一个参数的值
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
    }
    if (vertexShader)
        glDeleteShader(vertexShader);
    if (fragmentShader)
        glDeleteShader(fragmentShader);
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType {
    if (!shaderString) {
        exit(1);
    }
    GLuint shaderHandle = glCreateShader(shaderType);
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        exit(1);
    }
    return shaderHandle;
}

@end

