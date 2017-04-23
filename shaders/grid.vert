#ifdef GL_ES
precision mediump float;
#endif

attribute vec3 a_Coords;

uniform mat4 u_ViewMatrix;

varying float x;
varying float y;

void main() {

  x = a_Coords.x;
  y = a_Coords.y;

  vec4 pos = vec4(a_Coords.x, 0.0, a_Coords.y, 1.0);

  gl_Position = (u_ViewMatrix) * pos;
}
