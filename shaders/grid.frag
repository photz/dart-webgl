#ifdef GL_ES
precision mediump float;
#endif

varying float x;
varying float y;

void main() {

  vec4 border = vec4(94.0 / 255.0,
                     65.0 / 255.0,
                     47.0 / 255.0,
                     1.0);

  vec4 fields = vec4(252.0 / 255.0,
                     235.0 / 255.0,
                     182.0 / 255.0,
                     1.0);

  float d = 0.05;

  if (x - floor(x) < d ||
      ceil(x) - x < d ||
      y - floor(y) < d ||
      ceil(y) - y < d) {

    gl_FragColor = border;
  }
  else {
    gl_FragColor = fields;
  }

}

