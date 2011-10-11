module wrt.objects.Instanting;

/*

import wrt.objects.a3DObject : a3DObject;
import wrt.base.Ray : Ray;
import wrt.base.mat4 : mat4;
import wrt.base.vec3 : vec3;
import wrt.base.AABB : AABB;

class InstatingBVH : a3DObject {
	mat4 transf;
	mat4 inv_transf;
	BVH bvh;

	this(BVH bvh_) {
		bvh = bvh_;
	}

	AABB getAABB() {
		return obj.aabb;
	}

	static hitinfo hi;
	static Ray ray2;

	bool isIntersecting(ref Ray, float t_already = 1.0f/0.0f) {
		ray2 = Ray.create(inv_transf*ray.start, inv_transf*ray.direction);
		
		hi = bvh.recurse(ray2, t_already);
	}

	float intersectT(ref Ray) {
	}
	vec3 intersectionPoint(ref Ray) {
	}
	vec3 normalAtIntersection(ref Ray) {
	}

	Ray reflectionRay(ref Ray) {
	}
	Ray refractionRay(ref Ray) {
	}

	// Material transformation
	Material material;
	Material getMaterial() {
		return material;
	}

	void setMaterial(Material material_) {
		material = material_;
	}

	vec3 getCenter();
	AABB getAABB();

	// texture maping
	float get_u();
	float get_v();
}
*/
