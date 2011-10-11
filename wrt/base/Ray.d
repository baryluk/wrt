module wrt.base.Ray;

import std.math : sqrt;
import std.stdio : writef;

import wrt.base.memory: alloc, dealloc;


import wrt.base.vec3 : vec3;
import wrt.objects.a3DObject : a3DObject;

struct hitinfo {
	a3DObject obj;
	float t = 1.0f/0.0;
	static hitinfo nohit = hitinfo(null, 1.0f/0.0f);
}


// consistent with AABB.d
//version=aabbraytest_amy;
//version=aabbraytest_amy_withinvs;
//version=aabbraytest_amy_withinvs_and_early_end_and_paramlist;
version=aabbraytest_fyffe;

/// x = s + t*d
/// t is positive parameter
/// And additional acceleration parameters for AABB intersections
align(16) struct Ray {
	/*const*/ vec3 start;
	vec3 direction = vec3(0.0f, 0.0f, 0.0f);
	vec3 inv_direction;

version(aabbraytest_amy_withinvs_and_early_end_and_paramlist) {
	ubyte[6] aabbtest_cellnum;
}
version(aabbraytest_amy) {
	ubyte[4] sign;
}
version(aabbraytest_amy_withinvs) {
	ubyte[4] sign;
	ubyte[4] invsign;
}
version(aabbraytest_fyffe) {
	ubyte[6] aabbtest_cellnum;
}


	hitinfo hi;

	bool isValid() {
		return direction != vec3(0.0f, 0.0f, 0.0f);
	}

	const float refractive_index = 1.0f;

	static Ray create(vec3 start_, vec3 direction_) {
		direction_.normalize(); // not always nacasary
		Ray a = Ray(start_, direction_, vec3.I/direction_);
		a.actualize_signs();
		return a;
	}

	void actualize_signs() {
version(aabbraytest_amy_withinvs_and_early_end_and_paramlist) {
		aabbtest_cellnum[0] = cast(ubyte)(inv_direction.x < 0.0f ? 4 : 0); // 4*sign[0] + 0
		aabbtest_cellnum[3] = cast(ubyte)(inv_direction.y < 0.0f ? 5 : 1); // 4*sign[0] + 1
		aabbtest_cellnum[4] = cast(ubyte)(inv_direction.z < 0.0f ? 6 : 2); // 4*sign[0] + 2

		aabbtest_cellnum[2] = cast(ubyte)(inv_direction.x < 0.0f ? 0 : 4); // 4*invsign[0] + 0
		aabbtest_cellnum[1] = cast(ubyte)(inv_direction.y < 0.0f ? 1 : 5); // 4*invsign[0] + 1
		aabbtest_cellnum[5] = cast(ubyte)(inv_direction.z < 0.0f ? 2 : 6); // 4*invsign[0] + 2
}

version(aabbraytest_amy) {
		sign[0] = cast(ubyte)(inv_direction.x < 0.0f ? 1 : 0);
		sign[1] = cast(ubyte)(inv_direction.y < 0.0f ? 1 : 0);
		sign[2] = cast(ubyte)(inv_direction.z < 0.0f ? 1 : 0);
	version(aabbraytest_amy_withinvs) {
		invsign[0] = cast(ubyte)(inv_direction.x < 0.0f ? 0 : 1);
		invsign[1] = cast(ubyte)(inv_direction.y < 0.0f ? 0 : 1);
		invsign[2] = cast(ubyte)(inv_direction.z < 0.0f ? 0 : 1);
	}
}

// tak na oko to samo co amy_with_paramlist, ale mniej branchow
version(aabbraytest_fyffe) {
	aabbtest_cellnum[0] /* highIndexX */ = cast(ubyte)(inv_direction.x < 0.0f ? 0 : 1);
	aabbtest_cellnum[1] /* lowIndexX */ = cast(ubyte)(1 - aabbtest_cellnum[0]);
	aabbtest_cellnum[2] /* highIndexY */ = cast(ubyte)(inv_direction.y < 0.0f ? 0 : 1);
	aabbtest_cellnum[3] /* lowIndexY */ = cast(ubyte)(1 - aabbtest_cellnum[2]);
	aabbtest_cellnum[4] /* highIndexZ */ = cast(ubyte)(inv_direction.z < 0.0f ? 0 : 1);
	aabbtest_cellnum[5] /* lowIndexZ */ = cast(ubyte)(1 - aabbtest_cellnum[4]);

	aabbtest_cellnum[0] /* highIndexX */ = 4 * aabbtest_cellnum[0] + 0;
	aabbtest_cellnum[1] /* lowIndexX */ = 4 * aabbtest_cellnum[1] + 0;
	aabbtest_cellnum[2] /* highIndexY */ = 4 * aabbtest_cellnum[2] + 1;
	aabbtest_cellnum[3] /* lowIndexY */ = 4 * aabbtest_cellnum[3] + 1;
	aabbtest_cellnum[4] /* highIndexZ */ = 4 * aabbtest_cellnum[4] + 2;
	aabbtest_cellnum[5] /* lowIndexZ */ = 4 * aabbtest_cellnum[5] + 2;
}
	}

	vec3 get(float t) {
		return start + t*direction;
	}

	void direct_to(vec3 to_) {
		direction = (to_ - start);
		direction.normalize();
		inv_direction = vec3.I/direction;
		actualize_signs();
	}

	void print() {
		writef("(%.3f,%.3f,%.3f) -> (%.3f,%.3f,%.3f)", start.x, start.y, start.z, direction.x, direction.y, direction.z);
	}

    /**
     *                 _
     *       \   /|\   /|
     *        \   |n  /
     *      d  \  |  / r
     *         _\|| /
     * -----------+-------------
     *            p
     *
     *   r = d - 2*(n*d)*n
     *
	 */
	static Ray reflectionRay(in vec3 intersection, in vec3 direction, float m1tom2, float dn, in vec3 normal)
	in {
//		float x = (direction*normal);
//		assert(dn == x);
	}
	body {
		// now calculating new direction, and construct new ray
		return Ray.create(intersection, direction - 2.0f*dn * normal);
	}

	/**
	 *         a
	 *       \   /|\
	 *        \   | n
	 *      d  \  |          m1
	 *         _\||
	 * -----------+-------------
	 *           p||
	 *            | \        m2
	 *            |  |  r
	 *            |   \
	 *            | b _|/
	 *
	 *  warunek katow (sin a/sin b = m2/m1):  sqrt( 1 - m1^2/m2^2 (1 - (d*n)^2) ) = r*d
	 *  warunek normalizacji: r*r = 1
	 *  warunek jednej plaszczysny: (d x n) * r = 0
	 *
	 *  w skrocie:
	 *   r*r = 1
	 *   r*d = c1        // d pewien wektor, c1 pewna stala (chyba dodania)
	 *   r*p = 0         // p pewien wektor
	 *
	 * rozwiazanie:
	 *   r = m1/m2 (d-n)(d*n) - n sqrt( 1 - m1^2 / m2^2 (1 - (d*n)^2) )
	 *
	 * Snell's law
	 */
	static Ray refractionRay(in vec3 intersection, in vec3 direction, float m1tom2, float dn, in vec3 normal)
	in {
//		float x = (direction*normal);
//		assert(dn == x);
	}
	body {
		final float s = 1.0f - m1tom2*m1tom2 * (1.0f - dn*dn);
		//s += 1.0e-5;
		if (s <= 0.0f) {
			return Ray(); // total internal reflection
		}
		return Ray.create(intersection, m1tom2*direction + (sqrt(s) + dn*m1tom2) * normal);
	}

	static void fresnelCoeff(in vec3 incident_dir, float m1tom2, float dn, in vec3 normal, in vec3 reflection_dir, in vec3 refraction_dir, out float R, out float T) {
		/**
		 * r_perpendicular = (ni*cos(theta_i) - nt*cos(theta_t)) / (ni*cos(theta_i) + nt*cos(theta_t))
		 * t_perpendicular = 2*ni*cos(theta_i) / (ni*cos(theta_i) + nt*cos(theta_t))
		 * r_parallel = (nt*cos(theta_i) - ni*cos(theta_t)) / (nt*cos(theta_i) + ni*cos(theta_t))
		 * t_parallel = 2*ni*cos(theta_i) / (ni*cos(theta_t) + nt*cos(theta_i))
		 *
		 * Considering Snell's law:
		 * r_perpendicular = - sin(theta_i - theta_t) / sin(theta_i + theta_t)
		 * r_parallel = tan(theta_i - theta_t) / tan(theta_i + theta_t)
		 * t_perpendicular = 2 sin(theta_t) cos(theta_i) / sin(theta_i + theta_t)
		 * t_parallel = t_pependicular / cos(theta_i - theta_t)
		 */
/*
		final float cos_i = -dn;
		final float sin_i = sqrt(1.0f - cos_i*cos_i);
		final float sin_r = sin_i * m1tom2;
		final float cor_r = sqrt(1.0f - sin_r*sin_r);
		float cos_ratio = cos_i / cos_r;
		final float r_parallel = (cos_ratio - m1tom2) / (cos_ratio + m1tom2);
		cos_ratio = cos_r / cos_i;
		final float r_perpendicular = (cos_ratio - m1tom2) / (cos_ratio + m1tom2);
		R = 0.5f*(r_parallel*r_parallel + r_perpendicular*r_perpendicular)
		T = 1.0f - R;
*/
		final float m1tom2_sqr = m1tom2*m1tom2;
		final float cos_i = -dn;
		final float c = cos_i * m1tom2;
		final float g = sqrt(1.0f + c*c - m1tom2_sqr);
		final float gplusc = g+c;
		final float gminusc = g-c;
		float temp1 = gminusc*gplusc;
		float temp2 = (c*gplusc - m1tom2_sqr) / (c*gminusc + m1tom2_sqr);
		R = 0.5f * (temp1*temp1) * (1.0f + temp2*etmp2);
		T = 1.0f - R;
	}

	static const ALIGMENT = 16;

	new(size_t sz) {
		return alloc(sz, ALIGMENT);
	}
	delete(void* p) {
		return dealloc(p);
	}

}


/** Empty segment, is when far < near
 * Point segment is when far == near
 */

align(16) struct raysegment {
	float near, far;

	bool notZero() {
		return (far >= near);
	}

	static nohit = raysegment(1.0f/0.0f, -1.0f/0.0f);

	static const ALIGMENT = 16;

	new(size_t sz) {
		return alloc(sz, ALIGMENT);
	}
	delete(void* p) {
		return dealloc(p);
	}
}
