/**
 * cn.kuehne.flectioned - runtime reflection for D ($Rev: 8186 $)
 *
 * Authors: Thomas Kühne, thomas@kuehne.cn
 *
 * License:
 *
 * Copyright (c) 2006-2007, Thomas Kühne thomas@kuehne.cn
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

//module cn.kuehne.flectioned;
module external.flectioned;

// API
version(Unix){
//	version = Posix;
}else version(linux){
//	version = Posix;
}else version(Win32){
	version = MSWindows;
}else version(Windows){
	version = MSWindows;
}else{
	static assert(0, "unhandled OS");
}

// ABI
version(Posix){
	version = BIN_ELF;
}else version(MSWindows){
	version = BIN_PE;
}

// features
version(minimal){
	// no fake mangling of libc functions
}else{
	version = intrinsics;
}

// DMD-1 / DMD-2
static if(!is(string)){
	static if(! is(typeof((new object.Object()).toString()) string)){
		alias char[] string;
	}
}
static if(is(typeof((new char[3]).idup))){
	private const dmd_version = 2;
}else{
	private const dmd_version = 1;
}
static if(1 < dmd_version){
	const char[] invariantCall = "invariant(){ invariant_(); }";
	mixin("alias const(char*) stringz;");
}else{
	private const char[] invariantCall = "invariant{ invariant_(); }";
 	alias char* stringz;
}
static if(!is(string)){
	// DMD-1
	static if(! is(typeof((new Object()).toString()) string)){
		alias char[] string; // Tango
	}
}

/*
// import hell (-version=Tango isn't reliable)
static if(is(typeof((new object.Object()).toUtf8()) == char[])){
	const bool inTango = true;
	const bool inPhobos = false;
}else{
	const bool inTango = false;
	static if(is(typeof((new object.Object()).toString()))){
		const bool inPhobos = true;
	}else{
		const bool inPhobos = false;
	}
}
*/

const bool inPhobos = true;
const bool inTango = false;
static if(inTango){
/*
	import tango.core.Vararg;
	static import tango.text.convert.Layout;
	private tango.text.convert.Layout.Layout!(char) Formatter;
	import tango.stdc.ctype : isdigit;
	import tango.text.convert.Integer : toInt, toLong;
	import tango.core.Exception : IllegalArgumentException;
	import tango.stdc.string : memmove, memcpy, memcmp, strcmp;
	import tango.stdc.stringz : ptr2array = fromUtf8z;
	import tango.stdc.stdio : sscanf, printf;
	import tango.text.convert.Integer : size2array = toUtf8;
	import tango.core.Array : find, rfind;
	import tango.text.Util : delimit;
	static import tango.stdc.errno;
	private alias tango.stdc.errno.errno getErrno;
	private alias tango.stdc.errno.errno setErrno;
	import tango.core.Exception : TracedExceptionInfo, setTraceHandler;

	private uint toUint(char[] s){
		auto x = toLong(s);
		if(x < 0){
			throw new IllegalArgumentException("negative value");
		}
		return cast(uint) x;
	}

	private char[] getString(Object o){
		return o.toUtf8();
	}
*/
}else static if(inPhobos){
	import std.stdarg;
	import std.string : format, ptr2array = toString, size2array = toString, split, find, rfind;
	import std.ctype : isdigit;
	import std.conv : toInt, toUint;
	import std.c.string : memmove, memcmp, memcpy, strcmp;
	import std.c.stdlib : getErrno, setErrno;
	import std.c.stdio : sscanf;
	import std.demangle : demangle;
	
	private string getString(Object o){
		return o.toString();
	}
}else{
	static assert(0, "neither Phobos nor Tango");
}

unittest{
	Exception e = new Exception("abc");
	assert("abc" == getString(e));
}

version(Posix){
	static if(inTango){
/*
		import tango.stdc.string : strerror;
		import tango.stdc.posix.unistd : access, lseek;
		import tango.stdc.stdint : uint8_t, uint16_t, uint32_t, int32_t, uint64_t, int64_t;
		import tango.stdc.stdio : fopen, fclose, fgets, FILE, fread, fseek, printf, fprintf, stderr;
		import tango.stdc.stdlib : abort;
		import tango.stdc.posix.signal : sigaction_t, siginfo_t, sigemptyset, SA_SIGINFO, SIGSEGV, SIGFPE, SIGILL, sigaction;
*/
	}else version(DigitalMars){
		import std.c.linux.linux : mprotect, PROT_NONE, PROT_READ, PROT_WRITE, PROT_EXEC;
		import std.file : strerror;
		import std.c.linux.linux : access, lseek;
		import std.c.stdio : fopen, fclose, fgets, FILE, fread, fseek, fprintf, stderr;
		import std.stdint : uint8_t, uint16_t, uint32_t, int32_t, uint64_t, int64_t;
		import std.c.linux.linux : SIGILL, SIGSEGV, SIGFPE;
		import std.c.process : abort;
		import std.thread :  sigaction_t, sigaction, sigset_t;
		private extern(C){
			const SA_SIGINFO = 4;
			int sigemptyset(sigset_t*);
			struct siginfo_t{
				int si_signo;
				int si_errno;
				int si_code;
				void* si_addr;
				size_t[32] dummy;
			}
		}
	}else version(GNU){
		import std.file : strerror;
		import std.c.stdio : fopen, fclose, fgets, FILE, fread, fseek, fprintf, stderr;
		import std.stdint : uint8_t, uint16_t, uint32_t, int32_t, uint64_t, int64_t;
		import std.c.unix.unix : SIGILL, SIGSEGV, SIGFPE;
		import std.c.process : abort;
		import std.c.unix.unix :  sigaction_t, sigaction, sigset_t, siginfo_t, SA_SIGINFO, sigemptyset;
	}else{
		static assert(0, "unknown import locations");
	}
	
	static if(!is(typeof(strsignal))){
		private extern(C) char *strsignal(int sig);
	}

	static if(!is(typeof(ucontext_t))){
		private extern(C){
			struct stack_t{
				size_t *ss_sp;
				int ss_flags;
				size_t ss_size;
			}

			struct mcontext_t{
				size_t[19] gregs;
				size_t dummy[4096];
			}

			struct ucontext_t{
				size_t uc_flags;
				ucontext_t* uc_link;
				stack_t uc_stack;
				mcontext_t uc_mcontext;
				size_t dummy[4096];
			}
		}
	}

	static if(!is(typeof(mprotect))){
		private extern(C){
			int mprotect(void*, size_t, int);
			enum{
				PROT_NONE	= 0,
				PROT_READ	= 1,
				PROT_WRITE	= 2,
				PROT_EXEC	= 4
			}
		}
	}

	static if(!is(typeof(SEEK_SET))){
		private enum{
			SEEK_SET = 0
		}
	}

	static if(!is(typeof(getpagesize))){
		private extern(C) int getpagesize();
	}

	static if(!is(typeof(access))){
		private extern(C) int access(char*, int);
	}
}else version(MSWindows){
	static if(inTango){
//		import tango.sys.win32.UserGdi;
	}else static if(inPhobos){
		import std.c.windows.windows;
	}else{
		static assert(0);
	}

	static if(!is(typeof(IsBadReadPtr)))
		private extern(Windows) BOOL IsBadReadPtr(LPCVOID, UINT);

	static if(!is(typeof(SetLastError)))
		private extern(Windows) VOID SetLastError(DWORD);

	static if(!is(typeof(WriteProcessMemory)))
		private extern(Windows) BOOL WriteProcessMemory(HANDLE, void*, void*, size_t, size_t*);
}

/**
 * Base class of all exceptions thrown by Flectioned.
 */
class SymbolException : Exception{
	this(string msg){
		super(msg);
	}

	mixin(invariantCall);
	private void invariant_(){
		assert(msg.length > 0);
	}

	unittest{
		Class c = cast(Class)types["cn.kuehne.flectioned.SymbolException"];
		assert(c);
		assert(c.classInfo == SymbolException.classinfo);
	}
}


/**
 * Thrown if missing symbols are encountered.
 */
class ReflectionException : SymbolException{
	this(string msg){
		super(msg);
	}

	mixin(invariantCall);
	private void invariant_(){
		assert(msg.length > 0);
	}
	
	unittest{
		Class c = cast(Class)types["cn.kuehne.flectioned.ReflectionException"];
		assert(c);
		assert(c.classInfo == ReflectionException.classinfo);
	}
}

/**
 * No suitable overload or conflicting overloads found.
 */
class OverloadException : ReflectionException{
	this(char[] msg){
		super(msg);
	}

	mixin(invariantCall);
	private void invariant_(){
		assert(msg.length > 0);
	}
	
	unittest{
		Class c = cast(Class)types["cn.kuehne.flectioned.OverloadException"];
		assert(c);
		assert(c.classInfo == OverloadException.classinfo);
	}
}

/**
 * Thrown by illegal operations (e.g. instantiating interfaces)
 */
class IllegalReflectionException : ReflectionException{
	this(string msg){
		super(msg);
	}

	mixin(invariantCall);
	private void invariant_(){
		assert(msg.length > 0);
	}
	
	unittest{
		Class c = cast(Class)types["cn.kuehne.flectioned.IllegalReflectionException"];
		assert(c);
		assert(c.classInfo == IllegalReflectionException.classinfo);
	}
}

/**
 * Indicates incorrect (de-)mangling of symbol information
 */
class ManglingException : SymbolException{
	this(string msg){
		super(msg);
	}

	mixin(invariantCall);
	private void invariant_(){
		assert(msg.length > 0);
	}
	
	unittest{
		Class c = cast(Class)types["cn.kuehne.flectioned.ManglingException"];
		assert(c);
		assert(c.classInfo == ManglingException.classinfo);
	}
}

/**
 * Contains the known Symbols stored by their mangled names.
 *
 * Please note that more than one symbol could have identical mangling. Use
 * cn.kuehne.flectioned.addresses if you need access to all _symbols
 * (including nested D functions and local _symbols).
 *
 * See_Also: cn.kuehne.flectioned.addresses, cn.kuehne.flectioned.Trace.findSymbol
 */
Symbol[char[]] symbols;

unittest{
	foreach(Symbol s; symbols){
		// can't check for equality: some symbols have different names but share addresses (_deh_beg ...)
		assert(s.address in addresses);
	}
}

/**
 * All known Symbols stored by their starting _addresses.
 *
 * Bugs:
 *	Some symbols generated by DMD have identical _addresses
 *	(e.g. __deh_beg and an anonymous symbol).
 *
 * See_Also: cn.kuehne.flectioned.symbols, cn.kuehne.flectioned.Trace.findSymbol
 */
Symbol[void*] addresses;

/**
 * Base class for all Symbols and Types
 */
class Symbol{
	/**
	 * starting address
	 *
	 * More accuratly this is the value of the symbol optained from the
	 * underlying binary format.
	 */
	void* address;

	/**
	 * The size of the symbol in bytes
	 *
	 * Bugs: DMD quite often claims that a symbol is of _size 0, even when it isn't.
	 */
	size_t size;

	/**
	 * printable/demangled _name
	 *
	 * See_Also: cn.kuehne.flectioned.Symbol.mangledName
	 */
	string name;

	/**
	 * mangled name
	 *
	 * The very name provided by the binary format.
	 *
	 * See_Also: cn.kuehne.flectioned.Symbol.name
	 */
	string mangledName;

	/**
	 * The TypeInfo of this symbol
	 *
	 * null if unknown
	 */
	TypeInfo type;

	mixin(invariantCall);
	private void invariant_(){
		assert(name.length);
		if(type is null){
			assert(this.classinfo is Symbol.classinfo);
		}
	}

	this(void* address, size_t size, string name, TypeInfo ti){
		this.address = address;
		this.size = size;
		this.name = name;
		this.type = ti;
	}

	static if(inTango){
		/// toString wrapper for Tango
		override char[] toUtf8()
		out(s){
			assert(s.length > 0);
		}body{
			return toString();
		}
	}else static if(!inPhobos){
		static assert(0, "neither object.Object.toUtf8 nor object.Object.toString found");
	}

	string toString()
	out(s){
		assert(s.length > 0);
	}body{
		static if(is(typeof(Formatter))){
			return Formatter("{0} (0x{1" ~ ZX ~ "}, {2})", name, cast(size_t)address, size);
		}else{
			return format("%s (0x" ~ ZX ~ ", %s)", name, address, size);
		}
	}

	unittest{
		Symbol s = new Symbol(cast(void*)0x234_FABA, 13, "/so/viel/Schnee/", null);
		static if(4 == size_t.sizeof){
			assert("/so/viel/Schnee/ (0x0234FABA, 13)" == s.toString());
		}else static if(8 == size_t.sizeof){
			assert("/so/viel/Schnee/ (0x000000000234FABA, 13)" == s.toString());
		}else{
			static assert(0);
		}
	}

	/**
	 * Convert a dot delimited _name (e.g. "ab.cde") into a
	 * mangled _name(e.g. "2ab3cde").
	 */
	static char[] dot2qualified(string name)
	out(s){
		assert(s.length > name.length);
	}body{
		if(name.length < 1){
			throw new ManglingException("empty symbol");
		}

		size_t start = 0;
		size_t end = 0;

		// try to minimize relocating "result" via pre-allocation
		char[] result = new char[name.length + name.length / 5];
		result.length = 0;

		for(end = 0; end < name.length; end++){
			if('.' == name[end]){
				if(start - end == 1){
					throw new ManglingException("empty element found inside symbol " ~ name);
				}
				result ~= size2array(end - start);
				result ~= name[start .. end];
				start = end + 1;
			}
		}
		result ~= size2array(end - start);
		result ~= name[start .. end];
		return result;
	}

	unittest{
		assert(dot2qualified("a.bc.efghijklmn") == "1a2bc10efghijklmn");
	}

	/**
	 * cleanup this symbol after all symbols have been loaded
	 *
	 * (resolves LazyTypeInfos, finds members of aggregate types, etc.)
	 *
	 * See_Also: cn.kuehne.flectioned.LazyTypeInfo
	 */
	void cleanup(){
		type = LazyTypeInfo.resolve(type);
	}
	
	unittest{
		Class c = cast(Class)types["cn.kuehne.flectioned.Symbol"];
		assert(c);
		assert(c.classInfo == Symbol.classinfo);
	}
	
	unittest{
		Symbol* s = ("_D2cn6kuehne10flectioned7symbols" ~ typeof(symbols).mangleof) in symbols;
		assert(s);
		assert(s.address == &symbols);
	}

	unittest{
		Symbol* s = &symbols in addresses;
		assert(s);
		assert(s.address == &symbols);
	}

	/// register a new symbol
	static Symbol insertRawSymbol(stringz name, void* value, size_t size, bool isPublic = true){
		char[] mangled = ptr2array(name).dup;

		Symbol s = handleRawSymbol(mangled, value, size, isPublic);
		if(s !is null){
			s.mangledName = mangled;
			if(isPublic){
				symbols[s.mangledName] = s;
			}
			if(s.name.length == 0){
				s.name = s.mangledName;
			}

			addresses[s.address] = s;
		}
		return s;
	}
	
	unittest{
		auto pre_address = addresses.length;
		auto pre_symbols = symbols.length;
		Symbol s = insertRawSymbol("an-unique-symbol-just-for-testing\u0000".ptr,
			&pre_address, 2, false);
		assert(s);
		assert(pre_address + 1 == addresses.length);
		assert(pre_symbols == symbols.length);
		addresses.remove(s.address);
		assert(pre_address == addresses.length);
	}
	
	unittest{
		auto pre_address = addresses.length;
		auto pre_symbols = symbols.length;
		Symbol s = insertRawSymbol("an/unique/symbol/just/for/testing\u0000".ptr,
			&pre_address, 2, true);
		assert(s);
		assert(pre_address + 1 == addresses.length);
		assert(pre_symbols + 1 == symbols.length);
		addresses.remove(s.address);
		assert(pre_address == addresses.length);
		assert(pre_symbols + 1 == symbols.length);
		symbols.remove(s.name);
		assert(pre_address == addresses.length);
		assert(pre_symbols == symbols.length);
	}

	/**
	 * Find symbols inside an optlink map (dmd -L/DETAILEDMAP ...)
	 */
	static void scanOptlinkMap(string mapData,
		Symbol function(stringz name, void* address, size_t size, bool isPublic) foundSymbol = &insertRawSymbol)
	{
		// new RegExp("^0*([0-9A-F]*)H [0-9A-F]*H 0*([0-9A-F]*)H   Module=[^ ]* \\[(.*)\\]", "g");
		// using sscanf instead to support tango

		char * source = (mapData ~ "0").dup.ptr;
		char * raw = source;
		void* address = null;
		size_t size = 0;
		int end;
		char name[8192];

		while(*raw){
			char check;
			// find next entry
			int matchCount = sscanf(raw, "%zXH %*zXH %XH   %*[^ ] %c%[^]]%n", &address, &size, &check, name.ptr, &end);
			if(4 == matchCount && '[' == check){
				foundSymbol(name.ptr, address, size, true);
				raw += end;
			}

			// find next new-line
			while(*raw){
				if('\n' == *raw){
					raw++;
					break;
				}
				raw++;
			}
		}
		cleanupAllSymbols();

		delete source;
	}

	unittest{
		const char[] map =
		"0042EC20H 0042EC21H 00001H   Module=unittest_walker.obj(unittest_walker)\n"
		"00431C23H 0043EC25H 00002H   Module=E:\\dm\\bin\\..\\x.lib(multpol) [just/a/test]\n"
		"0042EC26H 0042EC29H 00003H   Module=unittest_walker.obj(unittest_walker)";

		static count = 0;
		static Symbol found(stringz name, void* address, size_t size, bool isPublic){
			assert(0x431C23 == cast(size_t)address);
			assert(2 == size);
			count++;
			assert(0 == strcmp(name, "just/a/test"));
			return null;
		}
	
		auto pre_address = addresses.length;
		auto pre_symbols = symbols.length;

		assert(0 == count);
		scanOptlinkMap(map, &found);
		assert(1 == count);

		assert(pre_address == addresses.length);
		assert(pre_symbols == symbols.length);
	}
	
	/**
	 * Tries to resolve all outsanding issues with the known Symbols
	 * (e.g. resolving LazyTypeinfo and finding aggreagte members)
	 */
	static void cleanupAllSymbols(){
		foreach(symbol; symbols){
			symbol.cleanup();
		}
		foreach(symbol; addresses){
			symbol.cleanup();
		}
	}
}

// terminator for Trace.getTrace
private extern(C) void main(int agrc, char** argv);
private extern(C) void _Dmain();

/**
 * Describes a step within a stack trace.
 *
 * See_Also: cn.kuehne.flectioned.TracedException
 */
class Trace{
	/**
	 * Address of the code executed.
	 * 
	 * See_Also: cn.kuehne.flectioned.Trace.symbol
	 */
	void* code;
	deprecated alias code pos;

	/**
	 * Symbol(if any) owning the code executed.
	 *
	 * See_Also: cn.kuehne.flectioned.Trace.code
	 */
	Symbol symbol;

	/**
	 * stack address
	 */
	void* stack;

	/**
	 * Commonly expected longest stack trace.
	 */
	static size_t tracePreAlloc = 16;

	this(Symbol symbol, void* stack, void* code){
		this.symbol = symbol;
		this.stack = stack;
		this.code = code;
	}

	unittest{
		int stack_dummy, code_dummy;
		Trace t = new Trace(null, &stack_dummy, &code_dummy);
		assert(&code_dummy == t.code);
		assert(&stack_dummy == t.stack);
		assert(null is t.symbol);
		delete t;
	}

	/**
	 * Find the Symbol that owns the given address.
	 */
	static Symbol findSymbol(void* addr){
		foreach(sym; addresses){
			if(sym.address <= addr && addr < sym.address + sym.size){
				return sym;
			}
		}
		return null;
	}

	unittest{
		assert(findSymbol(&symbols) == addresses[&symbols]);
		assert(findSymbol((cast(void*)&symbols) + symbols.sizeof - 1) == addresses[&symbols]);
		Symbol sym = findSymbol((cast(void*)&symbols) + symbols.sizeof);
		assert((sym is null) || (sym != addresses[&symbols]));
	}

	/**
	 * Get call trace.
	 *
	 * Bugs: should use WalkStack on MSWindows systems
	 */
	static Trace[] getTrace()
	out(result){
		assert(result.length > 0);
	}body{
		size_t bp;
		static if(size_t.sizeof == 4){
			asm{
				mov bp, EBP;
			}
		}else static if(8 == size_t.sizeof){
			uint a, b;
			asm{
				// gdc-0.23's X86_64 asm is broken
				db 0x48, 0x89, 0xE8; // mov rax, rbp
				db 0x48, 0x89, 0xE9; // mov rcx, rbp
				db 0x48, 0xc1, 0xc0, 0x20; // rol rax, 32
				mov a, EAX;
				mov b, ECX;
			}
			bp = a;
			bp <<= 32;
			bp |= b;
		}else{
			static assert(0, "unhandled pointer size");
		}

		Trace trace[] = new Trace[tracePreAlloc];
		trace.length = 0;

		bool reporter(Symbol symbol, void* stack, void* code){
			trace ~= new Trace(symbol, stack, code);
			return true;
		}
		getTrace(&reporter, bp);

		return trace;
	}

	unittest{
		Trace[] t;
		void test(){
			t = getTrace();
		}
		test();
		
		assert(t.length >= 3);

		bool foundMain = false;
		foreach(step; t){
			if(step.symbol && ((step.symbol.address == &main) || (step.symbol.address == &_Dmain)) || step.code is null){
				foundMain = true;
				break;
			}
		}
		assert(foundMain);
	}

	/// ditto
	static void getTrace(bool delegate(Symbol symbol, void* stack, void* code)reporter)
	in{
		assert(reporter);
	}body{
		size_t bp;
		static if(size_t.sizeof == 4){
			asm{
				mov bp, EBP;
			}
		}else static if(8 == size_t.sizeof){
			uint a, b;
			asm{
				// gdc-0.23's X86_64 asm is broken
				db 0x48, 0x89, 0xE8; // mov rax, rbp
				db 0x48, 0x89, 0xE9; // mov rcx, rbp
				db 0x48, 0xc1, 0xc0, 0x20; // rol rax, 32
				mov a, EAX;
				mov b, ECX;
			}
			bp = a;
			bp <<= 32;
			bp |= b;
		}else{
			static assert(0, "unhandled pointer size");
		}
		getTrace(reporter, bp);
	}
	
	unittest{
		int step;
		bool reporter(Symbol,void*,void*){
			step++;
			return (step < 4);
		}
		void test(){
			getTrace(&reporter);
		}
		test();

		assert(step == 4);
	}

	/// ditto
	static Trace[] getTrace(size_t bp){
		Trace trace[] = new Trace[tracePreAlloc];
		trace.length = 0;

		bool reporter(Symbol symbol, void* stack, void* code){
			trace ~= new Trace(symbol, stack, code);
			return true;
		}
		getTrace(&reporter, bp);
		return trace;
	}
	
	unittest{
		size_t bp;
		static if(size_t.sizeof == 4){
			asm{
				mov bp, EBP;
			}
		}else static if(8 == size_t.sizeof){
			uint a, b;
			asm{
				// gdc-0.23's X86_64 asm is broken
				db 0x48, 0x89, 0xE8; // mov rax, rbp
				db 0x48, 0x89, 0xE9; // mov rcx, rbp
				db 0x48, 0xc1, 0xc0, 0x20; // rol rax, 32
				mov a, EAX;
				mov b, ECX;
			}
			bp = a;
			bp <<= 32;
			bp |= b;
		}else{
			static assert(0);
		}
		Trace[] trace = getTrace(bp);
		assert(trace.length > 0);
		assert(trace[0].symbol);
		assert(trace[0].symbol.name.length > 0);
		assert(find(trace[0].symbol.name, ".unittest") != -1);
	}

	/// ditto
	static void getTrace(bool delegate(Symbol sym, void* stack, void* code)reporter, size_t bp){
		version(MSWindows){
			static bool may_read(size_t addr){
				return !IsBadReadPtr(cast(void*)addr, size_t.sizeof);
			}
		}else version(Posix){
			static bool may_read(size_t addr){
				setErrno(0);
				access(cast(char*)addr, 0);
				return getErrno() != 14;
			}
		}else{
			static assert(0);
		}

		Symbol symbol;
		size_t tmp;
		void* caller;

		while(bp){
			tmp = bp + size_t.sizeof;
			if(!may_read(tmp)){
				break;
			}
			
			caller = cast(void*)*cast(size_t *)tmp;
			if(!may_read(bp)){
				break;
			}
			bp =  *cast(size_t*) bp;
			symbol = findSymbol(caller);

			if(!reporter(symbol, cast(void*) bp, caller)){
				break;
			}
			if((symbol && ((symbol.address == &main)
					|| (symbol.address == &_Dmain)))
				|| (null is caller)
				|| (0 == bp))
			{
				break;
			}
		}
	}

	string toUtf8(){
		return toString();
	}

	string toString(){
		static if(is(typeof(Formatter))){
			return Formatter("0x{0" ~ ZX ~ "}\t0x{1" ~ ZX ~ "}\t{2}",
				cast(size_t)stack, cast(size_t)code, symbol ? symbol.name : "<?>"); 
		}else{
			return format("0x" ~ ZX ~ "\t0x" ~ ZX ~ "\t%s", stack, code, symbol ? symbol.name : "<?>");
		}
	}
	
	unittest{
		Trace t = new Trace(null, cast(void*)0x130, cast(void*)0x987_6543);
		static if(4 == size_t.sizeof){
			assert("0x00000130\t0x09876543\t<?>" == t.toString());
		}else static if(8 == size_t.sizeof){
			assert("0x0000000000000130\t0x0000000009876543\t<?>" == t.toString());
		}else{
			static assert(0);
		}
	}
}

/**
 * Helper function for gdb, invoke as
 * $(D_STRING call print_trace($ebp) ) or $(D_STRING call print_trace($rbp) )
 */
extern(C) void print_trace(size_t bp){
	// try to limit the use of Phobos/Tango functions as much as possible
	// to aid debugging the D-RT internals
	bool reporter(Symbol sym, void* stack, void* code){
		if(!sym){
			printf(("0x" ~ ZX_C ~"\t0x" ~ ZX_C ~ "\t<?>\n\x00"c).ptr, stack, code);
		}else{
			printf(("0x"  ~ ZX_C ~  "\t0x" ~ ZX_C ~ "\t%.*s (%p, %zu)\n\x00"c).ptr,
				stack, code, cast(int)sym.name.length, sym.name.ptr, sym.address, sym.size);
		}
		return true;
	}
	Trace.getTrace(&reporter, bp);
}

version(Posix){
	version(X86){
		version	= haveSegfaultTrace;
	}else version(X86_64){
		version	= haveSegfaultTrace;
	}

	version(haveSegfaultTrace){
		private extern(C){
			sigaction_t fault_action;
			void setupSegfaultTracer(){
				fault_action.sa_handler = cast(typeof(fault_action.sa_handler)) &fault_handler;
				sigemptyset(&fault_action.sa_mask);
				fault_action.sa_flags = SA_SIGINFO;
				sigaction(SIGSEGV, &fault_action, null);
				sigaction(SIGFPE, &fault_action, null);
				sigaction(SIGILL, &fault_action, null);
			}

			void fault_handler (int sn, siginfo_t * si, void *ctx){
				fprintf(stderr, "%s encountered at:\n", strsignal(sn));
				size_t ignore_handler = 0;
				bool reporter(Symbol sym, void* stack, void* code){
					if(ignore_handler){
						ignore_handler--;
					}else if(!sym){
						fprintf(stderr, ("0x" ~ ZX_C ~"\t0x" ~ ZX_C ~ "\t<?>\n\x00"c).ptr, stack, code);
					}else{
						fprintf(stderr, ("0x"  ~ ZX_C ~  "\t0x" ~ ZX_C ~ "\t%.*s (%p, %zu)\n\x00"c).ptr,
							stack, code, cast(int)sym.name.length, sym.name.ptr, sym.address, sym.size);
					}
					return true;
				}

				ucontext_t * context = cast(ucontext_t *) ctx;
				void* stack;
				void* code;
				version(X86){
					stack = cast(void*) context.uc_mcontext.gregs[6];
					code = cast(void*) context.uc_mcontext.gregs[14];
				}else version(X86_64){
					stack = cast(void*) context.uc_mcontext.gregs[0xF];
					code = cast(void*) context.uc_mcontext.gregs[0x10];
				}else{
					static assert(0);
				}
				reporter(Trace.findSymbol(code), stack, code);
				ignore_handler = 2;
				Trace.getTrace(&reporter);
				abort();
			}
		}
	}else{
		pragma(msg, "[INFO] SEGFAULT trace not yet implemented for this CPU");
	}
}else{
	pragma(msg, "[INFO] SEGFAULT trace not yet implemented for this OS");
}

private{
	version(Windows){
		static if(is(typeof((new Exception("")).print))){
			extern(C) void D6object9Exception5printMFZv();
			alias D6object9Exception5printMFZv _D6object9Exception5printMFZv;
		
			static if(dmd_version < 2){
				extern(C) void D6object9Exception5_ctorMFAaZC9Exception();
				alias D6object9Exception5_ctorMFAaZC9Exception _D6object9Exception5_ctorMFAaZC9Exception;
			}else{
				extern(C) void D6object9Exception5_ctorMFAxaZC9Exception();
				alias D6object9Exception5_ctorMFAxaZC9Exception _D6object9Exception5_ctorMFAaZC9Exception;
			}
		}else{
			extern(C) void D6object9Exception5_ctorMFAaAakC9ExceptionZC9Exception();
			alias D6object9Exception5_ctorMFAaAakC9ExceptionZC9Exception _D6object9Exception5_ctorMFAaAakC9ExceptionZC9Exception;
		}
	}else{
		static if(is(typeof((new Exception("")).print))){
			extern(C) void _D6object9Exception5printMFZv();
			static if(dmd_version < 2){
				extern(C) void _D6object9Exception5_ctorMFAaZC9Exception();
			}else{
				extern(C) void _D6object9Exception5_ctorMFAxaZC9Exception();
				alias _D6object9Exception5_ctorMFAxaZC9Exception _D6object9Exception5_ctorMFAaZC9Exception;
			}
		}else{
			extern(C) void _D6object9Exception5_ctorMFAaAakC9ExceptionZC9Exception();
		}
	}
}


static if(inTango){
	/**
	 * Exception containing stack trace information is provided by Tango,
	 * however the trace infromation is "private"
	 * ... thus the opApply-trick
	 */
	class TracedException : tango.core.Exception.TracedException{
		///
		Trace[] trace;

		///
		this(char[] msg){
			super(msg);
			getTrace();
		}

		///
		this(char[] msg, Exception e){
			super(msg, e);
			getTrace();
		}
		
		///
		this(char[] msg, char[] file, size_t line){
			super(msg, file, line);
			getTrace();
		}

		private void getTrace(){
			// get the real trace information from FlectionedTrace
			int delegate(inout char[]) dg;
			dg.ptr = cast(void*)this;
			dg.funcptr = &opApplyTrick;
			opApply(dg);
		}
		
		///
		static TracedExceptionInfo tangoTraceHandler(void* ptr = null){
			return new FlectionedTrace(ptr);
		}

		///
		void print(){
			print_traced_exception(this);
		}

		private static int opApplyTrick(inout char[] x){
			return 1;
		}

		private static class FlectionedTrace : TracedExceptionInfo{
			this(void* ptr = null ){
				if(ptr){
					m_trace = Trace.getTrace(cast(size_t) ptr);
				}else{
					m_trace = Trace.getTrace();

					// hide the trace infrastructure
					size_t start = 0;
					foreach(i, trace; m_trace){
						if(trace.symbol &&
							trace.symbol.name == "object.ClassInfo tango.core.Exception.traceContext(void*)"){
							start = i + 1;
							break;
						}
					}
					if(start){
						m_trace = m_trace[start .. $];
					}
				}

			}

			int opApply( int delegate( inout char[] ) dg ){
				int ret = 0;
		
				// kludge for exporting the trace information
				// to cn.kuehne.flectioned.TracedException
				if(&opApplyTrick == dg.funcptr){
					TracedException te = cast(TracedException) dg.ptr;
					if(te){
						te.trace = m_trace.dup;
						return 0x11_22_33_44;
					}
				}

				foreach( t; m_trace ){
					char[] buf = t.toString;
					ret = dg( buf );
					if(0 != ret){
						break;
					}
				}
				return ret;
			}

			private Trace[] m_trace;
		}
	}
}else static if(inPhobos){
	/**
	 * Exception containing stack trace information.
	 */
	class TracedException : Exception{
		///
		Trace[] trace;
		
		/**
		 * Use this to get access to the traces of all Exceptions
		 * after calling TracedException.traceAllExceptions(true)
		 */
		static Trace[][Exception] retraced;

		private static bool allExceptions = false;

		///
		static synchronized void traceAllExceptions(bool state = true){
			static void[] this_org;
			static void[] print_org;

			if(allExceptions == state){
				// no change
			}else if(state){
				void* this_addr = &_D6object9Exception5_ctorMFAaZC9Exception;
				version(GNU){
					ubyte[] this_ = Function.redirect(this_addr, &create_traced_exception);
				}else version(DigitalMars){
					ubyte[] this_ = Function.redirect(this_addr, &create_traced_exception_dmd);
				}else{
					static assert(0);
				}
			
				void* print_addr = &_D6object9Exception5printMFZv;
				ubyte[] print_ = Function.redirect(print_addr,  &print_traced_exception);
				if(this_org.length < 1){
					this_org = this_;
					print_org = print_;
				}
			}else{
				void* print_addr = &_D6object9Exception5printMFZv;
				Function.restoreRedirection(print_addr, print_org);

				void* this_addr = &_D6object9Exception5_ctorMFAaZC9Exception;
				Function.restoreRedirection(this_addr, this_org);
			}

			allExceptions = state;
		}
			
		unittest{
			try{
				throw new Exception("abc");
			}catch(Exception e){
				assert("abc" == e.msg);
				assert(!(e in retraced));
				delete e;
			}

			traceAllExceptions(true);

			try{
				throw new Exception("2abc34");
			}catch(Exception e){
				assert("2abc34" == e.msg);
				assert(e in retraced);
				delete e;
			}
			
			traceAllExceptions(false);

			try{
				throw new Exception("FOO");
			}catch(Exception e){
				assert("FOO" == e.msg);
				assert(!(e in retraced));
				delete e;
			}
		}
		
		///
		this(string message){
			super(message);
			if(!allExceptions){
				create_traced_exception(this, message);
			}
			trace = retraced[this];
		}

		unittest{
			TracedException e = new TracedException("just rain");
			assert("just rain" == e.msg);
			assert(e in retraced);
			assert(e.trace == retraced[e]);
		}

		void print(){
			print_traced_exception(this);
		}
		
		private static class RebaseHelper{
			private static RebaseHelper helper;

			void deleteRebasedException(Object o){
				Exception e = cast(Exception) o;
				if(e && e in retraced){
					retraced.remove(e);
				}
			}

			static this(){
				helper = new RebaseHelper();
			}
		}
	}

	version(DigitalMars){
		private Exception create_traced_exception_dmd(char[] msg, Exception e){
			return  create_traced_exception(e, msg);
		}
	}else version(GNU){
		// no argument reordering required
	}else{
		static assert(0);
	}

	/**
	 * Bugs: un-tracing constructors of nested Exceptions is nasty
	 */
	private Exception create_traced_exception(Exception e, string msg)
	in{
		assert(e);
	}body{
		e.msg = msg;

		char[] master = e.classinfo.name ~ " " ~ e.classinfo.name ~ "._ctor";

		Trace[] trace = Trace.getTrace();

		// remove all leading steps including the real constructor
		foreach(i, step; trace){
			if(step.symbol is null){
				continue;
			}
			string name = step.symbol.name;
			if(name.length < master.length){
				continue;
			}
			if(name[0 .. master.length] == master){
				trace = trace[i+1 .. $];
				goto Ldone;
			}
		}

		version(DigitalMars){
			void* checker = &create_traced_exception_dmd;
		}else version(GNU){
			void* checker = &create_traced_exception;
		}else{
			static assert(0);
		}

		// try to remove all leading steps inculding the checker
		foreach(i, step; trace){
			if(step.symbol && step.symbol.address == checker){
				trace = trace[i+1 .. $];
				goto Ldone;
			}
		}
	Ldone:
		TracedException.retraced[e] = trace;
		static if(is(typeof(object.Object.notifyRegister))){
			if(!TracedException.RebaseHelper.helper){
				TracedException.RebaseHelper.helper = new TracedException.RebaseHelper();
			}
			e.notifyRegister(&TracedException.RebaseHelper.helper.deleteRebasedException);
		}else static if(inTango){
			// not an issue because retraced isn't present
		}else{
			pragma(msg, "WARNING: memory leak due to missing Object.notifyRegister");
		}
		return e;
	}
	
}else{
	static assert(0, "neither Phobos nor Tango");
}

private void print_traced_exception(Exception e)
in{
	assert(e);
}body{
	Trace[]* trace;
	TracedException te = cast(TracedException)e;
	if(te){
		trace = &te.trace;
	}else static if(is(typeof(TracedException.retraced))){
		trace = e in TracedException.retraced;
	}
	string tmp = e.msg;
	printf("(%.*s) %.*s\n", e.classinfo.name, cast(int)tmp.length, tmp.ptr);
	if(trace){
		Trace[] t = *trace;
		foreach(step; t){
			tmp = getString(step);
			printf("\t%.*s\n", cast(int)tmp.length, tmp.ptr);
		}
	}
}

/// All known types, including primitive ones, stored by fully qualified name.
TypeSymbol[char[]] types;

unittest{
	foreach(t; types){
		assert((null == t.address) || (t.address in addresses));
	}
}

/// Base class for all Symbols describing types
abstract class TypeSymbol : Symbol{
	///
	TypeSymbol parent;

	/**
	 * member function - both static and non-static - of this type
	 *
	 * Bugs: doesn't include special properties like .sizeof, .length, etc. ...
	 */
	Function[][string] members;

	this(void* address, size_t size, string name, TypeInfo ti){
		super(address, size, name, ti);
		types[name] = this;
	}

	/**
	 * create a new instance of this type
	 *
	 * Throws: IllegalReflectionException, OverloadException
	 */
	void[] newInstance(...){
		return newInstanceV(_arguments, _argptr);
	}
	
	/**
	 * create a new instance of this type
	 *
	 * Throws: IllegalReflectionException, OverloadException
	 */
	abstract void[] newInstanceV(TypeInfo[], va_list);

	unittest{
		Class c = cast(Class)types["cn.kuehne.flectioned.TypeSymbol"];
		assert(c);
		assert(c.classInfo == TypeSymbol.classinfo);
	}

	override void cleanup(){
		super.cleanup();

		// find member functions
		string starter = name ~ ".";
		foreach(funcs; functions){
			if(startsWith(funcs[0].overload, starter)){
				string overload = funcs[0].overload[name.length + 1 .. $];
				if(cast(size_t)find(overload, ".") >= overload.length){
					members[overload] = funcs;
				}
			}
		}
	}

	unittest{
		TypeSymbol ti = types["object.Object"];
		assert("toHash" in ti.members);
	}

	/**
	 * Bugs: see cn.kuehne.flectioned.Function.resolve
	 * Throws: see cn.kuehne.flectioned.Function.resolve
	 */
	Function getFunction(string name, TypeInfo arguments[] ...){
		return Function.resolve(name, members, arguments);
	}
}

private extern(C) Object _d_newclass(ClassInfo);

/// represents a class
class Class : TypeSymbol{
	/// ClassInfo of the represented class
	ClassInfo classInfo;

	mixin(invariantCall);
	private void invariant_(){
		assert(classInfo !is null);
		ClassInfo c = classInfo;
		ushort i;
		for(i = 0; i < short.max; i++){
			if(c is Object.classinfo){
				break;
			}
			c = c.base;
		}
		assert(i < short.max);
	}

	this(void* address, size_t size, string name){
		classInfo = cast(ClassInfo) address;
		bool useClassInfoName = false;

		// use the classInfo name: demangle(mangling) != classInfo.name ....
		if(classInfo && classInfo.name){
			useClassInfoName  = true;
		}
		// templates...
		if(contains(name, "!(")){
			useClassInfoName = false;
		}
			
		super(address, size, useClassInfoName ? classInfo.name : name, new TypeInfo_Class());

		(cast(TypeInfo_Class)type).info = classInfo;
	}

	override void[] newInstanceV(TypeInfo[] arguments, va_list argptr){
		Object o = newObjectV(arguments, argptr);
		size_t a = cast(size_t) cast(void*)o;
		size_t* b = new size_t;
		*b = a;
		return (cast(ubyte*)b)[0 .. size_t.sizeof]; 
	}
	
	unittest{
		TypeSymbol* s = "object.Object" in types;
		assert(s);
		void[] instance = s.newInstance();
		assert(instance.length == (void*).sizeof);
		Object o = cast(Object) cast(void*) *cast(size_t*)instance.ptr;
		assert(o.classinfo == Object.classinfo);
	}

	/**
	 * create a new instance of the represented class
	 *
	 * Throws: cn.kuehne.flectioned.OverloadException
	 * Bugs: see Class.newObjectV
	 */
	Object newObject(...){
		return newObjectV(_arguments, _argptr);
	}

	unittest{
		TypeSymbol* s = "object.Object" in types;
		assert(s);
		Class c = cast(Class) *s;
		assert(c);
		assert(c.classInfo == Object.classinfo);
		Object o = c.newObject();
		assert(o.classinfo == Object.classinfo);
	}

	/**
	 * create a new instance of the represented class
	 *
	 * Bugs: requires an explicit this() constructor, doesn't support opCall
	 * Throws: cn.kuehne.flectioned.OverloadException
	 */
	Object newObjectV(TypeInfo[] arguments, va_list argptr){
		if(arguments.length){
			throw new IllegalReflectionException("custom constructors aren't yet supported");
		}

		// special case: Object
		if(classInfo == Object.classinfo){
			return new Object();
		}

		void* object = null;

		// allocate
		Function f;
		try{
			f = getFunction("new", [typeid(size_t)]);
		}catch{
		}

		if(f){
			// custom allocator
			object = (cast(void* function(uint))f.address)(classInfo.sizeof);
			(cast(byte*)object)[0 .. classInfo.init.length] = classInfo.init[];
		}else{
			// standard allocator
			object = cast(void*) _d_newclass(classInfo);
		}

		// call constructor
		f = getFunction("_ctor", arguments);
		(cast(void function(void*))f.address)(object); // @todo@ -> callFunction

		return cast(Object)object;
	}
	
	override string toString(){
		static if(is(typeof(Formatter))){
			return Formatter("{0} (0x{1" ~ ZX ~ "}, {2})", classInfo.name, cast(size_t)address, size);
		}else{
			return format("%s (0x" ~ ZX ~ ", %s)", classInfo.name, address, size);
		}
	}

	override void cleanup(){
		super.cleanup();
		Symbol* s = (cast(void*)classInfo.base) in addresses;
		if(s){
			parent = cast(TypeSymbol) *s;
		}
	}
}

/// represents a struct
class Struct : TypeSymbol{
	this(void* address, size_t size, string name){
		super(address, size, name, cast(TypeInfo_Struct) address);
	}

	/**
	 * Bugs: custom constructors and opCall aren't supported yet
	 */
	override void[] newInstanceV(TypeInfo[] arguments, va_list){
		if(arguments.length){
			throw new IllegalReflectionException("custom constructors aren't yet supported");
		}

		TypeInfo_Struct si = cast(TypeInfo_Struct) type;
		void* result;
		
		// allocate
		Function f;
		try{
			f = getFunction("new", [typeid(size_t)]);
		}catch{
		}

		if(f is null){
			// standard allocator
			if(si.init.ptr){
				result = si.init.dup.ptr;
			}else{
				size_t size = si.init.length / size_t.sizeof;
				if(si.init.length % size_t.sizeof){
					size++;
				}
				static if(is(typeof(si.flags))){
					if(si.flags()){
						result = (new void[si.init.length]).ptr;
					}else{
						result = (new size_t[size]).ptr;
					}
				}else{
					result = (new size_t[size]).ptr;
				}
			}
		}else{
			// custom allocator
			result = (cast(void* function(uint))f.address)(si.init.length);
			(cast(byte*)result)[0 .. si.init.length] = (cast(byte*)si.init.ptr)[0 .. si.init.length];
		}

		return result[0 .. si.init.length];
	}
}

/// represents a typedef'ed type
class Typedef : TypeSymbol{
	this(void* address, size_t size, string name){
		super(address, size, name, cast(TypeInfo_Typedef) address);
	}
	
	/// Bugs: not yet implemented
	override void[] newInstanceV(TypeInfo[], va_list){
		throw new IllegalReflectionException("not yet implemented");
	}
}

/// represents an enum type
class Enum : TypeSymbol{
	this(void* address, size_t size, char[] name){
		super(address, size, name, cast(TypeInfo_Enum) address);
	}

	/// Bugs: not yet implemented
	override void[] newInstanceV(TypeInfo[], va_list){
		throw new IllegalReflectionException("not yet implemented");
	}
}

/// represents an interface
class Interface : TypeSymbol{
	this(void* address, size_t size, char[] name){
		super(address, size, name, cast(TypeInfo_Interface) address);
	}

	override void[] newInstanceV(TypeInfo[], va_list){
		throw new IllegalReflectionException("can't create a new instance of interface " ~ name);
	}
}

/// 
class ValueSymbol : Symbol{
	this(void* address, size_t size, char[] name, TypeInfo ti){
		super(address, size, name, ti);
	}

	override void cleanup(){
		super.cleanup();
		name = getString(type) ~ " " ~ name;
	}
}

///
enum CallConvention{
	C,	///
	D,	///
	Windows,	///
	Pascal		///
}

/// Phobos' TypeInfo_Function doesn't care about argument types, calling conventions or this-pointers.
class TypeInfo_Function2 : TypeInfo_Function{
	bool require_this; ///
	TypeInfo[] arguments; ///
	CallConvention convention; ///

	this(TypeInfo returnType, TypeInfo[] argType, CallConvention conv, bool require_this){
		this.next = returnType;
		this.arguments = argType;
		this.convention = conv;
		this.require_this = require_this;
	}

	char[] generateNiceName(string overload_name = ""){
		char[] nice_name = new char[64];
		nice_name.length = 0;

		switch(convention){
			case CallConvention.C:
				nice_name ~= "extern(C) ";
				break;
			case CallConvention.D:
				// add nothing
				break;
			case CallConvention.Pascal:
				nice_name ~= "extern(Pascal) ";
				break;
			case CallConvention.Windows:
				nice_name ~= "extern(Windows) ";
				break;
			default:
				nice_name ~= "extern(?) ";
		}

		nice_name ~= getString(next) ~ " " ~ overload_name ~ "(";
		if(arguments.length){
			nice_name ~= getString(arguments[0]);
			foreach(t; arguments[1 .. $]){
				nice_name ~= ", " ~ getString(t);
			}
			if(require_this){
				nice_name ~= ", this";
			}
		}else if(require_this){
			nice_name ~= "this";
		}
		return nice_name ~= ")";
	}
}

/// all known functions including libc/libm/libpthread
Function[][char[]] functions;
unittest{
	foreach(fs; functions){
		foreach(f; fs){
			auto g = f.address in addresses;
			assert(g);
			assert(f.size == g.size);
		}
	}
}

///
class Function : Symbol{
	string overload; /// the fully qualified dot-delimited name
	
	TypeInfo_Function2 func(){
		return cast(TypeInfo_Function2) type;
	}

	///
	public CallConvention getCallConvention(){
		return func.convention;
	}

	///
	public TypeInfo[] getArguments(){
		return func.arguments;
	}

	///
	this(void* address, size_t size, string name, TypeInfo_Function2 ti){
		super(address, size, name, ti);
		this.overload = name;

		Function[]* fp = name in functions;
		if(fp){
			*fp ~= this;
		}else{
			Function[] f = new Function[1];
			f[0] = this;
			functions[name] = f;
		}
	}

	void cleanup(){
		super.cleanup();

		for(size_t i = 0; i < func.arguments.length; i++){
			func.arguments[i] = LazyTypeInfo.resolve(func.arguments[i]);
		}
		name = func.generateNiceName(overload);
	}

	///
	static Function resolve(string name, TypeInfo[] arguments ...){
		return resolve(name, functions, arguments);
	}
	
	/**
	 * Bugs:
	 *	variadic functions aren't yet supported
	 *
	 *	useless for non-primitive type due to Phobos bugs
	 */
	static Function resolve(string name, Function[][string] source, TypeInfo[] arguments ...){
		Function[]* candidates = name in source;
		Function externFunc;
		Function[] closerLook;

		if(candidates is null){
			throw new ReflectionException("no candidates found: " ~ name);
		}
		foreach(funct; *candidates){
			auto args = funct.getArguments();
			auto conv = funct.getCallConvention();

			if(args.length == arguments.length){
				// @todo@ variadic functions
				if(arguments == args){
					return funct;
				}else{
					closerLook ~= funct;
				}
			}else if(conv == CallConvention.C || conv == CallConvention.Pascal){
				if(externFunc){
					throw new ReflectionException("more than one extern(C)/extern(Pascal) function found");
				}else{
					externFunc = funct;
				}
			}else if(conv == CallConvention.Windows){
				throw new ReflectionException("@todo@ overloading extern(Windows) not yet supported: " ~ name);
			}
		}

		if(candidates.length == 0){
			throw new ReflectionException("no function with matching names found: " ~ name);
		}

		if(closerLook.length == 0){
			if(externFunc){
				return externFunc;
			}else{
				throw new ReflectionException("no matching overload found for " ~ name);
			}
		}

		throw new IllegalReflectionException("@todo@ implicit overloads aren't yet implemented: " ~ name);
	}

	private static void procWrite(void* pos, void[] data){
		version(Posix){
			void* addr = pos;
			size_t page = getpagesize();
			addr -= (cast(size_t)addr) % page;
	
			if(0 != mprotect(addr, page, PROT_READ | PROT_WRITE | PROT_EXEC)){
				int i = getErrno();
				static if(is(typeof(Formatter))){
					string msg = Formatter("failed to write redirection {0} {1}", i, strerror(i));
				}else{
					string msg = format("failed to write redirection %s %s", i, strerror(i));
				}
				throw new SymbolException(msg);
			}
			memmove(pos, data.ptr, data.length);
			mprotect(pos, page, PROT_READ | PROT_EXEC);
		}else version(MSWindows){
			size_t written = 0;
			SetLastError(0);
			if(!WriteProcessMemory(GetCurrentProcess(), pos,
				data.ptr, data.length, &written) || written != data.length)
			{	
				static if(is(typeof(Formatter))){
					string msg = Formatter("failed to write redirection: {0}", GetLastError()); 
				}else{
					string msg = format("failed to write redirection: %s", GetLastError()); 
				}
				throw new SymbolException(msg);
			}
		}else{
			static assert(0);
		}
	}

	unittest{
		int a = 0xDEDE_EDED;
		int b = 0x1234_5678;
		void[] data = (&b)[0 .. 1];
		procWrite(&a, data);
		assert(0x1234_5678 == a);
		assert(0x1234_5678 == b);
	}

	/**
	 * _Redirect all function calls for function from _to function to.
	 *
	 * Throws: IllegalReflectionException
	 * See_Also: cn.kuehne.flectioned.Function.restoreRedirect
	 * Returns: recovery information for Function.restoreRedirect
	 *
	 * Bugs: Doesn't preserve the exact protection attributes on Linux systems.
	 */
	static ubyte[] redirect(char[] from, char[] to){
		return redirect(symbols[from].address, symbols[to].address);
	}

	/// ditto
	static ubyte[] redirect(void* from, void* to)
	out(result){
		assert(result.length > 0);
	}body{
		// sanity checks
		if(((from <= to) && (to <= from+5))
			|| ((to <= from) && (from <= to+5)))
		{
			throw new IllegalReflectionException("illegal source-destination combination");
		}

		// compute ASM
		ubyte[6] cmd;
		cmd[0] = 0xE9; // jmp
		cmd[5] = 0xC3; // retn

		size_t new_dest = cast(size_t) to;
		new_dest = new_dest - (cast(size_t)from + 5);
		int offset = cast(int)cast(ptrdiff_t)new_dest;

		cmd[1 .. 1 + offset.sizeof] = (cast(ubyte*)&offset)[0 .. offset.sizeof];

		// save original
		ubyte[] original = (cast(ubyte*)from)[0 .. cmd.length].dup;

		// write asm
		procWrite(from, cmd);

		return original;
	}

	///
	static void restoreRedirection(void* addr, void[] data){
		procWrite(addr, data);
	}
	alias restoreRedirection restoreRedirect;
	
	unittest{
		// the code generated by the functions below has to be at least 6 bytes
		static int foo(int x){
			int i = 0;
			while(x > 0){
				i += x;
				x--;
			}
			return i;
		}

		static int bar(int x){
			int i = 1;
			while(x > 0){
				i *= x;
				x--;
			}
			return i;
		}

		assert(foo(4) == 10);
		assert(bar(4) == 24);

		ubyte[] backup = redirect(&foo, &bar);
		
		assert(foo(4) == 24);
		assert(bar(4) == 24);

		restoreRedirection(&foo, backup);
		
		assert(foo(4) == 10);
		assert(bar(4) == 24);
	}
}

/* **************************************************************************
 * nothing to see below
 * **************************************************************************/

static if(4 == size_t.sizeof){
	private const char[] ZX_C = "%.8X";
}else static if(8 == size_t.sizeof){
	private const char[] ZX_C = "%.16X";
}else{
	static assert(0);
}

static if(inTango){
	static if(4 == size_t.sizeof){
		private const char[] ZX = ":X8";
	}else static if(8 == size_t.sizeof){
		private const char[] ZX = ":X16";
	}else{
		static assert(0);
	}
}else static if(inPhobos){
	static if(4 == size_t.sizeof){
		private const char[] ZX = "%.8X";
	}else static if(8 == size_t.sizeof){
		private const char[] ZX = "%.16X";
	}else{
		static assert(0);
	}
}else{
	static assert(0);
}


private char[] readQualifiedName(inout char[] raw){
	char[] result;

	size_t start = 0;
	while(start < raw.length && isdigit(raw[start])){
		size_t end = start + 1;
		while(end < raw.length && isdigit(raw[end])){
			end++;
		}

		int len = toInt(raw[start .. end]);
		auto element = raw[end .. end + len];

		static if(is(typeof(demangle))){
			//  demangle templates
			if((3 < element.length) && ("__T" == element[0 .. 3])){
				static if(is(typeof(Formatter))){
					auto source = Formatter("_D1a{0}{1}", element.length, element);
				}else{
					auto source = format("_D1a%s%s", element.length, element);
				}
				source = demangle(source);
				if(source.length > 6){
					element = source[6 .. $].dup;
				}
			}
		}

		if(result.length < 1){
			result = element;
		}else{	
			result ~= "." ~ element;
		}
		start = end + len;
	}

	raw = raw[start .. $];

	return result;
}

/**
 * find all known symbols of the running process
 */
version(BIN_ELF){
	private extern(C){
		alias uint16_t Elf32_Half;
		alias uint16_t Elf64_Half;
		alias uint32_t Elf32_Word;
		alias  int32_t Elf32_Sword;
		alias uint32_t Elf64_Word;
		alias  int32_t Elf64_Sword;
		alias uint64_t Elf32_Xword;
		alias  int64_t Elf32_Sxword;
		alias uint64_t Elf64_Xword;
		alias  int64_t Elf64_Sxword;
		alias uint32_t Elf32_Addr;
		alias uint64_t Elf64_Addr;
		alias uint32_t Elf32_Off;
		alias uint64_t Elf64_Off;
		alias uint16_t Elf32_Section;
		alias uint16_t Elf64_Section;
		alias Elf32_Half Elf32_Versym;
		alias Elf64_Half Elf64_Versym;
		
		struct Elf32_Sym{
			Elf32_Word	st_name;
			Elf32_Addr	st_value;
			Elf32_Word	st_size;
			uint8_t	st_info;
			uint8_t	st_other;
			Elf32_Section	st_shndx;
		}
		
		struct Elf64_Sym{
			Elf64_Word	st_name;
			ubyte		st_info;
			ubyte		st_other;
			Elf64_Section	st_shndx;
			Elf64_Addr	st_value;
			Elf64_Xword	st_size;
		}
		
		struct Elf32_Phdr{
			Elf32_Word	p_type;
			Elf32_Off	p_offset;
			Elf32_Addr	p_vaddr;
			Elf32_Addr	p_paddr;
			Elf32_Word	p_filesz;
			Elf32_Word	p_memsz;
			Elf32_Word	p_flags;
			Elf32_Word	p_align;
		}
		
		struct Elf64_Phdr{
			Elf64_Word	p_type;
			Elf64_Word	p_flags;
			Elf64_Off	p_offset;
			Elf64_Addr	p_vaddr;
			Elf64_Addr	p_paddr;
			Elf64_Xword	p_filesz;
			Elf64_Xword	p_memsz;
			Elf64_Xword	p_align;
		}
		
		struct Elf32_Dyn{
			Elf32_Sword	d_tag;
			union{
				Elf32_Word d_val;
				Elf32_Addr d_ptr;
			}
		}
		
		struct Elf64_Dyn{
			Elf64_Sxword	d_tag;
			union{
				Elf64_Xword d_val;
				Elf64_Addr d_ptr;
			}
		}
		const EI_NIDENT = 16;

		struct Elf32_Ehdr{
			char 		e_ident[EI_NIDENT];	/* Magic number and other info */
			Elf32_Half	e_type;			/* Object file type */
			Elf32_Half	e_machine;		/* Architecture */
			Elf32_Word	e_version;		/* Object file version */
			Elf32_Addr	e_entry;		/* Entry point virtual address */
			Elf32_Off	e_phoff;		/* Program header table file offset */
			Elf32_Off	e_shoff;		/* Section header table file offset */
			Elf32_Word	e_flags;		/* Processor-specific flags */
			Elf32_Half	e_ehsize;		/* ELF header size in bytes */
			Elf32_Half	e_phentsize;		/* Program header table entry size */
			Elf32_Half	e_phnum;		/* Program header table entry count */
			Elf32_Half	e_shentsize;		/* Section header table entry size */
			Elf32_Half	e_shnum;		/* Section header table entry count */
			Elf32_Half	e_shstrndx;		/* Section header string table index */
		}

		struct Elf64_Ehdr{
			char		e_ident[EI_NIDENT];	/* Magic number and other info */
			Elf64_Half	e_type;			/* Object file type */
			Elf64_Half	e_machine;		/* Architecture */
			Elf64_Word	e_version;		/* Object file version */
			Elf64_Addr	e_entry;		/* Entry point virtual address */
			Elf64_Off	e_phoff;		/* Program header table file offset */
			Elf64_Off	e_shoff;		/* Section header table file offset */
			Elf64_Word	e_flags;		/* Processor-specific flags */
			Elf64_Half	e_ehsize;		/* ELF header size in bytes */
			Elf64_Half	e_phentsize;		/* Program header table entry size */
			Elf64_Half	e_phnum;		/* Program header table entry count */
			Elf64_Half	e_shentsize;		/* Section header table entry size */
			Elf64_Half	e_shnum;		/* Section header table entry count */
			Elf64_Half	e_shstrndx;		/* Section header string table index */
		}

		struct Elf32_Shdr{
			Elf32_Word	sh_name;		/* Section name (string tbl index) */
			Elf32_Word	sh_type;		/* Section type */
			Elf32_Word	sh_flags;		/* Section flags */
			Elf32_Addr	sh_addr;		/* Section virtual addr at execution */
			Elf32_Off	sh_offset;		/* Section file offset */
			Elf32_Word	sh_size;		/* Section size in bytes */
			Elf32_Word	sh_link;		/* Link to another section */
			Elf32_Word	sh_info;		/* Additional section information */
			Elf32_Word	sh_addralign;		/* Section alignment */
			Elf32_Word	sh_entsize;		/* Entry size if section holds table */
		}

		struct Elf64_Shdr{
			Elf64_Word	sh_name;		/* Section name (string tbl index) */
			Elf64_Word	sh_type;		/* Section type */
			Elf64_Xword	sh_flags;		/* Section flags */
			Elf64_Addr	sh_addr;		/* Section virtual addr at execution */
			Elf64_Off	sh_offset;		/* Section file offset */
			Elf64_Xword	sh_size;		/* Section size in bytes */
			Elf64_Word	sh_link;		/* Link to another section */
			Elf64_Word	sh_info;		/* Additional section information */
			Elf64_Xword	sh_addralign;		/* Section alignment */
			Elf64_Xword	sh_entsize;		/* Entry size if section holds table */
		}
		
		enum{
			PT_DYNAMIC	= 2,
			DT_STRTAB	= 5,
			DT_SYMTAB	= 6,
			DT_STRSZ	= 10,
			DT_DEBUG	= 21,
			SHT_SYMTAB	= 2,
			SHT_STRTAB	= 3,
			STB_LOCAL	= 0,
		}

		ubyte ELF32_ST_BIND(ulong info){
			return 	cast(ubyte)((info & 0xF0) >> 4);
		}

		static if(4 == (void*).sizeof){
			alias Elf32_Sym Elf_Sym;
			alias Elf32_Dyn Elf_Dyn;
			alias Elf32_Addr Elf_Addr;
			alias Elf32_Phdr Elf_Phdr;
			alias Elf32_Half Elf_Half;
			alias Elf32_Ehdr Elf_Ehdr;
			alias Elf32_Shdr Elf_Shdr;
		}else static if(8 == (void*).sizeof){
			alias Elf64_Sym Elf_Sym;
			alias Elf64_Dyn Elf_Dyn;
			alias Elf64_Addr Elf_Addr;
			alias Elf64_Phdr Elf_Phdr;
			alias Elf64_Half Elf_Half;
			alias Elf64_Ehdr Elf_Ehdr;
			alias Elf64_Shdr Elf_Shdr;
		}else{
			static assert(0);
		}
	
		struct dl_phdr_info {
			Elf_Addr	dlpi_addr;
			char* 		dlpi_name;
			Elf_Phdr*	dlpi_phdr;
			Elf_Half	dlpi_phnum;
		}
	
		alias int function(dl_phdr_info *info, size_t size, void *data) dl_iterate_phdr_callback;
		int dl_iterate_phdr(dl_iterate_phdr_callback, void *);
	}
	
	private void search_symtab(Elf_Sym* sym, char * str, size_t str_len, Elf_Addr base){
		for(sym++; sym.st_shndx; sym++)
		{
			if(sym.st_name && sym.st_name < str_len && sym.st_value)
			{
				Symbol.insertRawSymbol(sym.st_name + str, cast(void *)(sym.st_value + base), sym.st_size, true);
			}
		}
	}

	private void search_dynamic(Elf_Phdr * phdr, Elf_Addr base){
		char * string_table = null;
		size_t string_table_length = 0;
		Elf_Dyn* dyn = null;
		Elf_Sym* sym = null;
	
		for(dyn = cast(Elf_Dyn*)cast(void *)(phdr.p_vaddr + base); dyn.d_tag; dyn++){
			debug(elf) printf("\t\tDyn (d_tag:%i)\n", dyn.d_tag);

			if(dyn.d_tag == DT_STRTAB){
				if(dyn.d_val < base){
					string_table = cast(char *) (base + dyn.d_ptr);
				}else{
					string_table = cast(char *) dyn.d_ptr;
				}
			}else if(dyn.d_tag == DT_SYMTAB){
				if(dyn.d_val < base){
					sym = cast(Elf_Sym*)cast(void *) (base + dyn.d_ptr);
				}else{
					sym = cast(Elf_Sym*)cast(void *) dyn.d_ptr;
				}
			}else if(dyn.d_tag == DT_STRSZ){
				string_table_length = dyn.d_val;
			}
	
			if(sym && string_table && string_table_length){
				search_symtab(sym, string_table, string_table_length, base);
				sym = null;
			}
		}
	}
	
	private extern(C) int search_phdr_info(dl_phdr_info * info, size_t size, void * dummy){
		debug(elf) printf("dl_phdr_info (name:%s)\n", info.dlpi_name);
	
		for(size_t i = 0; i < info.dlpi_phnum; i++){
			Elf_Phdr* phdr = info.dlpi_phdr + i;
			debug(elf) printf("\tPhdr (p_type:%i)\n", phdr.p_type);
			if(phdr.p_type == PT_DYNAMIC){
				search_dynamic(phdr, info.dlpi_addr);
			}
		}
	
		return 0;
	}

	private void scan_static(FILE * fd){
		bool first_symbol = true;
		Elf_Ehdr header;
		Elf_Shdr section;
		Elf_Sym sym;
		char[] string_table;

		void read(void* ptr, size_t size){
			if(fread(ptr, 1, size, fd) != size){
				throw new SymbolException("read failure");
			}
		}

		void seek(ptrdiff_t offset){
			if(fseek(fd, offset, SEEK_SET) == -1){
				throw new SymbolException("seek failure");
			}
		}

		/* read elf header */
		read(&header, header.sizeof);
		if(header.e_shoff == 0){
			return;
		}

		/* find sections */
		for(ptrdiff_t i = header.e_shnum - 1; i > -1; i--){
			seek(header.e_shoff + i * header.e_shentsize);
			read(&section, section.sizeof);
			debug(none) printf("[%i] %i\n", i, section.sh_type);
			
			if(section.sh_type == SHT_STRTAB){
				/* read string table */
				debug(elf) printf("[%i] is STRING (size:%i)\n", i, section.sh_size);
				seek(section.sh_offset);
				string_table.length = section.sh_size;
				read(string_table.ptr, string_table.length);
			}else if(section.sh_type == SHT_SYMTAB){
				/* read symtab */
				debug(elf) printf("[%i] is SYMTAB (size:%i)\n", i, section.sh_size);
				if(section.sh_offset == 0){
					continue;
				}
				for(size_t j = 0; j < section.sh_size; j += Elf_Sym.sizeof){
					seek(section.sh_offset + j);
					read(&sym, sym.sizeof);

					if(!sym.st_name || !sym.st_value){
						// anonymous || undefined
						continue;
					}
					
					bool isPublic = true;
					if(STB_LOCAL == ELF32_ST_BIND(sym.st_info)){
						isPublic = false;
					}
					
					Symbol.insertRawSymbol(string_table.ptr + sym.st_name, cast(void*)sym.st_value, sym.st_size, isPublic);
				}
			}
		}
	}
	
	private void find_symbols(){
		// dynamic symbols
		dl_iterate_phdr(&search_phdr_info, null);
		
		// static symbols
		find_static();
	}

	private void find_static(){
		FILE* maps;
		char[4096] buffer;

		maps = fopen("/proc/self/maps", "r");
		if(maps is null){
			debug{
				throw new SymbolException("couldn't read '/proc/self/maps'");
			}else{
				return;
			}
		}
		scope(exit) fclose(maps);

		buffer[] = 0;
		while(fgets(buffer.ptr, buffer.length - 1, maps)){
			scope(exit){
				buffer[] = 0;
			}
			char[] tmp;
			cleanEnd: for(size_t i = buffer.length - 1; i >= 0; i--){
				switch(buffer[i]){
					case 0, '\r', '\n':
						buffer[i] = 0;
						break;
					default:
						tmp = buffer[0 .. i+1];
						break cleanEnd;
				}
			}
			
Lsplit:
			static if(is(typeof(split(""c)) == string[])){
				string[] tok = split(tmp);
				if(tok.length != 6){
					// no source file
					continue;
				}
			}else{
				char[][] tok = delimit(tmp, " \t");
				if(tok.length < 6){
					// no source file
					continue;
				}
				const tok_len = 33;
			}
			if(find(tok[$-1], "[") == 0){
				// pseudo source
				continue;
			}
			if(rfind(tok[$-1], ".so") == tok[$-1].length - 3){
				// dynamic lib
				continue;
			}
			if(find(tok[1], "r") == -1){
				// no read
				continue;
			}
			if(find(tok[1], "x") == -1){
				// no execute
				continue;
			}
			char[] addr = tok[0] ~ "\u0000";
			char[] source = tok[$-1] ~ "\u0000";
			const char[] marker = "\x7FELF"c;

			void* start, end;
			if(2 != sscanf(addr.ptr, "%zX-%zX", &start, &end)){
				continue;
			}
			if(cast(size_t)end - cast(size_t)start < 4){
				continue;
			}
			if(memcmp(start, marker.ptr, marker.length) != 0){
				// not an ELF file
				continue;
			}
			scan_static(fopen(source.ptr, "r"));
		}
	}
}else version(BIN_PE){

	private extern(Windows){
		enum{
			MAX_MODULE_NAME32 = 255,
			TH32CS_SNAPMODULE = 0x00000008,
		}

		static if(!is(typeof(MODULEENTRY32)))
			struct MODULEENTRY32 {
				DWORD  dwSize;
				DWORD  th32ModuleID;
				DWORD  th32ProcessID;
				DWORD  GlblcntUsage;
				DWORD  ProccntUsage;
				BYTE  *modBaseAddr;
				DWORD  modBaseSize;
				HMODULE hModule;
				char   szModule[MAX_MODULE_NAME32 + 1];
				char   szExePath[MAX_PATH];
			}
		
		static if(!is(typeof(Module32First)))
			BOOL Module32First(HANDLE, MODULEENTRY32*);

		static if(!is(typeof(Module32Next)))
			BOOL Module32Next(HANDLE, MODULEENTRY32*);
		
		static if(!is(typeof(CreateToolhelp32Snapshot)))
			HANDLE CreateToolhelp32Snapshot(DWORD,DWORD);

		private{
			// defining them at function level causes the wrong CallConvention
			extern(Windows) BOOL function(HANDLE, PCSTR, BOOL) sym_initialize;
			extern(Windows) DWORD function(HANDLE, HANDLE, PCSTR, PCSTR, DWORD, DWORD) sym_load_module;
			extern(Windows) BOOL function(HANDLE, DWORD, void*, void*) sym_enumerate_symbols;
		}

		int add_symbol(LPSTR name, ULONG addr, ULONG size, PVOID){
			Symbol.insertRawSymbol(name, cast(void*)addr, size, true);
			return true;
		}


		void find_symbols(){
			HANDLE proc;
			HANDLE snapshot;
			DWORD base;
			MODULEENTRY32 module_entry;
			char buffer[4096];

			HMODULE imagehlp;

			// create snapshot	
			proc = GetCurrentProcess();

			snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, 0);
			if(!snapshot){
				throw new SymbolException("failed: CreateToolHelp32Snapshot");
			}
			
			// init debugger helpers _after_ creating the snapshot
			imagehlp = LoadLibraryA("imagehlp.dll");
			if(!imagehlp){
				throw new SymbolException("failed to load imagehlp.dll");
			}
			scope(exit){
				FreeLibrary(imagehlp);
				sym_initialize = null;
				sym_load_module = null;
				sym_enumerate_symbols = null;
			}

			// init imagehlp.dll helpers
			sym_initialize = cast(typeof(sym_initialize)) GetProcAddress(imagehlp, "SymInitialize");
			if(!sym_initialize){
				throw new SymbolException("failed to get SymInitialize");
			}

			sym_load_module = cast(typeof(sym_load_module)) GetProcAddress(imagehlp, "SymLoadModule");
			if(!sym_load_module){
				throw new SymbolException("failed to get SymLoadModule");
			}
			sym_enumerate_symbols = cast(typeof(sym_enumerate_symbols)) GetProcAddress(imagehlp, "SymEnumerateSymbols");
			if(!sym_enumerate_symbols){
				throw new SymbolException("failed to get SymEnumerateSymbols");
			}

			if(!sym_initialize(proc, null, false)){
				throw new SymbolException("failed: SymInitialize");
			}

			// try to get the symbols of all MODULEs
			module_entry.dwSize = module_entry.sizeof;
			if(!Module32First(snapshot, &module_entry)){
				throw new SymbolException("failed: Module32First");
			}

			do{
				if(GetModuleFileNameA(module_entry.hModule, buffer.ptr, buffer.length)){
					base = sym_load_module(proc, HANDLE.init, buffer.ptr, null, 0, 0);
					if(base){
						sym_enumerate_symbols(proc, base, &add_symbol, null);
					}
				}
			}while(Module32Next(snapshot, &module_entry));
		}
	}
}else{
	static assert(0, "unsupported binary format");
}

private class PrimitiveTypeSymbol(T) : TypeSymbol{
	void[] initial;

	this(){
		TypeInfo ti = typeid(T);
		super(null, T.sizeof, getString(ti), ti);
		static if(is(T == void)){
			initial = new ubyte[0];
		}else{
			T t;
			initial = (cast(void*)&t)[0 .. T.sizeof].dup;
		}
	}

	override void[] newInstanceV(TypeInfo[] arguments, va_list){
		if(arguments.length != 0){
			throw new IllegalReflectionException("primitive types don't support constructors");
		}else{
			return initial.dup;
		}
	}
}

static this(){
	static if(inTango){
		Formatter = new tango.text.convert.Layout.Layout!(char)();
	}
	// insert fake Symbols for all primitve types
	new PrimitiveTypeSymbol!(void)();
	new PrimitiveTypeSymbol!(bool)();
	new PrimitiveTypeSymbol!(byte)();
	new PrimitiveTypeSymbol!(ubyte)();
	new PrimitiveTypeSymbol!(short)();
	new PrimitiveTypeSymbol!(ushort)();
	new PrimitiveTypeSymbol!(int)();
	new PrimitiveTypeSymbol!(uint)();
	new PrimitiveTypeSymbol!(long)();
	new PrimitiveTypeSymbol!(ulong)();
	/+ @BUG@ static if(is(cent)){
		new PrimitiveTypeSymbol!(cent)();
		new PrimitiveTypeSymbol!(ucent)();
	} +/
	new PrimitiveTypeSymbol!(float)();
	new PrimitiveTypeSymbol!(double)();
	new PrimitiveTypeSymbol!(real)();
	new PrimitiveTypeSymbol!(ifloat)();
	new PrimitiveTypeSymbol!(idouble)();
	new PrimitiveTypeSymbol!(ireal)();
	new PrimitiveTypeSymbol!(cfloat)();
	new PrimitiveTypeSymbol!(cdouble)();
	new PrimitiveTypeSymbol!(creal)();
	new PrimitiveTypeSymbol!(char)();
	new PrimitiveTypeSymbol!(dchar)();
	new PrimitiveTypeSymbol!(wchar)();

	// interpret all known symbol
	find_symbols();
	foreach(symbol; symbols){
		symbol.cleanup();
	}

	// trace all Exceptions
	static if(inTango){
		setTraceHandler(&TracedException.tangoTraceHandler);
	}else{
		version(TraceAllExceptions){
			TracedException.traceAllExceptions(true);
		}
	}

	// trace SEGFAULTs
	version(haveSegfaultTrace){
		setupSegfaultTracer();
	}
}

/**
 * fake TypeInfo that stores dot-delimited type names so that they can be
 * later replaced with the actual TypeInfos (->Symbol.cleanup())
 */ 
private class LazyTypeInfo : TypeInfo{
	char[] name;

	private this(char[] name){
		this.name = name.dup;
	}

	private static template fixBase(T){
		private static TypeInfo fixBase(TypeInfo ti){
			T t = cast(T) ti;
			if(t){
				t.base = resolve(t.base);
				return t;
			}else{
				return ti;
			}
		}
	}

	private static template fixTI(T){
		private static TypeInfo fixTI(TypeInfo ti){
			T t = cast(T) ti;
			if(!t){
				return ti;
			}
			static if(is(typeof(t.next) : TypeInfo)){
				t.next = resolve(t.next);
			}
			static if(is(typeof(t.m_next) : TypeInfo)){
				t.m_next = resolve(t.m_next);
			}
			static if(is(typeof(t.value) : TypeInfo)){
				t.value = resolve(t.value);
			}
			return t;
		}
	}

	private static TypeInfo resolve(TypeInfo ti){
		LazyTypeInfo lazyTi = cast(LazyTypeInfo) ti;
		if(lazyTi){
			TypeSymbol* ts = lazyTi.name in types;
			if(ts){
				// should catch all non-basic types
				ti = ts.type;
			}
		}

		ti = fixTI!(TypeInfo_Typedef)(ti);
		ti = fixTI!(TypeInfo_Pointer)(ti);
		ti = fixTI!(TypeInfo_Array)(ti);
		ti = fixTI!(TypeInfo_StaticArray)(ti);
		ti = fixTI!(TypeInfo_AssociativeArray)(ti);
		ti = fixTI!(TypeInfo_Function)(ti);
		ti = fixTI!(TypeInfo_Delegate)(ti);
		return ti;
	}

	char[] toString(){
		return "LazyTypeInfo(" ~ name ~ ")";
	}
}


private bool contains(string source, string pattern){
	if(0 == pattern.length){
		return true;
	}else{
		ptrdiff_t end = source.length - pattern.length;
		for(ptrdiff_t i = 0; 0 <= end - i; i++){
			if(source[i] == pattern[0]){
				if(source[i .. i+pattern.length] == pattern){
					return true;
				}
			}
		}
	}
	return false;
}

unittest{
	assert(contains("abcd", "a"));
	assert(contains("abcd", "b"));
	assert(contains("abcd", "c"));
	assert(contains("abcd", "d"));
	assert(contains("abcd", "ab"));
	assert(contains("abcd", "bc"));
	assert(contains("abcd", "cd"));
	assert(contains("abcd", "abc"));
	assert(contains("abcd", "bcd"));
	assert(!contains("abcd", "e"));
	assert(contains("e", "e"));
	assert(!contains("e", "f"));
	assert(!contains("e", "ef"));
	assert(!contains("ef", "efg"));
	assert(!contains("", "efg"));
	assert(contains("efg", ""));
}

private bool endsWith(string source, string pattern){
	return (source.length >= pattern.length) && (source[$-pattern.length .. $] == pattern);
}

unittest{
	assert(endsWith("abc", "c"));
	assert(endsWith("abc", "bc"));
	assert(endsWith("abc", "abc"));
	assert(endsWith("abc", ""));
	assert(endsWith("", ""));
	assert(!endsWith("abc", "C"));
	assert(!endsWith("", "c"));
}

private bool startsWith(string source, string pattern){
	return (source.length >= pattern.length) && (source[0 .. pattern.length] == pattern);
}

unittest{
	assert(startsWith("abc", "a"));
	assert(startsWith("abc", "ab"));
	assert(startsWith("abc", "abc"));
	assert(startsWith("abc", ""));
	assert(startsWith("", ""));
	assert(!startsWith("abc", "A"));
	assert(!startsWith("abc", "b"));
	assert(!startsWith("abc", "c"));
	assert(!startsWith("", "abc"));
}

private Symbol handleRawSymbol(string name_, void* value, size_t size, bool isPublic){
	debug(parser) writefln("handeRawSymbol %s %X %s %s", name_, value, size, isPublic);

	Symbol s = null;
	char[] name = name_.dup;
	char[] org =  name.dup;

	if(cast(size_t)find(org, "__foreachbody") < org.length){
		// ignore DMD's foreach bodies
		isPublic = false;
	}

	if(isPublic && (3 < name.length) && ('D' == name[0]) && isdigit(name[1])){
		// #637: internal symbols are missing the leading underscore
		// http://d.puremagic.com/issues/show_bug.cgi?id=637
		name = "_" ~ name;	
	}
	
	if(isPublic && (3 < name.length) && ("_D" == name[0 .. 2]) && isdigit(name[2])){
		name = name[2 .. $];
		char[] nice_name = readQualifiedName(name);

		switch(name[0]){
			// some kind of function
			case 'M', 'F', 'U', 'W', 'V', 'R':
				s = handleRawFunction(nice_name, name, value, size);
				break;
			default:
				const char[] markC = ".__Class";
				const char[] markI = ".__Interface";
				const char[] mark = "TypeInfo_";
				const char[] markInit = ".__init";
				if(endsWith(nice_name, markC) && name == "Z"){
					// a class
					s = new Class(value, size, nice_name[0 .. $ - markC.length]);
				}else if(endsWith(nice_name, markI) && name == "Z"){
					// an interface
					s = new Interface(value, size, nice_name[0 .. $ - markI.length]);
				}else if(name == "Z" && startsWith(nice_name, mark)
					&& isdigit(nice_name[mark.length + 1])
					&& endsWith(nice_name, ".__init")
					)
				{
					char[] real_name = nice_name[mark.length + 1 .. $ - markInit.length];

					switch(nice_name[mark.length]){
						case 'S': // a struct
							real_name = readQualifiedName(real_name);
							return new Struct(value, size, real_name);
						case 'E': // an enum
							real_name = readQualifiedName(real_name);
							return new Enum(value, size, real_name);
						case 'T': // a typedef
							real_name = readQualifiedName(real_name);
							return new Typedef(value, size, real_name);
						case 'B': // tuple ?
						case 'C': // class ?
						default:
							debug(internal) writefln("unhandled internal: %s", nice_name);
							break;
					}
				}else{
					s = handleRawVariable(nice_name, name, value, size);
				}
		}
	}

	if(!s){
		version(intrinsics){
			if(isPublic){
				string mangled;
				foreach(intrinsic; intrinsics){
					if(intrinsic[0] == org){
						mangled = intrinsic[1];
						break;
					}
				}
				if(mangled){
					// a known 'fake' mangling is present
					s = handleRawSymbol(mangled, value, size, isPublic);
				}
			}
		}

		if(!s){
			// just store the plain/mangled symbol
			s = new Symbol(value, size, org, null);
		}
	}

	return s;
}

private TypeInfo readNextTypeInfo(inout char[] raw){
	if(raw.length > 0){
		switch(raw[0]){
			case 'J': // out
			case 'K': // inout
			case 'P': // pointer
			{
				TypeInfo_Pointer ti = new TypeInfo_Pointer();
				raw = raw[1 .. $];
				static if(is(typeof((new TypeInfo_Pointer()).m_next))){
					ti.m_next = readNextTypeInfo(raw);
				}else{
					ti.next = readNextTypeInfo(raw);
				}
				if(ti.next is null){
					ti = null;
				}
				return ti;
			}
			case 'v':
			case 'Z': // DMD-0.176 internal
				raw = raw[1 .. $];
				return typeid(void);
			case 'x':
				raw = raw[1 .. $];
				return typeid(bool);
			case 'b':
				raw = raw[1 .. $];
				static if(is(bit)){
					return typeid(bit);
				}else{
					return typeid(bool);
				}
			case 'g':
				raw = raw[1 .. $];
				return typeid(byte);
			case 'h':
				raw = raw[1 .. $];
				return typeid(ubyte);
			case 's':
				raw = raw[1 .. $];
				return typeid(short);
			case 't':
				raw = raw[1 .. $];
				return typeid(ushort);
			case 'i':
				raw = raw[1 .. $];
				return typeid(int);
			case 'k':
				raw = raw[1 .. $];
				return typeid(uint);
			case 'l':
				raw = raw[1 .. $];
				return typeid(long);
			case 'm':
				raw = raw[1 .. $];
				return typeid(ulong);
			case 'f':
				raw = raw[1 .. $];
				return typeid(float);
			case 'd':
				raw = raw[1 .. $];
				return typeid(double);
			case 'e':
				raw = raw[1 .. $];
				return typeid(real);
			case 'o':
				raw = raw[1 .. $];
				return typeid(ifloat);
			case 'p':
				raw = raw[1 .. $];
				return typeid(idouble);
			case 'j':
				raw = raw[1 .. $];
				return typeid(ireal);
			case 'q':
				raw = raw[1 .. $];
				return typeid(cfloat);
			case 'r':
				raw = raw[1 .. $];
				return typeid(cdouble);
			case 'c':
				raw = raw[1 .. $];
				return typeid(creal);
			case 'a':
				raw = raw[1 .. $];
				return typeid(char);
			case 'u':
				raw = raw[1 .. $];
				return typeid(wchar);
			case 'w':
				raw = raw[1 .. $];
				return typeid(dchar);
			case 'A': // dynamic array
			{
				raw = raw[1 .. $];
				TypeInfo_Array ti = new TypeInfo_Array();
				TypeInfo next_ti = readNextTypeInfo(raw);
				if(next_ti is null){
					ti = null;
				}else{
					static if(is(typeof((new typeof(ti)()).value))){
						ti.value = next_ti;
					}else{
						ti.next = next_ti;
					}
				}
				return ti;
			}
			case 'G': // static array
			{
				TypeInfo_StaticArray ti = new TypeInfo_StaticArray();
				raw = raw[1 .. $];
				int i = 0;
				while(isdigit(raw[i])){
					i++;
				}
				ti.len = toUint(raw[0 .. i]);
				raw = raw[i .. $];
				TypeInfo next_ti = readNextTypeInfo(raw);
				if(next_ti is null){
					ti = null;
				}else{
					static if(is(typeof((new typeof(ti)).value))){
						ti.value = next_ti;
					}else{
						ti.next = next_ti;
					}
				}
				return ti;
			}
			case 'H': // associative array
			{
				raw = raw[1 .. $];
				TypeInfo_AssociativeArray ti = new TypeInfo_AssociativeArray();
				ti.key = readNextTypeInfo(raw);
				if(ti.key is null){
					ti = null;
				}else{
					TypeInfo next_ti = readNextTypeInfo(raw);
					if(next_ti is null){
						ti = null;
					}else{
						static if(is(typeof((new typeof(ti)).value))){
							ti.value = next_ti;
						}else{
							ti.next = next_ti;
						}
					}
				}
				return ti;
			}
			case 'C': /* class */
			case 'E': /* enum */
			case 'S': /* struct */
			case 'T': /* typedf */
				raw = raw[1 .. $];
				// fall through
			case '1': /* qualified name */
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				return new LazyTypeInfo(readQualifiedName(raw));	

			case 'D': // delegate
			case 'L': // lazy
			case 'F': // D
			case 'U': // C
			case 'W': // Windows
			case 'V': // Pascal
				// @todo@
				return null;

			case 'M': // this pointer
				// @todo@
				return null;

			default:
				throw new SymbolException("unhandled typeinfo " ~ raw);
		}
	}
	return null;
}

/// handle symbols that might describe a module level instance
private ValueSymbol handleRawVariable(char[] nice_name, char[] raw_rest, void* value, size_t size){
	debug(parser) writefln("handeRawVariable %s %s", nice_name, raw_rest);

	TypeInfo ti = readNextTypeInfo(raw_rest);
	if(!ti || raw_rest.length){
		// weired / nested
		return null;
	}else{
		return new ValueSymbol(value, size, nice_name, ti);
	}
}

/// handle symbols that might describe a function
private Function handleRawFunction(char[] nice_name, char[] raw_rest, void* value, size_t size){
	debug(parser) writefln("handeRawFunction %s %s", nice_name, raw_rest);
	TypeInfo[] arg;
	TypeInfo ret;
	bool need_this;
	CallConvention conv;

	// calling convention
LcallingConvention:
	switch(raw_rest[0]){
		case 'M':
			need_this = true;
			raw_rest = raw_rest[1 .. $];
			goto LcallingConvention;
		case 'F':
			conv = CallConvention.D;
			break;
		case 'U':
			conv = CallConvention.C;
			break;
		case 'W':
			conv = CallConvention.Windows;
			break;
		case 'V':
			conv = CallConvention.Pascal;
			break;
		default:
			return null;
	}
	raw_rest = raw_rest[1 .. $];

	// parameter
	while('Z' != raw_rest[0]){
		if('X' == raw_rest[0]){
			// (type ...)
			TypeInfo_Array ta = new TypeInfo_Array();
			static if(is(typeof((new typeof(ta)()).value))){
				ta.value = arg[$-1];
			}else{
				ta.next = arg[$-1];
			}
			arg[$-1] = ta;
			break;
		}else if('Y' == raw_rest[0]){
			// (...)
			TypeInfo_Array ta = new TypeInfo_Array();
			static if(is(typeof((new typeof(ta)()).value))){
				ta.value = typeid(TypeInfo);
			}else{
				ta.next = typeid(TypeInfo);
			}
			arg ~= ta;

			TypeInfo_Pointer tp = new TypeInfo_Pointer();
			static if(is(typeof((new typeof(tp)()).m_next))){
				tp.m_next = typeid(void);
			}else{
				tp.next = typeid(void);
			}
			arg ~= tp;
			break;
		}else{
			TypeInfo t = readNextTypeInfo(raw_rest);
			if(t is null){
				return null;
			}
			arg ~= t;
		}
	}
	raw_rest = raw_rest[1 .. $];

	// return type
	ret = readNextTypeInfo(raw_rest);
	if((ret is null) || raw_rest.length){
		return null;
	}

	return new Function(value, size, nice_name, new TypeInfo_Function2(ret, arg, conv, need_this));
}

version(intrinsics){
	private const char[][][] intrinsics = [
		// special
		["_Dmain" , "_D4mainFAAaZi"],
		["main" , "_D4mainUiPPaZi"],
		["_d_toObject" , "_D11_d_toObjectUPvZC6Object"],
		["_d_interface_cast" , "_D17_d_interface_castUPvC9ClassInfoZC6Object"],
		["_d_isbaseof2" , "_D12_d_isbaseof2UC9ClassInfoC9ClassInfokZi"],
		["_d_isbaseof" , "_D11_d_isbaseofUC9ClassInfoC9ClassInfoZi"],
		["_d_interface_vtbl" , "_D17_d_interface_vtblUC9ClassInfoC6ObjectZPv"],
		["_d_invariant" , "_D12_d_invariantUC6ObjectZv"],
		["_d_switch_string" , "_D16_d_switch_stringUAAaAaZi"],
		["_d_switch_ustring" , "_D17_d_switch_ustringUAAuAuZi"],
		["_d_switch_dstring" , "_D17_d_switch_dstringUAAwAwZi"],

		// pre DMD-1.001
		["_adReverseBit" , "_D13_adReverseBitUAbZAb"],
		["_d_arrayappend" , "_D14_d_arrayappendUPS3std2gc5ArrayAgkZl"],
		["_d_arrayappendc" , "_D15_d_arrayappendcUAgkZAg"],
		["_d_arraycast_frombit" , "_D20_d_arraycast_frombitUkAvZAv"],
		["_d_arraycat" , "_D11_d_arraycatUAgAgkZAg"],
		["_d_arraycatb" , "_D12_d_arraycatbUAbAbZAb"],
		["_d_arraycatn" , "_D12_d_arraycatnUkkZAg"],
		["_d_arraycopybit" , "_D15_d_arraycopybitUAbAbZAb"],
		["_d_arrayliteral" , "_D15_d_arrayliteralUkkZPv"],
		["_d_arraysetbit" , "_D14_d_arraysetbitUAbkkbZAb"],
		["_d_arraysetbit2" , "_D15_d_arraysetbit2UAbbZAb"],
		["_d_arraysetlength" , "_D17_d_arraysetlengthUkkPS3std2gc5ArrayZAg"],
		["_d_arraysetlength2" , "_D18_d_arraysetlength2UkkPS3std2gc5ArrayZAg"],
		["_d_arraysetlength3" , "_D18_d_arraysetlength3UkkPS3std2gc5ArraykZAg"],
		["_d_new" , "_D6_d_newUkkZm"],
		["_d_newarrayi" , "_D12_d_newarrayiUkkZm"],
		["_d_newarrayii" , "_D13_d_newarrayiiUkkkZm"],
		["_d_newarraymi" , "_D13_d_newarraymiUkiZm"],
		["_d_newbitarray" , "_D14_d_newbitarrayUkbZm"],
		["_d_newm" , "_D7_d_newmUkiZm"],

		// GDC
		["_d_arrayappendcp" , "_D16_d_arrayappendcpUAgkPvZAg"],
		["_d_arraysetlength2p" , "_D19_d_arraysetlength2pUkkPS3std2gc5ArrayPvZAg"],
		["_d_arraysetlength3p" , "_D19_d_arraysetlength3pUkkPS3std2gc5ArraykPvZAg"],
		["_d_gcc_query_stack_origin" , "_D25_d_gcc_query_stack_originUZPv"],
		["_d_gnu_cbridge_tza" , "_D18_d_gnu_cbridge_tzaUZi"],
		["_d_gnu_fd_clr" , "_D13_d_gnu_fd_clrUiPvZv"],
		["_d_gnu_fd_clr" , "_D13_d_gnu_fd_clrUiPvZv"],
		["_d_gnu_fd_copy" , "_D14_d_gnu_fd_copyUPvPvZv"],
		["_d_gnu_fd_copy" , "_D14_d_gnu_fd_copyUPvPvZv"],
		["_d_gnu_fd_isset" , "_D15_d_gnu_fd_issetUiPvZi"],
		["_d_gnu_fd_isset" , "_D15_d_gnu_fd_issetUiPvZi"],
		["_d_gnu_fd_set" , "_D13_d_gnu_fd_setUiPvZv"],
		["_d_gnu_fd_zero" , "_D14_d_gnu_fd_zeroUPvZv"],
		["_d_newarraymip" , "_D14_d_newarraymipUkiPkkPvZAv"],
		["_d_newmp" , "_D8_d_newmpUkiPkZAv"],
		["_d_run_Dmain" , "_D12_d_run_DmainUiPPaZi"],
		["_d_run_main" , "_D11_d_run_mainUiPPaPvZi"],

		// current
		["_aaGet" , "_D6_aaGetUPS3aaA2AAC8TypeInfokZPv"],
		["_aApplycd1" , "_D10_aApplycd1UAaDFPvZiZi"],
		["_aApplycd2" , "_D10_aApplycd2UAaDFPvPvZiZi"],
		["_aApplycw1" , "_D10_aApplycw1UAaDFPvZiZi"],
		["_aApplycw2" , "_D10_aApplycw2UAaDFPvPvZiZi"],
		["_aApplydc1" , "_D10_aApplydc1UAwDFPvZiZi"],
		["_aApplydc2" , "_D10_aApplydc2UAwDFPvPvZiZi"],
		["_aApplydw1" , "_D10_aApplydw1UAwDFPvZiZi"],
		["_aApplydw2" , "_D10_aApplydw2UAwDFPvPvZiZi"],
		["_aApplyRcd1" , "_D11_aApplyRcd1UAaDFPvZiZi"],
		["_aApplyRcd2" , "_D11_aApplyRcd2UAaDFPvPvZiZi"],
		["_aApplyRcw1" , "_D11_aApplyRcw1UAaDFPvZiZi"],
		["_aApplyRcw2" , "_D11_aApplyRcw2UAaDFPvPvZiZi"],
		["_aApplyRdc1" , "_D11_aApplyRdc1UAwDFPvZiZi"],
		["_aApplyRdc2" , "_D11_aApplyRdc2UAwDFPvPvZiZi"],
		["_aApplyRdw1" , "_D11_aApplyRdw1UAwDFPvZiZi"],
		["_aApplyRdw2" , "_D11_aApplyRdw2UAwDFPvPvZiZi"],
		["_aApplyRwc1" , "_D11_aApplyRwc1UAuDFPvZiZi"],
		["_aApplyRwc2" , "_D11_aApplyRwc2UAuDFPvPvZiZi"],
		["_aApplyRwd1" , "_D11_aApplyRwd1UAuDFPvZiZi"],
		["_aApplyRwd2" , "_D11_aApplyRwd2UAuDFPvPvZiZi"],
		["_aApplywc1" , "_D10_aApplywc1UAuDFPvZiZi"],
		["_aApplywc2" , "_D10_aApplywc2UAuDFPvPvZiZi"],
		["_aApplywd1" , "_D10_aApplywd1UAuDFPvZiZi"],
		["_aApplywd2" , "_D10_aApplywd2UAuDFPvPvZiZi"],
		["_aaRehash" , "_D9_aaRehashUPS3aaA2AAC8TypeInfoZPv"],
		["abort" , "_D5abortUZv"],
		["accept" , "_D6acceptUiPvPiZi"],
		["access" , "_D6accessUPaiZi"],
		["acos" , "_D4acosUdZd"],
		["acosf" , "_D5acosfUfZf"],
		["acosh" , "_D5acoshUdZd"],
		["acoshf" , "_D6acoshfUfZf"],
		["acoshl" , "_D6acoshlUeZe"],
		["acosl" , "_D5acoslUeZe"],
		["adler32" , "_D7adler32UkAvZk"],
		["_adReverseChar" , "_D14_adReverseCharUAaZl"],
		["_adReverseWchar" , "_D15_adReverseWcharUAuZl"],
		["_adSortBit" , "_D10_adSortBitUAbZAb"],
		["_adSortChar" , "_D11_adSortCharUAaZl"],
		["_adSortWchar" , "_D12_adSortWcharUAuZl"],
		["alarm" , "_D5alarmUkZk"],
		["__alloca" , "_D8__allocaUiZPv"],
		["asctime_r" , "_D9asctime_rUPvPaZPa"],
		["asin" , "_D4asinUdZd"],
		["asinf" , "_D5asinfUfZf"],
		["asinh" , "_D5asinhUdZd"],
		["asinhf" , "_D6asinhfUfZf"],
		["asinhl" , "_D6asinhlUeZe"],
		["asinl" , "_D5asinlUeZe"],
		["atan" , "_D4atanUdZd"],
		["atan2" , "_D5atan2UddZd"],
		["atan2f" , "_D6atan2fUffZf"],
		["atan2l" , "_D6atan2lUeeZe"],
		["atanf" , "_D5atanfUfZf"],
		["atanh" , "_D5atanhUdZd"],
		["atanhf" , "_D6atanhfUfZf"],
		["atanhl" , "_D6atanhlUeZe"],
		["atanl" , "_D5atanlUeZe"],
		["atexit" , "_D6atexitUPUZvZi"],
		["atol" , "_D4atolUPaZi"],
		["atoll" , "_D5atollUPaZl"],
		["basename" , "_D8basenameUPaZPa"],
		["bind" , "_D4bindUiPviZi"],
		["bsearch" , "_D7bsearchUPvPvkkPUPvPvZiZPv"],
		["calloc" , "_D6callocUkkZPv"],
		["cbrt" , "_D4cbrtUdZd"],
		["cbrtf" , "_D5cbrtfUfZf"],
		["cbrtl" , "_D5cbrtlUeZe"],
		["_Ccmp" , "_D5_CcmpUZv"],
		["_Cdiv" , "_D5_CdivUZv"],
		["ceil" , "_D4ceilUdZd"],
		["ceilf" , "_D5ceilfUfZf"],
		["ceill" , "_D5ceillUeZe"],
		["chmod" , "_D5chmodUPakZi"],
		["chown" , "_D5chownUPakkZi"],
		["chroot" , "_D6chrootUPaZi"],
		["clearerr" , "_D8clearerrUPvZv"],
		["clock" , "_D5clockUZi"],
		["close" , "_D5closeUiZi"],
		["closedir" , "_D8closedirUPvZi"],
		["_Cmul" , "_D5_CmulUZv"],
		["compress" , "_D8compressUAviZAv"],
		["confstr" , "_D7confstrUiPakZk"],
		["connect" , "_D7connectUiPviZi"],
		["copysign" , "_D8copysignUddZd"],
		["copysignf" , "_D9copysignfUffZf"],
		["copysignl" , "_D9copysignlUeeZe"],
		["cos" , "_D3cosUdZd"],
		["cosf" , "_D4cosfUfZf"],
		["cosh" , "_D4coshUdZd"],
		["coshf" , "_D5coshfUfZf"],
		["coshl" , "_D5coshlUeZe"],
		["cosl" , "_D4coslUeZe"],
		["crc32" , "_D5crc32UkAvZk"],
		["creat" , "_D5creatUPakZi"],
		["ctermid" , "_D7ctermidUPaZPa"],
		["ctime_r" , "_D7ctime_rUPT3std1c5linux7pthread8__time_tPaZPa"],
		["_d_arrayappendcT" , "_D16_d_arrayappendcTUC8TypeInfoAgZAg"],
		["_d_arrayappendT" , "_D15_d_arrayappendTUC8TypeInfoPS3std2gc5ArrayAgZl"],
		["_d_array_bounds" , "_D15_d_array_boundsUAakZv"],
		["_d_arraycast" , "_D12_d_arraycastUkkAvZAv"],
		["_d_arraycatnT" , "_D13_d_arraycatnTUC8TypeInfokZAg"],
		["_d_arraycatT" , "_D12_d_arraycatTUC8TypeInfoAgAgZAg"],
		["_d_arraycopy" , "_D12_d_arraycopyUkAgAgZAg"],
		["_d_arrayliteralT" , "_D16_d_arrayliteralTUC8TypeInfokZPv"],
		["_d_arraysetlengthiT" , "_D19_d_arraysetlengthiTUC8TypeInfokPS3std2gc5ArrayZAg"],
		["_d_arraysetlengthT" , "_D18_d_arraysetlengthTUC8TypeInfokPS3std2gc5ArrayZAg"],
		["_d_assert" , "_D9_d_assertUAakZv"],
		["_d_assert_msg" , "_D13_d_assert_msgUAaAakZv"],
		["daylight" , "_D8daylighti"],
		["__DBLULLNG" , "_D10__DBLULLNGUZm"],
		["__DBLULNG" , "_D9__DBLULNGUZk"],
		["_d_callfinalizer" , "_D16_d_callfinalizerUPvZv"],
		["_d_delarray" , "_D11_d_delarrayUPS3std2gc5ArrayZv"],
		["_d_delclass" , "_D11_d_delclassUPC6ObjectZv"],
		["_d_delinterface" , "_D15_d_delinterfaceUPPvZv"],
		["_d_delmemory" , "_D12_d_delmemoryUPPvZv"],
		["difftime" , "_D8difftimeUiiZd"],
		["dirfd" , "_D5dirfdUPvZi"],
		["dirname" , "_D7dirnameUPaZPa"],
		["_d_isbaseof" , "_D11_d_isbaseofUC9ClassInfoC9ClassInfoZi"],
		["div" , "_D3divUiiZG8h"],
		["_d_monitorrelease" , "_D17_d_monitorreleaseUC6ObjectZv"],
		["_d_newarrayiT" , "_D13_d_newarrayiTUC8TypeInfokZm"],
		["_d_newarraymiT" , "_D14_d_newarraymiTUC8TypeInfoiZm"],
		["_d_newarraymT" , "_D13_d_newarraymTUC8TypeInfoiZm"],
		["_d_newarrayT" , "_D12_d_newarrayTUC8TypeInfokZm"],
		["_d_newclass" , "_D11_d_newclassUC9ClassInfoZC6Object"],
		["_d_obj_cmp" , "_D10_d_obj_cmpUC6ObjectC6ObjectZi"],
		["_d_obj_eq" , "_D9_d_obj_eqUC6ObjectC6ObjectZi"],
		["_d_OutOfMemory" , "_D14_d_OutOfMemoryUZv"],
		["_d_switch_error" , "_D15_d_switch_errorUAakZv"],
		["_d_toObject" , "_D11_d_toObjectUPvZC6Object"],
		["dup" , "_D3dupUiZi"],
		["dup2" , "_D4dup2UiiZi"],
		["environ" , "_D7environPPa"],
		["erf" , "_D3erfUdZd"],
		["erfc" , "_D4erfcUdZd"],
		["erfcf" , "_D5erfcfUfZf"],
		["erfcl" , "_D5erfclUeZe"],
		["erff" , "_D4erffUfZf"],
		["erfl" , "_D4erflUeZe"],
		["execl" , "_D5execlUPaPaZi"],
		["execle" , "_D6execleUPaPaZi"],
		["execlp" , "_D6execlpUPaPaZi"],
		["exp" , "_D3expUdZd"],
		["exp2" , "_D4exp2UdZd"],
		["exp2f" , "_D5exp2fUfZf"],
		["exp2l" , "_D5exp2lUeZe"],
		["expf" , "_D4expfUfZf"],
		["expl" , "_D4explUeZe"],
		["expm1" , "_D5expm1UdZd"],
		["expm1f" , "_D6expm1fUfZf"],
		["expm1l" , "_D6expm1lUeZe"],
		["fabs" , "_D4fabsUdZd"],
		["fabsf" , "_D5fabsfUfZf"],
		["fabsl" , "_D5fabslUeZe"],
		["fattach" , "_D7fattachUiPaZi"],
		["fchmod" , "_D6fchmodUikZi"],
		["fclose" , "_D6fcloseUPvZi"],
		["fcloseall" , "_D9fcloseallUZi"],
		["fcntl" , "_D5fcntlUiiZi"],
		["fdatasync" , "_D9fdatasyncUiZi"],
		["FD_CLR" , "_D6FD_CLRUiPvZv"],
		["FDELT" , "_D5FDELTUiZi"],
		["fdim" , "_D4fdimUddZd"],
		["fdimf" , "_D5fdimfUffZf"],
		["fdiml" , "_D5fdimlUeeZe"],
		["FD_ISSET" , "_D8FD_ISSETUiPvZi"],
		["FDMASK" , "_D6FDMASKUiZi"],
		["fdopen" , "_D6fdopenUiPaZPv"],
		["FD_SET" , "_D6FD_SETUiPvZv"],
		["FD_ZERO" , "_D7FD_ZEROUPvZv"],
		["feclearexcept" , "_D13feclearexceptUiZi"],
		["fegetenv" , "_D8fegetenvUPvZi"],
		["fegetexceptflag" , "_D15fegetexceptflagUPiiZi"],
		["fegetround" , "_D10fegetroundUZi"],
		["feholdexcept" , "_D12feholdexceptUPvZi"],
		["feof" , "_D4feofUPvZi"],
		["feraiseexcept" , "_D13feraiseexceptUiZi"],
		["ferror" , "_D6ferrorUPvZi"],
		["fesetenv" , "_D8fesetenvUPvZi"],
		["fesetexceptflag" , "_D15fesetexceptflagUPiiZi"],
		["fesetround" , "_D10fesetroundUiZi"],
		["fetestexcept" , "_D12fetestexceptUiZi"],
		["feupdateenv" , "_D11feupdateenvUPvZi"],
		["fflush" , "_D6fflushUPvZi"],
		["ffs" , "_D3ffsUiZi"],
		["fgetc" , "_D5fgetcUPvZi"],
		["fgetpos" , "_D7fgetposUPvPiZi"],
		["fgets" , "_D5fgetsUPaiPvZPa"],
		["fgetwc" , "_D6fgetwcUPvZw"],
		["fgetws" , "_D6fgetwsUPwiPvZPw"],
		["fileno" , "_D6filenoUPvZi"],
		["floorf" , "_D6floorfUfZf"],
		["floorl" , "_D6floorlUeZe"],
		["fma" , "_D3fmaUdddZd"],
		["fmaf" , "_D4fmafUfffZf"],
		["fmal" , "_D4fmalUeeeZe"],
		["fmax" , "_D4fmaxUddZd"],
		["fmaxf" , "_D5fmaxfUffZf"],
		["fmaxl" , "_D5fmaxlUeeZe"],
		["fmin" , "_D4fminUddZd"],
		["fminf" , "_D5fminfUffZf"],
		["fminl" , "_D5fminlUeeZe"],
		["fmod" , "_D4fmodUddZd"],
		["fmodf" , "_D5fmodfUffZf"],
		["fmodl" , "_D5fmodlUeeZe"],
		["fmtmsg" , "_D6fmtmsgUiPaiPaPaPaZi"],
		["fnmatch" , "_D7fnmatchUAaAaZi"],
		["fopen" , "_D5fopenUPaPaZPv"],
		["fork" , "_D4forkUZi"],
		["fpathconf" , "_D9fpathconfUiiZi"],
		["fpdef" , "_D5fpdefPS3std1c5stdio6_iobuf"],
		["fplog" , "_D5fplogPS3std1c5stdio6_iobuf"],
		["fprintf" , "_D7fprintfUPvPaZi"],
		["fputc" , "_D5fputcUiPvZi"],
		["fputs" , "_D5fputsUPaPvZi"],
		["fputwc" , "_D6fputwcUwPvZw"],
		["fputws" , "_D6fputwsUPwPvZi"],
		["fread" , "_D5freadUPvkkPvZk"],
		["free" , "_D4freeUPvZv"],
		["freeaddrinfo" , "_D12freeaddrinfoUPvZv"],
		["freopen" , "_D7freopenUPaPaPvZPv"],
		["frexp" , "_D5frexpUdPiZd"],
		["frexpf" , "_D6frexpfUfPiZf"],
		["frexpl" , "_D6frexplUePiZe"],
		["fscanf" , "_D6fscanfUPvPaZi"],
		["fseek" , "_D5fseekUPviiZi"],
		["fseeko" , "_D6fseekoUPviiZi"],
		["fsetpos" , "_D7fsetposUPvPiZi"],
		["fstat" , "_D5fstatUiPvZi"],
		["ftell" , "_D5ftellUPvZi"],
		["ftello" , "_D6ftelloUPvZi"],
		["fwide" , "_D5fwideUPviZi"],
		["fwprintf" , "_D8fwprintfUPvPwZi"],
		["fwrite" , "_D6fwriteUPvkkPvZk"],
		["fwscanf" , "_D7fwscanfUPvPwZi"],
		["getaddrinfo" , "_D11getaddrinfoUPaPaPvPPvZi"],
		["getc" , "_D4getcUPvZi"],
		["getchar" , "_D7getcharUZi"],
		["getenv" , "_D6getenvUPaZPa"],
		["getErrno" , "_D8getErrnoUZi"],
		["gethostbyaddr" , "_D13gethostbyaddrUPviiZPv"],
		["gethostbyname" , "_D13gethostbynameUPaZPv"],
		["gethostbyname2_r" , "_D16gethostbyname2_rUPaiPvPvkPPvPiZi"],
		["gethostbyname_r" , "_D15gethostbyname_rUPaPvPvkPPvPiZi"],
		["gethostname" , "_D11gethostnameUPaiZi"],
		["getnameinfo" , "_D11getnameinfoUPviPaiPaiiZi"],
		["getpeername" , "_D11getpeernameUiPvPiZi"],
		["getpid" , "_D6getpidUZi"],
		["getprotobyname" , "_D14getprotobynameUPaZPv"],
		["getprotobynumber" , "_D16getprotobynumberUiZPv"],
		["getpwnam" , "_D8getpwnamUPaZPv"],
		["getpwnam_r" , "_D10getpwnam_rUPaPvPvkPPvZi"],
		["getpwuid" , "_D8getpwuidUkZPv"],
		["getpwuid_r" , "_D10getpwuid_rUkPvPakPPvZi"],
		["gets" , "_D4getsUPaZPa"],
		["getservbyname" , "_D13getservbynameUPaPaZPv"],
		["getservbyport" , "_D13getservbyportUiPaZPv"],
		["getsockname" , "_D11getsocknameUiPvPiZi"],
		["getsockopt" , "_D10getsockoptUiiiPvPiZi"],
		["getw" , "_D4getwUPvZi"],
		["getwc" , "_D5getwcUPvZw"],
		["gmtime_r" , "_D8gmtime_rUPT3std1c5linux7pthread8__time_tPvZPv"],
		["htonl" , "_D5htonlUkZk"],
		["htons" , "_D5htonsUtZt"],
		["hypot" , "_D5hypotUddZd"],
		["hypotf" , "_D6hypotfUffZf"],
		["hypotl" , "_D6hypotlUeeZe"],
		["ilogb" , "_D5ilogbUdZi"],
		["ilogbf" , "_D6ilogbfUfZi"],
		["ilogbl" , "_D6ilogblUeZi"],
		["IN6ADDR_ANY" , "_D11IN6ADDR_ANYS3std1c5linux6socket8in6_addr"],
		["IN6ADDR_LOOPBACK" , "_D16IN6ADDR_LOOPBACKS3std1c5linux6socket8in6_addr"],
		["inet_addr" , "_D9inet_addrUPaZk"],
		["inet_ntoa" , "_D9inet_ntoaUS3std1c5linux6socket7in_addrZPa"],
		["isalnum" , "_D7isalnumUwZi"],
		["isalpha" , "_D7isalphaUwZi"],
		["isascii" , "_D7isasciiUwZi"],
		["iscntrl" , "_D7iscntrlUwZi"],
		["isgraph" , "_D7isgraphUwZi"],
		["islower" , "_D7islowerUwZi"],
		["isprint" , "_D7isprintUwZi"],
		["ispunct" , "_D7ispunctUwZi"],
		["isspace" , "_D7isspaceUwZi"],
		["isupper" , "_D7isupperUwZi"],
		["isxdigit" , "_D8isxdigitUwZi"],
		["kill" , "_D4killUiiZi"],
		["__LCMP__" , "_D8__LCMP__UZv"],
		["ldexp" , "_D5ldexpUdiZd"],
		["ldexpf" , "_D6ldexpfUfiZf"],
		["ldexpl" , "_D6ldexplUeiZe"],
		["ldiv" , "_D4ldivUiiZG8h"],
		["__LDIV__" , "_D8__LDIV__UZv"],
		["lgamma" , "_D6lgammaUdZd"],
		["lgammaf" , "_D7lgammafUfZf"],
		["lgammal" , "_D7lgammalUeZe"],
		["__libc_stack_end" , "_D16__libc_stack_endPv"],
		["listen" , "_D6listenUiiZi"],
		["lldiv" , "_D5lldivUllZG16h"],
		["llrint" , "_D6llrintUdZl"],
		["llrintf" , "_D7llrintfUfZl"],
		["llrintl" , "_D7llrintlUeZl"],
		["llround" , "_D7llroundUdZl"],
		["llroundf" , "_D8llroundfUfZl"],
		["llroundl" , "_D8llroundlUeZl"],
		["localeconv" , "_D10localeconvUZPv"],
		["localtime_r" , "_D11localtime_rUPT3std1c5linux7pthread8__time_tPvZPv"],
		["log" , "_D3logUdZd"],
		["log10" , "_D5log10UdZd"],
		["log10f" , "_D6log10fUfZf"],
		["log10l" , "_D6log10lUeZe"],
		["log1p" , "_D5log1pUdZd"],
		["log1pf" , "_D6log1pfUfZf"],
		["log1pl" , "_D6log1plUeZe"],
		["log2" , "_D4log2UdZd"],
		["log2f" , "_D5log2fUfZf"],
		["log2l" , "_D5log2lUeZe"],
		["logb" , "_D4logbUdZd"],
		["logbf" , "_D5logbfUfZf"],
		["logbl" , "_D5logblUeZe"],
		["logf" , "_D4logfUfZf"],
		["logl" , "_D4loglUeZe"],
		["lrint" , "_D5lrintUdZi"],
		["lrintf" , "_D6lrintfUfZi"],
		["lrintl" , "_D6lrintlUeZi"],
		["lround" , "_D6lroundUdZi"],
		["lroundf" , "_D7lroundfUfZi"],
		["lroundl" , "_D7lroundlUeZi"],
		["lseek" , "_D5lseekUiiiZi"],
		["lstat" , "_D5lstatUPaPvZi"],
		["madvise" , "_D7madviseUPvkiZi"],
		["main" , "_D4mainUAAaZi"],
		["malloc" , "_D6mallocUkZPv"],
		["mblen" , "_D5mblenUPakZi"],
		["mbstowcs" , "_D8mbstowcsUPwPakZk"],
		["mbtowc" , "_D6mbtowcUPwPakZi"],
		["memchr" , "_D6memchrUPvikZPv"],
		["memcmp" , "_D6memcmpUPvPvkZi"],
		["memmove" , "_D7memmoveUPvPvkZPv"],
		["memset" , "_D6memsetUPvikZPv"],
		["_memset128" , "_D10_memset128UPrriZPr"],
		["_memset16" , "_D9_memset16UPssiZPs"],
		["_memset160" , "_D10_memset160UPcciZPc"],
		["_memset32" , "_D9_memset32UPiiiZPi"],
		["_memset64" , "_D9_memset64UPlliZPl"],
		["_memset80" , "_D9_memset80UPeeiZPe"],
		["_memsetn" , "_D8_memsetnUPvPviiZPv"],
		["mincore" , "_D7mincoreUPvkPhZi"],
		["mlock" , "_D5mlockUPvkZi"],
		["mlockall" , "_D8mlockallUiZi"],
		["mmap" , "_D4mmapUPvkiiiiZPv"],
		["modf" , "_D4modfUdPdZd"],
		["modff" , "_D5modffUfPfZf"],
		["modfl" , "_D5modflUePeZe"],
		["_moduleinfo_array" , "_D17_moduleinfo_arrayAC10ModuleInfo"],
		["mprotect" , "_D8mprotectUPvkiZi"],
		["mremap" , "_D6mremapUPvkkiZPv"],
		["msync" , "_D5msyncUPvkiZi"],
		["munlock" , "_D7munlockUPvkZi"],
		["munlockall" , "_D10munlockallUZi"],
		["munmap" , "_D6munmapUPvkZi"],
		["nan" , "_D3nanUPaZd"],
		["nanf" , "_D4nanfUPaZf"],
		["nanl" , "_D4nanlUPaZe"],
		["nearbyint" , "_D9nearbyintUdZd"],
		["nearbyintf" , "_D10nearbyintfUfZf"],
		["nearbyintl" , "_D10nearbyintlUeZe"],
		["nextafter" , "_D9nextafterUddZd"],
		["nextafterf" , "_D10nextafterfUffZf"],
		["nextafterl" , "_D10nextafterlUeeZe"],
		["nexttoward" , "_D10nexttowardUdeZd"],
		["nexttowardf" , "_D11nexttowardfUfeZf"],
		["nexttowardl" , "_D11nexttowardlUeeZe"],
		["no_catch_exceptions" , "_D19no_catch_exceptionsb"],
		["nsymbols" , "_D8nsymbolsk"],
		["ntohl" , "_D5ntohlUkZk"],
		["ntohs" , "_D5ntohsUtZt"],
		["open" , "_D4openUPaiZi"],
		["opendir" , "_D7opendirUPaZPv"],
		["perror" , "_D6perrorUPaZv"],
		["pipe" , "_D4pipeUG2iZi"],
		["pow" , "_D3powUddZd"],
		["powf" , "_D4powfUffZf"],
		["powl" , "_D4powlUeeZe"],
		["printf" , "_D6printfUPaZi"],
		["psymbols" , "_D8psymbolsPPS8internal5trace6Symbol"],
		["pthread_atfork" , "_D14pthread_atforkUPUZvPUZvPUZvZi"],
		["pthread_attr_destroy" , "_D20pthread_attr_destroyUPvZi"],
		["pthread_attr_getdetachstate" , "_D27pthread_attr_getdetachstateUPvPiZi"],
		["pthread_attr_getguardsize" , "_D25pthread_attr_getguardsizeUPvPkZi"],
		["pthread_attr_getinheritsched" , "_D28pthread_attr_getinheritschedUPvPiZi"],
		["pthread_attr_getschedparam" , "_D26pthread_attr_getschedparamUPvPvZi"],
		["pthread_attr_getschedpolicy" , "_D27pthread_attr_getschedpolicyUPvPiZi"],
		["pthread_attr_getscope" , "_D21pthread_attr_getscopeUPvPiZi"],
		["pthread_attr_getstack" , "_D21pthread_attr_getstackUPvPPvPkZi"],
		["pthread_attr_getstackaddr" , "_D25pthread_attr_getstackaddrUPvPPvZi"],
		["pthread_attr_getstacksize" , "_D25pthread_attr_getstacksizeUPvPkZi"],
		["pthread_attr_setdetachstate" , "_D27pthread_attr_setdetachstateUPviZi"],
		["pthread_attr_setguardsize" , "_D25pthread_attr_setguardsizeUPvkZi"],
		["pthread_attr_setinheritsched" , "_D28pthread_attr_setinheritschedUPviZi"],
		["pthread_attr_setschedparam" , "_D26pthread_attr_setschedparamUPvPvZi"],
		["pthread_attr_setschedpolicy" , "_D27pthread_attr_setschedpolicyUPviZi"],
		["pthread_attr_setscope" , "_D21pthread_attr_setscopeUPviZi"],
		["pthread_attr_setstack" , "_D21pthread_attr_setstackUPvPvkZi"],
		["pthread_attr_setstackaddr" , "_D25pthread_attr_setstackaddrUPvPvZi"],
		["pthread_barrierattr_destroy" , "_D27pthread_barrierattr_destroyUPvZi"],
		["pthread_barrierattr_getpshared" , "_D30pthread_barrierattr_getpsharedUPvPiZi"],
		["pthread_barrierattr_init" , "_D24pthread_barrierattr_initUPvZi"],
		["pthread_barrierattr_setpshared" , "_D30pthread_barrierattr_setpsharedUPviZi"],
		["pthread_barrier_destroy" , "_D23pthread_barrier_destroyUPvZi"],
		["pthread_barrier_init" , "_D20pthread_barrier_initUPvPvkZi"],
		["pthread_barrier_wait" , "_D20pthread_barrier_waitUPvZi"],
		["_pthread_cleanup_pop" , "_D20_pthread_cleanup_popUPviZv"],
		["_pthread_cleanup_pop_restore" , "_D28_pthread_cleanup_pop_restoreUPviZv"],
		["_pthread_cleanup_push" , "_D21_pthread_cleanup_pushUPvPUPvZvPvZv"],
		["_pthread_cleanup_push_defer" , "_D27_pthread_cleanup_push_deferUPvPUPvZvPvZv"],
		["pthread_condattr_destroy" , "_D24pthread_condattr_destroyUPvZi"],
		["pthread_condattr_getpshared" , "_D27pthread_condattr_getpsharedUPvPiZi"],
		["pthread_condattr_init" , "_D21pthread_condattr_initUPvZi"],
		["pthread_condattr_setpshared" , "_D27pthread_condattr_setpsharedUPviZi"],
		["pthread_cond_broadcast" , "_D22pthread_cond_broadcastUPvZi"],
		["pthread_cond_destroy" , "_D20pthread_cond_destroyUPvZi"],
		["pthread_cond_init" , "_D17pthread_cond_initUPvPvZi"],
		["pthread_cond_signal" , "_D19pthread_cond_signalUPvZi"],
		["pthread_cond_timedwait" , "_D22pthread_cond_timedwaitUPvPvPvZi"],
		["pthread_cond_wait" , "_D17pthread_cond_waitUPvPvZi"],
		["pthread_detach" , "_D14pthread_detachUkZi"],
		["pthread_exit" , "_D12pthread_exitUPvZv"],
		["pthread_getattr_np" , "_D18pthread_getattr_npUkPvZi"],
		["pthread_getconcurrency" , "_D22pthread_getconcurrencyUZi"],
		["pthread_getcpuclockid" , "_D21pthread_getcpuclockidUkPiZi"],
		["pthread_getschedparam" , "_D21pthread_getschedparamUkPiPvZi"],
		["pthread_getspecific" , "_D19pthread_getspecificUkZPv"],
		["pthread_key_create" , "_D18pthread_key_createUPkPUPvZvZi"],
		["pthread_key_delete" , "_D18pthread_key_deleteUkZi"],
		["pthread_kill" , "_D12pthread_killUkiZi"],
		["pthread_mutexattr_destroy" , "_D25pthread_mutexattr_destroyUPvZi"],
		["pthread_mutexattr_getpshared" , "_D28pthread_mutexattr_getpsharedUPvPiZi"],
		["pthread_mutexattr_gettype" , "_D25pthread_mutexattr_gettypeUPvPiZi"],
		["pthread_mutexattr_init" , "_D22pthread_mutexattr_initUPvZi"],
		["pthread_mutexattr_setpshared" , "_D28pthread_mutexattr_setpsharedUPviZi"],
		["pthread_mutexattr_settype" , "_D25pthread_mutexattr_settypeUPviZi"],
		["pthread_mutex_destroy" , "_D21pthread_mutex_destroyUPvZi"],
		["pthread_mutex_init" , "_D18pthread_mutex_initUPvPvZi"],
		["pthread_mutex_lock" , "_D18pthread_mutex_lockUPvZi"],
		["pthread_mutex_timedlock" , "_D23pthread_mutex_timedlockUPvPvZi"],
		["pthread_mutex_trylock" , "_D21pthread_mutex_trylockUPvZi"],
		["pthread_mutex_unlock" , "_D20pthread_mutex_unlockUPvZi"],
		["pthread_once" , "_D12pthread_onceUPiPUZvZi"],
		["pthread_rwlockattr_destroy" , "_D26pthread_rwlockattr_destroyUPvZi"],
		["pthread_rwlockattr_getkind_np" , "_D29pthread_rwlockattr_getkind_npUPvPiZi"],
		["pthread_rwlockattr_getpshared" , "_D29pthread_rwlockattr_getpsharedUPvPiZi"],
		["pthread_rwlockattr_init" , "_D23pthread_rwlockattr_initUPvZi"],
		["pthread_rwlockattr_setkind_np" , "_D29pthread_rwlockattr_setkind_npUPviZi"],
		["pthread_rwlockattr_setpshared" , "_D29pthread_rwlockattr_setpsharedUPviZi"],
		["pthread_rwlock_destroy" , "_D22pthread_rwlock_destroyUPvZi"],
		["pthread_rwlock_init" , "_D19pthread_rwlock_initUPvPvZi"],
		["pthread_rwlock_rdlock" , "_D21pthread_rwlock_rdlockUPvZi"],
		["pthread_rwlock_timedrdlock" , "_D26pthread_rwlock_timedrdlockUPvPvZi"],
		["pthread_rwlock_timedwrlock" , "_D26pthread_rwlock_timedwrlockUPvPvZi"],
		["pthread_rwlock_tryrdlock" , "_D24pthread_rwlock_tryrdlockUPvZi"],
		["pthread_rwlock_trywrlock" , "_D24pthread_rwlock_trywrlockUPvZi"],
		["pthread_rwlock_unlock" , "_D21pthread_rwlock_unlockUPvZi"],
		["pthread_rwlock_wrlock" , "_D21pthread_rwlock_wrlockUPvZi"],
		["pthread_setconcurrency" , "_D22pthread_setconcurrencyUiZi"],
		["pthread_setschedparam" , "_D21pthread_setschedparamUkiPvZi"],
		["pthread_setspecific" , "_D19pthread_setspecificUkPvZi"],
		["pthread_spin_destroy" , "_D20pthread_spin_destroyUPiZi"],
		["pthread_spin_init" , "_D17pthread_spin_initUPiiZi"],
		["pthread_spin_lock" , "_D17pthread_spin_lockUPiZi"],
		["pthread_spin_trylock" , "_D20pthread_spin_trylockUPiZi"],
		["pthread_spin_unlock" , "_D19pthread_spin_unlockUPiZi"],
		["pthread_testcancel" , "_D18pthread_testcancelUZv"],
		["pthread_yield" , "_D13pthread_yieldUZi"],
		["putc" , "_D4putcUiPvZi"],
		["putchar" , "_D7putcharUiZi"],
		["puts" , "_D4putsUPaZi"],
		["putw" , "_D4putwUiPvZi"],
		["putwc" , "_D5putwcUwPvZw"],
		["qsort" , "_D5qsortUPvkkPUPvPvZiZv"],
		["random" , "_D6randomUiZi"],
		["readdir" , "_D7readdirUPvZPv"],
		["realloc" , "_D7reallocUPvkZPv"],
		["recv" , "_D4recvUiPviiZi"],
		["recvfrom" , "_D8recvfromUiPviiPvPiZi"],
		["remainder" , "_D9remainderUddZd"],
		["remainderf" , "_D10remainderfUffZf"],
		["remainderl" , "_D10remainderlUeeZe"],
		["remap_file_pages" , "_D16remap_file_pagesUPvkikiZi"],
		["remquo" , "_D6remquoUddPiZd"],
		["remquof" , "_D7remquofUffPiZf"],
		["remquol" , "_D7remquolUeePiZe"],
		["rewind" , "_D6rewindUPvZv"],
		["rewinddir" , "_D9rewinddirUPvZv"],
		["rint" , "_D4rintUdZd"],
		["rintf" , "_D5rintfUfZf"],
		["rintl" , "_D5rintlUeZe"],
		["root" , "_D4rootPS8internal5trace6Symbol"],
		["round" , "_D5roundUdZd"],
		["roundf" , "_D6roundfUfZf"],
		["roundl" , "_D6roundlUeZe"],
		["scalbln" , "_D7scalblnUdiZd"],
		["scalblnf" , "_D8scalblnfUfiZf"],
		["scalblnl" , "_D8scalblnlUeiZe"],
		["scalbn" , "_D6scalbnUdiZd"],
		["scalbnf" , "_D7scalbnfUfiZf"],
		["scalbnl" , "_D7scalbnlUeiZe"],
		["scanf" , "_D5scanfUPaZi"],
		["sched_yield" , "_D11sched_yieldUZi"],
		["seekdir" , "_D7seekdirUPviZv"],
		["select" , "_D6selectUiPvPvPvPvZi"],
		["sem_close" , "_D9sem_closeUPvZi"],
		["sem_destroy" , "_D11sem_destroyUPvZi"],
		["sem_getvalue" , "_D12sem_getvalueUPvPiZi"],
		["sem_init" , "_D8sem_initUPvikZi"],
		["sem_post" , "_D8sem_postUPvZi"],
		["sem_trywait" , "_D11sem_trywaitUPvZi"],
		["sem_wait" , "_D8sem_waitUPvZi"],
		["send" , "_D4sendUiPviiZi"],
		["sendto" , "_D6sendtoUiPviiPviZi"],
		["setbuf" , "_D6setbufUPvPaZv"],
		["setenv" , "_D6setenvUPaPaiZi"],
		["setErrno" , "_D8setErrnoUiZi"],
		["setlocale" , "_D9setlocaleUiPaZPa"],
		["setsockopt" , "_D10setsockoptUiiiPviZi"],
		["setvbuf" , "_D7setvbufUPvPaikZi"],
		["shutdown" , "_D8shutdownUiiZi"],
		["sigaction" , "_D9sigactionUiPS3std6thread11sigaction_tPS3std6thread11sigaction_tZi"],
		["sigdelset" , "_D9sigdelsetUPS3std6thread8sigset_tiZi"],
		["sigemptyset" , "_D11sigemptysetUPvZi"],
		["sigismember" , "_D11sigismemberUPviZi"],
		["sin" , "_D3sinUdZd"],
		["sinf" , "_D4sinfUfZf"],
		["sinh" , "_D4sinhUdZd"],
		["sinhf" , "_D5sinhfUfZf"],
		["sinhl" , "_D5sinhlUeZe"],
		["sinl" , "_D4sinlUeZe"],
		["skipspace" , "_D9skipspaceUPaZPa"],
		["sleep" , "_D5sleepUiZv"],
		["socket" , "_D6socketUiiiZi"],
		["sprintf" , "_D7sprintfUPaPaZi"],
		["sqrt" , "_D4sqrtUdZd"],
		["sqrtf" , "_D5sqrtfUfZf"],
		["sqrtl" , "_D5sqrtlUeZe"],
		["srand" , "_D5srandUkZv"],
		["sscanf" , "_D6sscanfUPaPaZi"],
		["stack_free" , "_D10stack_freeUPS8internal5trace5StackZv"],
		["stack_freelist" , "_D14stack_freelistPS8internal5trace5Stack"],
		["stack_malloc" , "_D12stack_mallocUZPS8internal5trace5Stack"],
		["stat" , "_D4statUPaPvZi"],
		["_STD_critical_term" , "_D18_STD_critical_termUZv"],
		["stderr" , "_D6stderrPS3std1c5stdio6_iobuf"],
		["stdin" , "_D5stdinPS3std1c5stdio6_iobuf"],
		["_STD_monitor_staticdtor" , "_D23_STD_monitor_staticdtorUZv"],
		["stdout" , "_D6stdoutPS3std1c5stdio6_iobuf"],
		["_STI_critical_init" , "_D18_STI_critical_initUZv"],
		["_STI_monitor_staticctor" , "_D23_STI_monitor_staticctorUZv"],
		["strcat" , "_D6strcatUPaPaZPa"],
		["strchr" , "_D6strchrUPaiZPa"],
		["strcmp" , "_D6strcmpUPaPaZi"],
		["strcoll" , "_D7strcollUPaPaZi"],
		["strcpy" , "_D6strcpyUPaPaZPa"],
		["strcspn" , "_D7strcspnUPaPaZk"],
		["strftime" , "_D8strftimeUPakPaPvZk"],
		["strlen" , "_D6strlenUPaZi"],
		["strncat" , "_D7strncatUPaPakZPa"],
		["strncmp" , "_D7strncmpUPaPakZi"],
		["strncpy" , "_D7strncpyUPaPakZPa"],
		["strpbrk" , "_D7strpbrkUPaPaZPa"],
		["strrchr" , "_D7strrchrUPaiZPa"],
		["strspn" , "_D6strspnUPaPaZk"],
		["strstr" , "_D6strstrUPaPaZPa"],
		["strtod" , "_D6strtodUPaPPaZd"],
		["strtof" , "_D6strtofUPaPPaZf"],
		["strtok" , "_D6strtokUPaPaZPa"],
		["strtol" , "_D6strtolUPaPPaiZl"],
		["strtold" , "_D7strtoldUPaPPaZe"],
		["strtoll" , "_D7strtollUPaPPaiZl"],
		["strtoul" , "_D7strtoulUPaPPaiZk"],
		["strtoull" , "_D8strtoullUPaPPaiZm"],
		["strxfrm" , "_D7strxfrmUPaPakZk"],
		["swprintf" , "_D8swprintfUPwPwZi"],
		["swscanf" , "_D7swscanfUPwPwZi"],
		["symbol_cmp" , "_D10symbol_cmpUPvPvZi"],
		["sympair_cmp" , "_D11sympair_cmpUPvPvZi"],
		["sysconf" , "_D7sysconfUiZi"],
		["tan" , "_D3tanUdZd"],
		["tanf" , "_D4tanfUfZf"],
		["tanh" , "_D4tanhUdZd"],
		["tanhf" , "_D5tanhfUfZf"],
		["tanhl" , "_D5tanhlUeZe"],
		["tanl" , "_D4tanlUeZe"],
		["telldir" , "_D7telldirUPvZi"],
		["tempnam" , "_D7tempnamUPaPaZPa"],
		["tgamma" , "_D6tgammaUdZd"],
		["tgammaf" , "_D7tgammafUfZf"],
		["tgammal" , "_D7tgammalUeZe"],
		["tmpfile" , "_D7tmpfileUZPv"],
		["tmpnam" , "_D6tmpnamUPaZPa"],
		["trace_addsym" , "_D12trace_addsymUAaZPS8internal5trace6Symbol"],
		["trace_array" , "_D11trace_arrayUPS8internal5trace6SymbolZv"],
		["trace_deffilename" , "_D17trace_deffilenameAa"],
		["trace_epi" , "_D9trace_epiUZv"],
		["_trace_epi_n" , "_D12_trace_epi_nUZv"],
		["trace_free" , "_D10trace_freeUPvZv"],
		["trace_init" , "_D10trace_initUZv"],
		["trace_inited" , "_D12trace_initedi"],
		["trace_logfilename" , "_D17trace_logfilenameAa"],
		["trace_malloc" , "_D12trace_mallocUkZPv"],
		["trace_merge" , "_D11trace_mergeUZv"],
		["trace_ohd" , "_D9trace_ohdl"],
		["trace_order" , "_D11trace_orderUPS8internal5trace6SymbolZv"],
		["trace_place" , "_D11trace_placeUPS8internal5trace6SymbolkZv"],
		["trace_pro" , "_D9trace_proUAaZv"],
		["_trace_pro_n" , "_D12_trace_pro_nUZv"],
		["trace_readline" , "_D14trace_readlineUPvZPa"],
		["trace_report" , "_D12trace_reportUPS8internal5trace6SymbolZv"],
		["trace_setdeffilename" , "_D20trace_setdeffilenameUAaZi"],
		["trace_setlogfilename" , "_D20trace_setlogfilenameUAaZi"],
		["trace_sympair_add" , "_D17trace_sympair_addUPPS8internal5trace7SymPairPS8internal5trace6SymbolkZv"],
		["trace_term" , "_D10trace_termUZv"],
		["trace_times" , "_D11trace_timesUPS8internal5trace6SymbolZv"],
		["trace_tos" , "_D9trace_tosPS8internal5trace5Stack"],
		["trunc" , "_D5truncUdZd"],
		["truncf" , "_D6truncfUfZf"],
		["truncl" , "_D6trunclUeZe"],
		["tzname" , "_D6tznameG2Pa"],
		["tzset" , "_D5tzsetUZv"],
		["__U64_LDBL" , "_D10__U64_LDBLUZe"],
		["__ULDIV__" , "_D9__ULDIV__UZv"],
		["__ULLNGDBL" , "_D10__ULLNGDBLUZm"],
		["uncompress" , "_D10uncompressUAvkiZAv"],
		["ungetc" , "_D6ungetcUiPvZi"],
		["ungetwc" , "_D7ungetwcUwPvZw"],
		["unlink" , "_D6unlinkUPaZi"],
		["unsetenv" , "_D8unsetenvUPaZv"],
		["usleep" , "_D6usleepUkZv"],
		["utime" , "_D5utimeUPaPvZi"],
		["vfprintf" , "_D8vfprintfUPvPaPvZi"],
		["vfwprintf" , "_D9vfwprintfUPvPwPvZi"],
		["vprintf" , "_D7vprintfUPaPvZi"],
		["vsnprintf" , "_D9vsnprintfUPakPaPvZi"],
		["vsprintf" , "_D8vsprintfUPaPaPvZi"],
		["vswprintf" , "_D9vswprintfUPwPwPvZi"],
		["vwprintf" , "_D8vwprintfUPwPvZi"],
		["waitpid" , "_D7waitpidUiPiiZi"],
		["wcscmp" , "_D6wcscmpUPuPuZi"],
		["wcsftime" , "_D8wcsftimeUPwkPwPvZk"],
		["wcslen" , "_D6wcslenUPuZi"],
		["wcstombs" , "_D8wcstombsUPaPwkZk"],
		["wctomb" , "_D6wctombUPawZi"],
		["wprintf" , "_D7wprintfUPwZi"],
		["wscanf" , "_D6wscanfUPwZi"],
	];
}
