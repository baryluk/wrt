module wrt.base.Point;

import wrt.base.vec3 : vec3;
import wrt.objects.a3DObject : a3DObject;
import wrt.base.AABB : AABB;

enum osie : ubyte {
	X, Y, Z
};

align(16) struct Point {
	vec3 center;
	a3DObject obj;
}

align(16) struct Centroid {
	AABB aabb;
	a3DObject obj;
}
