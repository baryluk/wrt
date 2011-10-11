module wrt.Lights;

import wrt.objects.Light : Light;

final class Lights {
	Light[] objs;

	void opCatAssign(Light obj) {
		objs ~= obj;
	}

	int opApply(int delegate(ref Light obj) dg) {
		foreach (obj; objs) {
			dg(obj);
		}
		return 0;
	}

	size_t count() {
		return objs.length;
	}
}

Lights lights;
