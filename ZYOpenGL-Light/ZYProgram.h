//
//  ZYProgram.h
//  ZYOpenGL-Light
//
//  Created by wpsd on 2017/8/22.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ZYProgram : NSObject

@property (assign, nonatomic) GLuint positionLoc;

+ (instancetype)programWithVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

- (void)use;
- (GLuint)attributeLocWithName:(const GLchar *)name;
- (GLuint)uniformLocWithName:(const GLchar *)name;

- (void)setVec3WithName:(const GLchar *)name v1:(GLfloat)v1 v2:(GLfloat)v2 v3:(GLfloat)v3;
- (void)setMatrix4WithName:(const GLchar *)name mat4:(GLKMatrix4)mat4;
- (void)setFloatWithName:(const GLchar *)name value:(float)value;
- (void)setIntWithName:(const GLchar *)name value:(int)value;

@end
