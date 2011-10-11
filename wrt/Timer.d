module wrt.Timer;

import std.date;
import std.stdio;
 
class Timer {
	// Gets time in milisecond resolution
	static d_time getCount2() { return getUTCtime(); }

	/// Gets CPU tic (x86)
	static long getCount() {
		asm {
			naked	;
			rdtsc	;
			ret	;
		}
	}
	d_time starttime;

	///
	//long starttime;

	///
	char[] msg;
	float *dst;

	/// Starts timer
	this() { starttime = getCount2();}

	/// Starts timer and adds name to it
	this(char[] msg_, float* dst_ = null) {
		this(); msg = msg_;
		dst = dst_;
		writefln(msg ~ " started.");
	}

	/// Stops timer and prints (using log function) number of tics
	~this() {
		auto t = (getCount2() - starttime)/1000.0;
		if (dst !is null) {
			*dst = t;
		}
		if (msg !is null) {
			//writefln(msg ~ " done. elapsed time = %.0f ktics", t);
			writefln(msg ~ " done. elapsed time = %.3f s", t);
		} else {
			//writefln("elapsed time = %.0f ktics", t);
			writefln("elapsed time = %.3f s", t);
		}
	}
}

/// Gets CPU tic (x86)
long getTic() {
	asm {
		naked	;
		rdtsc	;
		ret	;
	}
}
