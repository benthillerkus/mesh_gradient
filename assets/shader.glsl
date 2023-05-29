#version 460 core

#include <flutter/runtime_effect.glsl>
#define MAIN
#include <oklch.glsl>
#undef MAIN

float wrapMix(in float lower, in float upper, in float a, in float b, in float t) {
  float range = upper - lower;
  float distance = mod(b - a + range / 2.0, range) - range / 2.0;
  return a + distance * t;
}

vec3 lchmix( in vec3 a, in vec3 b, in float t) {
  float distance = mod(b.z - a.z + TAU / 2.0, TAU) - TAU / 2.0;
  float h = a.z + distance * t;

  return vec3(mix(a.xy, b.xy, t), h);
}

uniform vec2 uSize;
uniform vec3[] uColor;

out vec4 FragColor;

void main() {
  vec2 position = FlutterFragCoord() / uSize;

  if (position.y < 0.125) {
    FragColor.rgb = oklch2srgb(lchmix(uColor[0], uColor[1], position.x));
  } else if (position.y < 0.25) {
    FragColor.rgb = oklab2srgb(mix(lch2lab(uColor[0]), lch2lab(uColor[1]), position.x));
  } else if (position.y < 0.75) {
    FragColor.rgb = mix(oklch2srgb(uColor[0]), oklch2srgb(uColor[1]), position.x);
  } else {
    if (position.x < 0.5) {
      FragColor.rgb = oklch2srgb(uColor[0]);
    } else {
      FragColor.rgb = oklch2srgb(uColor[1]);
    }
  }
}
