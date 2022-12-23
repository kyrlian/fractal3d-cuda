//Kyrlian, 20091121 - 20091201
//////////////////////////// TYPEDEF ////////////////////////////
typedef struct mlight{
 float3 dir;
 uint3 colour;
} mlight;

typedef struct __align__(16) observ{
 float3 point;
 float3 axis;
 float3 x;
 float3 y;
 float focal;
 float width;
 float scale;
 float maxdist;
 int maxiter;
 uint3 ambient;//ambient light comes from everywhere and is reflected to all direction
 uint3 diffuse;//diffuse light comes from everywhere and is reflected according to normal of surface
 mlight light;
 int power;
 float epsilonfactor;
} observ;
/// EOF ///
