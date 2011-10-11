module wrt.textures.TextureCompositor;

import wrt.textures.Texture : Texture;
import wrt.base.rgb : rgb;

final class TextureCompositorAffine : Texture {
	/*final*/ Texture base;
	const float a;
	rgb b;

	this(Texture base_, float a_ = 1.0f, rgb b_ = rgb.BLACK) { // BUG compilator przy float b_ = rgb.BLACK (zla linia/plik bledu)
		base = base_;
		a = a_;
		b = b_;
	}

	rgb getTexel(float u, float v, int mipmaplevel = 0)
	in {
		assert(0.0f <= u && u <= 1.0f);
		assert(0.0f <= v && v <= 1.0f);
		assert(mipmaplevel >= 0);
	}
	body {
		return a * base.getTexel(u, v, mipmaplevel) + b;
	}
}

final class TextureCompositorTruncate : Texture {
	/*final*/ Texture base;
	rgb a, b;

	this(Texture base_, rgb a_ = rgb.BLACK, rgb b_ = rgb.WHITE) {
		base = base_;
		a = a_;
		b = b_;
	}

	rgb getTexel(float u, float v, int mipmaplevel = 0)
	in {
		assert(0.0f <= u && u <= 1.0f);
		assert(0.0f <= v && v <= 1.0f);
		assert(mipmaplevel >= 0);
	}
	body {
		rgb temp = base.getTexel(u, v, mipmaplevel);
		if (temp.r < a.r) temp.r = a.r;
		if (temp.g < a.g) temp.g = a.g;
		if (temp.b < a.b) temp.b = a.b;
		if (temp.r > b.r) temp.r = b.r;
		if (temp.g > b.g) temp.g = b.g;
		if (temp.b > b.b) temp.b = b.b;
		return temp;
	}
}

final class TextureCompositorTemplate(T : char[]) : Texture {
	final Texture base;

	this(Texture base_) {
		base = base_;
	}

	rgb getTexel(float u, float v, int mipmaplevel = 0)
	in {
		assert(0.0f <= u && u <= 1.0f);
		assert(0.0f <= v && v <= 1.0f);
		assert(mipmaplevel >= 0);
	}
	body {
		rgb temp = base.getTexel(u, v, mipmaplevel);
		{
		float x = temp.r;
		temp.r = mixin(T);
		}
		{
		float x = temp.g;
		temp.g = mixin(T);
		}
		{
		float x = temp.b;
		temp.b = mixin(T);
		}
		return temp;
	}
}
