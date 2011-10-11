module wrt.Material;

import wrt.base.rgb : rgb;
import wrt.textures.Texture : Texture, Texture3D;

final class Material {
	rgb emittance; // jak swieci
	rgb reflectance; // jak odbija
	rgb refractance; // jak przeswituje
	rgb diffusion; // lambertian reflectance
	rgb absorbtion; // absorbcja podczas propagacji (zanik wykladniczy, prawo Beera)
	rgb specular; // phong specular highlight
	//rgb subsurfacescatering;
	rgb color;

	Texture texture;
	Texture3D texture3D;

	// additional textures:
	//   bump mapping
	//   normal mapping
	//   glock mapping (refractance mapping)
	//   reflectance mapping
	//   specular+phong mapping
	union {
		union {
			Texture3D bump_map;
			float bump_map_coeff;
		}
		Texture normal_map;
	}
	Texture glock_map;
	Texture reflectance_map;

	const float refractive_index = 1.1f; // Quartz
	float phong_exponent = 20.0f; // shininess, more higher more mirror-like

	/// BRDF bidirectional Reflectance Distribution Function

	this(rgb color_ = rgb.BLACK) {
		color = color_;
	}

	this(Texture texture_) {
		texture = texture_;
	}


	static const Material RED, GREEN, BLUE;

	static this() {
		RED = new Material(rgb.RED);
		GREEN = new Material(rgb.GREEN);
		BLUE = new Material(rgb.BLUE);
	}
}
