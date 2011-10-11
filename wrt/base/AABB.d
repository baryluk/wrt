/** Axis Alligned Bounding Box */
module wrt.base.AABB;

import std.stdio : writef;
import std.math;

import wrt.base.vec3 : vec3;
import wrt.base.Point : osie;
import wrt.base.Ray : Ray, raysegment;
import wrt.base.misc : min, max;

//version=aabbraytest_flipcode;
//version=aabbraytest_amy;
//version=aabbraytest_amy_withinvs; // cache 1-sign in Ray class, 2% faster
//version=aabbraytest_amy_withinvs_and_early_end; // next 2%
//version=aabbraytest_amy_withinvs_and_early_end_and_paramlist; // next 2%
//version=aabbraytest_gna_mono; // podobny do flipcode, wiekszy, ale szybszy na sse
//version=aabbraytest_rayslopes;
version=aabbraytest_fyffe; // fastest, bardzo podobny do amy_withinvs_and_early_end_and_paramlist,
							// ale bez early endow (procesor bardzo nie lubi if() w trakcie obliczen!)

align(16) struct AABB {
	union {
		struct {
			vec3 a = vec3.pinf; // negative bounding box
			vec3 b = vec3.minf;
		}
		vec3[2] bounds;
		float[8] cell;
	}

	invariant() {
		assert(a.x <= b.x || (a.x == 1.0f/0.0f && b.x == -1.0f/0.0f));
		assert(a.y <= b.y || (a.y == 1.0f/0.0f && b.y == -1.0f/0.0f));
		assert(a.z <= b.z || (a.z == 1.0f/0.0f && b.z == -1.0f/0.0f));
	}

	vec3 center() {
		return 0.5f*(a+b);
	}

	void print() {
		writef("AABB( %.7f %.7f %.7f - %.7f %.7f %.7f )", a.x, a.y, a.z, b.x, b.y, b.z);
	}

	AABB split(osie ax, float split_line, int part) {
		if (ax == osie.X) {
			if (part) {
				return AABB(a, vec3(split_line, b.y, b.z));
			} else {
				return AABB(vec3(split_line, a.y, a.z), b);
			}
		} else if (ax == osie.Y) {
			if (part) {
				return AABB(a, vec3(b.x, split_line, b.z));
			} else {
				return AABB(vec3(a.x, split_line, a.z), b);
			}
		} else {
			if (part) {
				return AABB(a, vec3(b.x, b.y, split_line));
			} else {
				return AABB(vec3(a.x, a.y, split_line), b);
			}
		}
	}


	void split_inplace(osie ax, float split_line, int part) {
		if (ax == osie.X) {
			if (part) {
				b.x = split_line;
			} else {
				a.x = split_line;
			}
		} else if (ax == osie.Y) {
			if (part) {
				b.y = split_line;
			} else {
				a.y = split_line;
			}
		} else {
			if (part) {
				b.z = split_line;
			} else {
				a.z = split_line;
			}
		}
	}

	bool intersect(ref raysegment rs, ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f) /* const */
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && rs.notZero()) {
//			writefln(ret, " ", t_min, " ", t_already, " ", rs.near, " ", rs.far);
			assert(t_min <= rs.near && rs.far <= t_already);
		}
	}
	body {
// http://www.flipcode.com/archives/SSE_RayBox_Intersection_Test.shtml
// http://www.flipcode.com/cgi-bin/fcarticles.cgi?show=65014
version(aabbraytest_flipcode) {
	pragma(msg, "Compiling aabbraytest_flipcode");
		final vec3 l1 = ray.inv_direction.mul_elems(a-ray.start);
		final vec3 l2 = ray.inv_direction.mul_elems(b-ray.start);
		final vec3 filtered_l1a = vec3.vecmin(l1, vec3.pinf);
		final vec3 filtered_l2a = vec3.vecmin(l2, vec3.pinf);
		final vec3 filtered_l1b = vec3.vecmax(l1, vec3.minf);
		final vec3 filtered_l2b = vec3.vecmax(l2, vec3.minf);
		final vec3 lmax = vec3.vecmax(filtered_l1a, filtered_l2a);
		final vec3 lmin = vec3.vecmin(filtered_l1b, filtered_l2b);

		raysegment rs = raysegment(max(lmin.getMax(), t_min), min(lmax.getMin(), t_already));

		if (!(t_min <= rs.near && rs.far < t_already)) {
			return raysegment.nohit;
		}

		return rs;
// http://cag.csail.mit.edu/~amy/papers/box-jgt.pdf
} else version(aabbraytest_amy) {
	pragma(msg, "Compiling aabbraytest_amy");
		float tmin = (bounds[ray.sign[0]].x - ray.start.x) * ray.inv_direction.x;
		float tmax = (bounds[1-ray.sign[0]].x - ray.start.x) * ray.inv_direction.x;
		final float tymin = (bounds[ray.sign[1]].y - ray.start.y) * ray.inv_direction.y;
		final float tymax = (bounds[1-ray.sign[1]].y - ray.start.y) * ray.inv_direction.y;
		if ( (tmin > tymax) || (tymin > tmax) ) {
			return raysegment.nohit;
		}
		if (tymin > tmin) {
			tmin = tymin;
		}
		if (tymax < tmax) {
			tmax = tymax;
		}
		final float tzmin = (bounds[ray.sign[2]].z - ray.start.z) * ray.inv_direction.z;
		final float tzmax = (bounds[1-ray.sign[2]].z - ray.start.z) * ray.inv_direction.z;
		if ( (tmin > tzmax) || (tzmin > tmax) ) {
			return raysegment.nohit;
		}
		if (tzmin > tmin) {
			tmin = tzmin;
		}
		if (tzmax < tmax) {
			tmax = tzmax;
		}

		if ( (tmin < t_already) && (tmax > t_min) ) {
			return raysegment(tmin, tmax);
		} else {
			return raysegment.nohit;
		}

//		return rs;
} else version(aabbraytest_amy_withinvs) {
	version(aabbraytest_amy_withinvs_and_early_end) {
	version(aabbraytest_amy_withinvs_and_early_end_and_paramlist) {
	pragma(msg, "Compiling aabbraytest_amy_withinvs_and_early_end_and_paramlist");
		// Bardzo szybka wersja, od 80 do 120 cykli w/g moich pomiarow

		float tmin = (cell[ray.aabbtest_cellnum[0]] - ray.start.x) * ray.inv_direction.x;
		final float tymax = (cell[ray.aabbtest_cellnum[1]] - ray.start.y) * ray.inv_direction.y;
		if ( (tmin > tymax) ) {
			return false;
		}
		float tmax = (cell[ray.aabbtest_cellnum[2]] - ray.start.x) * ray.inv_direction.x;
		final float tymin = (cell[ray.aabbtest_cellnum[3]] - ray.start.y) * ray.inv_direction.y;
		if ( (tymin > tmax) ) {
			return false;
		}

		if (tymin > tmin) {
			tmin = tymin;
		}
		if (tymax < tmax) {
			tmax = tymax;
		}
		final float tzmin = (cell[ray.aabbtest_cellnum[4]] - ray.start.z) * ray.inv_direction.z;
		if ( (tzmin > tmax) ) {
			return false;
		}
		final float tzmax = (cell[ray.aabbtest_cellnum[5]] - ray.start.z) * ray.inv_direction.z;
		if ( (tmin > tzmax)) {
			return false;
		}
		if (tzmin > tmin) {
			tmin = tzmin;
		}
		if (tzmax < tmax) {
			tmax = tzmax;
		}

		if (tmin < t_min) {
			tmin = t_min;
		}
		if (tmax > t_already) {
			tmax = t_already;
		}

		if ( (tmin < t_already) && (tmax > t_min)) {
			rs.near = tmin;
			rs.far = tmax;
			return true;
		} else {
			return false;
		}
	} else {
	pragma(msg, "Compiling aabbraytest_amy_withinvs_and_early_end");
		float tmin = (bounds[ray.sign[0]].x - ray.start.x) * ray.inv_direction.x;
		final float tymax = (bounds[ray.invsign[1]].y - ray.start.y) * ray.inv_direction.y;
		if ( (tmin > tymax) ) {
			return raysegment.nohit;
		}
		float tmax = (bounds[ray.invsign[0]].x - ray.start.x) * ray.inv_direction.x;
		final float tymin = (bounds[ray.sign[1]].y - ray.start.y) * ray.inv_direction.y;
		if ( (tymin > tmax) ) {
			return raysegment.nohit;
		}

		if (tymin > tmin) {
			tmin = tymin;
		}
		if (tymax < tmax) {
			tmax = tymax;
		}
		final float tzmin = (bounds[ray.sign[2]].z - ray.start.z) * ray.inv_direction.z;
		if ( (tzmin > tmax) ) {
			return raysegment.nohit;
		}
		final float tzmax = (bounds[ray.invsign[2]].z - ray.start.z) * ray.inv_direction.z;
		if ( (tmin > tzmax)) {
			return raysegment.nohit;
		}
		if (tzmin > tmin) {
			tmin = tzmin;
		}
		if (tzmax < tmax) {
			tmax = tzmax;
		}

		if ( (tmin < t_already) && (tmax > t_min) ) {
			return raysegment(tmin, tmax);
		} else {
			return raysegment.nohit;
		}
	}
	} else {
	pragma(msg, "Compiling aabbraytest_amy_withinvs");
		float tmin = (bounds[ray.sign[0]].x - ray.start.x) * ray.inv_direction.x;
		float tmax = (bounds[ray.invsign[0]].x - ray.start.x) * ray.inv_direction.x;
		final float tymin = (bounds[ray.sign[1]].y - ray.start.y) * ray.inv_direction.y;
		final float tymax = (bounds[ray.invsign[1]].y - ray.start.y) * ray.inv_direction.y;
		if ( (tmin > tymax) || (tymin > tmax) ) {
			return raysegment.nohit;
		}
		if (tymin > tmin) {
			tmin = tymin;
		}
		if (tymax < tmax) {
			tmax = tymax;
		}
		final float tzmin = (bounds[ray.sign[2]].z - ray.start.z) * ray.inv_direction.z;
		final float tzmax = (bounds[ray.invsign[2]].z - ray.start.z) * ray.inv_direction.z;
		if ( (tmin > tzmax) || (tzmin > tmax) ) {
			return raysegment.nohit;
		}
		if (tzmin > tmin) {
			tmin = tzmin;
		}
		if (tzmax < tmax) {
			tmax = tzmax;
		}

		if ( (tmin < t_already) && (tmax > t_min) ) {
			return raysegment(tmin, tmax);
		} else {
			return raysegment.nohit;
		}
	}
// http://cvs.gna.org/cvsweb/radius/src/rt_render_packet.cc?rev=1.3;cvsroot=radius
// znany jako intersect_ray_box_robust(...)
} else version(aabbraytest_gna_mono) {
	pragma(msg, "Compiling aabbraytest_gna_mono");
		final float xl1 = ray.inv_direction.x*(a.x-ray.start.x);
		final float xl2 = ray.inv_direction.x*(b.x-ray.start.x);
		final float xl1a = min(xl1, 1.0f/0.0f);
		final float xl2a = min(xl2, 1.0f/0.0f);
		final float xl1b = max(xl1, -1.0f/0.0f);
		final float xl2b = max(xl2, -1.0f/0.0f);

		float lmax = max(xl1a, xl2a);
		float lmin = min(xl1b, xl2b);

		final float yl1 = ray.inv_direction.y*(a.y-ray.start.y);
		final float yl2 = ray.inv_direction.y*(b.y-ray.start.y);
		final float yl1a = min(yl1, 1.0f/0.0f);
		final float yl2a = min(yl2, 1.0f/0.0f);
		final float yl1b = max(yl1, -1.0f/0.0f);
		final float yl2b = max(yl2, -1.0f/0.0f);

		lmax = min(max(yl1a, yl2a), lmax);
		lmin = max(min(yl1b, yl2b), lmin);

		final float zl1 = ray.inv_direction.z*(a.z-ray.start.z);
		final float zl2 = ray.inv_direction.z*(b.z-ray.start.z);
		final float zl1a = min(zl1, 1.0f/0.0f);
		final float zl2a = min(zl2, 1.0f/0.0f);
		final float zl1b = max(zl1, -1.0f/0.0f);
		final float zl2b = max(zl2, -1.0f/0.0f);

		lmax = min(max(zl1a, zl2a), lmax);
		lmin = max(min(zl1b, zl2b), lmin);

		lmin = max(lmin, t_min);
		lmax = min(lmax, t_already);

		if (t_min <= rs.near && rs.far < t_already) {
			rs.near = lmin;
			rs.far = lmax;
			return true;
		} else {
			return false;
		}


// http://www.cg.cs.tu-bs.de/people/eisemann/
} else version(aabbraytest_rayslopes) {
	pragma(msg, "Compiling aabbraytest_rayslopes");
	static assert(0, "Not implemented");

// http://tog.acm.org/resources/RTNews/html/rtnv21n1.html#art9
// very fast, and nicly optimalizes on modern CPUs
// similar to amy_with_paramlist, but different order of exits
} else version(aabbraytest_fyffe) {
	pragma(msg, "Compiling aabbraytest_fyffe");
	final float t1x = (bounds[ray.aabb_cellnum[0]] - ray.start.x) * ray.inv_direction.x;
	final float t2x = (bounds[ray.aabb_cellnum[1]] - ray.start.x) * ray.inv_direction.x;
	final float t1y = (bounds[ray.aabb_cellnum[2]] - ray.start.y) * ray.inv_direction.y;
	final float t2y = (bounds[ray.aabb_cellnum[3]] - ray.start.y) * ray.inv_direction.y;
	final float t1z = (bounds[ray.aabb_cellnum[4]] - ray.start.z) * ray.inv_direction.z;
	final float t2z = (bounds[ray.aabb_cellnum[5]] - ray.start.z) * ray.inv_direction.z;
	// order of tests are very important (it is misterious behaviour of CPUs)
	if (t1x > t2y || t2x < t1y || t1x > t2z || t2x < t1z || t1y > t2z || t2y < t1z) {
		return false;
	}
	if (t2x < 0.0 || t2y < 0.0 || t2z < 0.0) {
		return false;
	}
	// now compare with t_already. (t1{x,y,z} are strictly positive already)
	if (t1x > t_already || t1y > t_already || t1z > t_already) {
		return false;
	}

	// the next four lines are optional, they compute the intersection distance and return it
	float distance = t1x;
	if (t1y > distance) distance = t1y;
	if (t1z > distance) distance = t1z;
	rs.near = distance;
	return true;

} else version(aabbraytest_mahovsky) { // http://jgt.akpeters.com/papers/MahovskyWyvill04/
	pragma(msg, "Compiling aabbraytest_mahovsky");
	static assert(0, "Not implemented");
} else {
	static assert(0, "Choice Box/Ray intersection algorithm");
}
	}

	AABB merge(ref AABB aabb2) {
		return AABB(
			vec3.vecmin(a, aabb2.a),
			vec3.vecmax(b, aabb2.b)
		);
	}

	void add(ref vec3 p) {
		if (p.x < a.x) a.x = p.x;
		if (p.y < a.y) a.y = p.y;
		if (p.z < a.z) a.z = p.z;
		if (p.x > b.x) b.x = p.x;
		if (p.y > b.y) b.y = p.y;
		if (p.z > b.z) b.z = p.z;
	}

	void add(ref AABB aabb2) {
		if (aabb2.a.x < a.x) a.x = aabb2.a.x;
		if (aabb2.a.y < a.y) a.y = aabb2.a.y;
		if (aabb2.a.z < a.z) a.z = aabb2.a.z;
		if (aabb2.b.x > b.x) b.x = aabb2.b.x;
		if (aabb2.b.y > b.y) b.y = aabb2.b.y;
		if (aabb2.b.z > b.z) b.z = aabb2.b.z;
	}


	vec3 width() {
		return b-a;
	}

	float area() {
		vec3 w = width();
		return 2.0f*(w.x*w.y + w.y*w.z + w.z*w.x);
	}

	bool inner(ref AABB aabb2) {
		return (! (
			aabb2.a.x < a.x || aabb2.a.x > b.x ||
			aabb2.a.y < a.y || aabb2.a.y > b.y ||
			aabb2.a.z < a.z || aabb2.a.z > b.z ||
			aabb2.b.x < a.x || aabb2.b.x > b.x ||
			aabb2.b.y < a.y || aabb2.b.y > b.y ||
			aabb2.b.z < a.z || aabb2.b.z > b.z
		));
	}

	bool inner2(vec3 p) {
		return (! (
			p.x < a.x || p.x > b.x ||
			p.y < a.y || p.y > b.y ||
			p.z < a.z || p.z > b.z
		));
	}
}

/*
Generalnie Kay/Kajiya slabs test

Slab
http://www.siggraph.org/education/materials/HyperGraph/raytrace/rtinter3.htm

Branchless
http://ompf.org/ray/ray_box.html

Tez branchles, ale wraz z segmentem promienia
http://www.flipcode.com/archives/SSE_RayBox_Intersection_Test.shtml
http://www.flipcode.com/cgi-bin/fcarticles.cgi?show=65014

http://ompf.org/forum/viewtopic.php?f=4&t=701&sid=b0f7acc47f97337ce699225205e92563

http://cvs.gna.org/cvsweb/radius/src/rt_render_packet.cc?rev=1.3;cvsroot=radius#l382

"An Efficient and Robust Ray-Box Intersection Algorithm," by Amy Williams, Steve Barrus, R. Keith Morley, and Peter Shirley, JGT 10:1 (2005), pp. 49–54.
(generalnie algorytm Smitha, z optymalizacjami i cachowaniem i brakiem problemow z dzielniem przez 0 i -0)
http://cag.csail.mit.edu/~amy/papers/box-jgt.pdf
http://www.cs.utah.edu/~awilliam/box/ -  to samo,

Przeglad optymalizacji w kodzie Amy WIlliamsa
http://tog.acm.org/resources/RTNews/html/rtnv19n1.html#art7
http://jgt.akpeters.com/papers/LofstedtAkenineMoller05/ - tu sa rozne testy

http://jgt.akpeters.com/topics/?topic_id=19 - swietna lista

Fast Ray-Axis Aligned Bounding Box Overlap Tests with Plücker Coordinates
http://pages.cpsc.ucalgary.ca/~blob/ps/jgt04.pdf
http://jgt.akpeters.com/papers/MahovskyWyvill04/

Graham Fyffe - bardzo bardzo szybki. Na moje oko najszybszy!
http://tog.acm.org/resources/RTNews/html/rtnv21n1.html#art9
Szybszy niz te kody z RTnv19n1

automatyczne szukanie najlepszego algorytmu :)
http://www.cs.utah.edu/~aek/research/triangle.pdf
*/
