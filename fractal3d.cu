//Kyrlian, 20091121 - 20091201
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <math.h>
 #include <cstdio>
// opengl
 #include <GL/glew.h>
 #include <GL/glut.h>
#ifdef _WIN32
#include <GL/wglew.h>
#endif 
// cuda
#include <cuda_runtime.h>//_api.h>
 #include <cutil_inline.h>
 #include <cutil_gl_inline.h>
 #include <cutil_math.h>
 #include <cuda_gl_interop.h>
 #include <rendercheck_gl.h>
// struct include (observ and light)
 #include "structs.cu"
// some constants - other constants are in each code file
// #define BITSPERPIXEL 32
 #define BUFFER_DATA(i) ((char *)0 + i) // used in cuda_draw for textures
//////////////////////////// GLOBAL ////////////////////////////
//OpenGL PBO and texture "names"
 GLuint gl_PBO, gl_Tex, gl_Shader;
 //Source image on the host side
 uchar4 *h_Src = 0;
 // Destination image on the GPU side
 uchar4 *d_dst = NULL;
 //Original image width and height
 #define INIW 800
 #define INIH 600
 int imageW = INIW, imageH = INIH;
 // User interface variables
 int lastx = 0;
 int lasty = 0;
 bool leftClicked = false;
 bool middleClicked = false;
 bool rightClicked = false;
 // CheckFBO/BackBuffer class objects
 CFrameBufferObject *g_FrameBufferObject = NULL;
 CheckRender        *g_CheckRender = NULL;
 // windows title
 static char *windowsTitle = "CUDA fractal3d";
 // Timer ID
 unsigned int hTimer;
 // view is global (easier)
 observ view;
 observ* d_view; //pointer for device access
 //movement
 float movespeed = 0.1f;
 float moveangle = 0.1f;
 //misc
 //int finished = 0; 
//////////////////////////// Project includes //////////////////////////// 
// some globals are used in there, that's why I waited till here. Did I mention this is not good practice and I should use headers ?
 #include "misc.cu"
 #include "raytrace.cu"
 #include "cuda_draw.cu"
 #include "opengls.cu"
//////////////////////////// MAIN ////////////////////////////
int main(int argc, char* argv[]){
 // init light
  mlight viewlight;
  viewlight.dir=normalize(make_float3(-1,1,1));
  viewlight.colour=make_uint3(255, 215, 0);
 //init view
  view.point   = make_float3(0,-3,0);
  view.axis    = normalize(make_float3(0,1,0));
  view.x       = normalize(make_float3(1,0,0));
  view.y       = normalize(cross(view.axis,view.x));  
  view.focal   = 3;//focal(fixed)
  view.width   = 4;//width(user mod)
  view.scale   = view.width/imageW;//scale(computed in Draw)
  view.maxdist = 2*length(view.point);//maxdist(computed from autofocus)
  view.maxiter = 10;
  view.ambient = make_uint3(5);
  view.diffuse = make_uint3(40);
  view.light   = viewlight; 
  view.power   = 8;
  view.epsilonfactor = 0.1f;
 // Initialize OpenGL context first before the CUDA context is created.  This is needed
 // to achieve optimal performance with OpenGL/CUDA interop.
  initGL( argc, argv );
 // choose and init opengl cuda device
  cutilChooseCudaGLDevice(argc, argv);
  //allocate memory on the device for dview
  cutilSafeCall(cudaMalloc((void**) &d_view, sizeof(observ)));  
  //display usage
  usage();
 //opengl mapping to my functions
  glutDisplayFunc(cuda_draw);//opengl will call this when needed
  //glutIdleFunc(idleFunc);//this seems to take all cpu - we do nothing when idle, hus uneeded
  glutKeyboardFunc(keyboardFunc);
  glutMouseFunc(clickFunc);
  glutMotionFunc(motionFunc);
  glutReshapeFunc(reshapeFunc);//this is called when the windows is created, the opengl/cuda buffers are created then.
 //timer
  cutilCheckError(cutCreateTimer(&hTimer));
  cutilCheckError(cutStartTimer(hTimer));
 //loop
  atexit(cleanup);//cleanup function
  glutMainLoop();//main loop
 //end
 cudaThreadExit();//cuda exit
 cutilExit(argc, argv);
 return 0;
}
