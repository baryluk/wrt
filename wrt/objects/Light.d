module wrt.objects.Light;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;

import wrt.base.AABB : AABB;

abstract class Light : a3DObject {
	override vec3 getCenter();
	rgb getEmittance(float);

// a3DObject interfaces follows
	override bool intersect(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f) {
		return false;
	}
	override vec3 intersectionPoint(ref Ray ray) {
		throw new Exception("not intersecting");
	}
	override vec3 normalAtIntersection(ref Ray ray) {
		throw new Exception("not intersecting");
	}
	override Ray reflectionRay(ref Ray ray) {
		throw new Exception("not intersecting");
	}
	override Ray refractionRay(ref Ray ray) {
		throw new Exception("not intersecting");
	}
	override void get_uv(ref float u, ref float v) {
		u = 0.5f;
		v = 0.5f;
	}
}

final class PointLight : Light {
	const vec3 center;
	override vec3 getCenter() {
		return center;
	}

	const rgb emittance;
	override rgb getEmittance(float t) {
		t += 0.2f;
		return 1.0/(t*t) * emittance;
	}

	this(vec3 center_, rgb emittance_) {
		center = center_;
		emittance = emittance_;
	}

	override AABB getAABB() {
		return AABB(center - 1.0e-3f*vec3.I, center + 1.0e-3f*vec3.I);
	}
}
