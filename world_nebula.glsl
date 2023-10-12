//Sam Gates

precision highp float;

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

#define DIST_MAX 1000.0
#define MAX_STEPS 48
#define SHADOW_STEPS 12
#define VOLUME_LENGTH 15.
#define SHADOW_LENGTH 2.

//FBM taken from XT95 https://www.shadertoy.com/view/lss3zr
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

vec3 path(float z)
{
    vec3 p = vec3(cos((z *.005))*140.0, 90., z);
    return p;
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );
    return f;
}

//--------------------------------------------------

float map(vec3 p){
    
    float f = fbm(p);
    vec3 scale = vec3(1.,1.,1.);
    
    float sph = length(p*scale) - 12.*f*f;
    
    return min(max(0.0,sph),1.0);
    
}

float damain_warping( in vec3 p , out vec3 q, out vec3 r ){
    q.x = fbm( p + vec3(0.0,0.0,0.0) );
    q.y = fbm( p + vec3(5.2,1.3,1.0) );
    q.x += cos(0.5) + sin(0.3+0.5);

    r.x = fbm( p + 4.0*q);
    r.y = fbm( p + 10.0*q);

    return fbm( p + 4.0*r );
}

vec3 damain_warping_coloring( in vec3 p ){
    vec3 o = vec3(0.0,0.0,0.0);
    vec3 n = vec3(0.0,0.0,0.0);
    float luminance = 0.1;

    float f = damain_warping(p,o,n);

    vec3 cloud_base_col = vec3(0.2,0.1,0.9);
    vec3 cloud_blue = vec3(0.2,0.0,0.7);
    vec3 cloud_black = vec3(0.0,0.0,0.0);
    vec3 cloud_red = vec3(0.5,0.2,0.2);

    vec3 col = cloud_base_col;
    col = mix( col, cloud_blue, 1.5*f );
    col = mix( col, cloud_black, 1.3*dot(n,n) );
    col = mix( col, cloud_red, 1.1*o.y*o.y );

    return col * luminance;
}

float jitter;

vec4 cloudMarch(vec3 camera, vec3 ray){
    float density = 0.0;
    float stepLen = VOLUME_LENGTH/float(MAX_STEPS);
    
    float cloudDensity = 6.0;
  	vec3 cloudColor = vec3(.0,.0,.0);
    
    vec4 sum = vec4(vec3(0.),1.);
    
    vec3 pos = camera+ray*jitter;
    
    for(int i=0;i<MAX_STEPS;i++){
        density = smoothstep(0.,1.,fbm(pos*0.0025));
        
        cloudColor = damain_warping_coloring(pos);
        sum.rgb += cloudColor*sum.a;
        
        sum.a*=1.-density;

        pos+=ray*stepLen;
    }

    return sum;
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy*2.0-iResolution.xy)/min(iResolution.x,iResolution.y);

    jitter = hash(uv.x+uv.y*57.0);

    vec3 skybox = mix(vec3(0.1,0.,0.05),vec3(0.05,0.0,0.1),(1.-uv.y));

    vec3 camera = vec3(0.0,0.0,-10.0);
    vec3 dir = normalize(vec3(uv,1.0));

	vec4 res = cloudMarch(camera,dir);
    res = pow(res,vec4(2.0/2.6));
    vec3 col = res.rgb+mix(vec3(0.),skybox,res.a); //背景と合成
    // Output to screen
    fragColor = vec4(col,1.0);
}