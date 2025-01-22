#version 430 compatibility

#include "/lib/voxel.glsl"

in vec2 TexCoords;

//const bool colortex0MipmapEnabled = true;


/*
const int colortex0Format = RGBA32F;
const int colortex3Format = RGBA32F;
const int colortex4Format = RGBA32F;
const int colortex9Format = RGBA32F;
const int colortex10Format = RGBA32F;
*/

/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 fragColor;

void main() {
    vec3 col = texture2D(colortex0, TexCoords).rgb;

	fragColor = vec4(col, 1.0);
}