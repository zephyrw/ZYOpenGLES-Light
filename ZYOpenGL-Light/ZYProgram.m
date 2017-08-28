//
//  ZYProgram.m
//  ZYOpenGL-Light
//
//  Created by wpsd on 2017/8/22.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ZYProgram.h"
#import "GLESUtils.h"

@interface ZYProgram ()

@property (assign, nonatomic) GLuint programID;

@end


@implementation ZYProgram

+ (instancetype)programWithVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString {
    return [[self alloc] initWithVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString];
}

- (instancetype)initWithVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString
{
    self = [super init];
    if (self) {
        self.programID = [GLESUtils loadProgramWithVertexShaderString:vertexShaderString withFragmentShaderString:fragmentShaderString];
    }
    return self;
}

- (void)use {
    
    glUseProgram(self.programID);
    
}

- (GLuint)positionLoc {
    
    return glGetAttribLocation(_programID, "position");
    
}

- (GLuint)attributeLocWithName:(const GLchar *)name {
    
    return glGetAttribLocation(_programID, name);
    
}

- (GLuint)uniformLocWithName:(const GLchar *)name {
    
    return glGetUniformLocation(_programID, name);
    
}

- (void)setVec3WithName:(const GLchar *)name v1:(GLfloat)v1 v2:(GLfloat)v2 v3:(GLfloat)v3 {
    
    GLuint loc = glGetUniformLocation(_programID, name);
    glUniform3f(loc, v1, v2, v3);
    
}

- (void)setMatrix4WithName:(const GLchar *)name mat4:(GLKMatrix4)mat4 {
    
    GLuint loc = glGetUniformLocation(_programID, name);
    glUniformMatrix4fv(loc, 1, GL_FALSE, mat4.m);
    
}

- (void)setFloatWithName:(const GLchar *)name value:(float)value {
    
    GLuint loc = glGetUniformLocation(_programID, name);
    glUniform1f(loc, value);
    
}

- (void)setIntWithName:(const GLchar *)name value:(int)value {
    
    GLuint loc = glGetUniformLocation(_programID, name);
    glUniform1i(loc, value);
    
}

- (GLuint)genTextureWithImageName:(NSString *)imageName {
    UIImage *img = [UIImage imageNamed:imageName];
    if (!img) {
        NSLog(@"Failed to load image");
    }
    // 将图片数据以RGBA的格式导出到textureData中
    CGImageRef imageRef = [img CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    GLubyte *textureData = (GLubyte *)malloc(width * height * 4);
    
    //    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(textureData, width, height,
                                                 bitsPerComponent, bytesPerRow, CGImageGetColorSpace(imageRef),
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // 生成纹理
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return texture;
}

@end
