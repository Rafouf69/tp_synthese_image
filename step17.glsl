const int Steps = 750;
const float Epsilon = 0.04; // Marching epsilon
const float T=0.5;
#define TAU 6.28318530718
#define MAX_ITER 5
const float rA=1.0; // Minimum ray marching distance from origin
const float rB=50.0; // Maximum

float funccentre(in float a)
{
	if (a<=1.82 ||a>=8.17)
    {
    	return 1.0;
    }
    else
    {
        return 0.5+0.5*(sin(a-0.27));
    }
}

vec2 hash( vec2 p ) 
{
	p = vec2( dot(p,vec2(127.1,311.7)),
			  dot(p,vec2(269.5,183.3)) );

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

	vec2 i = floor( p + (p.x+p.y)*K1 );
	
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = step(a.yx,a.xy);    
    vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0*K2;

    vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );

	vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));

    return dot( n, vec3(70.0) );
}

float ridged( in vec2 p)
{
    return 2.0*(0.5 - abs(0.5- noise(p)));
}

float turbulence(in vec2 p, in float amplitude, in float fbase, in float attenuation, in int noctave) {
    int i;
    float res = .0;
    float f = fbase;
    for (i=0;i<noctave;i++) {
        res = res+amplitude*ridged(f*p);
        amplitude = amplitude*attenuation;
        f = f*2.;
    }
    return res;
}
float terrain(vec3 p)
{
    float montagne = turbulence(p.xz, 1.3, 0.1, 0.35, 8);

    return montagne  - p.y; 
}
float eau(vec3 p)
{
   float eau1 = turbulence(p.xz, 0.005, cos(iTime*0.2)*0.2, 0.02, 3);
   float eau2 = turbulence(p.xz, sin(iTime*5.)*(-0.01), 0.05, 0.05, 2);
   float eau3 = turbulence(p.xz, 0.005, 0.1, cos(iTime)*0.9, 2);

   	return 0.1 + eau1 + eau2 + eau3  - p.y;

}
// Transforms
vec3 rotateY(vec3 p, float a)
{
    p.x = p.x*cos(a) + p.z*sin(a);
    p.z = p.z*cos(a) - p.x*sin(a);
   return p;
}

// Smooth falloff function
// r : small radius
// R : Large radius
float falloff( float r, float R )
{
   float x = clamp(r/R,0.0,1.0);
   float y = (1.0-x*x);
   return y*y*y;
}

// Primitive functions

// Point skeleton
// p : point
// c : center of skeleton
// e : energy associated to skeleton
// R : large radius
float point(vec3 p, vec3 c, float e,float R)
{
   return e*falloff(length(p-c),R);
}


// Blending
// a : field function of left sub-tree
// b : field function of right sub-tree
float Blend(float a,float b)
{
   return a+b;
}

// Potential field of the object
// p : point
float object(vec3 p)
{
   float soleil = point(p,vec3( -19.8+4.0*mod(iTime,10.0),5.7-5.0*cos(0.6*mod(iTime,10.0)),-6.7),2.0,2.5);
   float v = terrain(p);
   return max(v,soleil-T);
}

// Calculate object normal
// p : point
vec3 ObjectNormal(in vec3 p )
{
   float eps = 0.0001;
   vec3 n;
   float v = object(p);
   n.x = object( vec3(p.x+eps, p.y, p.z) ) - v;
   n.y = object( vec3(p.x, p.y+eps, p.z) ) - v;
   n.z = object( vec3(p.x, p.y, p.z+eps) ) - v;
   return normalize(n);
}

vec3 WaterNormal(in vec3 p )
{
   float eps = 0.0001;
   vec3 n;
   float v = eau(p);
   n.x = eau( vec3(p.x+eps, p.y, p.z) ) - v;
   n.y = eau( vec3(p.x, p.y+eps, p.z) ) - v;
   n.z = eau( vec3(p.x, p.y, p.z+eps) ) - v;
   return normalize(n);
}
// Trace ray using ray marching
// o : ray origin
// u : ray direction
// h : hit
// s : Number of steps
void Trace(vec3 o, vec3 u, out bool h,out int s, out bool w, out int stepsWater, out vec3 pos)
{
   h = false;	
   w =false;
   stepsWater = 0;
   // Don't start at the origin
   // instead move a little bit forward
   float t=rA;

   for(int i=0; i<Steps; i++)
   {
      s=i;
      vec3 p = o+t*u;
      float v = object(p);
      float v2 = eau(p);
       
      // Hit object (1)
      if (w == false && v2>0.0)
      {
          w = true;
          stepsWater=i;
          u=reflect(u, WaterNormal(p));
          o=p;
          t=0.;
      }
      if (v > 0.0)
      {
         s=i;
         h = true;
         break;
      }
      
      // Move along ray
      t += max(Epsilon,min(-v2,-v)/2.0);  

      // Escape marched far away
      if (t>rB)
      {
         break;
      }
   }
   pos=o+t*u;
}

// Background color
vec3 background(vec3 rd)
{
   if(mod(iTime,20.0) <= 10.0 )
   {
   		return (0.2+0.8*sin(0.315*mod(iTime,10.0)))*mix(vec3(0.8, 0.8, 0.9), vec3(0.6, 0.9, 1.0), rd.y*1.0+0.25);
       
   }
   else
   {
		return vec3(0.1,0.1,0.1);
   }
}

float colorBand2(float value, float colorSteps) {
    float currentStep;
    float stepSize = 0.00001/ colorSteps;
    modf(value / stepSize, currentStep);
	return currentStep * stepSize;
}

// Shading and lighting
// p : point,
// n : normal at point


vec3 Shade(vec3 p, vec3 n, int s, vec3 rd, bool w)
{
   	// point light
    vec3 lightColor;
   	const vec3 lightPos = vec3(5.0, 5.0, 5.0);
    if(mod(iTime,20.0) <= 10.0 )
    {
   		lightColor = vec3((1.0 + 0.5*funccentre(mod(iTime,10.0)))*(sin(mod(iTime,10.0)*0.315)), (1.0 - 0.1*funccentre(mod(iTime,10.0)))*sin(mod(iTime,10.0)*0.315), sin(mod(iTime,10.0)*0.315));
    }
    else
    {
   		lightColor = vec3(0.1,0.1,0.1);

    }
    vec3 l = normalize(lightPos - p);

   	float alpha = p.y-0.5;
    float turb = clamp(turbulence(p.xy,1.2,0.5,0.2,4),-0.2,0.2);  
   	// Not even Phong shading, use weighted cosine instead for smooth transitions
   	float diff = 0.5*(1.0+dot(n, l));
    vec3 c;
    vec3 c1 = vec3(0.60,0.50,0.57);
    vec3 c2 = vec3(0.22,0.09,0.);
    
    if( p.y > 2.0 )
    {
        if(mod(iTime,20.0) <= 10.0 )
        {
       		c= vec3(0.8 + 0.2*funccentre(mod(iTime,10.0)),0.8 - 0.2*funccentre(mod(iTime,10.0)),0.);
        }
        else
        {
        	c= vec3(0.8,0.8,0.8);  
        }
    }
    else if( p.y > 0.1  && mod(p.y,0.12)<=0.01)
    {
    	c= vec3(-0.1,-0.1,-0.1);   
    }
	else
    {
        c= turb*c1*alpha + turb*(1.-alpha)*c2 + alpha*c1 + (1.-alpha)*c2;
        //c=vec3(0.0, 0.25, 0.4);
    }
   float fog = 0.7*float(s)/(float(Steps-1));
   c = (1.0-fog)*c+fog*vec3(1.0,1.0,1.0) + 0.5*diff*lightColor;
   if(w)
   {
   		c = c + vec3(0.,0.15,0.3);   
   }
   return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec2 pixel = (gl_FragCoord.xy / iResolution.xy)*2.0-1.0;

   // compute ray origin and direction
   float asp = iResolution.x / iResolution.y;
	vec3 rd = vec3(asp*pixel.x, pixel.y, -4.0);
   vec3 ro = vec3(-1.4, 0.45, 40.0);
   vec2 mouse = iMouse.xy / iResolution.xy;
   float a=-mouse.x*iTime*0.25;
   rd.z = rd.z+2.0*mouse.y;
   rd = normalize(rd);
   //ro = rotateY(ro, a);
   //rd = rotateY(rd, a);

   // Trace ray
   bool hit;
	bool w;
   // Number of steps
   int s;
   int stepsWater;
   vec3 pos;
   Trace(ro, rd, hit,s, w, stepsWater, pos);

   // Shade background
   vec3 rgb = background(rd);

   if (hit)
   {
      // Compute normal
      vec3 n = ObjectNormal(pos);

      // Shade object with light
      rgb = Shade(pos, n, s, rd, w);
   }
   float alpha = 1.;
   fragColor=vec4(rgb, alpha);
}