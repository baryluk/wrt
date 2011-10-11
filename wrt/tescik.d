module tescik;

align(16) struct vec3 {
	union {
		struct {
			float x;
			float y;
			float z;
			float dummy;
		}
		struct {
			float cell[4];
		}
	}

	static const ALIGMENT = 16;

/*
	new(size_t sz) {
		return alloc(sz, ALIGMENT);
	}
	delete(void* p) {
		return dealloc(p);
	}
*/

	const static vec3 pinf = vec3(1.0f/0.0f, 1.0f/0.0f, 1.0f/0.0f);
	const static vec3 minf = vec3(-1.0f/0.0f, -1.0f/0.0f, -1.0f/0.0f);

	const static vec3 X_AXIS = vec3(1.0f, 0.0f, 0.0f);
	const static vec3 Y_AXIS = vec3(0.0f, 1.0f, 0.0f);
	const static vec3 Z_AXIS = vec3(0.0f, 0.0f, 1.0f);

	const static vec3 I = vec3(1.0f, 1.0f, 1.0f);

}

void main() {
}

