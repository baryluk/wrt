module wrt.target.Screen;

import wrt.base.rgb : rgb;
import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;
import wrt.base.Ray : Ray, hitinfo;
import wrt.base.misc : cross;

typedef rgb Pixel;

/// abstract
abstract class Screen {
	const int xsize, ysize;
	const float xsizef, ysizef;
	const float d;

	vec3 origin, P1, P2, P3, P4;

	mat4 m;
	vec3 dx, dy;

	this(int xsize_ = 640, int ysize_ = 480, float d_ = 1.0f)
	in {
		assert(0 < xsize_ && xsize_ <= 32000);
		assert(0 < ysize_ && ysize_ <= 32000);
		assert(xsize_ % 4 == 0);
		assert(ysize_ % 4 == 0);
	}
	body {
		xsize = xsize_;
		ysize = ysize_;
		d = d_ = 5.0f;

		xsizef = 1.0f/xsize;
		ysizef = 1.0f/ysize;

		setCamera(
			vec3(0.0f, 0.0f, 0.0f),
			vec3(0.0f, 0.0f, 1.0f)
		);
	}

	void setCamera_lookat(vec3 pos, vec3 target) {
		setCamera(pos, target - pos);
	}

	vec3 pos, zaxis;

	void setCamera(vec3 pos_, vec3 zaxis_) {
		pos = pos_;
		zaxis = zaxis_;
		// set camera
		zaxis.normalize();
		vec3 xaxis = cross(vec3(0.0f, 1.0f, 0.0f), zaxis);
		vec3 yaxis = cross(xaxis, -zaxis);
		m = mat4(
			xaxis.x, xaxis.y, xaxis.z, 0.0f,
			yaxis.x, yaxis.y, yaxis.z, 0.0f,
			zaxis.x, zaxis.y, zaxis.z, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f
		);
		m.invert();
		m.cells[3] = pos.x;
		m.cells[7] = pos.y;
		m.cells[11] = pos.z;

		// move camera
		origin = m*vec3(0.0f, 0.0f, -d);
		P1 = m*vec3(-4.0f, 3.0f, 0.0f);
		P2 = m*vec3(4.0f, 3.0f, 0.0f);
		P3 = m*vec3(4.0f, -3.0f, 0.0f);
		P4 = m*vec3(-4.0f, -3.0f, 0.0f);

		dx = (P2 - P1) * xsizef;
		dy = (P4 - P1) * ysizef;
	}

	Ray getRayForPixel(int i, int j) {
		Ray ray = Ray(origin);
		ray.direct_to(P1 + i*dx + j*dy);
		return ray;
	}


	int opApply(int delegate(ref rgb*, ref Ray) dg) {
		Ray ray = Ray(origin);
		rgb *k = new rgb;
		vec3 P = P1;
		for (int y = 0; y < ysize; y++, P += dy) {
			vec3 Pdx = vec3(0.0f, 0.0f, 0.0f);
			for (int x = 0; x < xsize; x++, Pdx += dx) {
				ray.direct_to(P + Pdx);
				ray.hi = hitinfo.init;
				/// TODO: near plane culling
				dg(k, ray);
				setPixel(x, y, *k);
			}
		}
		return 0;
	}

	void setPixel(int x, int y, rgb k);
	rgb getPixel(int x, int y) {
		return rgb();
	}
}
