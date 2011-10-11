module wrt.textures.Texture;

import wrt.base.rgb : rgb;
import wrt.base.vec3 : vec3;

interface Texture {
	rgb getTexel(float u, float v, int mipmaplevel = 0);
}

interface Texture3D {
	rgb getTexel3D(vec3 xyz, int mipmaplevel = 0);
}

// http://graphics.stanford.edu/papers/trd/

// paper title: direct calculation of mip-map level for faster texture mapping

//final float2Binary f2b = { d };
//final int tlevel0 = ((f2b.bits & 0x7f800000) >> 23) - 127;
//dending on your internal mipmap-structure you maybe need to add/sub 1. 
//but normally you should avoid this because any cycle counts.
