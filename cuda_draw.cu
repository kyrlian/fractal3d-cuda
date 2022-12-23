//Kyrlian, 20091121 - 20091201
// adjust with higher blocksize - or with smaller as threads might wait a lot for each other (lockstep)
#define BLOCKSIZE 8//depends on memory needs: 4-8 is ok, 16 is not - use profiler to estimate
//Tested :
//4*4   threads per block (16) : 618ms, 
//6*6   threads per block (36) : 510ms
//8*8   threads per block (64) : 334ms, 
//10*10 threads per block (100): 376ms, - I guess pow(2) are better for memory management
//12*12 threads per block (144): 446ms,
//16*16 threads per block (256): 338ms. - not as good as 8*8, maybe because of lockstep
//17*17 doesnt run : too much ressources
//////////////////////////// KERNEL ////////////////////////////
__global__ void cudakernel(const int screenw, const int screenh, const observ* view, uchar4* pixeltable){
//use float4 for device for faster access, use float3 for local or shared
 int scx = blockIdx.x * blockDim.x + threadIdx.x;
 int scy = blockIdx.y * blockDim.y + threadIdx.y;
 // register __shared__ variables, should be quicker than going to view, which is in device global memory
 __shared__ float3 point, vx, vy, vfocal, lightdir;
 __shared__ float halfw, halfh, scale, maxdist, epsilonfactor;
 __shared__ int maxiter, power;
 __shared__ uint3 ambient, diffuse, lightcolour;
// if(scx < screenw && scy < screenh){//this is just to check and avoid outbound access
  if ((threadIdx.x==0) && (threadIdx.y==0)){//shared variables - shared among threads of the block
   point    = view->point;
   vx       = view->x;
   vy       = view->y;
   scale    = view->scale;
   maxdist  = view->maxdist;
   maxiter  = view->maxiter;
   power    = view->power;
   epsilonfactor = view->epsilonfactor;
   ambient  = view->ambient;
   diffuse  = view->diffuse;
   lightdir = view->light.dir;
   lightcolour = view->light.colour;
   vfocal = view->axis * view->focal;
   halfh = screenh/2;
   halfw = screenw/2;
  }
  __syncthreads();
  float3 raydir = normalize(vfocal + vx * (scx-halfw)*scale + vy * (scy-halfh)*scale);//is raydir device or local ? should be local I guess...
//  pixeltable[scy * screenw + scx] = RayTrace(view, raydir);//view is in device global memory, should use shared memory more (faster)
  pixeltable[scy * screenw + scx] = RayTrace(point, scale, maxdist, maxiter, power, epsilonfactor, ambient, diffuse, lightdir, lightcolour, raydir);
//  }
}
//////////////////////////// RUNNER (main) ////////////////////////////
__host__ void cuda_draw(){
 cutResetTimer(hTimer);
 //update scale (in case width was changed or image size was changed)
  view.scale = view.width/imageW;
 // map dst to opengl buffer 
  cutilSafeCall(cudaGLMapBufferObject((void**)&d_dst, gl_PBO));//map the PBO - locks it from opengl
 // copy to device memory
  cutilSafeCall(cudaMemcpy(d_view, &view, sizeof(observ), cudaMemcpyHostToDevice) );        
 // setup execution parameters
  dim3 block(BLOCKSIZE, BLOCKSIZE);
  dim3 grid(imageW/BLOCKSIZE, imageH/BLOCKSIZE); //thus w and h must be BLOCKSIZE multiples.
 // execute the kernel
  cudakernel<<< grid, block >>>(imageW, imageH, d_view, d_dst);
 // check if kernel execution generated and error
  cutilCheckMsg("Kernel execution failed");
 //make sure all kernels are done
  cudaThreadSynchronize();
 // unmap dst from opengl buffer  
  cutilSafeCall(cudaGLUnmapBufferObject(gl_PBO));//free the PBO so we can draw it
 //set up colors TODO see what this does exactly...
    glBindTexture(GL_TEXTURE_2D, gl_Tex);
   	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, imageW, imageH, GL_RGBA, GL_UNSIGNED_BYTE, BUFFER_DATA(0));
    // fragment program is required to display floating point texture
 //  glBindProgramARB(GL_FRAGMENT_PROGRAM_ARB, gl_Shader);
 //  glEnable(GL_FRAGMENT_PROGRAM_ARB);
 //  glDisable(GL_DEPTH_TEST);
    glBegin(GL_QUADS);
      glTexCoord2f(0.0f, 0.0f); glVertex2f(0.0f, 0.0f);
      glTexCoord2f(1.0f, 0.0f); glVertex2f(1.0f, 0.0f);
      glTexCoord2f(1.0f, 1.0f); glVertex2f(1.0f, 1.0f);
      glTexCoord2f(0.0f, 1.0f); glVertex2f(0.0f, 1.0f);
    glEnd();
    glBindTexture(GL_TEXTURE_2D, 0);
  //  glDisable(GL_FRAGMENT_PROGRAM_ARB);
 // really displays the image
  glutSwapBuffers();
 //print timer
  printf("GPU time : %.0f ms\n", cutGetTimerValue(hTimer));
}
