module wrt.objects.PlanePrim;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;

import wrt.Material : Material;

import wrt.base.AABB : AABB;

final class PlanePrim : a3DObject {
// initial values
	/*const*/ vec3 normal;
	float adist;

	this(vec3 normal_, float adist_) {
		normal = normal_;
		adist = adist_;
		material = new Material(rgb.GREEN);
	}

	override vec3 getCenter() {
		return vec3.I;
	}

// caching
debug {
	static PlanePrim last_plane;
}
	static float t;

	override bool intersect(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	out (ret) {
		if (ret) {
			assert(ray.hi.obj !is null);
			assert(ray.hi.obj is this);
		}
	}
	body {
		debug {
			last_plane = this;
		}
		final float d = normal * ray.direction;
		if (d == 0.0f) {
			return false;
		}
		t = (-1.0f/d) * (normal*ray.start + adist);
		if (t > t_min || t > ray.hi.t) {
			return false;
		}
		ray.hi.t = t;
		ray.hi.obj = this;
		return true;
	}

	override vec3 intersectionPoint(ref Ray ray)
	in {
		debug assert(last_plane is this);
	}
	body {
		return ray.start + t*ray.direction;
	}

	override vec3 normalAtIntersection(ref Ray ray)
	in {
		debug assert(last_plane is this);
	}
	body {
		return normal;
	}

	override Ray reflectionRay(ref Ray ray)
	in {
		debug assert(last_plane is this);
	}
	body {
		return Ray.reflectionRay(intersectionPoint(ray), ray.direction, 1.0f, ray.direction*normal, normal);
	}

	override Ray refractionRay(ref Ray ray) {
		return Ray.create(ray.start, ray.direction);
	}

	override void get_uv(ref float u, ref float v) {
		u = 0.5f;
		v = 0.5f;
	}

	override AABB getAABB() {
		return AABB();
	}

}
