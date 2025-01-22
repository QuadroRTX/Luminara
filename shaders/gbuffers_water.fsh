#version 430 compatibility

#include "/lib/voxel.glsl"
/*
const int colortex6Format = RGBA32F;
*/

in vec2 TexCoords;
in vec3 modelPos;
in vec3 viewPos;
in vec3 worldPos;
in vec3 eyePlayerPos;
in vec2 pos;
in vec4 Color;
in vec3 midblock;
in vec3 Normal;

uniform vec3 sunPosition;
in float id;
uniform float frameTimeCounter;
uniform sampler2D texture;

const float sunPathRotation = -20.0;

#include "/lib/water.glsl"

void main() {
   vec4 alb = pow(texture2D(texture, TexCoords), vec4(vec3(GAMMA), 1.0)) * Color;
   //alb.rgb *= hex(116, 204, 244);
   //alb.rgb *= vec3(0.1, 0.5, 1.0);
   int bid = int(round(id));
   vec3 rd = mat3(gbufferModelViewInverse) * normalize(viewPos);
   vec3 norm;
   if (bid == 31) norm = waternorm(pos, 0.01) * sign(eyePlayerPos.y);
   else norm = Normal;
   vec3 sunpos = mat3(gbufferModelViewInverse) * normalize(sunPosition);
   float ndotl = dot(norm, sunpos);
   vec3 reflectdir = reflect(rd, norm);
   vec3 spec = pow(max(dot(reflectdir, sunpos), 0.0), 64.0) * vec3(0.95, 0.9, 0.6);
   vec4 col = vec4(alb.rgb * (clamp(ndotl, 0.5, 1.0) + 0.5) + spec, alb.a);
   vec4 col2 = vec4(worldPos + midblock/64.0, 1.0);
   if (bid != 31) {col = texture2D(texture, TexCoords);}
   /* DRAWBUFFERS:0126 */
   //gl_FragData[0] = pow(col, vec4(vec3(GAMMA), 1.0));
   gl_FragData[1] = vec4(midblock, 1.0);
   gl_FragData[2] = vec4(norm * 0.5 + 0.5, 1.0);
   gl_FragData[3] = pow(vec4(col.rgb * alb.a, 1.0), vec4(vec3(GAMMA), 1.0));
   //gl_FragData[2] = vec4(midblock, 1.0);
}