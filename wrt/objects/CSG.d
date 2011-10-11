module wrt.objects.CSG;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;
import wrt.base.misc : cross, INV_PI, INV_PI2;
import wrt.Material : Material;

import wrt.base.AABB : AABB;


/* Rules:
 *
 * A+B (sum), intersection if hited A or B, first one
 * A*B (union), intersection if hitted A and B,
 * A-B (diff), intersection if hitted A, but not B
 *
 * then intersection with suraface of CSG will be on surface of A or B.
 *
 * algorithm:
 *
 * sum:
 *    i1=A.intersect(),
 *    i2=B.intersect(),
 *    return min(i1,i2) if any
 * union:
 *    i1=A.intersect(), if false return,
 *    i2=B.intersect(), if false return
 *
 *    we are taking i1[0] (first intersection with A), and test, if B.inside(i1[0])
 *       if so, 
 */

final class CSG : a3DObject {
	this() {
	}

	struct op {
		a3DObject a;
		a3DObject b;
		int op;
	}

	override bool intersect(ref Ray ray, float t_min = 0.0f, float t_already = 1.0/0.0f)
	{
		
	}

	override vec3 normalAtIntersection(ref Ray ray)
	{
		return normal;
	}

	override vec3 intersectionPoint(ref Ray ray)
	{
		return intersection; /// point of itersection
	}

	override Ray reflectionRay(ref Ray ray)
	{
		return Ray.reflectionRay(intersection, ray.direction, 1.0f, dn, normal);
	}

	override Ray refractionRay(ref Ray ray)
	{
		final float m1tom2 = (entering ? ray.refractive_index / material.refractive_index : material.refractive_index / ray.refractive_index);
		return Ray.refractionRay(intersection, ray.direction, m1tom2, dn, normal);
	}

	vec3 north = vec3(0.0f, 1.0f, 0.0f);
	vec3 equator = vec3(0.0f, 0.0f, 1.0f);

	vec3 ne;

	// for uv texturing
	override void get_uv(ref float u_, ref float v_)
	{
	}

	// for 3D texturing
	vec3 get_xyz() {
		return intersection;
	}

	override AABB getAABB() {
		return aabb;
	}
}
