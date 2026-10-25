shader_type canvas_item;
uniform sampler2D atlas_texture : filter_linear, repeat_disable;
uniform float source_top = 3360.0;
uniform int stage = 1;
uniform bool boss_rush = false;
uniform sampler2D earth_texture : filter_linear, repeat_disable;
uniform sampler2D cavern_texture : filter_linear, repeat_disable;
uniform float earth_uv_width = 0.625;
uniform vec4 region_edges = vec4(960.0,1440.0,2400.0,2880.0);
uniform float screen_height = 480.0;
vec3 tile(vec2 uv, float phase, int region) {
 vec2 cell_size=vec2(1.0/3.0,1.0/4.0);
 vec2 origin=vec2(float(region),float(clamp(stage-1,0,3)))*cell_size;
 // Square source tiles map to 480x480 world pixels; crop the 400px viewport horizontally.
 vec2 local=vec2(0.5+(uv.x-0.5)*(400.0/screen_height),phase);
 return texture(atlas_texture,origin+clamp(local,vec2(0.002),vec2(0.998))*cell_size).rgb;
}
vec3 terrain(vec2 uv, float source_y, int region) {
 float y=fract(source_y/screen_height);
 float weight=pow(sin(3.14159265*y),2.0);
 return mix(tile(uv,fract(y+0.5),region),tile(uv,y,region),weight);
}
vec3 space(vec2 uv,float y) { return terrain(uv,y,1); }
vec3 cave_sample(vec2 uv,float phase) {
 return texture(cavern_texture,clamp(vec2(0.5+(uv.x-0.5)*(400.0/screen_height),phase),vec2(0.002),vec2(0.998))).rgb;
}
vec3 cave(vec2 uv,float y) {
 float phase=fract(y/screen_height);
 float weight=pow(sin(3.14159265*phase),2.0);
 return mix(cave_sample(uv,fract(phase+0.5)),cave_sample(uv,phase),weight);
}
vec3 stage_four(vec2 uv,float y) {
 if(y>=region_edges.w) {
  // Earth is a one-shot panorama, NOT a modulo/repeating terrain tile.
  float phase=(y-region_edges.w)/(screen_height*2.0);
  vec3 earth=texture(earth_texture,clamp(vec2(0.5+(uv.x-0.5)*earth_uv_width,phase),vec2(0.002),vec2(0.998))).rgb;
  return mix(space(uv,y),earth,smoothstep(region_edges.w,region_edges.w+48.0,y));
 }
 if(y>=region_edges.y) return space(uv,y);
 if(y<region_edges.x) return cave(uv,y);
 // The surface occupies only this 480px traversal; it never becomes a loop.
 float phase=(y-region_edges.x)/screen_height;
 vec3 surface=tile(uv,phase,2);
 float horizon=region_edges.y-100.0-45.0*pow((uv.x-0.5)*2.0,2.0);
 surface=mix(space(uv,y),surface,1.0-smoothstep(horizon-18.0,horizon+18.0,y));
 surface=mix(cave(uv,y),surface,smoothstep(region_edges.x,region_edges.x+72.0,y));
 // Original stage4 has a dark industrial entrance at the surface's upper edge.
 float depth=y-region_edges.x;
 if(depth>=0.0 && depth<48.0) {
  if(uv.x>0.16 && uv.x<0.84) surface=vec3(0.008,0.014,0.018);
  if((uv.x>0.145 && uv.x<=0.16)||(uv.x>=0.84 && uv.x<0.855)) {
   float stripe=step(fract(depth/6.0),0.35);
   surface=mix(vec3(0.13,0.19,0.21),vec3(0.56,0.76,0.74),stripe);
  }
 }
 return surface;
}
void fragment() {
 float y=source_top+UV.y*screen_height;
 vec3 land;
 if(stage==4 && !boss_rush) land=stage_four(UV,y);
 else if(y>=region_edges.w) land=terrain(UV,y,0);
 else if(y>=region_edges.z) land=mix(terrain(UV,y,1),terrain(UV,y,0),smoothstep(region_edges.z,region_edges.w,y));
 else if(y>=region_edges.y) land=terrain(UV,y,1);
 else if(y>=region_edges.x) land=mix(terrain(UV,y,2),terrain(UV,y,1),smoothstep(region_edges.x,region_edges.y,y));
 else land=terrain(UV,y,2);
 float vignette=1.0-0.16*pow(abs(UV.x-0.5)*2.0,2.0);
 COLOR=vec4(land*vignette*0.87,1.0);
}
