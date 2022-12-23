//Kyrlian, 20091121 - 20091201
//////////////////////////// USAGE ////////////////////////////
void usage(){
 printf("Usage :\n");
// printf("  RETURN     : re-draw and save\n");
 printf("  z, q, s, d : move\n");
 printf("  e, c       : strafe up/down\n");
 printf("  r, v       : zoom in/out\n");
 printf("  i, j, k, l : rotate view around origin\n");
 printf("  4, 5, 6, 8: look around\n");
 printf("  g, h       : rotate light around view vertical axis\n");
 printf("  w, W       : decrease, increase maxiter\n");
// printf("  f          : toggle full screen\n");
// printf("  p, b       : save bmp\n");
 printf("  o          : print position\n");
 printf("  u          : print (this) usage\n");
 printf("  a          : quit\n");
 printf("Display is refreshed after any keystroke.\n");
 fflush(stdout);     
}
//////////////////////////// INFO ////////////////////////////
void float3_print(char *name, const float3 a){
 printf("%s: %f,%f,%f\n", name, a.x, a.y, a.z);
}
void printinfo(){
 printf("-------------------------------------\n");
 float3_print((char*)"view point",view.point);
 float3_print((char*)"view axis ",view.axis);
 float3_print((char*)"view x    ",view.x);
 float3_print((char*)"view y    ",view.y);
 float3_print((char*)"light dir ",view.light.dir);
              printf("focal     : %f\n",view.focal);
              printf("width     : %f\n",view.width);
              printf("scale     : %f\n",view.scale);
              printf("maxdist   : %f\n",view.maxdist);
              printf("maxiter   : %i\n",view.maxiter);
 printf("%s: %i,%i,%i\n", (char*)"ambient     ", view.ambient.x, view.ambient.y, view.ambient.z);
 printf("%s: %i,%i,%i\n", (char*)"diffuse     ", view.diffuse.x, view.diffuse.y, view.diffuse.z);
 printf("%s: %i,%i,%i\n", (char*)"light colour", view.light.colour.x, view.light.colour.y, view.light.colour.z);
 printf("-------------------------------------\n");
 fflush(stdout);
}
//////////////////////////// BMP ////////////////////////////
void savebmp(){
 static int i=0;
 char filename [20];
 sprintf(filename, "out_%d.bmp", i++);
 //SDL_SaveBMP(screen, filename);//TODO : well, opengl doesnt have a simple function to save an image :(
 printf("-------------------------------------\n");
 printf("Saving view to %s, parameters follow:\n",filename);
}
//////////////////////////// ROTATE ////////////////////////////
void rotate(float3* vect, const float3 axis, const float a){
 float x=vect->x; float y=vect->y; float z=vect->z;
 float u=axis.x;  float v=axis.y;  float w=axis.z;
 float ux=u*x; float uy=u*y; float uz=u*z;
 float vx=v*x; float vy=v*y; float vz=v*z;
 float wx=w*x; float wy=w*y; float wz=w*z;
 float sa, ca; sincosf(a, &sa, &ca);
 vect->x=u*(ux+vy+wz)+(x*(v*v+w*w)-u*(vy+wz))*ca+(-wy+vz)*sa;
 vect->y=v*(ux+vy+wz)+(y*(u*u+w*w)-v*(ux+wz))*ca+(wx-uz)*sa;
 vect->z=w*(ux+vy+wz)+(z*(u*u+v*v)-w*(ux+vy))*ca+(-vx+uy)*sa;
}
/// EOF ///
