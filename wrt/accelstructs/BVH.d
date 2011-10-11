/** Bounding Volume Hierarchy (using AABB) */
module wrt.accelstructs.BVH;

import std.stdio : writefln, writef;
//import std.math;

import wrt.base.vec3 : vec3;
import wrt.objects.a3DObject : a3DObject;
import wrt.base.AABB : AABB;
import wrt.base.Point : Point, Centroid, osie;
import wrt.base.Ray : Ray, raysegment, hitinfo;

version=recurse_sort;
//version=recursing_switch;

//version=BVHdebug;
//version=BVHdebugprints;

union BVH {
	BVHNode * node;
	BVHLeaf * leaf;
}

bool virtual_recurse(BVH x, ref Ray r, float t_min, float t_already) {
	return (x.node.flag ? x.node.recurse(r, t_min, t_already) : x.leaf.recurse(r, t_min, t_already));
}

bool virtual_recurse_stack(BVH x, ref Ray r, float t_min, float t_already) {
	return (x.node.flag ? x.node.recurse_stack(r, t_min, t_already) : x.leaf.recurse(r, t_min, t_already));
}

bool virtual_recurse_any(BVH x, ref Ray r, float t_min, float t_already) {
	return (x.node.flag ? x.node.recurse_any(r, t_min, t_already) : x.leaf.recurse_any(r, t_min, t_already));
}

bool virtual_recurse_any_stack(BVH x, ref Ray r, float t_min, float t_already) {
	return (x.node.flag ? x.node.recurse_any_stack(r, t_min, t_already) : x.leaf.recurse_any(r, t_min, t_already));
}

/** Binary axis alligned bounding box hierarchy */
struct BVHNode {
	/*const*/ AABB aabb; // 8*4B = 32
// flag must have identical offset in both structures!!
	int flag; // 4 B
	BVH node1[2]; // 8 B (wskaznik do obu)

	static BVHNode * create(ref AABB aabb_, BVH left_, BVH right_) {
		assert(left_.node !is null && right_.node !is null);
		BVHNode *r = new BVHNode;
		r.aabb = aabb_;
		r.node1[0] = left_;
		r.node1[1] = right_;
		r.flag = 1;
		return r;
	}

	static BVH build_bining(Centroid[] points, ref AABB aabb, ref AABB centroids_aabb, int depth = 0)
	in {
		assert(depth >= 0);
		assert(points !is null);
		assert(points.length >= 1);
		//assert(aabb.inner(centroids_aabb));
		foreach (int i, ref p; points) {
			assert(aabb.inner(p.aabb));
		}
		foreach (ref p; points) {
			assert(centroids_aabb.inner2(p.aabb.center()));
		}
	}
	body {
		if (points.length <= 3) {
			BVH ret;
			ret.leaf = BVHLeaf.create(points, aabb);
			return ret;
		}

		// 16 should be the best
		const int NUM_OF_BINS = 8;

		// bins for sorting
		int[NUM_OF_BINS] bins_x, bins_y, bins_z;

		// bin bounds (initalized to negative bounding box)
		AABB[NUM_OF_BINS] bb_x, bb_y, bb_z;

		/*final*/ vec3 w = centroids_aabb.width() + 0.1e-5f*vec3.I;
		final vec3 k = (0.999f*NUM_OF_BINS*vec3.I)/w;

		assert(aabb.inner(centroids_aabb));

		// bining acording to center, and computing binbounds
		// O(n/k)
		foreach (ref p; points) {
			final vec3 c = p.aabb.center() - centroids_aabb.a;
			assert(c.x >= 0);
			assert(c.y >= 0);
			assert(c.z >= 0);
			assert(c.x <= w.x);
			assert(c.y <= w.y);
			assert(c.z <= w.z);

			final size_t xi = cast(size_t)(k.x*c.x);
			bins_x[xi]++;
			bb_x[xi].add(p.aabb);

			final size_t yi = cast(size_t)(k.y*c.y);
			bins_y[yi]++;
			bb_y[yi].add(p.aabb);

			final size_t zi = cast(size_t)(k.z*c.z);
			bins_z[zi]++;
			bb_z[zi].add(p.aabb);
		}


		// O(k), to sie czesciowo da urownoleglic O(lg k)
		// przy k proceosrach, ale k jest male wiec nie potrzeba

		// N_L_j_x_acum = bins_x[0] + ... + bins_x[j]
		static int[NUM_OF_BINS] N_L_j_x_acum, N_L_j_y_acum, N_L_j_z_acum;
		static int[NUM_OF_BINS] N_R_j_x_acum, N_R_j_y_acum, N_R_j_z_acum;

		// A_L_j_x = surface_area(bb_x[0] + ... + bb_x[j])
		static float[NUM_OF_BINS] A_L_j_x, A_L_j_y, A_L_j_z;
		static float[NUM_OF_BINS] A_R_j_x, A_R_j_y, A_R_j_z;

		// first pass from left
		// save accumulated counts of triangles
		// and areas
		// O(SPLITS);
		{
		int N_L_j_x, N_L_j_y, N_L_j_z;
		AABB temp_x, temp_y, temp_z;
		for (int i = 0; i < NUM_OF_BINS; i++) {
			N_L_j_x += bins_x[i];
			N_L_j_x_acum[i] = N_L_j_x;
			temp_x.add(bb_x[i]);
			A_L_j_x[i] = temp_x.area();

			N_L_j_y += bins_y[i];
			N_L_j_y_acum[i] = N_L_j_y;
			temp_y.add(bb_y[i]);
			A_L_j_y[i] = temp_y.area();

			N_L_j_z += bins_z[i];
			N_L_j_z_acum[i] = N_L_j_z;
			temp_z.add(bb_z[i]);
			A_L_j_z[i] = temp_z.area();
		}
		}

		// second pass from right
		// O(SPLITS);
		{
		int N_R_j_x, N_R_j_y, N_R_j_z;
		AABB temp_x, temp_y, temp_z;
		for (int i = NUM_OF_BINS-1; i >= 0; i--) {
			N_R_j_x += bins_x[i];
			N_R_j_x_acum[i] = N_R_j_x;
			temp_x.add(bb_x[i]);
			A_R_j_x[i] = temp_x.area();

			N_R_j_y += bins_y[i];
			N_R_j_y_acum[i] = N_R_j_y;
			temp_y.add(bb_y[i]);
			A_R_j_y[i] = temp_y.area();

			N_R_j_z += bins_z[i];
			N_R_j_z_acum[i] = N_R_j_z;
			temp_z.add(bb_z[i]);
			A_R_j_z[i] = temp_z.area();
		}
		}

		float minimum_cost = 1.0f/0.0f;

		size_t minimum_i = 1;
		int ax = 0;

		// evaluate cost function for bin bounduaries using computed values
		// and remember optimal
		// O(SPLITS);
		for (int i = 1; i < NUM_OF_BINS; i++) {
			float cost_j;

			cost_j = N_L_j_x_acum[i-1]*A_L_j_x[i-1] + N_R_j_x_acum[i]*A_R_j_x[i];
			if (cost_j < minimum_cost) {
				minimum_i = i;
				minimum_cost = cost_j;
				ax = 0;
			}

			cost_j = N_L_j_y_acum[i-1]*A_L_j_y[i-1] + N_R_j_y_acum[i]*A_R_j_y[i];
			if (cost_j < minimum_cost) {
				minimum_i = i;
				minimum_cost = cost_j;
				ax = 1;
			}

			cost_j = N_L_j_z_acum[i-1]*A_L_j_z[i-1] + N_R_j_z_acum[i]*A_R_j_z[i];
			if (cost_j < minimum_cost) {
				minimum_i = i;
				minimum_cost = cost_j;
				ax = 2;
			}
		}

		int N_L, N_R;
		if (ax == 0) {
			N_L = N_L_j_x_acum[minimum_i-1];
			N_R = N_R_j_x_acum[minimum_i];
		}
		if (ax == 1) {
			N_L = N_L_j_y_acum[minimum_i-1];
			N_R = N_R_j_y_acum[minimum_i];
		}
		if (ax == 2) {
			N_L = N_L_j_z_acum[minimum_i-1];
			N_R = N_R_j_z_acum[minimum_i];
		}

		assert(N_L + N_R == points.length);

		if (N_L == points.length || N_R == points.length) {
			BVH ret;
			ret.leaf = BVHLeaf.create(points, aabb);
			return ret;
		}

		// in place partitioning acording to split
		// O(n)
		size_t mid;
		AABB aabb_left, aabb_right;
		AABB centroids_aabb_left, centroids_aabb_right;
		{
		size_t i = 0;
		size_t j = points.length-1;
		do {
			while (i < j) {
				/*final*/ vec3 c = points[i].aabb.center() - centroids_aabb.a;
				if ((ax == 0 && cast(size_t)(k.x*c.x) >= minimum_i) ||
					(ax == 1 && cast(size_t)(k.y*c.y) >= minimum_i) ||
					(ax == 2 && cast(size_t)(k.z*c.z) >= minimum_i)) {
version(BVH_partition_inplace) {
					aabb_right.add(points[i].aabb);
					centroids_aabb_right.add(points[i].aabb.center());
}
					break;
				}
version(BVH_partition_inplace) {
				aabb_left.add(points[i].aabb);
				centroids_aabb_left.add(points[i].aabb.center());
}
				i++;
			}
			while (i < j) {
				/*final*/ vec3 c = points[j].aabb.center() - centroids_aabb.a;
				if ((ax == 0 && cast(size_t)(k.x*c.x) < minimum_i) ||
					(ax == 1 && cast(size_t)(k.y*c.y) < minimum_i) ||
					(ax == 2 && cast(size_t)(k.z*c.z) < minimum_i)) {
version(BVH_partition_inplace) {
					aabb_left.add(points[j].aabb);
					centroids_aabb_left.add(points[j].aabb.center());
}
					break;
				}
version(BVH_partition_inplace) {
				aabb_right.add(points[j].aabb);
				centroids_aabb_right.add(points[j].aabb.center());
}
				j--;
			}
			if (i <= j) {
				/*final*/ Centroid temp = points[i];
				points[i] = points[j];
				points[j] = temp;

				if (i == j) {
				vec3 c = points[j].aabb.center() - centroids_aabb.a;
				if ((ax == 0 && cast(size_t)(k.x*c.x) < minimum_i) ||
					(ax == 1 && cast(size_t)(k.y*c.y) < minimum_i) ||
					(ax == 2 && cast(size_t)(k.z*c.z) < minimum_i)) {
version(BVH_partition_inplace) {
// a moze odwortnie
					aabb_left.add(points[j].aabb);
					centroids_aabb_left.add(points[j].aabb.center());
}
					break;
				}
version(BVH_partition_inplace) {
// a moze odwortnie
				aabb_right.add(points[j].aabb);
				centroids_aabb_right.add(points[j].aabb.center());
}
				}

				i++;
				j--;
			}
		} while (i < j);
		}

		mid = N_L;

version(BVH_partition_inplace) {
} else {
		foreach (ref p; points[0 .. mid]) {
			aabb_left.add(p.aabb);
			centroids_aabb_left.add(p.aabb.center());
		}

		foreach (ref p; points[mid .. $]) {
			aabb_right.add(p.aabb);
			centroids_aabb_right.add(p.aabb.center());
		}
}

version(BVHdebug) {
		assert(aabb.inner(aabb_right));
		assert(aabb.inner(aabb_left));

		assert(aabb.inner(centroids_aabb_right));
		assert(aabb.inner(centroids_aabb_left));

		assert(aabb_right.inner(centroids_aabb_right));
		assert(aabb_right.inner(centroids_aabb_right));

		foreach (ref p; points[0 .. mid]) {
			assert(aabb_left.inner(p.aabb));
		}

		foreach (ref p; points[mid .. $]) {
			if (!aabb_right.inner(p.aabb)) {
				writefln();
				p.aabb.print();
				aabb_right.print();
				writefln();

				(p.aabb.a-aabb_right.a).print();
				writefln();
				(aabb_right.b - p.aabb.b).print();
			}
			assert(aabb_right.inner(p.aabb));
		}

		foreach (ref p; points[0 .. mid]) {
			assert(centroids_aabb_left.inner2(p.aabb.center()));
		}

		foreach (ref p; points[mid .. $]) {
			assert(centroids_aabb_right.inner2(p.aabb.center()));
		}
}


		// a moze mid+1 ?, albo cos takiego
		/*final*/ BVH left = build_bining(points[0 .. mid], aabb_left, centroids_aabb_left, depth+1);
		/*final*/ BVH right = build_bining(points[mid .. $], aabb_right, centroids_aabb_right, depth+1);

		BVH ret;
		ret.node = BVHNode.create(aabb, left, right);
		return ret;
	}

	void print(int depth = 0) {
		for (int i = 0; i < depth; i++) {
			writef(" ");
		}
		writef(" %d ", depth);
		aabb.print();

		if (node1[0].node.flag) {
			node1[0].node.print(depth+1);
		} else {
			node1[0].leaf.print(depth+1);
		}

		if (node1[1].node.flag) {
			node1[1].node.print(depth+1);
		} else {
			node1[1].leaf.print(depth+1);
		}
	}

	bool intersect(ref raysegment rs, ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret) {
			assert(t_min <= rs.near && rs.far < t_already);
		}
	}
	body {
		return aabb.intersect(rs, ray, t_min, t_already);
	}

	// TODO: upewnic sie co do rekursji ogonowych
	// TODO: najlepiej przerobic na reczny stos
	bool recurse(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && ray.hi.obj !is null) {
			assert(t_min <= ray.hi.t && ray.hi.t <= t_already && ray.hi.t < 1.0f/0.0f);
		}
	}
	body {
		static raysegment rs1 = void, rs2 = void;
		final bool n1p = node1[0].node.aabb.intersect(rs1, ray, t_min, t_already); // in node&leaf identical
		final bool n2p = node1[1].node.aabb.intersect(rs2, ray, t_min, t_already); // in node&leaf identical
		final float rs2_near = rs2.near; // potrzebujemy niestatycznie

		// sortujemy najpierw wezly z ograniczeniem na t_already
		if (n1p && n2p) { // oba przecinaja sie i oba sa przed t_already
version(recurse_sort) {
			BVH first = void, second = void;
			if (rs2.near < rs1.near) { // rs2 jest wczesniej, odwroc
				raysegment temp = rs2;
				rs2 = rs1;
				rs1 = temp;
				first = node1[1];
				second = node1[0];
			} else { // rs1 jest wczesniej, zapisz
				first = node1[0];
				second = node1[1];
			}
} else {
			BVH first = node1[0], second = node1[1];
}

			bool hi1 = (first.node.flag ?
				first.node.recurse(ray, t_min, t_already)
				:
				first.leaf.recurse(ray, t_min, t_already));

			if (ray.hi.t < rs2_near) { // to hi1 w sumie nie jest potrzebne
				return hi1;
			}

			t_already = ray.hi.t;

			bool hi2 = (second.node.flag ?
				second.node.recurse(ray, t_min, t_already)
				:
				second.leaf.recurse(ray, t_min, t_already));

			return (hi1 || hi2);
		} else if (n1p) { // co najwyzej jeden sie przecina
			return (node1[0].node.flag ? node1[0].node.recurse(ray, t_min, t_already) : node1[0].leaf.recurse(ray, t_min, t_already));
		} else if (n2p) { // rs2 sie przecina, zapisz go do rs1
			return (node1[1].node.flag ? node1[1].node.recurse(ray, t_min, t_already) : node1[1].leaf.recurse(ray, t_min, t_already));
		} else { // nic sie nie przecina
			//first = null;
			// jesli w first nic nie trafismy to napewno tez w second
			return false;
		}
	}
	// koszty maksymalne (sprawdzenia jednego wezla):
	// 8 porownan fp
	// 12 przypisan (w tym 7 fp)
	// 7-8 porownan wskaznikow (sprawdzenie czy sa null)

	bool recurse_any(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && ray.hi.obj !is null) {
			assert(t_min <= ray.hi.t && ray.hi.t < t_already);
		}
	}
	body {
		static raysegment rs1 = void, rs2 = void;
		final bool n1p = node1[0].node.aabb.intersect(rs1, ray, t_min, t_already); // in node&leaf identical
		final bool n2p = node1[1].node.aabb.intersect(rs2, ray, t_min, t_already); // in node&leaf identical

version(recursing_switch) {
		switch (n1p + 2*n2p) {
			case 0:
				return false;
			case 1:
				return (node1[0].node.flag ? node1[0].node.recurse_any(ray, t_min, t_already) : node1[0].leaf.recurse_any(ray, t_min, t_already));
			case 2:
				return (node1[1].node.flag ? node1[1].node.recurse_any(ray, t_min, t_already) : node1[1].leaf.recurse_any(ray, t_min, t_already));
			case 3:
				final bool hi1 = (node1[0].node.flag ? node1[0].node.recurse_any(ray, t_min, t_already) : node1[0].leaf.recurse_any(ray, t_min, t_already));
				if (hi1) {
					return hi1;
				}
				return (node1[1].node.flag ? node1[1].node.recurse_any(ray, t_min, t_already) : node1[1].leaf.recurse_any(ray, t_min, t_already));
			default:
				assert(0);
		}
		assert(0);
} else {
		if (n1p && n2p) { // oba przecinaja sie i oba sa przed t_already
			final bool hi1 = (node1[0].node.flag ? node1[0].node.recurse_any(ray, t_min, t_already) : node1[0].leaf.recurse_any(ray, t_min, t_already));
			if (hi1) {
				return true;
			}
			return (node1[1].node.flag ? node1[1].node.recurse_any(ray, t_min, t_already) : node1[1].leaf.recurse_any(ray, t_min, t_already));
		} else if (n1p) {  // co najwyzej jeden sie przecina
			return (node1[0].node.flag ? node1[0].node.recurse_any(ray, t_min, t_already) : node1[0].leaf.recurse_any(ray, t_min, t_already));
		} else if (n2p) { // rs2 sie przecina, zapisz go do rs1
			return (node1[1].node.flag ? node1[1].node.recurse_any(ray, t_min, t_already) : node1[1].leaf.recurse_any(ray, t_min, t_already));
		} else { // nic sie nie przecina
			return false;
		}
}
	}

	bool recurse_any_stack(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && ray.hi.obj !is null) {
			assert(t_min <= ray.hi.t && ray.hi.t <= t_already && ray.hi.t < 1.0f/0.0f);
		}
	}
	body {
		static raysegment rs1 = void, rs2 = void;

		static BVHNode*[30] stack;
		int stack_i = 0;

		BVH current;
		current.node = this;
//		stack[0] = this;

//		while (stack_i >= 0) {
		while (true) {
			if (current.node.flag == 1) {
				final bool n1p = current.node.node1[0].node.aabb.intersect(rs1, ray, t_min, t_already); // in node&leaf identical
				final bool n2p = current.node.node1[1].node.aabb.intersect(rs2, ray, t_min, t_already); // in node&leaf identical
				if (n1p && n2p) {
					stack[stack_i++] = current.node;
					current = current.node.node1[0];
				} else if (n1p) {
					current = current.node.node1[0];
				} else if (n2p) {
					current = current.node.node1[1];
				} else {
					if (stack_i) {
						current = stack[--stack_i].node1[1];
					} else {
						return false;
					}
				}
			} else {
				if (current.leaf.recurse_any(ray, t_min, t_already)) {
					return true;
				} else {
					if (stack_i) {
						current = stack[--stack_i].node1[1];
					} else {
						return false;
					}
				}
			}
		}
		return false;
	}

	bool recurse_stack(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && ray.hi.obj !is null) {
			assert(t_min <= ray.hi.t && ray.hi.t <= t_already && ray.hi.t < 1.0f/0.0f);
		}
	}
	body {
		static raysegment rs1 = void, rs2 = void;

		static BVHNode*[30] stack;
		static int[30] stack_side;
		static float[30] stack_rs2near;
		int stack_i = 0;

		BVH current;
		current.node = this;
//		stack[0] = this;

		bool ret = false;

//		while (stack_i >= 0) {
		while (true) {
			if (current.node.flag == 1) {
				final bool n1p = current.node.node1[0].node.aabb.intersect(rs1, ray, t_min, t_already); // in node&leaf identical
				final bool n2p = current.node.node1[1].node.aabb.intersect(rs2, ray, t_min, t_already); // in node&leaf identical
				if (n1p && n2p) {
					if (rs1.near < rs2.near) {
						stack_side[stack_i] = 1;
						stack_rs2near[stack_i] = rs2.near;
						stack[stack_i++] = current.node;
						current = current.node.node1[0];
					} else {
						stack_side[stack_i] = 0;
						stack_rs2near[stack_i] = rs1.near;
						stack[stack_i++] = current.node;
						current = current.node.node1[1];
					}
				} else if (n1p) {
					current = current.node.node1[0];
				} else if (n2p) {
					current = current.node.node1[1];
				} else {
next1:
					if (stack_i--) {
						if (t_already < stack_rs2near[stack_i]) {
							goto next1;
						}
						current = stack[stack_i].node1[stack_side[stack_i]];
					} else {
						return ret;
					}
				}
			} else {
				// Note: don't reverse this expression! side effects
				ret = current.leaf.recurse(ray, t_min, t_already) || ret;
				t_already = ray.hi.t;
next2:
				if (stack_i--) {
					if (t_already < stack_rs2near[stack_i]) {
						goto next2;
					}
					current = stack[stack_i].node1[stack_side[stack_i]];
				} else {
					return ret;
				}
			}
		}
		return ret;
	}

}

struct BVHLeaf {
	const AABB aabb; // 6*4B = 24
	int flag = 0; // 4 B
	Centroid[] objs; // 8 B // gdybybyly posortowane to bybylo lepiej troche z cachem

	static BVHLeaf * create(a3DObject obj_) {
		BVHLeaf *r = new BVHLeaf;
		r.objs = [Centroid(obj_.getAABB(),obj_)];
		r.aabb = r.objs[0].aabb;
		r.flag = 0;
		return r;
	}

	static BVHLeaf * create(Centroid[] objs_, ref AABB aabb_)
	in {
		foreach (ref obj_; objs_) {
			assert(aabb_.inner(obj_.aabb));
		}
	}
	body {
		BVHLeaf *r = new BVHLeaf;
		r.aabb = aabb_;
		r.objs = objs_;
		r.flag = 0;
		return r;
	}

	void print(int depth = 0) {
		for (int i = 0; i < depth; i++) {
			writef(" ");
		}
		writef(" %d ", depth);
		aabb.print();

		foreach (ref obj; objs) {
			for (int i = 0; i < depth+1; i++) {
				writef(" ");
			}
			writef("obj %x, center= ", &obj.obj);
			obj.obj.getCenter().print();
		}
	}

	bool intersect(ref raysegment rs, ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && rs.notZero()) {
			assert(t_min <= rs.near && rs.far < t_already);
		}
	}
	body {
		return aabb.intersect(rs, ray, t_min, t_already);
	}

	bool recurse(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && ray.hi.obj !is null) {
			assert(t_min <= ray.hi.t && ray.hi.t < t_already);
		}
	}
	body {
//		if (objs.length == 1) {
//			return objs[0].obj.intersect(ray, t_min, t_already);
//		} else {
			bool r = false;
			foreach (ref obj; objs) {
				r = obj.obj.intersect(ray, t_min, t_already) || r; // mozna zrobic ++, uwaga na efekty uboczne
				// jest bylo by (r || intersect) i r == true, to intersect sie nie ewaluje
			}
			return r;
//		}
	}
	
	bool recurse_any(ref Ray ray, float t_min = 0.0f, float t_already = 1.0f/0.0f)
	in {
		assert(t_min < t_already);
	}
	out (ret) {
		if (ret && ray.hi.obj !is null) {
			assert(t_min <= ray.hi.t && ray.hi.t <= t_already && ray.hi.t < 1.0f/0.0);
		}
	}
	body {
		foreach (ref obj; objs) {
			if (obj.obj.intersect(ray, t_min, t_already)) {
				return true;
			}
		}
		return false;
	}
}


static assert(BVHNode.aabb.offsetof == BVHLeaf.aabb.offsetof);
static assert(BVHNode.flag.offsetof == BVHLeaf.flag.offsetof);

/*
Ray Tracing Dynamic Scenes using Selective Restructuring
http://gamma.cs.unc.edu/SR/

Asynchronous BVH Construction for Ray Tracing Dynamic Scenes on ...
http://www.cs.utah.edu/~thiago/papers/async_bvh_build.pdf 
http://www.sci.utah.edu/~wald/Publications/2007///AsyncBuild/download//async.pdf
i referencje tam

Ray Tracing Deformable Scenes using Dynamic Bounding Volume Hierarchies
http://www.sci.utah.edu/~wald/Publications/2007///BVH/download//togbvh.pdf

Instant Ray Tracing: The Bounding Interval Hierarchy
http://graphics.uni-ulm.de/BIH.pdf 

On fast Construction of SAH based Bounding Volume Hierarchies
http://www.sci.utah.edu/~wald/Publications/2007///FastBuild/download//fastbuild.pdf
i referencje tam

State of the Art in Ray Tracing Animated Scenes
http://www.sci.utah.edu/~wald/Publications/2007///Star07/download//star07rt.pdf

*/
