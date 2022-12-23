//Kyrlian, 20091121 - 20091201
//////////////////// OpenGL init //////////////////////
void initGL(int argc, char **argv){
 printf("initGL:\n");
 printf("Initializing GLUT...\n");
  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE);
  glutInitWindowSize(imageW, imageH);
  glutInitWindowPosition(0, 0);
  glutCreateWindow(argv[0]);
  glutSetWindowTitle(windowsTitle);
 printf("Loading extensions: %s\n", glewGetErrorString(glewInit()));
 if (!glewIsSupported( "GL_VERSION_1_5 GL_ARB_vertex_buffer_object GL_ARB_pixel_buffer_object" )) {
  fprintf(stderr, "Error: failed to get minimal extensions for demo\n");
  fprintf(stderr, "This sample requires:\n");
  fprintf(stderr, "  OpenGL version 1.5\n");
  fprintf(stderr, "  GL_ARB_vertex_buffer_object\n");
  fprintf(stderr, "  GL_ARB_pixel_buffer_object\n");
  exit(-1);
 }
 printf("OpenGL window created.\n");
}
//////////////////// OpenGL shaders //////////////////////
// gl_Shader for displaying floating-point texture
/*
static const char *shader_code = 
"!!ARBfp1.0\n"
"TEX result.color, fragment.texcoord, texture[0], 2D; \n"
"END";

GLuint compileASMShader(GLenum program_type, const char *code)
{
    GLuint program_id;
    glGenProgramsARB(1, &program_id);
    glBindProgramARB(program_type, program_id);
    glProgramStringARB(program_type, GL_PROGRAM_FORMAT_ASCII_ARB, (GLsizei) strlen(code), (GLubyte *) code);
    GLint error_pos;
    glGetIntegerv(GL_PROGRAM_ERROR_POSITION_ARB, &error_pos);
    if (error_pos != -1) {
        const GLubyte *error_string;
        error_string = glGetString(GL_PROGRAM_ERROR_STRING_ARB);
        fprintf(stderr, "Program error at position: %d\n%s\n", (int)error_pos, error_string);
        return 0;
    }
    return program_id;
}*/
//////////////////// OpenGL init buffers //////////////////////
void initOpenGLBuffers(int w, int h){
    printf("initOpenGLBuffers:\n");
    // delete old buffers
    if (h_Src) {
        free(h_Src);
        h_Src = 0;
    }
    if (gl_Tex) {
        glDeleteTextures(1, &gl_Tex);
        gl_Tex = 0;
    }
    if (gl_PBO) {
        cudaGLUnregisterBufferObject(gl_PBO);
        glDeleteBuffers(1, &gl_PBO);
        gl_PBO = 0;
    }
    // check for minimized window
    if ((w==0) && (h==0)) {
        return;
    }
    // allocate new buffers
	h_Src = (uchar4*)malloc(w * h * 4);
    printf("Creating GL texture...\n");
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &gl_Tex);
        glBindTexture(GL_TEXTURE_2D, gl_Tex);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, h_Src);
    printf("Texture created.\n");
    printf("Creating PBO...\n");
        glGenBuffers(1, &gl_PBO);
        glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, gl_PBO);
        glBufferData(GL_PIXEL_UNPACK_BUFFER_ARB, w * h * 4, h_Src, GL_STREAM_COPY);
        //While a PBO is registered to CUDA, it can't be used 
        //as the destination for OpenGL drawing calls.
        //But in our particular case OpenGL is only used 
        //to display the content of the PBO, specified by CUDA kernels,
        //so we need to register/unregister it only once.
        cutilSafeCall( cudaGLRegisterBufferObject(gl_PBO) );
    printf("PBO created.\n");
    // load shader program
 //   gl_Shader = compileASMShader(GL_FRAGMENT_PROGRAM_ARB, shader_code);
}
//////////////////// OpenGL reshape //////////////////////
void reshapeFunc(int w, int h){
    printf("reshapeFunc\n");
    w=BLOCKSIZE*(int)(w/BLOCKSIZE);// all sizes must be multiples of BLOCKSIZE
    h=BLOCKSIZE*(int)(h/BLOCKSIZE);
    glViewport(0, 0, w, h);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, 1.0, 0.0, 1.0, 0.0, 1.0);
    initOpenGLBuffers(w, h);
    imageW = w;
    imageH = h;
}
//////////////////// OpenGL cleaner //////////////////////
void cleanup(){
 printf("OpenGL Cleanup\n");
 if (h_Src) {
  free(h_Src);
  h_Src = 0;
 }
 cutilSafeCall(cudaFree(d_view));//free d_view
 cutilCheckError(cutStopTimer(hTimer) );
 cutilCheckError(cutDeleteTimer(hTimer));
 cutilSafeCall(cudaGLUnregisterBufferObject(gl_PBO));
 glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
 glDeleteBuffers(1, &gl_PBO);
 glDeleteTextures(1, &gl_Tex);
 glDeleteProgramsARB(1, &gl_Shader);
 if (g_FrameBufferObject) {
  delete g_FrameBufferObject; g_FrameBufferObject = NULL;
 }
 if (g_CheckRender) {
  delete g_CheckRender; g_CheckRender = NULL;
 }
}
//////////////////  OpenGL keyboard function ////////////////// 
void keyboardFunc(unsigned char k, int, int){
 switch (k){
  case '\033':
  case 'a':
  case 'A':
   printf("bye!\n");
   exit(0);
   break;
//DRAW
  case ' '://just redraw
   break;
/*   
  case 'p'://save bmp
  case 'b'://save bmp
   savebmp();
  //break;//dont break, wait for the printinfo part
*/
  case 'o'://output view info to stdout
   printinfo();
  break;
//ITERATIONS
  case 'w':
   view.maxiter--;
   printf("maxiter: %i\n",view.maxiter);
  break;
  case 'W':
   view.maxiter++;
   printf("maxiter: %i\n",view.maxiter);   
  break;
//EPSILON FACTOR
  case 'x':
   view.epsilonfactor *= 0.1f;
   printf("epsilonfactor: %f\n",view.epsilonfactor);
  break;
  case 'X':
   view.epsilonfactor *= 10.0f;
   printf("epsilonfactor: %f\n",view.epsilonfactor);   
  break;
//POWER p/P  
  case 'p':
   view.power--;
   printf("power: %i\n",view.power);
  break;
  case 'P':
   view.power++;
   printf("power: %i\n",view.power);   
  break;
//MOVEMENT (zqsd, ec) azerty
  case 'z'://forward
   view.point+=view.axis * movespeed;
   float3_print((char*)"view point",view.point);
  break;
  case 's'://backward
   view.point-=view.axis * movespeed;
   float3_print((char*)"view point",view.point);
  break;
  case 'q'://left
   view.point-=view.x * movespeed;
   float3_print((char*)"view point",view.point); 
  break;
  case 'd'://right
     view.point+=view.x * movespeed;
     float3_print((char*)"view point",view.point); 
  break;
  case 'e'://up
     view.point+=view.y * movespeed;
     float3_print((char*)"view point",view.point); 
  break;
  case 'c'://down
     view.point-=view.y * movespeed;       
     float3_print((char*)"view point",view.point);
  break;
//WIDTH (r/v)
  case 'r'://zoom in
   view.width-= movespeed;
   printf("width: %f\n",view.width);
  break;
  case 'v'://zoom out
   view.width+= movespeed;
   printf("width: %f\n",view.width);   
  break;
//LOOK (4568) and circle around (ijkl)
  case 'k'://change axis and y and point
   rotate(&(view.point), view.x, moveangle);//dont break, we need to look down
  case '8'://change axis and y
   rotate(&(view.axis), view.x, moveangle);
   rotate(&(view.y), view.x, moveangle);
  break;
  case 'i'://change axis and y and point
   rotate(&(view.point), view.x, -1*moveangle);//dont break, we need to look down
  case '5'://change axis and y
   rotate(&(view.axis), view.x, -1*moveangle);
   rotate(&(view.y), view.x, -1*moveangle);
  break;
  case 'l'://change axis and x and point
   rotate(&(view.point), view.y, -1*moveangle);//dont break, we need to look down
  case '4'://change axis and x
   rotate(&(view.axis), view.y, -1*moveangle);
   rotate(&(view.x), view.y, -1*moveangle);
  break;
  case 'j'://change axis and x and point
   rotate(&(view.point), view.y, moveangle);//dont break, we need to look down
  case '6'://change axis and x
   rotate(&(view.axis), view.y, moveangle);
   rotate(&(view.x), view.y, moveangle);
  break;
  case '7'://change y and x
   rotate(&(view.x), view.axis, -1*moveangle);
   rotate(&(view.y), view.axis, -1*moveangle);
  break;
  case '9'://change y and x
   rotate(&(view.x), view.axis, moveangle);
   rotate(&(view.y), view.axis, moveangle);   
  break;
//move light (g/h)
  case 'g'://rotate light around view vertical axis
   rotate(&(view.light.dir), view.y, moveangle);
  break;
  case 'h':
   rotate(&(view.light.dir), view.y, -1*moveangle);
  break;
//OTHER
/*  case 'f'://toggle full screen - no need, use window manager to do this
   static int fullscreen = 0;
   fullscreen=1-fullscreen;
   if (fullscreen==1)glutFullScreen();
   else glutReshapeWindow(INIW,INIH);
  break;*/
 default://display usage
    usage();
   break;
 }
 //whatever key was pressed :
  // normalize all axes, to avoid rotation crunch
   view.axis = normalize(view.axis);
   view.x= normalize(view.x);
   view.light.dir = normalize(view.light.dir);
   view.y = normalize(cross(view.axis,view.x));
  // autofocus to compute maxdist
   float a=autofocus();
   if(a>0){
    view.maxdist = 10 * a;
    movespeed = a * view.width * 0.1f;
    moveangle = fminf(atan2(a, view.width),0.1f);
   }
  // call for redraw
  glutPostRedisplay(); //glut will call the redisplay, wich will trigger a redraw
}
////////////////// OpenGL mouse click function ////////////////// 
void clickFunc(int button, int state, int x, int y){
 printf("click\n");
 if (button == 0) leftClicked = !leftClicked;
 if (button == 1) middleClicked = !middleClicked;
 if (button == 2) rightClicked = !rightClicked;
 int modifiers = glutGetModifiers(); 
 if (leftClicked && (modifiers & GLUT_ACTIVE_SHIFT)) {
  leftClicked = 0;
  middleClicked = 1;
 }
 if (state == GLUT_UP) {
  leftClicked = 0;
  middleClicked = 0;
 }
 lastx = x;
 lasty = y;
}
////////////////// OpenGL mouse motion function /////////////////////
void motionFunc(int x, int y){
// double fx = (double)(x - lastx) / 50.0 / (double)(imageW);        
// double fy = (double)(lasty - y) / 50.0 / (double)(imageH);
} // motionFunc
////////////////// OpenGL idle function /////////////////////
void idleFunc(){
//glutPostRedisplay();//don't - this would mean redraw all the time
}
