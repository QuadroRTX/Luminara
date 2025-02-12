#version 460 compatibility

out vec2 texcoords;

void main() {
	gl_Position = ftransform();
    texcoords = gl_MultiTexCoord0.st;
}