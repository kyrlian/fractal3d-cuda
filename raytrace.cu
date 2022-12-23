//Kyrlian, 20091121 - 20091201
//fractal formulas from http://www.fractalforums.com/3d-fractal-generation/true-3d-mandlebrot-type-fractal/?action=printpage
//#define EPSILON 0.000001f // is now adaptative (=scale)
#define DIVERGENCE 2.0f//float
//#define POWER 8.0f //float
#define PHONG_EXP 8//
//#define EPSILONFACT 0.1f//epsilon=scale*EPSILONFACT
//////////////////////////// RAY STEP / TEST ////////////////////////////
// compute raytrace step at given point - scalar derivative
__host__ float HRayStep(const float3 &point, int maxiter, int power){
 float3 z = point;
 float  r = length(z);
 float dr = 1.0f;
 int    i = maxiter;                   //max iteration count
 while(r<DIVERGENCE && i--) {
  float ph = asinf( z.z/r );
  float th = atan2f( z.y,z.x );
  float zr = powf( r, power - 1.0f );
  dr = zr * dr * power + 1.0f;
  zr *= r;
  float sph,cph; sincosf(power*ph, &sph, &cph);
  float sth,cth; sincosf(power*th, &sth, &cth);
  z.x = zr * cph*cth + point.x;
  z.y = zr * cph*sth + point.y;
  z.z = zr * sph     + point.z;
  r=length(z);
 }
  return 0.5f*logf(r)*r/dr;
}
//device version uses some specific device functions, runtime si divided by 2 using cuda __ functions !
inline __device__ float RayStep(const float3 &point, int maxiter, int power){
 float3 z = point;
 float  r = length(z);
 float dr = 1.0f;
 int    i = maxiter;                   //max iteration count
 while(r<DIVERGENCE && i--) {
  float ph = asinf( __fdividef( z.z, r ) );
  float th = atan2f( z.y, z.x );
  float zr = __powf( r, power - 1.0f );
  dr = zr * dr * power + 1.0f;
  zr *= r;
  float sph,cph; __sincosf(power*ph, &sph, &cph);
  float sth,cth; __sincosf(power*th, &sth, &cth);
  z.x = zr * cph*cth + point.x;
  z.y = zr * cph*sth + point.y;
  z.z = zr * sph     + point.z;
  r=length(z);
 }
  return 0.5f * __logf(r) * __fdividef (r , dr);
}
// Test a point against fractal iteration
/*
inline __device__ int RayTest(const float3 &point, int maxiter, int power){ //return 0 if not found or 1 if found
 //test:draw square (normal is not computed from this, so shadows will be weird) : 
 //float c=0.5f; if (fabs(point->x)<c && fabs(point->y)<c && fabs(point->z)<c)return 1;else return 0;
 float3 z = make_float3(0.0f);
 float  r = 1e-10;
 int    i = maxiter;
 while( i-- ) {
  float ph = asinf( __fdividef( z.z, r ) );
  float th = atan2f( z.y, z.x );
  float zr = __powf(r, power);
  float sph,cph; __sincosf(power*ph, &sph, &cph);
  float sth,cth; __sincosf(power*th, &sth, &cth);
  z.x = zr * cph*cth + point.x;
  z.y = zr * cph*sth + point.y;
  z.z = zr * sph     + point.z;
  r=length(z);
  if( r > DIVERGENCE )return 0;
 }
 return 1;
}
*/
//////////////////////////// NORMAL ////////////////////////////
//returns a vector normal to the surface, inbound
inline __device__ float3 RayNormal(float3 &point, int maxiter, int power, const float eps=1e-3f){//quicker: 30ms, less right
   float3 t = point;
   float c=RayStep(t, maxiter, power);
                       t.x+=eps;
   float cx = RayStep( t, maxiter, power );
   t = point;          t.y+=eps;
   float cy = RayStep( t, maxiter, power );
   t = point;          t.z+=eps;
   float cz = RayStep( t, maxiter, power );
   return normalize(make_float3( c-cx, c-cy, c-cz ));
}
/*
inline __device__ float3 RayNormal(const float3 &point, int maxiter, int power, const float eps=1e-3f){
   float cx = RayStep(point - make_float3(eps,0,0), maxiter, power) - RayStep(point + make_float3(eps,0,0), maxiter, power);
   float cy = RayStep(point - make_float3(0,eps,0), maxiter, power) - RayStep(point + make_float3(0,eps,0), maxiter, power);
   float cz = RayStep(point - make_float3(0,0,eps), maxiter, power) - RayStep(point + make_float3(0,0,eps), maxiter, power);
   return normalize(make_float3( cx, cy, cz ));
}*/
//////////////////////////// RAY MARCHER (A/NA) ////////////////////////////
// adaptative raymarch - uses raystep
// return 1 if found 0 if not, set point coords in last param
__host__ int HRayMarchA(const float3 &from, const float3 &direction, int power, float epsilon, float viewlimit, int maxiter, float3 *point, float *dist){
 *point = from;
 *dist  = 0.0f;
 while(*dist<viewlimit){
  float step = HRayStep(*point, maxiter, power);
  if(step < epsilon)return 1;// exit is close enough to point - ie found
  *point += step * direction;
  *dist  += step;
 }
 return 0;
}
inline __device__ int RayMarchA(const float3 &from, const float3 &direction, int power, float epsilon, float viewlimit, int maxiter, float3 *point, float *dist){
 *point = from;
 *dist  = 0.0f; 
 while(*dist<viewlimit){
  float step = RayStep(*point, maxiter, power);
  if(step < epsilon)return 1;// exit is close enough to point - ie found
  *point += step * direction;
  *dist  += step;  
 }
 return 0;
}

// non adaptative raymarch - uses (raytest) RayStep to have the same result as RayMarchA for in/out definition, except we walk at a non adaptative step
// return 1 if found 0 if not, set point coords in last param
inline __device__ int RayMarchNA(const float3 &from, const float3 &direction, int power, float step, float epsilonfactor, float viewlimit, int maxiter, float3 *point, float *dist){
 *point = from;
 *dist  = 0.0f;  
 float epsilon = step * epsilonfactor;
 while(*dist<viewlimit){
  *point += step * direction;
  *dist  += step;
  step *= 1.1f;//increase step regularly (ie resolution decrease with distance)
//  if (RayTest(*point, maxiter)==1) return 1; //exit if point found
  if (RayStep(*point, maxiter, power)< epsilon) return 1;//use same test as RayMarchA, except our step is fixed
 }
 return 0;
}
//////////////////////////// AUTOFOCUS ////////////////////////////
// returns distance to point in center of the screen, used to compute view max dist (10*autofocus)
__host__ float autofocus(){
 float3 found;
 float founddist;
 if(HRayMarchA(view.point, view.axis, view.power, view.scale * view.epsilonfactor , view.maxdist, view.maxiter, &found, &founddist)==1)
  return founddist;
 else return 0.0f;
}
//////////////////////////// CUSTOM float*uint3 OPERATOR ////////////////////////////
inline __device__ uint3 operator*(float s, uint3 a)//this operator doenst exist in cuda_math and I need it below
{    return make_uint3(a.x * s, a.y * s, a.z * s);   }
inline __device__ uint3 operator*(uint3 a, float s)//define both orders
{    return make_uint3(a.x * s, a.y * s, a.z * s);   }
//////////////////////////// RAY TRACER (main) ////////////////////////////
// returns pixel color
//all args are shared in VRAM, thus const
//__device__ uchar4 RayTrace(const observ* view, const float3 &raydir){
__device__ uchar4 RayTrace(const float3 &point, const float &scale, const float &maxdist, const int &maxiter, const int &power, const float &epsilonfactor, const uint3 &gambient, const uint3 &gdiffuse, const float3 &lightdir, const uint3 &lightcolour, const float3 &raydir){
 uint3 c = make_uint3(0);
 float3 found, found2;
 float founddist, founddist2;
 //we set epsilon as scale/12, which seems to be fine
 if(RayMarchA(point, raydir, power, scale * epsilonfactor, maxdist, maxiter, &found, &founddist)==1){
  float3 fnormal = RayNormal(found, maxiter, power, scale * epsilonfactor);
  float  dp = __saturatef(dot(fnormal, raydir));
// float  fact = (1.0f- __fdividef( founddist, viewlimit ) );//so attenuation is proportional to distance and max distance - bad if maxdistance is adaptative
  c = gambient + dp * gdiffuse;//this is called the 'ambient' part, ie touched by no light. I added a diffuse part for shadowing.
// this would be done for each light in the scene
  if(RayMarchNA(found, -1.0f*lightdir, power, scale, epsilonfactor, maxdist, maxiter, &found2, &founddist2)==0){//we can deactivate this test to save some time, meaning no real light casting and just simulate shadow with normals.
   // in light, compute diffuse and specular light amounts
   float diffuse = __saturatef(dot(fnormal, lightdir));// staturate clamps in 0-1
//   float specular = __powf (__saturatef(dot(reflect(raydir, fnormal), lightdir)), PHONG_EXP);
   float specular = __powf (__saturatef(dot((lightdir+raydir)/2, fnormal)), PHONG_EXP);//quicker by 3ms
   c += diffuse * lightcolour + specular * make_uint3(255);//diffuse reflection is of light colour, and specular reflexion is white
  }
  c = min( c, make_uint3(255) );//phong = ambient + diffuse + specular
  // we could add Ambient occlusion (trace in every direction, add light for each not-blocked ray
 }
 return make_uchar4(c.x,c.y,c.z,1);
}
