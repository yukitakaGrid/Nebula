precision highp float;
uniform vec2 resolution;
uniform vec2 mouse;
uniform int frame;
uniform float time;
uniform sampler2D backbuffer;

#define DIST_MIN 0.001
#define ITE_MAX 1
#define DIST_MAX 1000.0
#define MAX_STEPS 24
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

float fsnoise(vec2 c){
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
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

vec3 repetition(vec3 p,float fre){
    return mod(p,fre)-fre*0.5;
}

float sdSphere( vec3 p, float s )
{
    p = repetition(p,2.);
    return length(p)-s;
}

float map(vec3 p){
    float dist = 0.0;
    float size = 0.04;
    return sdSphere(p,size);
}

float volumeMap(vec3 p,float f){
    p = repetition(p,20.0);
    vec3 scale = vec3(0.7,1.,1.);
    
    float sph = length(p*scale) - 15.*f*f;
    
    return min(max(0.0,sph),1.0);
}

float damain_warping( in vec3 p , out vec3 q, out vec3 r ,float f){
    q.x = f;
    q.y = f;
    q.x += cos(0.5) + sin(0.3+0.5);

    float ff = fbm(p+4.*q);
    r.x = ff;
    r.y = ff;

    return fbm( p + 4.0*r );
}

vec3 damain_warping_coloring( in vec3 p ,float f){
    vec3 o = vec3(0.0,0.0,0.0);
    vec3 n = vec3(0.0,0.0,0.0);
    float luminance = 0.1;

    float dw = damain_warping(p,o,n,f);

    vec3 cloud_base_col = vec3(0.2,0.1,0.9);
    vec3 cloud_blue = vec3(0.2,0.0,0.7);
    vec3 cloud_black = vec3(0.2,0.2,0.2);
    vec3 cloud_red = vec3(0.5,0.2,0.2);

    vec3 col = cloud_base_col;
    col = mix( col, cloud_blue, 1.5*dw );
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
        if(sum.a<.01)break;
        
        float f = fbm(pos);
        float fogD = volumeMap(pos,f);
        
        if(fogD<0.999){
            density = clamp((fogD/float(MAX_STEPS))*cloudDensity,0.0,1.0);
            
            cloudColor = damain_warping_coloring(pos,f);
            sum.rgb += cloudColor*sum.a;
            
            sum.a*=1.-density;
        }
        
        //dust star
        for(int i=0; i<ITE_MAX; i++){
            float d = map(pos);

            if(d<DIST_MIN){
                sum.rgb += vec3(0.3);
                break;
            }   
        }

        pos+=ray*stepLen;
    }

    return sum;
    
}

vec3 rotate ( vec3 pos, vec3 axis,float theta )
{
    axis = normalize( axis );
    
    vec3 v = cross( pos, axis );
    vec3 u = cross( axis, v );
    
    return u * cos( theta ) + v * sin( theta ) + axis * dot( pos, axis );   
    
}

void main()
{
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);

    jitter = hash(uv.x+uv.y*57.0);

    vec3 skybox = mix(vec3(0.1,0.,0.05),vec3(0.05,0.0,0.1),(1.-uv.y));

    vec3 camera = vec3(time*1.5,time*0.5,-10.0+time*4.);
    vec3 dir = normalize(vec3(uv,1.0));
    //dir = rotate(dir,vec3(0.,0.,1.),time*2.0);
    //dir = rotate(dir,vec3(1.,0.,0.),-sin(time)*0.2-0.2);
    vec3 light = vec3(0.,0.,5.);

	  vec4 res = cloudMarch(camera,dir);
    res = pow(res,vec4(2.0/2.6));

    vec3 col = res.rgb+mix(vec3(0.),skybox,res.a); //背景と合成
    
    col = mix(vec3(0.),col,clamp(time*0.2,0.,1.));
    
    if(1.8<time && time<4. && fsnoise(vec2(time))<0.3)
      col = vec3(0.);

    gl_FragColor = vec4(col,1.);

}