module wrt.textures.PPMTexture;

import std.stream : Stream, BufferedFile, FileMode;

import wrt.textures.Texture;
import wrt.base.rgb : rgb;

final class PPMTexture : Texture {
	char[] filename;
	ubyte[3][] pixels;

	int xsize, ysize;

	this(char[] filename_) {
		filename = filename_;
		scope Stream s = new BufferedFile(filename, FileMode.In);
		char[] temp;
		temp = s.readLine();
		assert(temp == "P6"); // hard assert
		s.readf("%d %d\n", &xsize, &ysize);
		pixels.length = xsize*ysize;
		int maxcolors;
		s.readf("%d", &maxcolors);
		assert(maxcolors == 255); // hard assert
		ubyte a, b, c;
		ubyte* p = pixels[0].ptr;
		for (int i = 0; i < 3*ysize*xsize; i++) {
			s.read(*p++);
		}
		s.close();
	}

	rgb getTexel(float u, float v, int mipmaplevel = 0) 
	in {
		assert(0.0f <= u && u <= 1.0f);
		assert(0.0f <= v && v <= 1.0f);
		assert(mipmaplevel >= 0);
	}
	body {
		final int x = cast(int)(u*(xsize-1));
		final int y = cast(int)(v*(ysize-1));
		assert(0 <= x && x < xsize);
		assert(0 <= y && y < ysize);
		return rgb.from(pixels[y*xsize + x]);
	}
}

final class PPMTextureBilinear : Texture {
	char[] filename;
	ubyte[3][] pixels;

	int xsize, ysize;

	this(char[] filename_) {
		filename = filename_;
		scope Stream s = new BufferedFile(filename, FileMode.In);
		char[] temp;
		temp = s.readLine();
		assert(temp == "P6"); // hard assert
		s.readf("%d %d\n", &xsize, &ysize);
		pixels.length = xsize*ysize;
		int maxcolors;
		s.readf("%d", &maxcolors);
		assert(maxcolors == 255); // hard assert
		ubyte a, b, c;
		ubyte* p = pixels[0].ptr;
		for (int i = 0; i < 3*ysize*xsize; i++) {
			s.read(*p++);
		}
		s.close();
	}

	rgb getTexel(float u, float v, int mipmaplevel = 0) 
	in {
		assert(0.0f <= u && u <= 1.0f);
		assert(0.0f <= v && v <= 1.0f);
		assert(mipmaplevel >= 0);
	}
	body {
		float fracx = u*(xsize-1);
		float fracy = v*(ysize-1);
		final int x = cast(int)(fracx);
		final int y = cast(int)(fracy);
		fracx -= x;
		fracy -= y;

		assert(0 <= x && x < xsize);
		assert(0 <= y && y < ysize);

		return (1.0f-fracx)*(1.0f-fracy)*rgb.from(pixels[y*xsize + x])
			+ fracx*(1.0f-fracy)*rgb.from(pixels[y*xsize + x+1])
			+ (1.0f-fracx)*fracy*rgb.from(pixels[(y+1)*xsize + x])
			+ fracx*fracy*rgb.from(pixels[(y+1)*xsize + x+1]);
	}
}
