shader_type canvas_item;
uniform float phase = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 a=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 p=UV-0.5;
 float edge=1.0-smoothstep(0.18,0.49,length(p*vec2(0.9,1.1)));
 float n=noise(UV*5.0+phase*0.015)*0.65+noise(UV*11.0)*0.35;
 float density=smoothstep(0.28,0.79,n)*edge;
 COLOR=vec4(mix(vec3(0.39,0.57,0.68),vec3(0.78,0.86,0.88),n),density*0.23);
}
