module wrt.textures.PerlinTexture;

import wrt.textures.Texture : Texture, Texture3D;
import wrt.base.rgb : rgb;
import wrt.textures.perlin : perlin_noise_2D, perlin_noise_3D;
import wrt.base.vec3 : vec3;
import std.math : cos;

/// TODO: animation
final class PerlinTexture : Texture {
	const rgb base_color;
	const int seed;
	const float scale;

	this(int seed_ = 1763871, rgb base_color_ = rgb.WHITE, float scale_ = 32.0f) {
		seed = seed_;
		base_color = base_color_;
		scale = scale_;
	}

	rgb getTexel(float u, float v, int mipmaplevel = 0)
	in {
		assert(0.0f <= u && u <= 1.0f);
		assert(0.0f <= v && v <= 1.0f);
		assert(mipmaplevel >= 0);
	}
	body {
		float temp = 0.5f*(perlin_noise_2D(seed, scale*u, scale*v) + 0.7f);
		if (temp < 0.0f) return rgb.BLACK;
		if (temp > 1.0f) return base_color;
		return temp * base_color;
	}
}

/// TODO: animation
final class CyclicPerlinTexture : Texture {
	rgb base_color;
	const int seed;

	this(int seed_ = 1763871, rgb base_color_ = rgb.WHITE) {
		seed = seed_;
		base_color = base_color_;
	}

	rgb getTexel(float u, float v, int mipmaplevel = 0)
	in {
		assert(0.0f <= u && u <= 1.0f);
		assert(0.0f <= v && v <= 1.0f);
		assert(mipmaplevel >= 0);
	}
	body {
		return 0.5f*(1.0f + perlin_noise_2D(seed, u, v)) * base_color;
	}
}

// http://freespace.virgin.net/hugo.elias/models/m_perlin.htm

final class PerlinTexture3D : Texture3D {
	const rgb base_color;
	const int seed;
	const float scale;

	this(int seed_ = 1711821, rgb base_color_ = rgb.WHITE, float scale_ = 32.0f) {
		seed = seed_;
		base_color = base_color_;
		scale = scale_;
	}

	rgb getTexel3D(vec3 xyz, int mipmaplevel = 0)
	in {
		assert(mipmaplevel >= 0);
	}
	body {
		xyz += vec3(1.0e3f, 1.0e3f, 1.0e3f);
		float temp = 0.5f*(perlin_noise_3D(seed, scale*xyz.x, scale*xyz.y, scale*xyz.z) + 0.7f);

		// marble
		temp = cos(6.0f*xyz.z + 10.0f*temp)*0.5f + 0.5f;

		// wood
		//temp *= 20.0f;
		//temp -= cast(int)temp;

		if (temp < 0.0f) return rgb.BLACK;
		if (temp > 1.0f) return base_color;
		return temp * base_color;
	}
}
