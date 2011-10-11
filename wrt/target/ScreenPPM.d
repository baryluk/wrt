module wrt.target.ScreenPPM;

import std.stream : Stream, BufferedFile, FileMode;

import wrt.base.rgb : rgb;

import wrt.target.Screen : Screen, Pixel;

final class ScreenPPM : Screen {
	rgb[] pixels;

	this(int xsize_ = 640, int ysize_ = 480, float d_ = 1.0f, int bpm_ = 32)
	body {
		super(xsize_, ysize_, d_);

		pixels.length = xsize*ysize;
	}

	override void setPixel(int x, int y, rgb k)
	in {
		assert(0 <= x && x < xsize);
		assert(0 <= y && y < ysize);
	}
	body {
		pixels[y*xsize + x] = k;
	}

	void dump(string filename) {
		Stream s = new BufferedFile(filename, FileMode.Out);
		s.writef("P6\n%d %d\n255\n", xsize, ysize);
		for (uint i = 0; i < xsize*ysize; i++) {
			s.write(cast(ubyte)(pixels[i].r <= 1.0f ? pixels[i].r*255.0f : 255));
			s.write(cast(ubyte)(pixels[i].g <= 1.0f ? pixels[i].g*255.0f : 255));
			s.write(cast(ubyte)(pixels[i].b <= 1.0f ? pixels[i].b*255.0f : 255));
		}
		s.close();
	}
}
