module wrt.misc.DoubleLinkedList;

class DoubleLinkedList(T) {
private:
	Node first_, last_;

	//size_t lenght_;

	class Node {
private:
		T* t;
		Node prev, next;

public:
		this(ref T t0) {
			t = &t0;
		}
	
		// befor us
		Node insertBefore(ref T t0) {
			auto n = new Node(t0);

			n.prev = this.prev;
			n.next = this;
	
			if (this.prev is null) {
				this.prev = n;
				first_ = n;
			} else {
				this.prev.next = n;
			}

			this.prev = n;

			return n;
		}

		Node insertAfter(ref T t0) {
			auto n = new Node(t0);

			n.prev = this;
			n.next = this.next;
	
			if (this.next is null) {
				this.next = n;
				last_ = n;
			} else {
				this.next.prev = n;
			}

			this.next = n;

			return n;
		}

		void remove() {
			if (this.prev is null) {
				first_ = this.next;
			} else {
				this.prev.next = this.next;
			}

			if (this.next is null) {
				last_ = this.prev;
			} else {
				this.next.prev = this.prev;
			}

			// delete this;
		}

		T* get() {
			return t;
		}

	}

public:
	invariant {
		assert(last_ is null ^^ first_ !is null);
	}

	bool notempty() {
		return (first_ !is null);
	}

	bool isempty() {
		return (first_ is null);
	}

	this() {
	}

	this(T[] tab) {
		foreach (t; tab) {
			insertEnd(&t);
		}
	}

	Node insertBeginning(ref T t0)
	out {
		assert(notempty());
	}
	body {
		if (first_ !is null) {
			return first_.insertBefor(t0);
		} else {
			auto n = new Node(t0);
			first_ = n;
			last_ = n;
			n.prev = null;
			n.next = null;
			return n;
		}
	}

	Node insertEnd(ref T t0)
	out {
		assert(notempty());
	}
	body {
		if (last_ !is null) {
			return last_.insertAfter(t0);
		} else {
			return insertBeginning(t0);
		}
	}

	int opApply(int delegate(int i, ref T* t0) dg) {
		size_t i = 0;
		Node n = first_;

		while (n !is null) {
			int r = dg(i, n.t);
			if (r) {
				return r;
			}
			n = n.next;
			i++;
		}

		return 0;
	}

	int opApply_r(int delegate(int i, ref T* t0) dg) {
		size_t i = 0;
		Node n = last_;

		while (n !is null) {
			int r = dg(i, n.t);
			if (r) {
				return r;
			}
			n = n.prev;
			i++;
		}

		return 0;
	}

	size_t lenght()
	out(ret) {
		assert(ret >= 0);
	}
	body {
		size_t i = 0;
		Node n = first_;

		while (n !is null) {
			n = n.next;
			i++;
		}

		return i;
	}

	Node opIndex(int idx) {
		if (idx >= 0) {
			size_t i = 0;
			Node n = first_;

			while (n !is null) {
				if (i == idx) {
					return n;
				}
				n = n.next;
				i++;
			}
		} else {
			size_t i = -1;
			Node n = last_;

			while (n !is null) {
				if (i == idx) {
					return n;
				}
				n = n.prev;
				i--;
			}
		}
		throw new Exception("Invalid DoubleLinkedList index");
	}

	Node first() {
		return first_;
	}

	Node last() {
		return last_;
	}
}
