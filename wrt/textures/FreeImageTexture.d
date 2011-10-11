module wrt.textures.FreeImageTexture;

import wrt.base.rgb : rgb;
import wrt.textures.Texture : Texture;

version(with_freeimage) {

import wrt.external.disabled.freeimage;

final class FreeImageTexture : Texture {
	const FreeImageBitmap fib;
	const int xsize, ysize;

	this(char[] filename) {
		fib = new FreeImageBitmap(filename);
		if (!fib.isValid()) {
			throw new Exception("bad format of file");
		}
		xsize = fib.width;
		ysize = fib.height;
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
		RGBQUAD rq;
		FreeImage_GetPixelColor(fib.fib, cast(uint)x, cast(uint)y, &rq);
		return rgb(rq.rgbRed*(1.0f/255.0f), rq.rgbGreen*(1.0f/255.0f), rq.rgbBlue*(1.0f/255.0f));
	}
}

} // version(with_freeimage)
