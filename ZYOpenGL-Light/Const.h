//
//  Const.h
//  ZYOpenGL-Light
//
//  Created by wpsd on 2017/8/22.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#ifndef Const_h
#define Const_h

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define pow pow

static NSString *vertexShaderString = SHADER_STRING
(
 attribute vec3 position;
 attribute vec3 normal;
 attribute vec2 texCoords;
 varying vec3 fNormal;
 varying vec3 fragPos;
 varying vec2 fTexCoords;
 
 uniform mat4 model;
 uniform mat4 view;
 uniform mat4 projection;
 
 void main()
 {
     fNormal = normal;
     fragPos = vec3(model * vec4(position, 1.0));
     fTexCoords = texCoords;
     gl_Position = projection * view * model * vec4(position, 1.0);
 }
 );

static NSString *fragmentShaderString = SHADER_STRING
(
// uniform mediump vec3 lightColor;
// uniform mediump vec3 objectColor;
 
// uniform mediump vec3 lightPos;
 uniform mediump vec3 viewPos;
 
 varying mediump vec3 fNormal;
 varying mediump vec3 fragPos;
 varying mediump vec2 fTexCoords;
 
 struct Material {
     highp sampler2D diffuse;
     highp sampler2D specular;
     highp float shininess;
 };
 uniform Material material;
 
 struct DirLight {
     highp vec3 direction;
     
     highp vec3 ambient;
     highp vec3 diffuse;
     highp vec3 specular;
 };
 uniform DirLight dirLight;
 
 struct PointLight {
     highp vec3 position;
     
     highp float constant;
     highp float linear;
     highp float quadratic;
     
     highp vec3 ambient;
     highp vec3 diffuse;
     highp vec3 specular;
 };
 uniform PointLight pointLights[4];
 
 struct SpotLight {
     highp vec3 position;
     highp vec3 direction;
     highp float cutOff;
     highp float outerCutOff;
     
     highp vec3 ambient;
     highp vec3 diffuse;
     highp vec3 specular;
     
     highp float constant;
     highp float linear;
     highp float quadratic;
 };
 uniform SpotLight spotLight;
 
 highp vec3 CalcDirLight(DirLight light, highp vec3 normal, highp vec3 viewDir);
 highp vec3 CalcPointLight(PointLight light, highp vec3 normal, highp vec3 fragPos, highp vec3 viewDir);
 highp vec3 CalcSpotLight(SpotLight spotLight, highp vec3 normal, highp vec3 fragPos, highp vec3 viewDir);
 
 void main()
 {
     // 属性
     highp vec3 norm = normalize(fNormal);
     highp vec3 viewDir = normalize(viewPos - fragPos);
     
     // 第一阶段：定向光照
     highp vec3 result = CalcDirLight(dirLight, norm, viewDir);
     // 第二阶段：点光源
     for(int i = 0; i < 4; i++) {
         result += CalcPointLight(pointLights[i], norm, fragPos, viewDir);
     }
     // 第三阶段：聚光
     result += CalcSpotLight(spotLight, norm, fragPos, viewDir);
     
     gl_FragColor = vec4(result, 1.0);
 }
 
 highp vec3 CalcDirLight(DirLight light, highp vec3 normal, highp vec3 viewDir)
 {
    highp vec3 lightDir = normalize(-light.direction);
    // 漫反射着色
    highp float diff = max(dot(normal, lightDir), 0.0);
    // 镜面光着色
    highp vec3 reflectDir = reflect(-lightDir, normal);
    highp float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    // 合并结果
    highp vec3 ambient  = light.ambient  * vec3(texture2D(material.diffuse, fTexCoords));
    highp vec3 diffuse  = light.diffuse  * diff * vec3(texture2D(material.diffuse, fTexCoords));
    highp vec3 specular = light.specular * spec * vec3(texture2D(material.specular, fTexCoords));
    return (ambient + diffuse + specular);
 }
 
 highp vec3 CalcPointLight(PointLight light, highp vec3 normal, highp vec3 fragPos, highp vec3 viewDir)
 {
    highp vec3 lightDir = normalize(light.position - fragPos);
    // 漫反射着色
    highp float diff = max(dot(normal, lightDir), 0.0);
    // 镜面光着色
    highp vec3 reflectDir = reflect(-lightDir, normal);
    highp float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
     // 合并结果
    highp vec3 ambient  = light.ambient  * vec3(texture2D(material.diffuse, fTexCoords));
    highp vec3 diffuse  = light.diffuse  * diff * vec3(texture2D(material.diffuse, fTexCoords));
    highp vec3 specular = light.specular * spec * vec3(texture2D(material.specular, fTexCoords));
    // 衰减
    highp float distance    = length(light.position - fragPos);
    highp float attenuation = 1.0 / (light.constant + light.linear * distance +
                               light.quadratic * (distance * distance));
    ambient  *= attenuation;
    diffuse  *= attenuation;
    specular *= attenuation;
    return (ambient + diffuse + specular);
 }
 
 highp vec3 CalcSpotLight(SpotLight light, highp vec3 normal, highp vec3 fragPos, highp vec3 viewDir)
 {
     highp vec3 lightDir = normalize(light.position - fragPos);
     // 漫反射着色
     highp float diff = max(dot(normal, lightDir), 0.0);
     // 镜面光着色
     highp vec3 reflectDir = reflect(-lightDir, normal);
     highp float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
     // 合并结果
     highp vec3 ambient  = light.ambient  * vec3(texture2D(material.diffuse, fTexCoords));
     highp vec3 diffuse  = light.diffuse  * diff * vec3(texture2D(material.diffuse, fTexCoords));
     highp vec3 specular = light.specular * spec * vec3(texture2D(material.specular, fTexCoords));
     // 聚光
     highp float theta = dot(lightDir, normalize(-light.direction));
     highp float epsilon   = light.cutOff - light.outerCutOff;
     highp float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
     diffuse *= intensity;
     specular *= intensity;
     // 衰减
     highp float distance    = length(light.position - fragPos);
     highp float attenuation = 1.0 / (light.constant + light.linear * distance +
                                light.quadratic * (distance * distance));
     ambient  *= attenuation;
     diffuse  *= attenuation;
     specular *= attenuation;
     return (ambient + diffuse + specular);
 }
 
 );

static NSString *lightFragmentShaderString = SHADER_STRING
(
 void main()
 {
     gl_FragColor = vec4(1.0);
 }
 );

static float boxVertices[] = {
    -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  0.0f, 0.0f,
    0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  1.0f, 0.0f,
    0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  1.0f, 1.0f,
    0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  1.0f, 1.0f,
    -0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  0.0f, 0.0f,
    
    -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   0.0f, 0.0f,
    0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   1.0f, 0.0f,
    0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   1.0f, 1.0f,
    0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   1.0f, 1.0f,
    -0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   0.0f, 0.0f,
    
    -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
    -0.5f,  0.5f, -0.5f, -1.0f,  0.0f,  0.0f,  1.0f, 1.0f,
    -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f, -1.0f,  0.0f,  0.0f,  0.0f, 0.0f,
    -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
    
    0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
    0.5f,  0.5f, -0.5f,  1.0f,  0.0f,  0.0f,  1.0f, 1.0f,
    0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
    0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
    0.5f, -0.5f,  0.5f,  1.0f,  0.0f,  0.0f,  0.0f, 0.0f,
    0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,  0.0f, 1.0f,
    0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,  1.0f, 1.0f,
    0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,  1.0f, 0.0f,
    0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,  1.0f, 0.0f,
    -0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,  0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,  0.0f, 1.0f,
    
    -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,  0.0f, 1.0f,
    0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,  1.0f, 1.0f,
    0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,  1.0f, 0.0f,
    0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,  1.0f, 0.0f,
    -0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,  0.0f, 0.0f,
    -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,  0.0f, 1.0f
};

static float cubePositions[] = {
     0.0f,  0.0f,  0.0f,
     2.0f,  5.0f, -15.0f,
    -1.5f, -2.2f, -2.5f,
    -3.8f, -2.0f, -12.3f,
     2.4f, -0.4f, -3.5f,
    -1.7f,  3.0f, -7.5f,
     1.3f, -2.0f, -2.5f,
     1.5f,  2.0f, -2.5f,
     1.5f,  0.2f, -1.5f,
    -1.3f,  1.0f, -1.5f
};

static float pointLightPos[] = {
     0.7f,  0.2f,  2.0f,
     2.3f, -3.3f, -4.0f,
    -4.0f,  2.0f, -12.0f,
     0.0f,  0.0f, -3.0f
};

#endif /* Const_h */
