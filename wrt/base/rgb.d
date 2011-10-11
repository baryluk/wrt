module wrt.base.rgb;

import std.stdio : writefln;

import wrt.base.memory : alloc, dealloc;

struct rgb {
	union {
		struct {
			float r = 0.0f;
			float g = 0.0f;
			float b = 0.0f;
			float __dummy;
		}
		float cell[4];
	}

	static const ALIGMENT = 16;

	new(size_t sz) {
		return alloc(sz, ALIGMENT);
	}
	delete(void* p) {
		return dealloc(p);
	}

	void setColor(ref rgb color_) {
		r = color_.r;
		g = color_.g;
		b = color_.b;
	}

	static rgb from(ubyte[3] color_) {
		return rgb(color_[0]*(1.0f/255.0f), color_[1]*(1.0f/255.0f), color_[2]*(1.0f/255.0f));
	}

	static const rgb BLACK = rgb(0.0f, 0.0f, 0.0f);
	static const rgb WHITE = rgb(1.0f, 1.0f, 1.0f);
	static const rgb RED = rgb(1.0f, 0.0f, 0.0f);
	static const rgb GREEN = rgb(0.0f, 1.0f, 0.0f);
	static const rgb BLUE = rgb(0.0f, 0.0f, 1.0f);

	void print() {
		writefln("(%.3f,%.3f,%.3f)", r, g, b);
	}

version(rgb_simd) {
	static rgb mul(rgb* a, rgb* b) {
		rgb ret = void;
		rgb* pret = &ret;
		asm {
			mov EAX, a;
			mov EBX, b;
			movups XMM0, [EAX];
			movups XMM1, [EBX];
			mov EAX, pret;
			mulps XMM0, XMM1;
			movups [EBX], XMM0;
			emms;
		};
		return ret;
	}
}


	rgb opMul(ref rgb x) {
		version(rgb_simd) {
			return mul(this, &x);
		} else {
			return rgb(r*x.r, g*x.g, b*x.b);
		}
	}

version(rgb_simd) {
	static rgb add(rgb* a, rgb* b) {
		rgb ret = void;
		rgb* pret = &ret;
		asm {
			mov EAX, a;
			mov EBX, b;
			movups XMM0, [EAX];
			movups XMM1, [EBX];
			mov EAX, pret;
			addps XMM0, XMM1;
			movups [EBX], XMM0;
			emms;
		};
		return ret;
	}
}

	rgb opAdd(ref rgb x) {
		version(rgb_simd) {
			return add(this, &x);
		} else {
			return rgb(r+x.r, g+x.g, b+x.b);
		}
	}

version(rgb_simd) {
	static void addto(rgb* a, rgb* b) {
		asm {
//			naked;
			mov EAX, a;
			mov EBX, b;
			movups XMM0, [EAX];
			movups XMM1, [EBX];
			addps XMM0, XMM1;
			movups [EAX], XMM0;
			emms;
//			ret;
		}
	}
}

	void opAddAssign(ref rgb x) {
		version(rgb_simd) {
			addto(this, &x);
		} else {
			r += x.r;
			g += x.g;
			b += x.b;
		}
	}

	rgb opMul(float c) {
		return rgb(c*r, c*g, c*b);
	}

	void opMulAssign(float c) {
		r *= c;
		g *= c;
		b *= c;
	}

	void to_sRGB() {
		const static EXP = 1.0/2.4;
		const static a = 0.055;
		const static b = (1.0 + a);

		// From linear RGB to sRGB
		for (int i = 0; i < 3; i++) {
			cell[i] = (cell[i] <= 0.0031308 ? 12.92 * cell[i] : b * pow(cell[i], EXP) - a);
		}
	}
}
