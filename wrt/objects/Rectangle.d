module wrt.objects.Rectangle;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;
import wrt.base.misc : cross;

import wrt.base.AABB : AABB;

// p = start + u*a + v*b; // a,b \in [0,1]
//  ray = ray_start + t*direction;
final class Rectangle : a3DObject {
	vec3 start, a, b;
	vec3 normal;
	float d;

	this(vec3 start_, vec3 a_, vec3 b_) {
		start = start_;
		a = a_;
		b = b_;

		normal = cross(a-start, b-start);

		d = - (start*normal);
	}

	override vec3 getCenter() {
		return start + 0.5f*(a+b);
	}

// caching
	static float u, v, t;
	static Rectangle last_rectangle;
debug {
	static Rectangle last_rectangle_normal;
}
	static vec3 intersection;

	override bool intersect(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	out (ret) {
		if (ret) {
			assert(ray.hi.obj !is null);
			assert(ray.hi.obj is this);
		}
	}
	body {
		debug {
			last_rectangle = this;
		}

		// direction can be not normalized
		t = - (normal * ray.start + d) / (normal * ray.direction);

		// t can be -+inf, if n*dir == 0
		if (t < t_min || t > t_already || t > ray.hi.t) {
			return false;
		}

		intersection = ray.get(t);

		vec3 inplane = intersection-start;

		ray.hi.t = t;
		ray.hi.obj = this;
		return true;
	}

	override vec3 normalAtIntersection(ref Ray ray)
	in {
		debug assert(last_rectangle is this);
		debug {
			last_rectangle_normal = this;
		}
	}
	body {
		//intersection = ray.start + t*ray.direction;
		return normal;
	}

	override vec3 intersectionPoint(ref Ray ray)
	in {
		debug assert(last_rectangle is this);
		debug assert(last_rectangle_normal is this);
	}
	body {
		return intersection;
	}

	override Ray reflectionRay(ref Ray ray)
	in {
		debug assert(last_rectangle is this);
	}
	body {
		return Ray.reflectionRay(intersection, ray.direction, 1.0f, ray.direction*normal, normal);
	}

	override Ray refractionRay(ref Ray ray)
	in {
		debug assert(last_rectangle is this);
	}
	body {
		return Ray.create(intersection, ray.direction);
	}

	override void get_uv(ref float u_, ref float v_)
	in {
		debug assert(last_rectangle is this);
	}
	body {
		u_ = 0.5f;
		v_ = 0.5f;
	}

	override AABB getAABB() {
		return AABB(
			vec3.vecmin(vec3.vecmin(start, start+a), vec3.vecmin(start+b, start+a+b)),
			vec3.vecmax(vec3.vecmax(start, start+a), vec3.vecmax(start+b, start+a+b))
		);
	}
}
