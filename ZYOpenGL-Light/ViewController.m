//
//  ViewController.m
//  ZYOpenGL-Light
//
//  Created by wpsd on 2017/8/22.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/EAGL.h>
#import "ZYProgram.h"
#import "Const.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ViewController ()

@property (strong, nonatomic) EAGLContext *glContext;
@property (strong, nonatomic) ZYProgram *boxProgram;
@property (strong, nonatomic) ZYProgram *lightProgram;
@property (strong, nonatomic) GLKTextureInfo *boxTextureInfo;
@property (strong, nonatomic) GLKTextureInfo *specTextureInfo;
@property (assign, nonatomic) GLuint boxTexture;
@property (assign, nonatomic) GLuint specTexture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupContext];
    [self setupVertext];
    
}

- (void)setupContext {
    
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.glContext) {
        NSLog(@"Failed to create openGL context");
        return;
    }
    
    [EAGLContext setCurrentContext:self.glContext];
    
    GLKView *glView = (GLKView *)self.view;
    glView.context = self.glContext;
    glView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    glEnable(GL_DEPTH_TEST);
    
}

- (void)setupVertext {
    
    self.boxProgram = [ZYProgram programWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
    self.lightProgram = [ZYProgram programWithVertexShaderString:vertexShaderString fragmentShaderString:lightFragmentShaderString];
    
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(boxVertices), boxVertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(self.boxProgram.positionLoc, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GL_FLOAT), (GLvoid *)0);
    glEnableVertexAttribArray(self.boxProgram.positionLoc);
    
    GLuint normalLoc = [self.boxProgram attributeLocWithName:"normal"];
    glVertexAttribPointer(normalLoc, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GL_FLOAT), (GLvoid *)(3 * sizeof(GL_FLOAT)));
    glEnableVertexAttribArray(normalLoc);
    
    GLuint texCoordsLoc = [self.boxProgram attributeLocWithName:"texCoords"];
    glVertexAttribPointer(texCoordsLoc, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GL_FLOAT), (GLvoid *)(6 * sizeof(GL_FLOAT)));
    glEnableVertexAttribArray(texCoordsLoc);
    
    glVertexAttribPointer(self.lightProgram.positionLoc, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GL_FLOAT), (GLvoid *)0);
    glEnableVertexAttribArray(self.boxProgram.positionLoc);
    
    NSError *boxError = nil;
    self.boxTextureInfo = [GLKTextureLoader textureWithCGImage:[UIImage imageNamed:@"container2"].CGImage
                                                       options:@{GLKTextureLoaderOriginBottomLeft : @(YES)}
                                                         error:&boxError];
    if (boxError) {
            NSLog(@"Failed to load box texture: %@", boxError);
    }
    
    NSError *specError = nil;
    self.specTextureInfo = [GLKTextureLoader textureWithCGImage:[UIImage imageNamed:@"container2_specular"].CGImage
                                                        options:@{GLKTextureLoaderOriginBottomLeft : @(YES)}
                                                          error:&specError];
    if (specError) {
        NSLog(@"Failed to load specular texture: %@", specError);
    }
    
//    self.boxTexture = [self genTextureWithImageName:@"container2"];
//    self.specTexture = [self genTextureWithImageName:@"container2_specular"];

    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0.1, 0.1, 0.1, 0.1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.boxProgram use];
    [self.boxProgram setVec3WithName:"lightColor"  v1:1.0 v2:1.0 v3:1.0];
    [self.boxProgram setVec3WithName:"objectColor" v1:1.0 v2:0.5 v3:0.31];
    
    GLKMatrix4 projection = GLKMatrix4MakePerspective(M_PI_4, SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100.0);
    [self.boxProgram setMatrix4WithName:"projection" mat4:projection];
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    float camX = sin(currentTime) * 10;
    float camZ = cos(currentTime) * 10;
    GLKVector3 viewPos = GLKVector3Make(camX, 0.0, camZ);
    GLKMatrix4 viewMat = GLKMatrix4MakeLookAt(viewPos.x, viewPos.y, viewPos.z, 0, 0, 0, 0, 1, 0);
    [self.boxProgram setMatrix4WithName:"view" mat4:viewMat];
    
//    GLKMatrix4 boxModel = GLKMatrix4MakeRotation(0, 1, 1, 1);
//    boxModel = GLKMatrix4Scale(boxModel, 2, 2, 2);
//    [self.boxProgram setMatrix4WithName:"model" mat4:boxModel];
    
    [self.boxProgram setVec3WithName:"viewPos" v1:viewPos.y v2:viewPos.y v3:viewPos.z];
    [self.boxProgram setFloatWithName:"material.shininess" value:16.0];
    
    // directional light
    [self.boxProgram setVec3WithName:"dirLight.direction" v1: -0.2 v2: -1.0 v3: -0.3];
    [self.boxProgram setVec3WithName:"dirLight.direction" v1: -0.2f v2: -1.0f v3: -0.3f];
    [self.boxProgram setVec3WithName:"dirLight.ambient" v1: 0.05f v2: 0.05f v3: 0.05f];
    [self.boxProgram setVec3WithName:"dirLight.diffuse" v1: 0.4f v2: 0.4f v3: 0.4f];
    [self.boxProgram setVec3WithName:"dirLight.specular" v1: 0.5f v2: 0.5f v3: 0.5f];
    // point light 1
    [self.boxProgram setVec3WithName:"pointLights[0].position" v1:pointLightPos[0] v2:pointLightPos[1] v3:pointLightPos[2]];
    [self.boxProgram setVec3WithName:"pointLights[0].ambient" v1: 0.05f v2: 0.05f v3: 0.05f];
    [self.boxProgram setVec3WithName:"pointLights[0].diffuse" v1: 0.8f v2: 0.8f v3: 0.8f];
    [self.boxProgram setVec3WithName:"pointLights[0].specular" v1: 1.0f v2: 1.0f v3: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[0].constant" value: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[0].linear" value: 0.09];
    [self.boxProgram setFloatWithName:"pointLights[0].quadratic" value: 0.032];
    // point light 2
    [self.boxProgram setVec3WithName:"pointLights[0].position" v1:pointLightPos[3] v2:pointLightPos[4] v3:pointLightPos[5]];
    [self.boxProgram setVec3WithName:"pointLights[1].ambient" v1: 0.05f v2: 0.05f v3: 0.05f];
    [self.boxProgram setVec3WithName:"pointLights[1].diffuse" v1: 0.8f v2: 0.8f v3: 0.8f];
    [self.boxProgram setVec3WithName:"pointLights[1].specular" v1: 1.0f v2: 1.0f v3: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[1].constant" value: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[1].linear" value: 0.09];
    [self.boxProgram setFloatWithName:"pointLights[1].quadratic" value: 0.032];
    // point light 3
    [self.boxProgram setVec3WithName:"pointLights[0].position" v1:pointLightPos[6] v2:pointLightPos[7] v3:pointLightPos[8]];
    [self.boxProgram setVec3WithName:"pointLights[2].ambient" v1: 0.05f v2: 0.05f v3: 0.05f];
    [self.boxProgram setVec3WithName:"pointLights[2].diffuse" v1: 0.8f v2: 0.8f v3: 0.8f];
    [self.boxProgram setVec3WithName:"pointLights[2].specular" v1: 1.0f v2: 1.0f v3: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[2].constant" value: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[2].linear" value: 0.09];
    [self.boxProgram setFloatWithName:"pointLights[2].quadratic" value: 0.032];
    // point light 4
    [self.boxProgram setVec3WithName:"pointLights[0].position" v1:pointLightPos[9] v2:pointLightPos[10] v3:pointLightPos[11]];
    [self.boxProgram setVec3WithName:"pointLights[3].ambient" v1: 0.05f v2: 0.05f v3: 0.05f];
    [self.boxProgram setVec3WithName:"pointLights[3].diffuse" v1: 0.8f v2: 0.8f v3: 0.8f];
    [self.boxProgram setVec3WithName:"pointLights[3].specular" v1: 1.0f v2: 1.0f v3: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[3].constant" value: 1.0f];
    [self.boxProgram setFloatWithName:"pointLights[3].linear" value: 0.09];
    [self.boxProgram setFloatWithName:"pointLights[3].quadratic" value: 0.032];
    // spotLight
    [self.boxProgram setVec3WithName:"spotLight.position" v1:viewPos.x v2:viewPos.y v3:viewPos.z];
    [self.boxProgram setVec3WithName:"spotLight.direction" v1:0.0f v2:0.0f v3:1.0f];
    [self.boxProgram setVec3WithName:"spotLight.ambient" v1: 0.0f v2: 0.0f v3: 0.0f];
    [self.boxProgram setVec3WithName:"spotLight.diffuse" v1: 1.0f v2: 1.0f v3: 1.0f];
    [self.boxProgram setVec3WithName:"spotLight.specular" v1: 1.0f v2: 1.0f v3: 1.0f];
    [self.boxProgram setFloatWithName:"spotLight.constant" value: 1.0f];
    [self.boxProgram setFloatWithName:"spotLight.linear" value: 0.09];
    [self.boxProgram setFloatWithName:"spotLight.quadratic" value: 0.032];
    [self.boxProgram setFloatWithName:"spotLight.cutOff" value: cos(12.5f / 18.0f * M_PI)];
    [self.boxProgram setFloatWithName:"spotLight.outerCutOff" value: cos(15.0f / 18.0f * M_PI)];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.boxTextureInfo.name);
    [self.boxProgram setIntWithName:"material.diffuse" value:0];
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.specTextureInfo.name);
    [self.boxProgram setIntWithName:"material.specular" value:1];
    
    for (unsigned int i = 0; i < 10; i++)
    {
        GLKMatrix4 model = GLKMatrix4MakeTranslation(cubePositions[i * 3], cubePositions[i * 3 + 1], cubePositions[i * 3 + 2]);
        float angle = 20.0f * i;
        model = GLKMatrix4Rotate(model, angle / 180.0 * M_PI, 1.0, 0.3, 0.5);
        [self.boxProgram setMatrix4WithName:"model" mat4:model];
        
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    
//    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    [self.lightProgram use];
    
    [self.lightProgram setMatrix4WithName:"projection" mat4:projection];
    [self.lightProgram setMatrix4WithName:"view" mat4:viewMat];
    for (int i = 0; i < 4; i++) {
        GLKMatrix4 lightModel = GLKMatrix4MakeTranslation(pointLightPos[3 * i], pointLightPos[3 * i + 1], pointLightPos[3 * i + 2]);
        lightModel = GLKMatrix4Scale(lightModel, 0.2, 0.2, 0.2);
        [self.lightProgram setMatrix4WithName:"model" mat4:lightModel];
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    
    
}


@end
