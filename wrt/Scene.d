module wrt.Scene;

import std.math : sqrt, pow;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;
import wrt.objects.Light : Light;
import wrt.Lights : lights;
import wrt.Material : Material;
import wrt.base.AABB : AABB;
import wrt.accelstructs.KDTree : KDTree;
import wrt.accelstructs.BVH : BVH, BVHNode, virtual_recurse, virtual_recurse_stack, virtual_recurse_any, virtual_recurse_any_stack;

import wrt.base.Point : Point, Centroid;

import std.stdio : writefln, writef;

//version=trace_statistics;

// Show individual color for each hited object
//version=firsthit_visualdebug;
//version=firsthit_t_visualdebug;

// Cast reflection/refraction/light rays if color of object is not black
version=rays_second;

// Cast reflection rays
//version=rays_reflection;
// Cast refraction rays
//version=rays_refraction;
// Use virtual function for reflection/refraction rays
//version=secondary_using_virtual;

// Enable texture mapping
version=texturing;
version=texturing3D;

version=rays_lights;

// Show id's of occluders
//version=shadow_visualdebug;

//version=rays_lights_no_occlusion_tests;

// Enable diffuse lighting
version=lambert_lighting;
// Enable phong specular highlights
version=phong_lighting;

// Both side of surface are visible, and adjust sign of normal
version=bidirectional_normal;

static const t_min = 1.0e-3f;
static const t_max = 1.0e5f;

final class Scene {
	a3DObject[] objs;
	size_t objs_offset = 0;
	static const int max_depth = 6;

version(trace_statistics) {
	static int stats[max_depth+1];
	static int occlusion_tests[max_depth+1];
	static int occlusion_tests_pos[max_depth+1];

	static int intersection_tests[max_depth+1];
}
	float ambinet = 0.05f;
	//rgb background = rgb(0.15f, 0.1f, 0.0f);

	this() {
		objs.length = 1000;
	}

	void opCatAssign(a3DObject obj) {
		if (objs_offset < objs.length) {
			objs[objs_offset++] = obj;
		} else {
			objs.length = cast(size_t)((objs.length+2)*1.6);
			objs[objs_offset++] = obj;
		}
	}

	int count() {
		return objs_offset;
	}

	int opApply(int delegate(ref a3DObject obj) dg) {
		foreach (obj; objs[0 .. objs_offset]) {
			int ret = dg(obj);
			if (ret) {
				return ret;
			}
		}
		return 0;
	}

	/// TODO; method of Ray
	rgb trace(ref Ray ray, int depth = 0)
	in {
		assert(depth >= 0);
		assert(ray.isValid());
	}
	body {
version(trace_statistics) {
		stats[depth]++;
}
		if (depth >= max_depth) {
			return rgb.BLACK;
			//return background;
		}

		//ray.hi musi byc zainicializowane na brak hitu, ale teoretycznie moze byc statyczny, a przynajmniej dla danego levelu
//		final bool hi0 = virtual_recurse_stack(bvh, ray, t_min, t_max);
		final bool hi0 = virtual_recurse(bvh, ray, t_min, t_max);

		assert(hi0 == (ray.hi.obj !is null));

		version(firsthit_visualdebug) {
			if (ray.hi.obj !is null) {
			version(firsthit_t_visualdebug) {
				return (2.0f/ray.hi.t)*rgb.WHITE;
			} else {
				uint a = cast(uint)(cast(void*)(ray.hi.obj));
				return rgb(
					((1871412631*a) % 10) / 10.0f,
					((a * 1914811121) % 10) / 10.0f,
					((987156131*a) % 10) / 10.0f
				);
			}
			}
		}

		if (!hi0) {
			return rgb.GREEN;
		}

		return shader(ray, depth);
	}

	rgb shader(ref Ray ray, int depth) {
		final float narest_t = ray.hi.t;
		final a3DObject narest_obj = ray.hi.obj;

		if (ray.hi.obj is null) {
			return rgb.RED;
		}

		assert(t_min < narest_t && narest_t < t_max && narest_t < 1.0f/0.0f);
		/// repeat computation
		ray.hi.t = t_max;
		final bool k = narest_obj.intersect(ray, t_min, t_max);
		final float t = ray.hi.t;
		assert(k);
		/// repeat computation
		assert(t == narest_t);

		final Material obj_mat = narest_obj.getMaterial();

		//final
		vec3 n = narest_obj.normalAtIntersection(ray); // MUST be called first, becaouse reflectionRay/refractionRay/interesctionPoint code use it

version(rays_second) {
version(rays_reflection) {
		// najpierw obliczamy promienie, bo buforowanie wynikow w obiektach moze sie popsuc przy rekursji
		final bool reflect_ray_bool = (obj_mat.reflectance != rgb.BLACK && depth < max_depth);
}

version(rays_refraction) {
		final bool refract_ray_bool = (obj_mat.refractance != rgb.BLACK && depth < max_depth);
}

version(rays_reflection) {
version(secondary_using_virtual) {
		Ray reflect_ray = (reflect_ray_bool ? narest_obj.reflectionRay(ray) : Ray());
} else {
		//Ray reflect_ray = Ray.reflectionRay(intersection, ray.direction, 1.0f, dn, normal);
}
}

version(rays_refraction) {
version(secondary_using_virtual) {
		Ray refract_ray = (refract_ray_bool ? narest_obj.refractionRay(ray) : Ray());
} else {
		//final float m1tom2 = (entering ? ray.refractive_index / material.refractive_index : material.refractive_index / ray.refractive_index);
		//Ray refract_ray = Ray.refractionRay(intersection, ray.direction, m1tom2, dn, normal);
}
}

		// TODO: Fresnel's law
version(rays_fresnel_refraction_reflection) {
}
}

version(texturing) {
version(texturing3D) {
		rgb point_color;
		if (obj_mat.texture3D) {
			final vec3 p = narest_obj.intersectionPoint(ray); // gdzies tam drugi raz jest bez sensu
			point_color = obj_mat.texture3D.getTexel3D(p);
		} else if (obj_mat.texture) {
			float u, v;
			narest_obj.get_uv(u, v);
			point_color = obj_mat.texture.getTexel(u, v);
		} else {
			point_color = obj_mat.color;
		}
} else {
		float u, v;
		if (obj_mat.texture) {
			narest_obj.get_uv(u, v);
		}

		final rgb point_color = (obj_mat.texture !is null ? obj_mat.texture.getTexel(u, v) : obj_mat.color);
}
} else {
		final rgb point_color = obj_mat.color;
}

		rgb ret = ambinet * point_color;

		//final vec3 p = (point_color != rgb.BLACK || obj_mat.specular != rgb.BLACK ? narest_obj.intersectionPoint(ray) : vec3.init);

version(rays_second) {
		// search lights
		if (point_color != rgb.BLACK || obj_mat.specular != rgb.BLACK) {
			/*final*/ vec3 p = narest_obj.intersectionPoint(ray);
			Ray ray_tolight = Ray(p); // shadow ray

			//final
			float dn = - (ray.direction * n);

			version(bidirectional_normal) {
				if (dn < 0.0f) {
					dn = -dn;
					n = -n;
				}
			}

			if (dn > 0.0f) {
version(rays_lights) {
lights_foreach:
				foreach (Light light_obj; lights) {
					ray_tolight.direct_to(light_obj.getCenter());
					final float ln = ray_tolight.direction * n;
					if (ln > 0.0f) {
						final float light_t = sqrt((light_obj.getCenter() - p).norm2()); /// TODO: optimize - doubled calculations (in .direct_to)
						version(rays_lights_no_occlusion_tests) {
						} else {
version(trace_statistics) {
							occlusion_tests[depth]++;
}

							if (virtual_recurse_any_stack(bvh, ray_tolight, t_min, light_t)) {
	version(trace_statistics) {
								occlusion_tests_pos[depth]++;
	}
								version(shadow_visualdebug) {
									if (hi3.obj !is null) {
										a3DObject oc = hi3.obj;
										uint a = cast(uint)(cast(void*)(oc));
										return rgb(
											((1872631*a) % 10) / 10.0f,
											((a * 19811121) % 10) / 10.0f,
											((9871131*a) % 10) / 10.0f
										);
									}
								}

								version (shadow_cache) {
									obj.setLastOccluder(hi2.obj);
								}

								/// TODO: transluent objects
								continue lights_foreach;
							}
						} // version(rays_lights_no_occlusion_tests)

						// n*d   - Lambert's law, simple shading
						// 1/r^2 - energy from point light
						//rgb a = dn * (ray_tolight.direction*n) * (mat.color * light_obj.getEmittance(1.0f));

						/*final*/ rgb emittance_of_light = light_obj.getEmittance(sqrt(light_t)); // with atenuation
						//rgb emittance_of_light = light_obj.getEmittance(1.0f);

						// Moj wymysl, taki Lambert
						version (lambert_lighting) {
							ret += ln * (point_color * emittance_of_light); // z textury
							//ret += ln * (obj_mat.diffusion * emittance_of_light);
						}

						// Phong:
						// intensity = diffuse * (L*N) + specular * (V*R)^n
						// N - normalna do powierzchni // obj.normalAtIntersection(ray)
						// L - wektor w kierunku swiatla // ray_tolight.direction
						// V - ray.direction
						// R - wektor L odbity na powierzchni, czyli L - 2 * (L*N) * N
						// n ~ 20.0f
						// to wyglada ze pierwszy czynnik to lambert, a drugi to taka aproksymacja fajna
						version (phong_lighting) {
							if (obj_mat.specular != rgb.BLACK)  {
								/*final*/ vec3 reflection_of_l = ray_tolight.direction - 2.0f * (ln)*n;
								ret += emittance_of_light * obj_mat.specular * pow(ray.direction * reflection_of_l, obj_mat.phong_exponent);
							}
						}

						/// TODO: Phong-Blinn, Gaussian, Beckmann, Heidrich-Seidel, Ward, Cook-Torrance

						//writef("oswietlenie=");
						//a.print();
						// can be stored in object as local lightning,
						// and reused later (ie. for object visible throuth multiple ways
						// (mirrors, lens), or for interpolation of small surfaces)


						/// TODO: absorbance (in each channel)  light = light_in * exp(-d * C)
						/// Beer's law
						/// albo absorbance == 0.15 * color

					} // ln > 0
				} // foreach lights
} // version(rays_lights)
			} // dn > 1
		} // color

		/// TODO: addaptative depth
		/// don't recurse to manny times, for dark surfaces
		/// jesli jednak rekursujesz, to moze daj rekursowanej funkcji znac, aby ona zbyt duzo sie nie meczyla
version(rays_reflection) {
		if (reflect_ray_bool && reflect_ray.direction != vec3(0.0f, 0.0f, 0.0f)) {
			ret += obj_mat.reflectance * trace(reflect_ray, depth+1);
		}
}

version(rays_refraction) {
		if (refract_ray_bool && refract_ray.direction != vec3(0.0f, 0.0f, 0.0f)) {
			ret += obj_mat.refractance * trace(refract_ray, depth+1);
		}
}
} // version(rays_second)

		//ret *= exp(env.absorbtion*t);

		// czy swieci
		if (obj_mat.emittance != rgb.BLACK) {
			//Ray r = mat.emittancion(ray);
			//ret += (1.0f / (narest_t)) * mat.emittance;
			ret += obj_mat.emittance;
		}

		return ret;
	}

	KDTree kdtree;

	void build_kdtree() {
/*
		Point[] points;
		points.length = count();

		int i = 0;
		foreach (a3DObject obj; objs[0 .. objs_offset]) {
			points[i] = Point(obj.getCenter(), obj); // struct
			i++;
		}

		kdtree = KDTreeNode.build_median(points);

		AABB aabb = AABB(vec3(-1.0e4f, -1.0e4f, -1.0e4f),vec3(1.0e4f, 1.0e4f, 1.0e4f));
		aabb.print();

		//kdtree.print(aabb);

		points.length = 0;
*/
	}

	BVH bvh;

	void build_bvh() {
		Centroid[] primitives;
		primitives.length = count();

		AABB scene_bb;
		AABB centroids_bb;

		int i = 0;
		foreach (a3DObject obj; objs[0 .. objs_offset]) {
			primitives[i] = Centroid(obj.getAABB(), obj); // struct
			scene_bb.add(primitives[i].aabb);
			centroids_bb.add(primitives[i].aabb.center());
			i++;
		}

		writef("scene AABB ");
		scene_bb.print();
		writefln();

		bvh = BVHNode.build_bining(primitives, scene_bb, centroids_bb);

		//bvh.print();

		primitives.length = 0;
	}
}

