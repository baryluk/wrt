module wrt.main;

//version=with_flectioned;


version(with_flectioned) {
//import cn.k.flectioned;
import external.flectioned;
}

import std.stdio : writefln;
import std.string : atoi;

version (D_Version2) {
import sgc=core.memory;
} else {
import sgc=std.gc;
}

import wrt.Scene : Scene;
import wrt.target.ScreenSDL : ScreenSDL;

import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;

import wrt.Timer : Timer;

import wrt.samplers;

import wrt.scenes.sponza : create_scene_sponza;

Scene get_scene(int frame_number = 0) {
	Scene scene;

	//scene = create_scene_test(frame_number);
	//scene = create_scene_balls(frame_number);
	//scene = create_scene_bunny(frame_number);
	//scene = create_scene_cat_and_glock(frame_number);
	//scene = create_scene_bunnys(frame_number);
	//scene = create_scene_budda(frame_number);
	//scene = create_scene_dragon(frame_number);
	//scene = create_scene_lucy(frame_number);
	//scene = create_scene_bvhtest(frame_number);

	scene = create_scene_sponza(frame_number);

	return scene;	
}

//version=trace_statistics;


int main(char[][] args) {

version(with_flectioned) {
	TracedException.traceAllExceptions();
}

try {
	int frame_number = 0;
	if (args.length > 1) {
		frame_number = cast(int)atoi(args[1]);
	}

	Scene scene;

sgc.disable();
	{
	scope Timer timer = new Timer("scene generation/loading");
	scene = get_scene(frame_number);
	}

sgc.enable();
sgc.fullCollect();

	{
	scope Timer timer = new Timer("kd-tree creation");
	scene.build_kdtree();
	}

sgc.disable();
	{
	scope Timer timer = new Timer("BVH creation");
	scene.build_bvh();
	}
sgc.enable();
sgc.fullCollect();

	//ScreenSDL screen = new ScreenSDL(800, 600, 0.5f);
	ScreenSDL screen = new ScreenSDL(256, 256, 0.5f);

	screen.setCamera(
		vec3(1.0f, 3.0f-0.1f*frame_number, 1.0f),
		mat4.rotation(vec3.Y_AXIS, 0.01f*3.16f*frame_number)*vec3(1.0f, 0.0f, 0.0f)
	);

sgc.fullCollect();
sgc.disable();

	bool mlrta_sampling = false;
	bool adaptative_subsampling = false;
	bool threaded_sampling = false;
	bool tiling_sampling = false;

	if (adaptative_subsampling) {
		writefln("adaptative subsampling enabled");
	} else {
		if (mlrta_sampling) {
			;
		} else {
			writefln("adaptative subsampling disabled");
			if (threaded_sampling) {
				writefln("threaded raytracer");
			} else {
				if (tiling_sampling) {
					writefln("tiled raytracer");
				} else {
					writefln("standard raytracer");
				}
			}
		}
	}

	float tracing_time;

	screen.main_loop( delegate int () {
		scope Timer timer = new Timer("raytracing", &tracing_time);
		if (adaptative_subsampling) {
			adaptative_sampler(scene, screen);
		} else {
			if (mlrta_sampling) {
				mlrta_sampler(scene, screen);
			} else {
				if (threaded_sampling) {
					threaded_sampler(scene, screen);
				} else {
					if (tiling_sampling) {
						tiled_sampler(scene, screen);
					} else {
						standard_sampler(scene, screen);
					}
				}
			}
		}
		sgc.genCollect();

		return 0;
	} );

sgc.enable();

/*
	{
	scope Timer timer = new Timer("saving bitmap");
	screen.dump("output_files/output.ppm");
	}
*/

version(trace_statistics) {
	writefln("Tracing statistics:");
	writefln();

	{
	writefln("traces (higher better):");
	int total;
	for (int i = 0; i < scene.max_depth; i++) {
		writefln("  level %d rays: %d", i, scene.stats[i]);
		total += scene.stats[i];
	}
	writefln(" Total: %d", total);
	writefln(" MRays/s: %.3f", total/tracing_time / 1.0e6f);
	}

	{
	writefln("intersection_tests (lower better):");
	int total;
	for (int i = 0; i < scene.max_depth; i++) {
		writefln("  level %d tests: %d", i, scene.intersection_tests[i]);
		total += scene.intersection_tests[i];
	}
	writefln(" Total: %d", total);
	writefln(" MRays/s: %.3f", total/tracing_time / 1.0e6f);
	}

	{
	writefln("occlusion_tests (lower better):");
	int total;
	for (int i = 0; i < scene.max_depth; i++) {
		writefln("  level %d tests: %d \tpositive: %d", i, scene.occlusion_tests[i], scene.occlusion_tests_pos[i]);
		total += scene.occlusion_tests[i];
	}
	writefln(" Total: %d", total);
	writefln(" MRays/s: %.3f", total/tracing_time / 1.0e6f);
	}
}

} catch (Exception e) {
	e.print();
}

	return 0;
}

/*

http://research.microsoft.com/~ppsloan/rtrt99.pdf
http://www.cs.utah.edu/~shirley/irt/ - super!

Wyczesany algorytm:
ftp://download.intel.com/technology/computing/applications/download/mlrta.pdf

Fajne forum:
http://ompf.org/forum/viewtopic.php?f=4&t=30

https://graphics.stanford.edu/wikis/cs348b-07

http://www.cs.utah.edu/~shirley/irt/stoll_optimization_s2006.pdf

Inne silniki: rosengarden, OpenRT, InView, irt, pbrt

SIMD:

http://gcc.gnu.org/onlinedocs/gcc-3.4.0/gcc/X86-Built-in-Functions.html

Fresnel formula:
[24,26] w Christiansen+Wansen
[61]
http://physics-animations.com/Physics/English/rays_txt.htm

Swietna strona Glassnera:
http://www.glassner.com/andrew/cg/graphics.htm

http://gamma.cs.unc.edu/RT/

Coupled Use of BSP and BVH Trees in Order to Exploit Ray Bundle ...
http://www.hpc-sa.com/downloads/RT07_paper1006_final.pdf

Czyli cheaty stosowane przez demoscene
http://www.cfxweb.net/modules.php?name=News&file=article&sid=625
"Rubicon" and "Rubicon 2" by Suburban Creations 
"Heaven seven" and "Spot" by Exceed 
"Fresnel" and "Fresnel 2" by Kolor
Gamma2 by mfx
Kolor by 

Np. shadow cache prosty (na cala scene)
oraz First hit optimalisation, czyli propagacja stalych opisujacych ray.start
we wszystkie procedury!!

http://ompf.org/ray/wip/v1/
http://ompf.org/ray/wip/

RTRT FAQ
http://www1.acm.org/pubs/tog/resources/RTNews/demos/rtrt_faq.txt

Benchmark
http://homepages.paradise.net.nz/nickamy/benchmark.html

http://homepages.paradise.net.nz/nickamy/raytracer/raytracer.htm

GI: interlived sampling technique
http://bat710.univ-lyon1.fr/~bsegovia/PhD/
http://bat710.univ-lyon1.fr/~bsegovia/papers/ids.html
face cluster radiosity: http://www.cs.cmu.edu/~ajw/paper/fcr-eg99/

diffuse interreflection:
http://download.nvidia.com/developer/GPU_Gems_2/GPU_Gems2_ch14.pdf

GI idea: http://ompf.org/forum/viewtopic.php?f=4&t=720

optymalizacje:
http://www.tantalon.com/pete.htm

Raytracing goes mainstream
http://developer.intel.com/technology/itj/2005/volume09issue02/art01_ray_tracing/vol09_art01.pdf


Z realstorm:
programers haven - http://www.algonet.se/~synchron/pheaven/www/area12.htm
scena - http://www.monostep.org/
java - http://www.antiflash.net/raytrace/
reference - http://fuzzyphoton.tripod.com/rtref.htm
http://remon.mojomedia.at/aboutme.html
http://www.oroboro.com/rafael/docserv.php/index/projects/article/raytrace	
http://tog.acm.org/resources/RTNews/demos/overview.htm
http://www.lightflowtech.com/

*/
