module wrt.geometry.triangulation;

import wrt.misc.DoubleLinkedList : DoubleLinkedList;

/** Simple algorith for simple polygon triangulation */

Triangle[] triangulate(vertex[] P) {
	Triangle[] D = new Triangle[P.length - 2];
	D.length = 0;

	auto R = new DoubleLinkedList!(vertex)(P);

	R.Node x0 = R.first();
	R.Node xi = R[2];

	while (xi != x0) {
		if (isAnEar(xi.prev().get(), P, R) && P.length != 3) {
			D ~= new Triangle(
					xi.prev().prev().get(), 
					xi.prev().get(), 
					xi.get()
				);
			P -= xi.prev();
			if (xi in R && isConvexVertex(xi.get())) {
				xi.remove(); // from R
			}
			if (xi.prev() in R && isConvexVertex(xi.prev().get())) {
				xi.prev().remove(); // from R
			}
			if (xi.prev() == x0) {
				xi = xi.next();
			}
		} else {
		}
	}

	return D;
}

bool isAnEar(vertex* xi, vertex[] P, DoubleLinkedList!(vertex) R) {
	if (R.isempty()) { // P is convex
		return true;
	} else {
		if (isConvexVertex(xi)) {
			if () {
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
}
