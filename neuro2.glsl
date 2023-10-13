precision highp float;

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;


float PI = 3.14159265;
mat2 genRot(float a){
	return mat2(cos(a),-sin(a),sin(a),cos(a));
}
vec2 pmod(vec2 p,float count){
	p *= genRot(PI+time*5./count);
	float at = atan(p.y/p.x);
	float r = length(p);
	at = mod(at,2. * PI / count);
	p = vec2(r * cos(at),r * sin(at));
	p *= genRot(-PI/count);
	return p;
}

float sdCylinder(vec3 p,float q){
    float rotStrong = 0.25;
    float tornadoStrong = 0.009;
    float wide = .01;
    return length(p.xy - vec2(rotStrong,0.)) - wide + tornadoStrong * sin(q);
}

float map(vec3 p){
	vec3 q = p;
	p.xy *= genRot(p.z/1.);
	p.xy = pmod(p.xy,8.);
	float string = sdCylinder(p,q.z);
	return string;
}

vec3 calcNormal( in vec3 p) // for function f(p)
{
    const float eps = 0.00001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(map(p+h.xyy) - map(p-h.xyy),
                           map(p+h.yxy) - map(p-h.yxy),
                           map(p+h.yyx) - map(p-h.yyx) ) );
}

vec4 raymarching(vec3 o,vec3 r){
	float t = 0.;
	vec3 p;
	for(int i = 0; i < 128; i++){
		p = o + r * t;
		float d = map(p);
		t += d * 0.75;
	}
	vec3 n = calcNormal(p);
	return vec4(n,t);
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
	vec3 c = vec3(0.,0.,0.1);
	vec3 r = vec3(uv,1.5);
	vec4 d = raymarching(c,r);
	vec3 color = vec3(1.-d.w*0.2);

	gl_FragColor = vec4( color, 1.0 );
}