module wrt.accelstructs.MLRTA;

import wrt.base.vec3 : vec3;
import wrt.base.Ray : Ray, hitinfo;
import wrt.accelstructs.BVH : BVH, virtual_recurse_stack;
import wrt.base.AABB : AABB;

import wrt.base.misc : cross;

import std.stdio : writefln;

enum Result {
	None,
	Partial,
	Full
}

align(16) final struct Beam {
	union {
		vec3[4] plane_normals;
		struct {
			vec3 Left, Up, Right, Down;
		}
	}
	float[4] dists;
	vec3[4] plane_normals_positive_components;
	vec3[4] plane_normals_negative_components;

	const static int tiling = 32;
	Ray[] ray_set;
	int x1, y1, x2, y2;

	int width() {
		return x2-x1;
	}
	int height() {
		return y2-y1;
	}

	Ray* get_ray(int x, int y) {
		return &ray_set[y*tiling + x];
	}

	Ray* UpLeft() { return get_ray(x1, y1); }
	Ray* UpRight() { return get_ray(x2-1, y1); }
	Ray* DownLeft() { return get_ray(x1, y2-1); }
	Ray* DownRight() { return get_ray(x2-1, y2-1); }

	static Beam create(Ray[] rays_, int x1_, int y1_, int x2_, int y2_) {
		Beam beam;
		beam.ray_set = rays_;
		beam.x1 = x1_;
		beam.x2 = x2_;
		beam.y1 = y1_;
		beam.y2 = y2_;
		beam.Left = cross(beam.DownLeft.direction, beam.UpLeft.direction);
		beam.Up = cross(beam.UpLeft.direction, beam.UpRight.direction);
		beam.Right = cross(beam.UpRight.direction, beam.DownRight.direction);
		beam.Down = cross(beam.DownRight.direction, beam.DownLeft.direction);

		for (int i = 0; i < 4; i++) {
			beam.plane_normals_positive_components[i] =
				vec3(
					(beam.plane_normals[i].x > 0.0f ? beam.plane_normals[i].x : 0.0f),
					(beam.plane_normals[i].y > 0.0f ? beam.plane_normals[i].y : 0.0f),
					(beam.plane_normals[i].z > 0.0f ? beam.plane_normals[i].z : 0.0f));
			beam.plane_normals_negative_components[i] =
				vec3(
					(beam.plane_normals[i].x < 0.0f ? beam.plane_normals[i].x : 0.0f),
					(beam.plane_normals[i].y < 0.0f ? beam.plane_normals[i].y : 0.0f),
					(beam.plane_normals[i].z < 0.0f ? beam.plane_normals[i].z : 0.0f));
//			beam.dists[i] = - (beam.plane_normals[i] * 
		}
		return beam;
	}

	/*
	 * Return value says if Beam beam intersect with Axis Alligned Bounding Box aabb
	 *   None - beam omited completly aabb
	 *                 \ \
	 *           +----+ \ \
	 *           |    |  \ \
	 *           |    |   \ \
	 *           +----+    \ \
	 *   Full - all rays in beam are hiting box, we can produce maximal and minimal value of raysegment.near
	 *           \ \
	 *           +----+
	 *           | \ \|
	 *           |  \ |
	 *           +----+\
	 *                \ \
	 *   Partial - some yes, some no
	 *           \     \
	 *           +----+ \
	 *           | \  |  \
	 *           |  \ |   \
	 *           +----+    \
	 *                \     \
	 *      or
	 *     \           \
	 *      \    +----+ \
	 *       \   |    |  \
	 *        \  |    |   \
	 *         \ +----+    \
	 *          \           \
	 *
	 * Of course in 3D it is more complicated, but generaly there is no more options
	 */
	// TODO: wyeliminowac false positives
	Result intersect(ref AABB aabb, float t_min) {
		float[4] nplane;
		int positives;
		for (int i = 0; i < 4; i++) {
			nplane[i] = plane_normals_positive_components[i].cell[0] * aabb.a.cell[0]
					+ plane_normals_negative_components[i].cell[0] * aabb.b.cell[0]
					+ plane_normals_positive_components[i].cell[1] * aabb.a.cell[1]
					+ plane_normals_negative_components[i].cell[1] * aabb.b.cell[1]
					+ plane_normals_positive_components[i].cell[2] * aabb.a.cell[2]
					+ plane_normals_negative_components[i].cell[2] * aabb.b.cell[2];
			if (nplane[i] > 0.0f) {
				positives++;
			}
		}
		static Result[5] r = [Result.Full, Result.Partial, Result.Partial, Result.Partial, Result.None];
		return r[positives];
	}

	// Splits beam into 4 parts
	Beam[] split() {
		return null;
	}

	/// TODO: partial Hilbert curve
	int opApply(int delegate(ref Ray, ref int, ref int) dg) {
		for (int y = y1; y < y2; y++) {
		for (int x = x1; x < x2; x++) {
			int ret = dg(ray_set[y*tiling + x], x, y);
			if (ret) {
				return ret;
			}
		}
		}
		return 0;
	}
}

int[50] last_recursion;
int[50] nul_recursion;
int[50] split_recursion;

/*
 * Return value says if there was any hit:
 *  None - there was no real hit, at any level by any ray
 *  Full - all rays hited something (possibly on different levels)
 *  Partial some rays hited something, some nothing
 */
//Result mlrta_recurse(BVH bvh, Ray[] rays, int width, int height, ref Beam beam, float t_min = 0.0f, int depth = 0, int direct_splits = 0) {
Result mlrta_recurse(BVH bvh, ref Beam beam, float t_min = 0.0f, int depth = 0, int direct_splits = 0) {
begin:
	if (bvh.node.flag == 0) {
		goto single;
	}
	Result r1 = beam.intersect(bvh.node.node1[0].node.aabb, t_min);
	Result r2 = beam.intersect(bvh.node.node1[1].node.aabb, t_min);
	if (r1 == Result.None && r2 == Result.None) {
		/*           \\\
		 *  +---+     \\\ Rs
		 *  | A |      \\\
		 *  +---+ +---+ \\\
		 *        | B |
		 *        +---+
		 */
		nul_recursion[depth]++;
		return Result.None;
	} else if (r1 == Result.Full && r2 == Result.None) {
		bvh = bvh.node.node1[0];
		depth++;
		direct_splits = 0;
		goto begin;
	} else if (r1 == Result.None && r2 == Result.Full) {
		bvh = bvh.node.node1[1];
		depth++;
		direct_splits = 0;
		goto begin;
	} else if (r1 == Result.None && r2 == Result.Partial) {
		// disable some
		bvh = bvh.node.node1[1];
		depth++;
		direct_splits = 0;
		goto begin;
	} else if (r1 == Result.Partial && r2 == Result.None) {
		// disable some
		bvh = bvh.node.node1[0];
		depth++;
		direct_splits = 0;
		goto begin;
	} else {
		/*
		 * Generaly we should first test box which is nearer eye (smaller t parrameter),
		 * because this in many situations (especially for good BVH with tight AABBs),
		 * improve performance by early termination (hit in A, is nearer that possible hit in B,
		 * if any)
		 * there is no easy way to get strict ordering, even for full intersections
		 */
		/*
		 *             -----+ // Rs
		 *	                |////
		 *	            A   |////
		 *                 /|///
		 *              ----+------+
		 *               ///|/  B  |
		 *	                |      |
		 *
		 * Even if we will determine which box are hited first for which rays (this isn't hard)
		 * we need to track some interesting situations (like reentring second box, and paralel recursion
		 * in both, complex interboxes dependencies).
		 *
		 *	But there are some simple situations, when we can do this:
		 * First: not overlaping boxes
		 *
		 *  \\\\\
		 *  +----+
		 *  | \\\|\    A full, B partial
		 *  |A \\|\\
		 *  +----+\\\+----+
		 *       \\\\|   B|
		 *        \\\|\   |
		 *    miss}\\+----+
		 *          \\\\\
		 *
		 *    \\\\\
		 *  +----+\\{miss
		 *  |   \|\\\       A partial, B full
		 *  |A   |\\\\
		 *  +----+\\\+----+
		 *         \\|\\ B|
		 *          \|\\\ |
		 *           +----+
		 *            \\\\
		 *
		 *    \\\
		 *  +----+
		 *  |   \|\    Both full
		 *  |    |\\
		 *  +----+\\\+----+
		 *         \\|\   |
		 *          \|\\  |
		 *           +----+
		 *            \\\
		 *
		 *  \\\\\\
		 *  +----+\{miss
		 *  | \\\|\\       Both partial
		 *  |A \\|\\\
		 *  +----+\\\+----+
		 *       \\\\|\  B|
		 *        \\\|\\  |
		 *    miss}\\+----+
		 *          \\\\\\
		 *
		 *  \\\\\
		 * +-+\\\\          Both partial
		 * | |\\\\\+-+
		 * +-+ \\\\| |
		 *      \\\+-+
		 *       \\\\\
         *
		 * and similar patterns.
		 */
		/*
		 * We can recurse simply for both for complex situations, for easier we can do some analisys.
		 */
		/* Analisis should begin from partitioning _rays_ into 4 sets:
		 *
		 * X - curent box
		 * R - set of rays
		 *
		 * 1) A=hiting A := {r \in R | A.intersect(r) /\ t_min < A.intersect_t_near(r) < t_already },
		 * 2) A'=no hiting A
		 * 3) B=hiting B,
		 * 4) B'=no hiting B
		 *
		 * hiting relation is for t \in [t_min, t_already],   t_min>=0, t_already<=\infty
		 *
		 * Next we construct additional sets:
		 *
		 * Aonly := A-B
		 * Bonly := B-A
		 * nothing := A' /\ B'
		 *
		 * We throw out (mark them as nohit) 'nothing' (if not empty).
		 *
		 * For not empty Aonly and Bonly we simple call recurse_mlrta for them, or normal bvh.recurse if they are power of 1.
		 *
		 * Then we create more sets:
		 *
		 * AandB := A /\ B
		 *
		 * If not empty:
		 *
		 * AbeforB := {r \in (A /\ B) | A.intersect_t_near(r) < B.intersectt_t_near(r)}
		 * BbeforA := {r \in (A /\ B) | A.intersect_t_near(r) >= B.intersectt_t_near(r)}
		 *
		 * AbeforB and BbeforA are no overlaping
		 *
		 * AbeforB /\ BbeforA === {}
		 *
		 * And call proper recurse_mlrta, and track what was returned in each ray (or group, if Full/None).
		 * If no hit:
		 *   check in second box
		 * If hit:
		 *   check in second box with properly adjusted t_already
		 *
		 *
		 * In most complex situations, all sets are non empty, but are not overlaping:
		 *  nothing - trivial
		 *  Aonly - simple (recursion 1: A.mlrta_recurse(Aonly, t_min, t_already))
		 *  Bonly - simple (recursion 2: B.mlrta_recurse(Bonly, t_min, t_already))
		 *  AbeforB - complex:
		 *     recursion 3: AbeforBresult = A.mlrta_recurse(AbeforB, t_min, t_already)
		 *     and for some rays:
		 *        possiblyinBrays := {r | (r,t) \in (AbeforBresult), B.intersect_t_near(r) <= t}
		 *        possiblyinBt := {t | (r,t) \in (AbeforBresult), B.intersect_t_near(r) <= t}
		 *        recursion 4: B.mlrta_recurse(possiblyinBrays, possibltinBt)
		 *  BbeforA - complex:
		 *     analogical to AbeforB, recursion 5, and recursion 6
		 *
		 *
		 * We can't use tail recursion, because all cases for them (like Bonly empty, and so on),
		 * are covered with if's at the begining of function.
		 *
		 *
		 * Because we are possibly running A.mlrta_recurse 3 times (for Aonly and AbeforB - this two are indepndent,
		 * and for BbeforA - this is depndent on some additional condition), we can Aonly and AbeforB evaluate
		 * in the same time, this have, additionaly some other advantages.
		 * If Aonly have holes, then it can even have more holes, this can lead to problems
		 * with evaluting sets, and efectivly compute intersections.
		 * So there are some situations, where we should use whole beam in second box, but individually disable
		 * some rays, and don't recurse when we have beam full of such rays, or they are intersecting
		 * exclusivly with something which we will not recurse.
		 *
		 * Example:
		 *                 +---------------------+
		 *                 |                     |
		 *                 |                  \  |
		 *                 |               b2\  \|
		 *                 |                   \ | \a1
		 *                 |                     |\  \
		 *                 |                     |  \  \
		 *                 |                     |    \  \
		 *                 |                     |      \  \
		 *                 |                     |  +----+   \
		 *                 |                     |  |    | \   \
		 *                 |                 r   |  |  T |   \  \
		 *                 |                -----|--|--^-|----- *
		 *                 |                     |  |    |    / /
		 *                 |    A                |  |B   | /  /
		 *                 |                     |  +----+  /
		 *                 |                     |     /  /
		 *                 |                     |   /  /
		 *                 |                     | /  /
		 *                 |                 b2 /|  /
		 *                 |                     |/a2
		 *                 |                    /|
		 *                 +---------------------+
		 *
		 *
		 * We have beam a12, which intersect Fully with A, and partially with B (partition for B gives beam b12),
		 * beam b12 hits triangle T in B (some rays in beam b12 hit nothing). So we continue with full beam a12,
		 * and recurse down to A (also with information about hit in B). If in A, we will intersect with something,
		 * we will need to check if resulting intersection is real intersection (have not only disabled rays,
		 * and posibly simplify beam, i.e. (D are disabled rays, x are active)
		 *
		 *      DD
		 *      xx
		 *
		 * to have grater coherency, acurracy, and smaller overhead at smaller level.
		 *
		 * For patterns like:
		 *    hole (like in our example):
		 *         xxxx
		 *         xxDx
		 *         xxxx
		 *    hole-like:
		 *         xD    xxx  xxxx   xxDxx
		 *         xx    xDx  xDDx   xDxxx
		 *   and so one, we probably should continue with disabled rays.
		 *   For some configuration of disabled rays (when holes 'D' separate beam into two):
		 *         xxDxx        xD     xDxx   xxDx
		 *         xxDxx        xD     xDDx   xDDD
		 *   we should divide beam into more coherent ones, or switch to mono raytracing.
		 *    ->   xx yy        y      x yy   xx m
		 *         xx yy        y      x Dy   xD
		 *
		 * For 2x2 beams, we should use SIMD traversal.
		 */
		/*
		 * This set should be computed fast, represented compactly, and easly to partition.
		 * Additionaly using coherency is must be!
		 * We can try utilising existing set, buy only slicing it properly.
		 * This is especially true, for large and very large packets. They have grater coherency,
		 * are comonly used for raytracing in high resolution, or antialiasing
		 * (with stratifies sampling preferebly - they are easier to partition).
		 *
		 * Additionaly, we can determine if given region needs antialiasing.
		 *
		 * Expected performance:
		 *  First few boxes will be completly Full/None,
		 *  Then (level 8+), will begin minor Partial boxes,
		 *  At the bottom (level 20~), most will be mixture of Full/None/Partial,
		 *  And if set will be small (<=2 rays, and we have first Partial) we should switch to mono ray traversal/or 2x2 packet
		 *
		 * Prefered starting ray set:
		 *  Without antialiasing: 16x16 pixels
		 *  With antialiasing: 32x32, or 64x64 (16x16 pixel, + 4 or 16 stratified point per pixel)
		 *
		 * Expected amortised cost (for moderatly uniform, and not overlaping boxes):
		 *   mono ray traversal: O(log n)
		 *   mlrta: O(log k * log log n + log n / k) - for n objects, and k rays in packet
		 *
		 *   "/ k" from amorisation of traversal,
		 *   "log k * log log n" from the fact that we must partitione sets, and set should decres at each level
		 *
		 * T(n,k) = T(n/2,k/2) + 2*C_traversal_and_beam_intersect + log k
		 *
		 * log k for finding of intersection/substraction between "2d rectangles".
		 * Note resulting set can have holes (but boxes are integrated, so any way we should test
		 * For such rays (so they can be anyway be integrated into Aonly, for grater working set)
		 *
		 * So as can be seen, for larger k the cost should be better, if partiioning
		 * constants aren't too big (but they are practicly independent of scene, and number of rays in packet)
		 * 
		 */

		// use only for entry point
		// on first not simple condition, switch to mono tracing
		if (direct_splits >= 2 || beam.height * beam.width <= 4 || bvh.node.node1[0].node.flag == 0 || bvh.node.node1[1].node.flag == 0) {
			last_recursion[depth]++;

single:

//			foreach (ref Ray ray, int x, int y; beam) {
		for (int y = beam.y1; y < beam.y2; y++) {
		for (int x = beam.x1; x < beam.x2; x++) {
				 virtual_recurse_stack(bvh, beam.ray_set[beam.tiling*y + x], t_min, 1.0f/0.0f);
		}
		}
//			}
			return Result.Partial;
		} else {
			if (r1 == Result.Full && r2 == Result.Full) {
				depth++;
				mlrta_recurse(bvh.node.node1[0], beam, t_min, depth);
				bvh = bvh.node.node1[1];
				goto begin;
			} else {
				split_recursion[depth]++;

				int new_width = beam.width/2;
				int new_height = beam.height/2;

				Beam[] new_beams = new Beam[4];

				for (int i = 0; i < 4; i++) {
					int x_offset = (i % 2 == 0 ? 0 : new_width);
					int y_offset = (i < 2 ? 0 : new_height);

					new_beams[i] = Beam.create(
						beam.ray_set,
						beam.x1 + x_offset, beam.y1 + y_offset,
						beam.x1 + x_offset + new_width, beam.y1 + y_offset + new_height
					);
				}

					depth++;
				if (r1 == Result.Full) {
					for (int i = 0; i < 4; i++) {
						mlrta_recurse(bvh.node.node1[1], new_beams[i], t_min, depth, direct_splits+1);
					}
					bvh = bvh.node.node1[0];
					goto begin;
				} else if (r2 == Result.Full) {
					for (int i = 0; i < 4; i++) {
						mlrta_recurse(bvh.node.node1[0], new_beams[i], t_min, depth, direct_splits+1);
					}
					bvh = bvh.node.node1[1];
					goto begin;
				} else {
					for (int i = 0; i < 4; i++) {
						mlrta_recurse(bvh, new_beams[i], t_min, depth, direct_splits+1);
					}
				}
			
				return Result.Partial;
			}
		}
	}
}
