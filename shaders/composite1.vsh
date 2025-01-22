#version 430 compatibility

#include "/lib/voxel.glsl"

varying vec2 TexCoords;

void main() {
   gl_Position = ftransform();
   TexCoords = gl_MultiTexCoord0.st;
}