// Copied from https://www.shadertoy.com/view/dlSXzw
// 1: smoothstep, 2: smootherstep
#define SMOOTH 2

const float PI = 3.1415926535897932384626433832795;
const float TAU = 2.0 * PI;

// Smooth HSV to RGB conversion from https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb( in vec3 c ) {
  vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  
  #if (SMOOTH==1)
	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	
  #elif (SMOOTH==2)
  // Ken Perlin's smootherstep() polynomial.
  vec3 x = rgb;
  rgb = x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
  #endif

  return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 mul3( in mat3 m, in vec3 v ) {
  return vec3(
    dot(v,m[0]),
    dot(v,m[1]),
    dot(v,m[2])
  );
}

// inverse overload.
vec3 mul3( in vec3 v, in mat3 m ) {
  return mul3(m,v);
}

// Adapted from https://bottosson.github.io/posts/oklab
// The commented code is the original code followed by GLSL adaptation.
vec3 srgb2oklab(vec3 c) {
  // float l = 0.4122214708f * c.r + 0.5363325363f * c.g + 0.0514459929f * c.b;
  // float m = 0.2119034982f * c.r + 0.6806995451f * c.g + 0.1073969566f * c.b;
	// float s = 0.0883024619f * c.r + 0.2817188376f * c.g + 0.6299787005f * c.b;
    
  // The matrix to multiply by.
  mat3 m1 = mat3(
      0.4122214708,0.5363325363,0.0514459929,
      0.2119034982,0.6806995451,0.1073969566,
      0.0883024619,0.2817188376,0.6299787005
  );
  
  vec3 lms = mul3(m1,c);

  // float l_ = cbrtf(l);
  // float m_ = cbrtf(m);
  // float s_ = cbrtf(s);
  
  // Equivalent to cbrt().
  lms = pow(lms,vec3(1./3.));

  // return {
  //     0.2104542553f*l_ + 0.7936177850f*m_ - 0.0040720468f*s_,
  //     1.9779984951f*l_ - 2.4285922050f*m_ + 0.4505937099f*s_,
  //     0.0259040371f*l_ + 0.7827717662f*m_ - 0.8086757660f*s_,
  // };
  
  mat3 m2 = mat3(
      +0.2104542553,+0.7936177850,-0.0040720468,
      +1.9779984951,-2.4285922050,+0.4505937099,
      +0.0259040371,+0.7827717662,-0.8086757660
  );
  
  return mul3(m2,lms);
}

// Same as above.
vec3 oklab2srgb(vec3 c) {
  // float l_ = c.L + 0.3963377774f * c.a + 0.2158037573f * c.b;
  // float m_ = c.L - 0.1055613458f * c.a - 0.0638541728f * c.b;
  // float s_ = c.L - 0.0894841775f * c.a - 1.2914855480f * c.b;

  // We have 1. as the first column since the code doesn't
  // have an argument to multiply by for cL.
  mat3 m1 = mat3(
      1.0000000000,+0.3963377774,+0.2158037573,
      1.0000000000,-0.1055613458,-0.0638541728,
      1.0000000000,-0.0894841775,-1.2914855480
  );

  // We need to convert the `struct Lab` c variable into `vec3`.
  vec3 lms = mul3(m1,c);

  // float l = l_*l_*l_;
  // float m = m_*m_*m_;
  // float s = s_*s_*s_;
  
  lms = lms * lms * lms;

  // return {
  // 	+4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s,
  // 	-1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s,
  // 	-0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s,
  // };
  
  // this is essentially the m1 from the code before just inverted.
  mat3 m2 = mat3(
      +4.0767416621,-3.3077115913,+0.2309699292,
      -1.2684380046,+2.6097574011,-0.3413193965,
      -0.0041960863,-0.7034186147,+1.7076147010
  );
  return mul3(m2,lms);
}

// universal lab -> lch conversion.
vec3 lab2lch( in vec3 c ) {
  return vec3(
    c.x,
    sqrt((c.y*c.y) + (c.z * c.z)),
    atan(c.z,c.y)
  );
}

// universal lch -> lab conversion
vec3 lch2lab( in vec3 c ) {
  return vec3(
    c.x,
    c.y*cos(c.z),
    c.y*sin(c.z)
  );
}

// shortcuts
vec3 srgb2oklch( in vec3 c ) { 
  return lab2lch(srgb2oklab(c)); 
}

vec3 oklch2srgb( in vec3 c ) { 
  return oklab2srgb(lch2lab(c)); 
}

#ifndef MAIN
void main() {}
#endif
