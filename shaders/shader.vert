#version 460 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 aTex;

layout (location = 0) out vec3 oColor;
layout (location = 1) out vec2 texCoord;

void main()
{
    gl_Position = vec4(aPos, 0.0, 1.0);
    oColor = aColor;
    texCoord = aTex;
}