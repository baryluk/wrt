module wrt.accelstructs.KDTree;

import std.stdio : writefln, writef;
//import std.math;

import wrt.base.AABB : AABB;
import wrt.objects.a3DObject : a3DObject;
import wrt.base.Point : Point, osie;

interface KDTree {
	void print(ref AABB aabb, int depth = 0);
}

/**
 * TODO: zrobic jako rekord variantowy, na uniach
 * i zmienimalizowac rozmiar, 8 B bylo by optymzalnie
 * ale ustalam limit na 16
 *
 * TODO: jacys hakerzy rosyjscy twierdza ze sie da zejsc ponizej 8 bajtow
 */
final class KDTreeNode : KDTree {
	float split_line;	// 4 B
	KDTree[2] node1;	// 4 B
	//a3DObject list;		// 4 B
	osie os;

	this(osie os_, float split_line_, KDTree left_, KDTree right_) {
		os = os_;
		split_line = split_line_;
		node1[0] = left_;
		node1[1] = right_;
	}

	static int partition(Point[] points, int left, int right, int pivotIndex, osie ax)
	in {
		assert(points !is null);
//		assert(left < right);
//		assert(left <= pivotIndex && pivotIndex < right);
	}
	body {
		Point pivotValue = points[pivotIndex];
		Point temp = points[right];
		points[right] = pivotValue;
		points[pivotIndex] = temp;
		int storeIndex = left;
		float pivotValueCoord = (ax == osie.X ? pivotValue.center.x : (ax == osie.Y ? pivotValue.center.y : pivotValue.center.z));
		for (int i = left; i < right-1; i++) {
			float coord = (ax == osie.X ? points[i].center.x : (ax == osie.Y ? points[i].center.y : points[i].center.z));
			if (coord < pivotValueCoord) {
				temp = points[storeIndex];
				points[storeIndex] = points[i];
				points[i] = temp;
				storeIndex++;
			}
		}

		temp = points[right];
		points[right] = points[storeIndex];
		points[storeIndex] = temp;

		return storeIndex;
	}

	static int select(Point[] points, int k, int left, int right, osie ax)
	in {
		assert(points !is null);
		assert(left < right);
//		assert(left+k < right);
	}
	body {
		assert(points.length);
		while(1) {
			int pivotIndex = left; // 0
			int pivotNewIndex = partition(points, left, right, pivotIndex, ax);
			if (k == pivotNewIndex) {
				return k;
			} else if (k < pivotNewIndex) {
				right = pivotNewIndex - 1;
			} else {
				left = pivotNewIndex + 1;
			}
		}
		assert(0);
	}

	static KDTree build_median(Point[] points, int depth = 0)
	in {
		assert(depth >= 0);
		assert(points !is null);
		assert(points.length >= 1);
	}
	body {
		if (points.length == 1) {
			return new KDTreeLeaf(points[0].obj);
		}

		osie ax = (depth % 3 == 0 ? osie.X : (depth % 3 == 1 ? osie.Y : osie.Z));

		// sort partially array, and give index of mediana
		int medianIndex = select(points, points.length/2, 0, points.length-1, ax);
		Point medianPoint = points[medianIndex];

		float coord = (ax == osie.X ? medianPoint.center.x : (ax == osie.Y ? medianPoint.center.y : medianPoint.center.z));

		KDTree left = build_median(points[0 .. medianIndex], depth+1);
		KDTree right = build_median(points[medianIndex .. $], depth+1);

		return new KDTreeNode(ax, coord, left, right);
	}

	void print(ref AABB aabb, int depth = 0) {
		for (int i = 0; i < depth; i++) {
			writef(" ");
		}
		writefln("node, split ax = %d, ", os, "split_line=%f", split_line);
		
		if (node1[0]) {
			AABB temp = aabb.split(os, split_line, 1);
			temp.print();
			node1[0].print(temp, depth+1);
		}
		if (node1[1]) {
			AABB temp = aabb.split(os, split_line, 0);
			temp.print();
			node1[1].print(temp, depth+1);
		}
	}
}

final class KDTreeLeaf : KDTree {
	a3DObject obj;

	this(a3DObject obj_) {
		obj = obj_;
	}

	void print(ref AABB aabb, int depth = 0) {
		for (int i = 0; i < depth; i++) {
			writef(" ");
		}
		writef("obj %x, center=", &obj);
		obj.getCenter().print();
	}
}
