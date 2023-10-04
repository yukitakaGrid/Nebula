precision highp float;

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

float pattern( in vec2 p , out vec2 q, out vec2 r )
{
    q.x = fbm( p + vec2(0.0,0.0) );
    q.y = fbm( p + vec2(5.2,1.3) );
    q.x += cos(iTime*0.1)*0.5;

    r.x = fbm( p + 4.0*q + vec2(1.7,9.2) );
    r.y = fbm( p + 4.0*q + vec2(8.3,2.8) );

    return fbm( p + 4.0*r );
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 mouseuv = (mouse.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    vec2 o = vec2(0.0,0.0);
    vec2 n = vec2(0.0,0.0);

    float f = pattern(uv*3.0,o,n);

    vec3 col = vec3(0.2,0.1,0.4);
    col = mix( col, vec3(0.2,0.0,0.7), f );
    col = mix( col, vec3(0.0,0.0,0.0), dot(n,n) );
    col = mix( col, vec3(0.6,0.2,0.2), 0.5*o.y*o.y );
    col = mix( col, vec3(0.0,0.0,0.25), 0.5*smoothstep(1.2,1.3,abs(n.y)+abs(n.x)) );

    gl_FragColor = vec4(col ,1.0);
}