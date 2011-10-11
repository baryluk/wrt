module wrt.base.memory;

import std.c.stdlib : malloc, free/*, posix_memalign*/;

version (D_Version2) {
import core.exception : oom = OutOfMemoryError;
} else {
import std.outofmemory : oom = OutOfMemoryException;
}

void* alloc(size_t sz) {
	void *p;
/*	if (std.c.stdlib.posix_memalign(&p, ALIGNMENT, sz) != 0) {
		throw new OutOfMemoryException(); // or other problem
	}
*/
	p = malloc(sz);
	if (!p) {
		throw new oom();
	}
	std.gc.addRange(p, p + sz);
	return p;
}

void dealloc(void *p) {
	if (p) {
		std.gc.removeRange(p);
		std.c.stdlib.free(p);
	}
}
