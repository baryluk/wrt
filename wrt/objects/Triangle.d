module wrt.objects.Triangle;

import std.math : abs;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;

import wrt.base.misc : cross, min, max;

import wrt.base.AABB : AABB;

import wrt.Material : Material;

import std.stdio : writefln, writef;

static const int mod3[6] = [0,1,2,0,1,2];

// 4
static const EPSILON = 0.1e-4f;

align(16) struct vertex {
	const vec3 pos;
	const vec3 normal;
	const float u, v;  /// TODO: combine this to pos.dummy, normal.dummy? :)

	static vertex* fromvec3(vec3 pos_, float u_ = 0.0f, float v_ = 0.0f) {
		vertex *ret = new vertex;
		ret.pos = pos_;
		ret.u = u_;
		ret.v = v_;
		return ret;
	}

	static vertex fromvec3_struct(vec3 pos_, float u_ = 0.0f, float v_ = 0.0f) {
		vertex ret;
		ret.pos = pos_;
		ret.u = u_;
		ret.v = v_;
		return ret;
	}

	static vertex create(float posx, float posy, float posz, float u_ = 0.0f, float v_ = 0.0f) {
		vertex ret;
		ret.pos = vec3(posx, posy, posz);
		ret.u = u_;
		ret.v = v_;
		return ret;
	}

	void print() {
		pos.print();
	};
}

version (D_Version2) {
import cstdlib = core.stdc.stdlib;
import core.exception : oom = OutOfMemoryError;
import sgc = core.memory;
} else {
import cstdlib = std.c.stdlib;
import std.outofmemory : oom = OutOfMemoryException;
import sgc = std.gc;
}

/*
char[] x
void* current_memory_begin;
void* current_memory;
*/

final class Triangle : a3DObject {
	new(size_t sz) {
		void* p;

		p = cstdlib.malloc(sz);
		if (!p) {
			throw new ooom();
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
	/*final */vertex* vertexs[3];

// precalculated values
	//vec3 normal; // real normal
	const float nu, nv, nd;
	const int k; // axis of projection
	const float bnu, bnv;
	const float cnu, cnv;
	/*final */float sign01, sign02;

	this(vertex* a_, vertex* b_, vertex* c_, bool resetNormals = false, bool resetSign = false) {
		/// TODO: check degenerated triangles
		vertexs[0] = a_;
		vertexs[1] = b_;
		vertexs[2] = c_;

		vec3 b = vertexs[1].pos-vertexs[0].pos;
		vec3 c = vertexs[2].pos-vertexs[0].pos;
		if (b.norm2() < 0.1e-6f || c.norm2() < 0.1e-6f) {
			nd = 1.0f/0.0f;
			nu = 0.0f;
			nv = 0.0f;
			k = 0;
			return;
			//throw new Exception("Degenreated triangle");
		}
		vec3 normal = cross(b, c);
		k = (
			abs(normal.x) > abs(normal.y)
			?
			(abs(normal.x) > abs(normal.z) ? 0 : 2)
			:
			(abs(normal.y) > abs(normal.z) ? 1 : 2)
			);
		final int uaxis = mod3[k+1];
		final int vaxis = mod3[k+2];

		if (normal.cell[k] == 0.0f) {
			nd = 1.0f/0.0f;
			nu = 0.0f;
			nv = 0.0f;
			k = 0;
			return;
			//throw new Exception("Degenerated triangle");
		}

		final real krec = 1.0f / normal.cell[k];

		nu = normal.cell[uaxis] * krec;
		nv = normal.cell[vaxis] * krec;
		nd = (normal*vertexs[0].pos) * krec;

		final real reci = 1.0f / (b.cell[uaxis]*c.cell[vaxis] - b.cell[vaxis]*c.cell[uaxis]);

		bnu = b.cell[uaxis] * reci;
		bnv = -b.cell[vaxis] * reci;

		cnu = c.cell[vaxis] * reci;
		cnv = -c.cell[uaxis] * reci; // odwroone u/v?

		if (resetNormals) {
			normal.normalize();
			normall = normal;

			vertexs[0].normal = normal;
			vertexs[1].normal = normal;
			vertexs[2].normal = normal;
		}


		if (resetSign) {
			actualizeSigns();
		} else {
			sign01 = 1.0f;
			sign02 = 1.0f;
		}

		material = Material.GREEN;
	}

	void actualizeSigns() {
		// becouse some normals are computed automaticly, they
		// can have wrong direction (not coherent), so we swap some
		sign01 = (vertexs[0].normal * vertexs[1].normal > 0.0f ? 1.0f : -1.0f);
		sign02 = (vertexs[0].normal * vertexs[2].normal > 0.0f ? 1.0f : -1.0f);	
	}

	override vec3 getCenter() {
		return vertexs[0].pos;
	}

// caching
	__thread static float u, v, t; // barycentric coordinates of intersection
debug {
	__thread static Triangle last_triangle;
	__thread static Triangle last_triangle_normal;
}
	__thread static vec3 n; // interpolated normal at intersection
	__thread static vec3 intersection;

	/// 
	override bool intersect(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	out (ret) {
		if (ret) {
			assert(ray.hi.obj !is null);
			assert(ray.hi.obj is this);
			if (!(t_min <= ray.hi.t && ray.hi.t < t_already)) {
				writefln(nd);
				writefln(nu, " ", nv);
				ray.start.print();
				ray.direction.print();
				writefln(ray.hi.t);
			}
			assert(t_min <= ray.hi.t && ray.hi.t < t_already);
		}
	}
	body {
		debug {
			last_triangle = this;
		}

		final int uaxis = mod3[k+1];
		final int vaxis = mod3[k+2];

		// do division early, so using it in multiplication in t will not stall pipeline
		final float d = 1.0f / (ray.direction.cell[k] + nu*ray.direction.cell[uaxis] + nv*ray.direction.cell[vaxis]);

		t = (nd - ray.start.cell[k] - nu*ray.start.cell[uaxis] - nv*ray.start.cell[vaxis]) * d;

		if (!(t_min <= t && t < t_already && t < ray.hi.t)) {
			return false;
		}

		final float hu = ray.start.cell[uaxis] + t*ray.direction.cell[uaxis] - vertexs[0].pos.cell[uaxis];
		final float hv = ray.start.cell[vaxis] + t*ray.direction.cell[vaxis] - vertexs[0].pos.cell[vaxis];

		u = hv * bnu + hu * bnv;
		if (u < 0.0f) {
			return false;
		}

		v = hu * cnu + hv * cnv;
		if (v < 0.0f) {
			return false;
		}

		if (u+v > 1.0f) {
			return false;
		}

		ray.hi.t = t;
		ray.hi.obj = this;
		return true;
	}

	vec3 normall;

	override vec3 normalAtIntersection(ref Ray ray)
	in {
		debug assert(last_triangle is this);
	}
	body {
		debug {
			last_triangle_normal = this;
		}
		n = vertexs[0].normal + v*(sign01*vertexs[1].normal-vertexs[0].normal) + u*(sign02*vertexs[2].normal-vertexs[0].normal);
		n.normalize();
		intersection = ray.get(t);
		return n;
	}

	override vec3 intersectionPoint(ref Ray ray)
	in {
		debug assert(last_triangle is this);
		debug assert(last_triangle_normal is this);
	}
	body {
		return intersection;
	}

	override Ray reflectionRay(ref Ray ray)
	in {
		debug assert(last_triangle is this);
	}
	body {
		return Ray.reflectionRay(intersection, ray.direction, 1.0f, ray.direction*n, n);
	}

	override Ray refractionRay(ref Ray ray)
	in {
		debug assert(last_triangle is this);
	}
	body {
		return Ray.create(intersection, ray.direction);
	}

	override void get_uv(ref float u_, ref float v_)
	in {
		debug assert(last_triangle is this);
	}
	body {
		u_ = vertexs[0].u + u*(vertexs[1].u-vertexs[0].u) + u*(vertexs[2].u-vertexs[0].u);
		v_ = vertexs[0].v + v*(vertexs[1].v-vertexs[0].v) + v*(vertexs[2].v-vertexs[0].v);
	}

	override AABB getAABB() {
		final float minx = min(vertexs[0].pos.x, vertexs[1].pos.x, vertexs[2].pos.x);
		final float maxx = max(vertexs[0].pos.x, vertexs[1].pos.x, vertexs[2].pos.x);
		final float miny = min(vertexs[0].pos.y, vertexs[1].pos.y, vertexs[2].pos.y);
		final float maxy = max(vertexs[0].pos.y, vertexs[1].pos.y, vertexs[2].pos.y);
		final float minz = min(vertexs[0].pos.z, vertexs[1].pos.z, vertexs[2].pos.z);
		final float maxz = max(vertexs[0].pos.z, vertexs[1].pos.z, vertexs[2].pos.z);
		return AABB(vec3(minx, miny, minz), vec3(maxx, maxy, maxz));
	}
}
