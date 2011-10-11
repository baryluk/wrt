module wrt.base.vec3;

import std.math : sqrt;
import std.stdio : writef;

import wrt.base.memory: alloc, dealloc;

import wrt.base.mat4 : mat4;
import wrt.base.misc : min, max;

align(16) struct vec3 {
	union {
		struct {
			float x;
			float y;
			float z;
			float dummy = 0.0;
		}
		struct {
			float cell[4];
		}
	}


	//static const ALIGMENT = 16;

	new(size_t sz) {
		//return alloc(sz, ALIGMENT);
		return alloc(sz, 16);
	}
	delete(void* p) {
		return dealloc(p);
	}

	const static vec3 pinf = vec3(1.0f/0.0f, 1.0f/0.0f, 1.0f/0.0f);
	const static vec3 minf = vec3(-1.0f/0.0f, -1.0f/0.0f, -1.0f/0.0f);

	const static vec3 X_AXIS = vec3(1.0f, 0.0f, 0.0f);
	const static vec3 Y_AXIS = vec3(0.0f, 1.0f, 0.0f);
	const static vec3 Z_AXIS = vec3(0.0f, 0.0f, 1.0f);

	const static vec3 I = vec3(1.0f, 1.0f, 1.0f);

	float opMul(ref vec3 b) {
		return x*b.x + y*b.y + z*b.z;
	}

	float norm2() {
		return x*x + y*y + z*z;
	}


	void normalize() {
		//opDivAssign(sqrt(norm2()));
		
		// John Carmacks from Id Soft. Quake3, code probably
		// or mayby Hary Tarolli from Nvidia
		// this is slightly optimised version,
		// see http://www.lomont.org/Math/Papers/2003/InvSqrt.pdf
		float p = norm2();
		final float phalf = 0.5f*p;
		uint i = *(cast(int*)(&p)); // get bits for floating value
		i = 0x5f375a86u - (i>>1);   // gives initial guess y0
		p = *(cast(float*)(&i));    // convert bits back to float
		p = p*(1.5f - phalf*p*p);   // Newton step, repeating increases accuracy

		opMulAssign(p);
	}

	vec3 opNeg() {
		return vec3(-x, -y, -z);
	}

	vec3 opMul(float c) {
		return vec3(x*c, y*c, z*c);
	}

	vec3 opDiv(float c) {
		return vec3(x/c, y/c, z/c);
	}


	vec3 mul_elems(ref vec3 b) {
		return vec3(x*b.x, y*b.y, z*b.z);
	}

	vec3 opAdd(ref vec3 b) {
		return vec3(x+b.x, y+b.y, z+b.z);
	}

	vec3 opDiv(ref vec3 b) {
		return vec3(x/b.x, y/b.y, z/b.z);
	}

	vec3 opSub(ref vec3 b) {
		return vec3(x-b.x, y-b.y, z-b.z);
	}

	void opAddAssign(ref vec3 b) {
		x += b.x;
		y += b.y;
		z += b.z;
	}

	void opSubAssign(ref vec3 b) {
		x -= b.x;
		y -= b.y;
		z -= b.z;
	}

	void opMulAssign_r(float c) {
		x *= c;
		y *= c;
		z *= c;
	}

	void opDivAssign(float c) {
		x /= c;
		y /= c;
		z /= c;
	}

	float getMax() {
		return max(x, y, z);
	}

	float getMin() {
		return min(x, y, z);
	}

/*
	static vec3 vecmin(vec3 a, vec3 b) {
		return vec3(
			min(a.x, b.x),
			min(a.y, b.y),
			min(a.z, b.z)
		);
	}

	static vec3 vecmax(vec3 a, vec3 b) {
		return vec3(
			max(a.x, b.x),
			max(a.y, b.y),
			max(a.z, b.z)
		);
	}
*/

	static vec3 vecmin(ref vec3 a, ref vec3 b) {
		return vec3(
			(a.x < b.x ? a.x : b.x),
			(a.y < b.y ? a.y : b.y),
			(a.z < b.z ? a.z : b.z)
		);
	}

	static vec3 vecmax(ref vec3 a, ref vec3 b) {
		return vec3(
			(a.x > b.x ? a.x : b.x),
			(a.y > b.y ? a.y : b.y),
			(a.z > b.z ? a.z : b.z)
		);
	}


	void print() {
		writef("[ %.5f %.5f %.5f ]", x, y, z);
	}


	void opMulAssign(ref mat4 m) {
		cell[] = [m.xx*x + m.xy*y + m.xz*z + m.xw,
		m.yx*x + m.yy*y + m.yz*z + m.yw,
		m.zx*x + m.zy*y + m.zz*z + m.zw, 0.0f/0.0f];
	}
}
