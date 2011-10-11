module wrt.samplers;

import std.stdio : writefln;
import std.math : abs;

import wrt.Scene : Scene;
import wrt.target.Screen : Screen;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;

void adaptative_sampler(Scene scene, Screen screen) {
	/*
	 * +--*--+
	 * |  |  |
	 * *--*--*
	 * |  |  |
	 * +--*--+
	 *
	 * + - already calculated
	 * * - to calculate on subdivision
	 */

	const int biggest_step = 8;

	// multi pass version
	for (int y = -screen.ysize/2; y < screen.ysize/2; y += biggest_step) {
		for (int x = -screen.xsize/2; x < screen.xsize/2; x += biggest_step) {
			screen.setPixel(x, y, scene.trace(screen.getRayForPixel(x, y)));
		}
	}
		
	void subsample(int x, int y, int step) {
		//if (step == 1) return;
		/// TODO: first get, a, b and compare, then c, and compare, then d
		/// if false, not calculate them
		rgb a = screen.getPixel(x, y);
		rgb b = screen.getPixel(x+step, y);
		rgb c = screen.getPixel(x, y+step);
		rgb d = screen.getPixel(x+step, y+step);
		float diff(rgb c1, rgb c2) {
			return abs(c1.r-c2.r) + abs(c1.g-c2.g) + abs(c1.b-c2.b);
		}

		const float toler = 0.08;

		if (diff(a, d) < toler &&
			diff(b, c) < toler && // diagonal
			diff(a, b) < toler &&
			diff(c, d) < toler &&
			diff(a, c) < toler &&
			diff(b, d) < toler) {
			/// NOTE: first pixeoverwrite (simpler conditions)
			float xaf = 0.0f, yaf = 0.0f;
			final float stepf = 1.0f/step;;
			/// NOTE: this can be calculated in orginal coordinates, so setPixel will dont need +i, +j
			/// TODO: ac, bd can be moved to the outer loop! (4 mul, and 4 sub/add less)
			for (int ya = 0; ya < step; ya++) {
				/// TODO: calculate a/b coefficient, one mul+sub less
				xaf = 0.0f;
				for (int xa = 0; xa < step; xa++) {
					// bilinear interpolation
					screen.setPixel(x+xa, y+ya, (1.0f-xaf)*(1.0f-yaf) * a + (1.0f-xaf)*yaf * b + xaf*(1.0f-yaf) * c + xaf*yaf * d);
					xaf += stepf;
				}
				yaf += stepf;
			}
		} else {
			step /= 2;
			screen.setPixel(x+step, y, scene.trace(screen.getRayForPixel(x+step, y))); // this point can be allready present, if not mayby reinterpolate lefter tile
			screen.setPixel(x+step, y+step, scene.trace(screen.getRayForPixel(x+step, y+step)));
			screen.setPixel(x, y+step, scene.trace(screen.getRayForPixel(x, y+step)));
			screen.setPixel(x+2*step, y+step, scene.trace(screen.getRayForPixel(x+2*step, y+step)));
			screen.setPixel(x+step, y+2*step, scene.trace(screen.getRayForPixel(x+step, y+2*step)));

			if (step == 1) return;

			subsample(x, y, step);
			subsample(x, y+step, step);
			subsample(x+step, y, step);
			subsample(x+step, y+step, step);
		}
	}

	for (int y = -screen.ysize/2; y < screen.ysize/2-biggest_step; y += biggest_step) {
		for (int x = -screen.xsize/2; x < screen.xsize/2-biggest_step; x += biggest_step) {
			subsample(x, y, biggest_step);
		}
	}
}

void tiled_sampler(Scene scene, Screen screen) {
	int tiling = 16;

	for (int y = -screen.ysize/2; y < screen.ysize/2; y+=tiling) {
	for (int x = -screen.xsize/2; x < screen.xsize/2; x+=tiling) {
		for (int yi = 0; yi < tiling; yi++) {
		for (int xi = 0; xi < tiling; xi++) {
			screen.setPixel(x+xi, y+yi, scene.trace(screen.getRayForPixel(x+xi, y+yi)));
		}
		}
	}
	}
}

void standard_sampler(Scene scene, Screen screen) {
	foreach (pixel, ray; screen) {
		*pixel = scene.trace(ray);
	}
}

void threaded_sampler(Scene scene, Screen screen) {
}

import wrt.accelstructs.MLRTA : mlrta_recurse, Beam, last_recursion, nul_recursion, split_recursion;

void mlrta_sampler(Scene scene, Screen screen) {
	const int tiling = 32;
	Ray[] rays = new Ray[tiling*tiling];

	for (int y = -screen.ysize/2; y < screen.ysize/2; y+=tiling) {
	for (int x = -screen.xsize/2; x < screen.xsize/2; x+=tiling) {
		int j;
		// TODO: Hilbert curver order
		for (int yi = 0; yi < tiling; yi++) {
		for (int xi = 0; xi < tiling; xi++) {
			rays[j++] = screen.getRayForPixel(x+xi, y+yi);
		}
		}

		Beam beam = Beam.create(rays,
			0, 0,
			tiling, tiling
		);

		mlrta_recurse(scene.bvh, beam, 1.0e-3f);
				
		int i = 0;
		// TODO: Hilbert curver order
		for (int yi = 0; yi < tiling; yi++) {
		for (int xi = 0; xi < tiling; xi++) {
			Ray ray = rays[i];
			i++;

			rgb p = (ray.hi.obj !is null ? scene.shader(ray, 0) : rgb.GREEN);

			screen.setPixel(x+xi, y+yi, p);
		}
		}
	}
	}

	foreach(i,x; last_recursion[0 .. 12]) {
		writefln("EP %d = %d", i, x);
	}

	foreach(i,x; nul_recursion[0 .. 12]) {
		writefln("nulEP: %d = %d", i, x);
	}

	foreach(i,x; split_recursion[0 .. 12]) {
		writefln("splitEP: %d = %d", i, x);
	}
}
