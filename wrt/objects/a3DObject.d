module wrt.objects.a3DObject;

import wrt.base.vec3 : vec3;
import wrt.base.Ray : Ray;
import wrt.Material : Material;
import wrt.base.AABB : AABB;

abstract class a3DObject {
	bool intersect(ref Ray, float t_min = 0.0f, float t_already = 1.0f/0.0f);
	vec3 intersectionPoint(ref Ray);
	vec3 normalAtIntersection(ref Ray);

	Ray reflectionRay(ref Ray);
	Ray refractionRay(ref Ray);

	Material material;
	// material properties
	Material getMaterial() {
		return material;
	}
	void setMaterial(Material material_) {
		material = material_;
	}

	vec3 getCenter();
//	float getArea();
	AABB getAABB();

	// texture maping
	void get_uv(ref float u, ref float v);

version(shadow_cache) {
	a3DObject last_occluder;
	// shadow cache
	// NOTE: for small occluders and incoherent rays, this can lead to cache trashing
	a3DObject getLastOccluder() {
		return last_occluder;
	}
	void setLastOccluder(a3DObject last_occluder_) {
		last_occluder = last_occluder_;
	}
}
}
