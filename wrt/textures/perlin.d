module wrt.textures.perlin;

float noise_1D(int seed, int x) {
	x = x ^ seed;
	x = (x<<13) ^ x;
	x = x ^ (seed << 11);
	return (1.0f - ((x*(x*x*15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0f);
}

float noise_2D(int seed, int x, int y) {
	return noise_1D(seed, 98173897 * x + 89148979 * y);
}

float noise_3D(int seed, int x, int y, int z) {
	return noise_1D(seed, 73263419 * x + 98317411 * y + 98178411 * z);
}


float smoothedNoise_1D(int seed, int x) {
	return noise_1D(seed, x)/2.0f + noise_1D(seed, x-1)/4.0f + noise_1D(seed, x+1)/4.0f;
}

float smoothedNoise_2D(int seed, int x, int y) {
	return noise_2D(seed, x-1, y-1)/16.0f + noise_2D(seed, x-1, y)/8.0f + noise_2D(seed, x-1, y+1)/16.0f
	     + noise_2D(seed, x, y-1)/8.0f    + noise_2D(seed, x, y)/4.0f   + noise_2D(seed, x, y+1)/8.0f
	     + noise_2D(seed, x+1, y-1)/16.0f + noise_2D(seed, x+1, y)/8.0f + noise_2D(seed, x+1, y+1)/16.0f;
}

float smoothedNoise_3D(int seed, int x, int y, int z) {
	return
	0.5f*(
		noise_3D(seed, x-1, y-1, z-1)/32.0f + noise_3D(seed, x-1, y, z-1)/16.0f + noise_3D(seed, x-1, y+1, z-1)/32.0f
	     + noise_3D(seed, x, y-1, z-1)/16.0f    + noise_3D(seed, x, y, z-1)/8.0f   + noise_3D(seed, x, y+1, z-1)/16.0f
	     + noise_3D(seed, x+1, y-1, z-1)/32.0f + noise_3D(seed, x+1, y, z-1)/16.0f + noise_3D(seed, x+1, y+1, z-1)/32.0f

		 + noise_3D(seed, x-1, y-1, z)/16.0f + noise_3D(seed, x-1, y, z)/8.0f + noise_3D(seed, x-1, y+1, z)/16.0f
	     + noise_3D(seed, x, y-1, z)/8.0f    + noise_3D(seed, x, y, z)/4.0f   + noise_3D(seed, x, y+1, z)/8.0f
	     + noise_3D(seed, x+1, y-1, z)/16.0f + noise_3D(seed, x+1, y, z)/8.0f + noise_3D(seed, x+1, y+1, z)/16.0f

		 + noise_3D(seed, x-1, y-1, z+1)/32.0f + noise_3D(seed, x-1, y, z+1)/16.0f + noise_3D(seed, x-1, y+1, z+1)/32.0f
	     + noise_3D(seed, x, y-1, z+1)/16.0f    + noise_3D(seed, x, y, z+1)/8.0f   + noise_3D(seed, x, y+1, z+1)/16.0f
	     + noise_3D(seed, x+1, y-1, z+1)/32.0f + noise_3D(seed, x+1, y, z+1)/16.0f + noise_3D(seed, x+1, y+1, z+1)/32.0f);
}

float interpolate_1D(float a, float b, float x) {
//	linear interpolation
	return a*(1.0f-x) + b*x;
//	cosine interpolation
//	float f = (1.0f - cos(x * 3.1415927f)) * 0.5f;
//	return  a*(1.0f-f) + b*f;
}

float interpolatedNoise_1D(int seed1, int seed2, float x) {
	final int intx = cast(int)x;
	final float fractx = x - intx;
	final int s = seed1*seed2 + (seed1^seed2);
	final float v1 = smoothedNoise_1D(s, intx);
	final float v2 = smoothedNoise_1D(s, intx+1);
	return interpolate_1D(v1, v2, fractx);
}

float interpolatedNoise_2D(int seed1, int seed2, float x, float y) {
	final int intx = cast(int)x;
	final float fractx = x - intx;
	final int inty = cast(int)y;
	final float fracty = y - inty;
	final int s = seed1*seed2 + (seed1^seed2);
	final float v1 = smoothedNoise_2D(s, intx, inty);
	final float v2 = smoothedNoise_2D(s, intx+1, inty);
	final float v3 = smoothedNoise_2D(s, intx, inty+1);
	final float v4 = smoothedNoise_2D(s, intx+1, inty+1);

	final float i1 = interpolate_1D(v1, v2, fractx);
	final float i2 = interpolate_1D(v3, v4, fractx);

	return interpolate_1D(i1, i2, fracty);
}

float interpolatedNoise_3D(int seed1, int seed2, float x, float y, float z) {
	final int intx = cast(int)x;
	final float fractx = x - intx;
	final int inty = cast(int)y;
	final float fracty = y - inty;
	final int intz = cast(int)z;
	final float fractz = z - intz;
	final int s = seed1*seed2 + (seed1^seed2);

	final float v1 = smoothedNoise_3D(s, intx, inty, intz);
	final float v2 = smoothedNoise_3D(s, intx+1, inty, intz);
	final float v3 = smoothedNoise_3D(s, intx, inty+1, intz);
	final float v4 = smoothedNoise_3D(s, intx+1, inty+1, intz);

	final float v5 = smoothedNoise_3D(s, intx, inty, intz+1);
	final float v6 = smoothedNoise_3D(s, intx+1, inty, intz+1);
	final float v7 = smoothedNoise_3D(s, intx, inty+1, intz+1);
	final float v8 = smoothedNoise_3D(s, intx+1, inty+1, intz+1);

	final float i1 = interpolate_1D(v1, v2, fractx);
	final float i2 = interpolate_1D(v3, v4, fractx);

	final float j1 = interpolate_1D(i1, i2, fracty);

	final float i3 = interpolate_1D(v5, v6, fractx);
	final float i4 = interpolate_1D(v7, v8, fractx);

	final float j2 = interpolate_1D(i3, i4, fracty);

	return interpolate_1D(j1, j2, fractz);
}


float perlin_noise_1D(int seed, float x) {
	enum doubling_factor = 2.0f;
	const float persistance = 0.45f;
	float total = 0.0f;
	float frequency = 1.0f;
	float amplitude = 0.5f;
	for (int i = 0; i < 8; i++) {
//		total += amplitude * interpolatedNoise_1D(seed, i, x*frequency);
		total += amplitude * interpolatedNoise_1D(seed, i, x);
		x *= doubling_factor;
//		frequency *= doubling_factor;
		amplitude *= persistance;
	}
	return total;
}

float perlin_noise_2D(int seed, float x, float y) {
	enum doubling_factor = 2.0f;
	const float persistance = 0.5f;
	float total = 0.0f;
	//float frequency = 1.0f;
	float amplitude = 0.5f;
	for (int i = 0; i < 8; i++) {
//		total += amplitude * interpolatedNoise_2D(seed, i, x*frequency, y*frequency);
		total += amplitude * interpolatedNoise_2D(seed, i, x, y);
		x *= doubling_factor;
		y *= doubling_factor;
//		frequency *= doubling_factor;
		amplitude *= persistance;
	}
	return total;
}

float perlin_noise_3D(int seed, float x, float y, float z) {
	enum doubling_factor = 2.0f;
	const float persistance = 0.5f;
	float total = 0.0f;
//	float frequency = 1.0f;
	float amplitude = 0.5f;
	for (int i = 0; i < 8; i++) {
		//total += amplitude * interpolatedNoise_3D(seed, i, x*frequency, y*frequency, z*frequency);
		total += amplitude * interpolatedNoise_3D(seed, i, x, y, z);
		x *= doubling_factor;
		y *= doubling_factor;
		z *= doubling_factor;
//		frequency *= doubling_factor;
		amplitude *= persistance;
	}
	return total;
}

version (modified_fbm) {

/* See also http://iquilezles.org/www/articles/morenoise/morenoise.htm 
 * How to compute derivatives of perlin noise quickly (important for perlin_noise_3D for normal vectors).
 *
 */

float perlin_noise_3d_fbm_modified(int seed, float x, float y) {
	enum doubling_factor = 2.0f;
	const float persistance = 0.5f;
	float total = 0.0f;
	float amplitude = 0.5f;
	float sum_dx = 0.0f;
	float sum_dz = 0.0f;
	float dx, dz;
	for (int i = 0; i < ioct; i++) {
		float n0 = interpolatedNoise_3d_and_derivatives(seed, i, x, y, &dx, &dz);
		sum_dx += n[0];
		sum_dz += n[1];
		total += amplitude * n[0] / (1.0f + sum_dx*sum_dx + sum_dz*sum_dz);  // modified fmb
//		total += amplitude * n[0]; // classic fbm
		amplitude *= persistance;
		x *= doubling_factor;
		y *= doubling_factor;
	}
	return total;
}

}
