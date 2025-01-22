#version 120

varying vec2 TexCoords;
varying vec3 viewPos;

void main() {
   gl_Position = ftransform();
   viewPos = gl_Vertex.xyz;
   TexCoords = gl_MultiTexCoord0.st;
}