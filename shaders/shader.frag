#version 460 core
layout (location = 0) out vec4 FragColor;

layout (location = 0) in vec3 oColor;
layout (location = 1) in vec2 texCoord;

layout (set = 2, binding = 0) uniform sampler2D tex;

void main()
{
    FragColor = texture(tex, texCoord) * vec4(oColor, 1.0);
}