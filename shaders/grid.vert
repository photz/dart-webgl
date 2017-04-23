#ifdef GL_ES
precision mediump float;
#endif

attribute vec3 a_Coords;

uniform mat4 u_ViewMatrix;

void main() {

  vec4 pos = vec4(a_Coords.x, 0.0, a_Coords.y, 1.0);

  gl_Position = (u_ViewMatrix) * pos;
}
