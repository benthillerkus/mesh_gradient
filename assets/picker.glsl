#version 460 core

#include <flutter/runtime_effect.glsl>
#define MAIN
#include <oklch.glsl>
#undef MAIN

uniform vec2 uSize;
uniform vec3 uColor;

out vec4 FragColor;

void main() {
  vec2 position = FlutterFragCoord() / uSize;

  FragColor = vec4(oklch2srgb(vec3(uColor.x, uColor.y, atan(position.y - 0.5, position.x - 0.5))), 1.0);
}