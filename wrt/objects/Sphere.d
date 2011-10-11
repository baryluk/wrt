module wrt.objects.Sphere;

import std.math : acos, sin, sqrt;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;
import wrt.base.misc : cross, INV_PI, INV_PI2;
import wrt.Material : Material;

import wrt.base.AABB : AABB;


// for manual allocation
version (D_Version2) {
import cstdlib = core.stdc.stdlib;
import core.exception : oom = OutOfMemoryError;
import sgc = core.memory;
} else {
import cstdlib = std.c.stdlib;
import std.outofmemory : oom = OutOfMemoryException;
import sgc = std.gc;
}

// ||x - c||^2 = r^2
final class Sphere : a3DObject {
	new(size_t sz) {
		void* p;

		p = cstdlib.malloc(sz);
		if (!p) {
			throw new oom();
		}
		sgc.addRange(p, p + sz);
		return p;
    }

	delete(void* p) {
		if (p) {
			sgc.removeRange(p);
			cstdlib.free(p);
		}
	}



// initial values
	/*const*/ vec3 center;		// used
	const float radius;	// used
	const float sqr_radius; // used
	const float inv_radius; // used

	this(vec3 center_, float radius_, rgb color_ = rgb.BLACK) {
		center = center_;
		radius = radius_;
		sqr_radius = radius*radius;
		inv_radius = 1.0f/(radius+0.1e-3f);
		ne = cross(north, equator);
		material = new Material(color_);
	}

	override vec3 getCenter() {
		return center;
	}

// caching
	/// some temporaries, for reuse of previous computations
	static double delta;
	static double t0;
	static double vd, dn;
debug {
	static Sphere last_sphere;
}
	static vec3 normal, intersection;

	// ||x - c||^2 = r^2
	// ||s-c + t*d||^2 = r^2
	// v := s-c
	// v^2 + t * 2(v*d) + t^2 * d*d - r^2 = 0
	// d*d t^2 + 2*v*d + (v*v - r^2) = 0
	// delta = (2*v*d)^2 - 4*d*d*(v*v-r^2)
	// t1 = (-2*v*d - sqrt(delta) / (2*d*d)
	// t2 = (-2*v*d + sqrt(delta) / (2*d*d)
	bool entering;

	override bool intersect(ref Ray ray, float t_min = 0.0f, float t_already = 1.0/0.0f)
	out (ret) {
		if (ret) {
			assert(ray.hi.obj !is null);
			assert(ray.hi.obj is this);
		}
	}
	body {
		debug {
			last_sphere = this;
		}
		final vec3 v = ray.start-center;
		vd = v*ray.direction;
		delta = vd*vd - v.norm2() + sqr_radius;
		if (delta <= 0.0f) {
			return false;
		}
		final float sqrtd = sqrt(delta);
		// last component becouse of rounding errors
		final float t1 = (-sqrtd - vd); // first
		final float t2 = (sqrtd - vd); // second
		assert(t1 <= t2);
		final float t1temp = t1 + 1.0e-4;
		final float t2temp = t2 - 1.0e-3;
		if (t1temp > t_min) {
			entering = true;
			t0 = t1temp;
		} else {
			entering = false;
			t0 = t2temp;
		}
		if (t0 > t_min && t0 < t_already && t0 < ray.hi.t) {
			ray.hi.t = t0;
			ray.hi.obj = this;
			return true;
		} else {
			return false;
		}
	}

	// ||x - c||^2 = r^2
	// x = s + t*d
	// ||(s - c) + t*d||^2 = r^2
	// ||v + t*d||^2 = r^2

	// ||x - c||^2 = r^2
	// n = (x - c) / ||x - c||
	override vec3 normalAtIntersection(ref Ray ray)
	in {
		debug assert(last_sphere is this);
		assert(t0 > 0.0f);
	}
	body {
		intersection = ray.get(t0); /// point of itersection
		normal = inv_radius * (entering ? intersection - center : center - intersection);

		// caching
		dn = (entering ? ray.direction*normal : -ray.direction*normal);
		//dn = -ray.direction*normal;

		return normal;
	}

	override vec3 intersectionPoint(ref Ray ray)
	in {
		debug assert(last_sphere is this);
		assert(t0 > 0.0f);
	}
	body {
		return intersection; /// point of itersection
	}

	override Ray reflectionRay(ref Ray ray)
	in {
		debug assert(last_sphere is this);
		assert(t0 > 0.0f);
	}
	body {
		return Ray.reflectionRay(intersection, ray.direction, 1.0f, dn, normal);
	}

	override Ray refractionRay(ref Ray ray)
	in {
		debug assert(last_sphere is this);
		assert(t0 > 0.0f);
	}
	body {
		final float m1tom2 = (entering ? ray.refractive_index / material.refractive_index : material.refractive_index / ray.refractive_index);
		return Ray.refractionRay(intersection, ray.direction, m1tom2, dn, normal);
	}

	vec3 north = vec3(0.0f, 1.0f, 0.0f);
	vec3 equator = vec3(0.0f, 0.0f, 1.0f);

	vec3 ne;

	// for uv texturing
	override void get_uv(ref float u_, ref float v_)
	in {
		debug assert(last_sphere is this);
	}
	body {
		/*final*/ vec3 vp = inv_radius * (intersection-center); // prawie jak normal, tyle ze +-
		final float phi = acos(-(north*vp));
		v_ = INV_PI * phi;
		u_ = (
			ne*vp > 0.0f
			?
			acos(vp*equator / sin(phi)) * INV_PI2
			:
			1.0f - acos(vp*equator / sin(phi)) * INV_PI2
		);
	}

	// for 3D texturing
	vec3 get_xyz() {
		return normal;
	}

	override AABB getAABB() {
		return AABB(center - (1.0001f*radius)*vec3.I, center + (1.0001f*radius)*vec3.I);
	}
}

// http://www.cs.unc.edu/~rademach/xroads-RT/RTarticle.html
