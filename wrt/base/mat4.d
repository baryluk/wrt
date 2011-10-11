module wrt.base.mat4;

import std.math : cos, sin;

import wrt.base.vec3 : vec3;

align(16) struct mat4 {
	union {
		struct {
			const float xx, xy, xz, xw;
			const float yx, yy, yz, yw;
			const float zx, zy, zz, zw;
			const float wx, wy, wz, ww;
		}
		const float cells[16];
	}

	static mat4 rotation(vec3 axis, float angle) {
		final float c = cos(angle);
		final float s = sin(angle);
		final float C = 1.0f-c;
		final float xs = axis.x*s, ys = axis.y*s, zs = axis.z*s;
		final float xC = axis.x*C, yC = axis.y*C, zC = axis.z*C;
		final float xyC = axis.x*yC, yzC = axis.y*zC, zxC = axis.z*xC;
		return mat4(
			axis.x*xC + c, xyC - zs, zxC + ys, 0.0f,
			xyC + zs, axis.y*yC + c, yzC - xs, 0.0f,
			zxC - ys, yzC + xs, axis.z*zC + c, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f
		);
	}

	static mat4 translation(vec3 direction, float scale = 1.0f) {
		return mat4(
			1.0f, 0.0f, 0.0f, direction.x*scale,
			0.0f, 1.0f, 0.0f, direction.y*scale,
			0.0f, 0.0f, 1.0f, direction.z*scale,
			0.0f, 0.0f, 0.0f, 1.0f
		);
	}

	static mat4 scale(float c) {
		return mat4(
			c, 0.0f, 0.0f, 0.0f,
			0.0f, c, 0.0f, 0.0f,
			0.0f, 0.0f, c, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);

	}

	static mat4 scale_xyz(float cx, float cy, float cz) {
		return mat4(
			cx, 0.0f, 0.0f, 0.0f,
			0.0f, cy, 0.0f, 0.0f,
			0.0f, 0.0f, cz, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);

	}


	static const I = mat4(1.0f, 0.0f, 0.0f, 0.0f,
						0.0f, 1.0f, 0.0f, 0.0f,
						0.0f, 0.0f, 1.0f, 0.0f,
						0.0f, 0.0f, 0.0f, 1.0f);

	const int
		XX = 0, XY = 1, XZ = 2, XW = 3,
		YX = 4, YY = 5, YZ = 6, YW = 7,
		ZX = 8, ZY = 9, ZZ = 10, ZW = 11,
		WX = 12, WY = 13, WZ = 14, WW = 15;

	vec3 opMul(vec3 b) {
		return vec3(
				xx*b.x + xy*b.y + xz*b.z + xw,
				yx*b.x + yy*b.y + yz*b.z + yw,
				zx*b.x + zy*b.y + zz*b.z + zw
		);
	}

/*
	vec4 opMul(vec4 b) {
		return vec4(
				xx*b.x + xy*b.y + xz*b.z + xw*b.w,
				yx*b.x + yy*b.y + yz*b.z + yw*b.w,
				zx*b.x + zy*b.y + zz*b.z + zw*b.w,
				wx*b.x + wy*b.y + wz*b.z + ww*b.w
		);
	}
*/

	mat4 opMul(mat4 b) {
		mat4 ret;
		for (int i = 0; i < 4; i++) {
			for (int j = 0; j < 4; j++) {
				ret.cells[4*i+j] =
					cells[4*i+0] * b.cells[4*0 + j] +
					cells[4*i+1] * b.cells[4*1 + j] +
					cells[4*i+2] * b.cells[4*2 + j] +
					cells[4*i+3] * b.cells[4*3 + j];
			}
		}
		return ret;
	}

	/// invert in place
	/// assums that matrix is projection matrix (so part of inversion can be done
	/// by transposition)
	void invert() {
		mat4 t;
		float tx = -cells[3], ty = -cells[7], tz = -cells[11];
		for (int h = 0; h < 3; h++) {
			for ( int v = 0; v < 3; v++) {
				t.cells[h + v * 4] = cells[v + h * 4];
			}
		}
		for (int i = 0; i < 11; i++) {
			cells[i] = t.cells[i];
		}
		cells[3] = tx * cells[0] + ty * cells[1] + tz * cells[2];
		cells[7] = tx * cells[4] + ty * cells[5] + tz * cells[6];
		cells[11] = tx * cells[8] + ty * cells[9] + tz * cells[10];
	}
}
