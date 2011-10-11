module wrt.models.PlyLoader;

import std.stream : Stream, BufferedFile, FileMode, EndianStream;
import std.stdio : writefln, writef;
import std.string : split, isNumeric, toString, atof;
version (D_Version2) {
import std.conv : to;
alias to!(int,string) toInt;
alias to!(uint,string) toUint;
alias to!(byte,string) toByte;
alias to!(ubyte,string) toUbyte;
alias to!(short,string) toShort;
alias to!(ushort,string) toUshort;
alias to!(float,string) toFloat;
alias to!(double,string) toDouble;
} else {
import std.conv : toInt, toUint, toByte, toUbyte, toShort, toUshort,
		toFloat, toDouble;
}

import std.system : Endian;
import std.cstream : dout;

import wrt.Scene :  Scene;
import wrt.objects.Triangle : Triangle, vertex;
import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;
import wrt.Material : Material;

import wrt.Timer : Timer;

/** Simplified ply format
 * ---
 * vertices: 123
 * faces: 180
 * v 0.1 0.2 0.3
 * ...
 * v 0.5 -0.2 0.4
 * f 1 2 3
 * ...
 * f 142 163 180
 * ---
 */
void load_simpleply_into_scene(Scene scene, char[] filename, Material material = null, mat4 transform = mat4.I) {
	scope Stream s = new BufferedFile(filename, FileMode.In);
	char[] temp;

	int vertices;
	s.readf("vertices: %d\n", &vertices);
	vertex[] vertex_list;
	vertex_list.length = vertices;

	int faces;
	s.readf("faces: %d\n", &faces);

	writefln("reading %d vertices, and %d faces from %s", vertices, faces, filename);

	int off = scene.objs_offset;
	if (scene.objs.length - scene.objs_offset > faces) {
	} else {
		writefln("doallokowywanie");
		scene.objs.length = scene.objs.length + faces;
	}

	{
	scope Timer timer = new Timer("loading vertexs");
	if (transform == mat4.I) {
		float x, y, z;
		for (int i = 0; i < vertices; i++) {
			s.readf("v %f %f %f\n", &x, &y, &z);
			vertex_list[i] = vertex.create(x, y, z);
		}
	} else {
		float x, y, z;
		for (int i = 0; i < vertices; i++) {
			s.readf("v %f %f %f\n", &x, &y, &z);
			vertex_list[i] = vertex.fromvec3_struct(transform*vec3(x, y, z));
		}
	}
	}

	{
	scope Timer timer = new Timer("loading faces");
	int v1, v2, v3;
	for (int i = 0; i < faces; i++) {
		s.readf("f %d %d %d\n", &v1, &v2, &v3);
		assert(1 <= v1 && v1 <= vertices);
		assert(1 <= v2 && v2 <= vertices);
		assert(1 <= v3 && v3 <= vertices);
		scene.objs[off+i] = new Triangle(&vertex_list[v1-1], &vertex_list[v3-1], &vertex_list[v2-1], true);
		if (material) {
			scene.objs[off+i].setMaterial(material);
		}
	}
	}

	scene.objs_offset = off+faces;

	s.close();
}

/*
http://tog.acm.org/resources/SPD/

http://www.tecgraf.puc-rio.br/~diego/professional/rply/
http://homepages.paradise.net.nz/nickamy/code.htm

http://www-static.cc.gatech.edu/projects/large_models/
http://graphics.stanford.edu/data/3Dscanrep/
http://graphics.stanford.edu/data/3Dscanrep/3Dscanrep.html#bunny
*/

enum Type {
	int8,
	uint8,
	int16,
	uint16,
	int32,
	uint32,
	float32,
	float64,
	list
}

struct Property {
	char[] name;
	Type type;
	Type type1;
	Type type2;
}

struct Element {
	char[] name;
	int count;
	Property[] properties;
}

version=progressbar;

void load_ply_into_scene(Scene scene, char[] filename, Material material = null, mat4 transform = mat4.I) {
	scope Stream s = new EndianStream(new BufferedFile(filename, FileMode.In), Endian.BigEndian);

	char[] temp;
	temp = s.readString(4);
	if (temp != "ply\n") {
		throw new Exception("not ply format");
	}
	temp = s.readLine();
	char[][] temp2 = split(temp);
	if (temp2.length != 3 || temp2[0] != "format") {
		throw new Exception("missing or bad format line");
	}
	if (temp2[2] != "1.0") {
		throw new Exception("only version 1.0 supported");
	}
	int format = -1;
	switch (temp2[1]) {
		case "ascii":
			format = 0;
			break;
		case "binary_little_endian":
			format = 1;
			break;
		case "binary_big_endian":
			format = 2;
			break;
		default:
			throw new Exception("only ascii, binary_{little,big}_endian supported");
	}

	int line = 2;
	Element* last_element;
	Element[] elements;
	Element*[char[]] elements_hash;

header_loop:
	while(true) {
		line++;
		temp = s.readLine(temp);
		temp2 = split(temp);
		if (temp2.length < 1) {
			throw new Exception("problem in file '"~filename~"' line " ~ toString(line));
		}
		switch (temp2[0]) {
			case "comment":
				break;
			case "element":
				if (temp2.length != 3) {
					throw new Exception("component '" ~ temp2[0] ~"' should have exactly 3 fields in file '"~filename~"' line " ~ toString(line));
				}
				if (temp2[1] in elements_hash) {
					throw new Exception("element '" ~ temp2[1] ~"' was already bean seen in header! in file '"~filename~"' line " ~ toString(line));
				}
				if (!isNumeric(temp2[2])) {
					throw new Exception("third field of element component should be a number, not '" ~ temp2[2] ~"'! in file '"~filename~"' line " ~ toString(line));
				}
				elements ~= Element(temp2[1].dup, toInt(temp2[2]));
				elements_hash[temp2[1].dup] = &elements[elements.length-1];
				last_element = &elements[elements.length-1];
				break;
			case "property":
				if (last_element is null) {
					throw new Exception("property befor any element! in file '"~filename~"' line " ~ toString(line));
				}
				if (!(temp2.length == 3 || (temp2[1] == "list" && temp2.length == 5))) {
					throw new Exception("component '" ~ temp2[0] ~"' should have exactly 3 (or 5 for list datatype) fields in file '"~filename~"' line " ~ toString(line));
				}
				Type toType(char[] temp_) {
					switch (temp_) {
						case "float":
							return Type.float32;
						case "int":
							return Type.int32;
						case "uchar":
							return Type.uint8;
						case "list":
							return Type.list;
						default:
							throw new Exception("unknown or not implemented datatype '" ~ temp2[1] ~"' in property '"~temp_~"' in file '"~filename~"' line " ~ toString(line));
					}
					assert(0);
				}
				Type t = toType(temp2[1]);
				if (t == Type.list) {
					Type t2 = toType(temp2[2]);
					Type t3 = toType(temp2[3]);
					last_element.properties ~= Property(temp2[4].dup, t, t2, t3);
				} else {
					last_element.properties ~= Property(temp2[2].dup, t);
				}
				break;
			case "end_header":
				break header_loop;
			default:
				throw new Exception("unknown component '" ~ temp2[0] ~"' in file '"~filename~"' line " ~ toString(line));
		}
	}

	if (("vertex" in elements_hash) is null) {
		throw new Exception("No 'vertex' component in header");
	}
	if (("face" in elements_hash) is null) {
		throw new Exception("No 'face' component in header");
	}

	if (elements_hash["vertex"].properties.length < 3) {
		throw new Exception("Vertex element should have at least 3 properties");
	}

	if (elements_hash["vertex"].properties[0].name != "x"
		|| elements_hash["vertex"].properties[0].type != Type.float32) {
		throw new Exception("Vertex element should have 1st property x of type float");
	}
	if (elements_hash["vertex"].properties[1].name != "y"
		|| elements_hash["vertex"].properties[1].type != Type.float32) {
		throw new Exception("Vertex element should have 2nd property y of type float");
	}
	if (elements_hash["vertex"].properties[2].name != "z"
		|| elements_hash["vertex"].properties[2].type != Type.float32) {
		throw new Exception("Vertex element should have 3rd property z of type float");
	}

	if (elements_hash["face"].properties.length < 1) {
		throw new Exception("Face element should have at least 1 properties");
	}

	if (!((elements_hash["face"].properties[0].name == "vertex_index"
		|| elements_hash["face"].properties[0].name == "vertices_index"
		|| elements_hash["face"].properties[0].name == "vertex_indices")
		&& elements_hash["face"].properties[0].type == Type.list
		&& elements_hash["face"].properties[0].type1 == Type.uint8
		&& elements_hash["face"].properties[0].type2 == Type.int32)) {
		throw new Exception("Face element should have first property vertex_index (or vertices_index) of type list(uint8,int32) [ list uchar int vertex_index ]");
	}

	int vertices = elements_hash["vertex"].count;
	vertex[] vertex_list;
	vertex_list.length = vertices;

	int faces = elements_hash["face"].count;

	writefln("reading %d vertices, and %d faces from %s", vertices, faces, filename);

	int face_off = scene.objs_offset;
	if (scene.objs.length - face_off > faces) {
	} else {
		writefln("doallokowywanie");
		scene.objs.length = scene.objs.length + faces;
	}

	int vertex_i = 0;
	int face_i = 0;

	bool trans = (transform != mat4.I);

	{
	scope Timer timer = new Timer("loading vertexs and faces");

	if (format == 0) {
		// zrobic optymalizacje dla format vertex3+face_list 

		foreach (ref element; elements) {
			int kropek_already = 0;
			char[] element_name = element.name;

			version(progressbar) {
				writef("%s: 0%%", element_name);
			}

			int pl = element.properties.length;
			int what = 0;
			switch (element_name) {
				case "face":
					what = 1;
					break;
				case "vertex":
					what = 2;
					break;
				default:
					what = 0;
					break;
			}
			for (int i = 0; i < element.count; i++) {
				line++;

				version (progressbar) {
					int kropek = cast(int)(50.0*i/element.count);
					for (; kropek_already < kropek; kropek_already++) {
						if (kropek % 5 == 0) {
							dout.printf("%d0%%", (kropek/5));
						} else {
							dout.write('.');
						}
						dout.flush();
					}
				}

				temp = s.readLine(temp);
				if (what == 2) {
					temp2 = split(temp);
					if (trans) {
						vertex_list[vertex_i++] = vertex.fromvec3_struct(transform*vec3(atof(temp2[0]), atof(temp2[1]), atof(temp2[2])));
					} else {
						vertex_list[vertex_i++] = vertex.create(atof(temp2[0]), atof(temp2[1]), atof(temp2[2]));
					}
				} else if (what == 1) {
					temp2 = split(temp);
					int vertex_in_face = toInt(temp2[0]);
					assert(vertex_in_face == 3);
					int v1 = toInt(temp2[1]);
					int v2 = toInt(temp2[2]);
					int v3 = toInt(temp2[3]);
					assert(0 <= v1 && v1 < vertices);
					assert(0 <= v2 && v2 < vertices);
					assert(0 <= v3 && v3 < vertices);
					scene.objs[face_off+face_i] = new Triangle(&vertex_list[v1], &vertex_list[v3], &vertex_list[v2], true);
					if (material) {
						scene.objs[face_off+face_i].setMaterial(material);
					}
					face_i++;
				} else {
					continue;
				}
			}

			version(progressbar) {
				writefln("100%%");
			}
		}
	} else if (format == 2) {

		foreach (ref element; elements) {
			int kropek_already;
			char[] element_name = element.name;

			version(progressbar) {
				writef("%s: 0%%", element_name);
			}

			int pl = element.properties.length;
			int what = 0;
			switch (element_name) {
				case "face":
					what = 1;
					break;
				case "vertex":
					what = 2;
					break;
				default:
					what = 0;
					break;
			}

			for (int i = 0; i < element.count; i++) {
				version (progressbar) {
					int kropek = cast(int)(50.0*i/element.count);
					for (; kropek_already < kropek; kropek_already++) {
						if (kropek % 5 == 0) {
							dout.printf("%d0%%", (kropek/5));
						} else {
							dout.write('.');
						}
						dout.flush();
					}
				}

				int float_i, int_i;
				int[][] var_list_int;
				float[3] var_float;
				int[3] var_int;

				for (int j = 0; j < pl; j++) {
					switch (element.properties[j].type) {
						case Type.float32:
							var_float[float_i++] = readjust!(float)(s);
							break;
						case Type.uint32:
							var_int[int_i++] = readjust!(uint)(s);
							break;
						case Type.int32:
							var_int[int_i++] = readjust!(uint)(s);
							break;
						case Type.uint8:
							var_int[int_i++] = readjust!(ubyte)(s);
							break;
						case Type.list:
							{
							int list_count = readandcast!(int)(s, element.properties[j].type1);
							switch (element.properties[j].type2) {
								case Type.int32:
									{
									int[] var_list_int2 = new int[list_count];
									for (int k = 0; k < list_count; k++) {
										var_list_int2[k] = readjust!(int)(s);
									}
									var_list_int ~= var_list_int2;
									}
									break;
								case Type.uint32:
									{
									int[] var_list_int2 = new int[list_count];
									for (int k = 0; k < list_count; k++) {
										var_list_int2[k] = cast(int)readjust!(uint)(s);
									}
									var_list_int ~= var_list_int2;
									}
									break;
								default:
									throw new Exception("c");
							}
							}
							break;
						default:
							throw new Exception("a");
					}
				}

				if (what == 2) {
					assert(var_float.length == 3);
					if (trans) {
						vertex_list[vertex_i++] = vertex.fromvec3_struct(transform*vec3(var_float[0], var_float[1], var_float[2]));
					} else {
						vertex_list[vertex_i++] = vertex.create(var_float[0], var_float[1], var_float[2]);
					}
				} else if (what == 1) {
					int vertex_in_face = var_list_int[0].length;
					assert(vertex_in_face == 3);
					int v1 = var_list_int[0][0];
					int v2 = var_list_int[0][1];
					int v3 = var_list_int[0][2];
					assert(0 <= v1 && v1 < vertices);
					assert(0 <= v2 && v2 < vertices);
					assert(0 <= v3 && v3 < vertices);
					scene.objs[face_off+face_i] = new Triangle(&vertex_list[v1], &vertex_list[v3], &vertex_list[v2], true);
					if (material) {
						scene.objs[face_off+face_i].setMaterial(material);
					}
					face_i++;
				} else {
					continue;
				}
			}

			version(progressbar) {
				writefln("100%%");
			}
		}
	} else {
		throw new Exception("Only ascii/big_endian format currently implemented");
	}

	for (int i = 0; i < faces; i++) {
		Triangle tri = cast(Triangle)scene.objs[face_off+i];
		if (tri !is null) {
			tri.actualizeSigns();
		} else {
			throw new Exception("d");
		}
	}

	} // Timer

	scene.objs_offset = face_off+faces;

	s.close();
}

T readandcast(T)(Stream s, Type type_) {
	switch (type_) {
		case Type.uint8:
			ubyte list_count_byte;
			s.read(list_count_byte);
			return cast(T)list_count_byte;
		case Type.uint32:
			uint list_count_uint;
			s.read(list_count_uint);
			return cast(T)list_count_uint;
		case Type.float32:
			float list_count_float;
			s.read(list_count_float);
			return cast(T)list_count_float;
		case Type.float64:
			double list_count_double;
			s.read(list_count_double);
			return cast(T)list_count_double;
		case Type.int8:
			byte list_count_byte;
			s.read(list_count_byte);
			return cast(T)list_count_byte;
		case Type.int32:
			int list_count_int;
			s.read(list_count_int);
			return cast(T)list_count_int;
		default:
			throw new Exception("b");
	}
	assert(0);
}

T readjust(T)(Stream s) {
	T x;
	s.read(x);
	return x;
}
