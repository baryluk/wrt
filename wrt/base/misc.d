module wrt.base.misc;

import wrt.base.vec3 : vec3;

const float PI = 3.141592f;
const float PI2 = 2.0f*PI;
const float INV_PI = 1.0f/PI;
const float INV_PI2 = 1.0f/(2.0f*PI);

float sqr(float x) {
	return x*x;
}

double sqr(double x) {
	return x*x;
}

vec3 cross(ref vec3 a, ref vec3 b) {
	return vec3(a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x);
}

vec3 solve(ref vec3 a1, ref vec3 a2, ref vec3 a3, ref vec3 b) {
	vec3 x;

	final float det = a1.x*a2.y*a3.z + a1.z*a2.x*a3.y + a1.y*a2.z*a3.x
		- a1.x*a2.z*a3.y - a1.z*a2.y*a3.x - a1.y*a2.x*a3.z;

	if (det == 0.0f) {
		return vec3();
	//	throw new Error("det zero");
	}

	x.x = b.x*a2.y*a3.z + b.z*a2.x*a3.y + b.y*a2.z*a3.x
		- b.x*a2.z*a3.y - b.z*a2.y*a3.x - b.y*a2.x*a3.z;

	x.y = a1.x*b.y*a3.z + a1.z*b.x*a3.y + a1.y*b.z*a3.x
		- a1.x*b.z*a3.y - a1.z*b.y*a3.x - a1.y*b.x*a3.z;

	x.z = a1.x*a2.y*b.z + a1.z*a2.x*b.y + a1.y*a2.z*b.x
		- a1.x*a2.z*b.y - a1.z*a2.y*b.x - a1.y*a2.x*b.z;

	x /= det;

	return x;
}

float min(float a, float b, float c) {
	return (b < c ? (a < b ? a : b) : (a < c ? a : c));
}

float max(float a, float b, float c) {
	return (b > c ? (a > b ? a : b) : (a > c ? a : c));
}

float min(float a, float b) {
	return (a < b ? a : b);}

float max(float a, float b) {
	return (a > b ? a : b);
}


// dokledniejszy pod adresem: http://lucille.svn.sourceforge.net/svnroot/lucille/angelina/haskellmuda/libm/log2.mu
// dokladnosc 2ulp
float fast_log2(float val) {
	final int* exp_ptr = cast(int*) (&val);
	int x = *exp_ptr;
	final int log_2 = ((x >> 23) & 255) - 128;
	x &= ~(255 << 23);
	x += (127 << 23);
	*exp_ptr = x;
	return (val + log_2);
}
