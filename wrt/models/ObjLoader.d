module wrt.models.ObjLoader;

import std.stream : Stream, BufferedFile, FileMode, EndianStream;
import std.stdio : writefln, writef;
import std.string : split, isNumeric, toString, atof, atoi;
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

void load_obj_into_scene(Scene scene, char[] filename, Material material = null, mat4 transform = mat4.I) {
	if (filename.length < 5 || filename[$-4 .. $] != ".obj") {
		throw new Exception("Bad Wavefront Obj file extension");
	}

	scope Stream s = new BufferedFile(filename, FileMode.In);

	writefln("preprocesing file (counting elements)");

	int count_objects, count_groups, count_vertices, count_normal_vertices,
		count_texture_vertices, count_faces, count_materials;
	int count_triangles;

	foreach (ulong n, char[] line; s) { // TODO: own faster looping
		if (line.length == 0)
			continue;
		if (line[0] == '#')
			continue;
		char[][] temp2 = split(line);
		if (temp2.length == 0)
			continue;
		if (temp2[0][0] == '#')
			continue;
		// TODO: line continuation ( \ char on the end of line)
		char[][] args = temp2[1 .. $];
		int argc = args.length;
		assert(args.length == temp2.length - 1);
		switch (temp2[0]) {

// Vertex data

			case "v": // geometric vertices
				if (!(isNumeric(args[0]) && isNumeric(args[1]) && isNumeric(temp2[2]))) {
					throw new Exception("bad floating point in line " ~ toString(n));
				}
				if (argc == 4 && !isNumeric(args[3])) {
					throw new Exception("bad floating point in line " ~ toString(n));
				}

				count_vertices++;
				break;
			case "vt": // texture vertices
				if (!(1 <= argc && argc <= 3)) {
					throw new Exception("element vt should have 1 .. 3 parameters");
				}

				count_texture_vertices++;
				break;
			case "vn": // vertex normals
				if (!(argc == 3)) {
					throw new Exception("element vn should have 3 parameters");
				}
				count_normal_vertices++;
				break;

			case "vp": // parameter space vertices (Free-form curve/surface attributes
				throw new Exception("not supported element in line " ~ toString(n));
			case "cstype": // rational or non-rational forms of curve or surface type
				throw new Exception("not supported element in line " ~ toString(n));
			case "deg": // degree
				throw new Exception("not supported element in line " ~ toString(n));
			case "bmat": // basis matrix
				throw new Exception("not supported element in line " ~ toString(n));
			case "step": // step size
				throw new Exception("not supported element in line " ~ toString(n));

// Elements

			case "p": // point
				throw new Exception("not supported element in line " ~ toString(n));
			case "l": // line
				throw new Exception("not supported element in line " ~ toString(n));

			case "f": // face
				if (!(3 <= argc)) {
					throw new Exception("element f should have at least 3 parameters");
				}
				int triangles = (argc - 2);

				count_faces++;
				count_triangles += triangles;

				if (triangles != 1) {
					throw new Exception("polygons other than triangles not supported");
				}

				break;

			case "curv": // curve
				throw new Exception("not supported element in line " ~ toString(n));
			case "curv2": // 2D curve
				throw new Exception("not supported element in line " ~ toString(n));
			case "surf": // surface
				throw new Exception("not supported element in line " ~ toString(n));

// Free-form curve/surface body statements

			case "parm": // paramater values
				throw new Exception("not supported element in line " ~ toString(n));
			case "trim": // outer trimming loop
				throw new Exception("not supported element in line " ~ toString(n));
			case "hole": // inner trimming loop
				throw new Exception("not supported element in line " ~ toString(n));
			case "scrv": // special curve
				throw new Exception("not supported element in line " ~ toString(n));
			case "sp": // special point
				throw new Exception("not supported element in line " ~ toString(n));
			case "end": // end statement
				throw new Exception("not supported element in line " ~ toString(n));

// Connectivity between free-form surfaces

			case "con": // connect
				throw new Exception("not supported element in line " ~ toString(n));

// Grouping
			case "g": // group name
				if (argc != 1) {
					throw new Exception("element g should have 1 parameter");
				}
				count_groups++;
				break;
			case "s": // smoothing group
				throw new Exception("not supported element in line " ~ toString(n));
			case "mg": // merging group
				throw new Exception("not supported element in line " ~ toString(n));
			case "o": // object name
				if (argc != 1) {
					throw new Exception("element o should have 1 parameter");
				}
				count_objects++;
				break;

// Display/render atributes

			case "bevel": // bevel interpolation
				throw new Exception("not supported element in line " ~ toString(n));
			case "c_interp": // color interpolation
				throw new Exception("not supported element in line " ~ toString(n));
			case "d_interp": // dissolve interpolation
				throw new Exception("not supported element in line " ~ toString(n));
			case "lod": // level of detail
				throw new Exception("not supported element in line " ~ toString(n));
			case "usemtl": // material name
				if (!(argc >= 1)) {
					throw new Exception("element usemtl should have at least 1 parameters");
				}
				count_materials++;
				break;
			case "mtllib": // material library
				break;
			case "shadow_obj": // shadow_casting
				throw new Exception("not supported element in line " ~ toString(n));
			case "trace_obj": // ray tracing
				throw new Exception("not supported element in line " ~ toString(n));
			case "ctech": // curve approximation technique
				throw new Exception("not supported element in line " ~ toString(n));
			case "stech": // surface approximation technique
				throw new Exception("not supported element in line " ~ toString(n));

// General

			case "call": // include another file
				throw new Exception("not supported element in line " ~ toString(n));
			case "csh": // executes unix command
				throw new Exception("not supported element in line " ~ toString(n));

			default:
				throw new Exception("unknown element in line " ~ toString(n));

		}
	}

	writefln("file preprocesed, allocating memmory");

	vertex[] vertex_list = new vertex[count_vertices];

	writefln("reading %d vertices, and %d faces (%d triangles) from %s", count_vertices, count_faces, count_triangles, filename);

	int face_off = scene.objs_offset;
	int face_i = 0; // face_off+face_i is index in scene.objs array, NOTE: slice can be better
	if (scene.objs.length - face_off > count_faces) {
	} else {
		writefln("doallokowywanie");
		scene.objs.length = scene.objs.length + count_faces;
	}

	s.seekSet(0);

	int i_objects, i_groups, i_vertices, i_normal_vertices,
		i_texture_vertices, i_faces, i_materials;
	int i_triangles;

	bool trans = (transform != mat4.I);

	foreach (ulong n, char[] line; s) { // TODO: own faster looping
		if (line.length == 0)
			continue;
		if (line[0] == '#')
			continue;
		char[][] temp2 = split(line);
		if (temp2.length == 0)
			continue;
		if (temp2[0][0] == '#')
			continue;
		char[][] args = temp2[1 .. $];
		int argc = args.length;
		assert(args.length == temp2.length - 1);
		switch (temp2[0]) {
// Vertex data

			case "v": // geometric vertices
				if (trans) {
					vertex_list[i_vertices++] = vertex.fromvec3_struct(transform*vec3(atof(args[0]), atof(args[1]), atof(args[2])));
				} else {
					vertex_list[i_vertices++] = vertex.create(atof(args[0]), atof(args[1]), atof(args[2]));
				}
				break;
			case "vt": // texture vertices
				i_texture_vertices++;
				break;
			case "vn": // vertex normals
				i_normal_vertices++;
				break;

			case "vp": // parameter space vertices (Free-form curve/surface attributes
				throw new Exception("not supported element in line " ~ toString(n));
			case "cstype": // rational or non-rational forms of curve or surface type
				throw new Exception("not supported element in line " ~ toString(n));
			case "deg": // degree
				throw new Exception("not supported element in line " ~ toString(n));
			case "bmat": // basis matrix
				throw new Exception("not supported element in line " ~ toString(n));
			case "step": // step size
				throw new Exception("not supported element in line " ~ toString(n));

// Elements

			case "p": // point
				throw new Exception("not supported element in line " ~ toString(n));
			case "l": // line
				throw new Exception("not supported element in line " ~ toString(n));

			case "f": // face
				int triangles = argc - 2;

				int gv(int i, int maximum = i_vertices) {
					if (i == 0) {
						throw new Exception("zero index in vertex_list is bad in line " ~ toString(n));
					}
					if (i > maximum || i < -maximum) {
						writefln("i ", i, "iv", maximum);
						throw new Exception("vertex_list index out of range in line " ~ toString(n));
					}
					return (i >= 0 ? i-1 : maximum-i);
				}

				// f 1/1/1 2/2/2 3/3/3 4/4/4
				// f v/vt/vn

/*
 *
 *       The first reference number is the geometric vertex. (v)
 *       The second reference number is the texture vertex. It follows
 *       the first slash. (vt)
 *       The third reference number is the vertex normal. It follows the
 *       second slash. (vn)
 */

				int[3]
					triangle_geometric_vertex_idx,
					triangle_texture_vertex_idx,
					triangle_normal_vertex_idx;
				
				if (triangles == 1) {
					foreach (vertex_i, reference; args) {
						char[][] temp3 = split(reference, "/");
						if (temp3.length == 0) {
							throw new Exception("something really bad in line " ~ toString(n));
						}
						if (temp3[0].length == 0) {
							throw new Exception("no index of geometric vertex in line " ~ toString(n));
						} else {
							if (!isNumeric(temp3[0])) {
								throw new Exception("bad reference of geomtric vertex in line " ~ toString(n));
							}
							triangle_geometric_vertex_idx[vertex_i] = gv(cast(int)atoi(temp3[0]));
						}

						triangle_texture_vertex_idx[vertex_i] = -1;
						if (temp3.length > 1) {
							if (temp3[1].length != 0) {
								if (!isNumeric(temp3[1])) {
									throw new Exception("bad reference of texture vertex in line " ~ toString(n));
								}
								triangle_texture_vertex_idx[vertex_i] = gv(cast(int)atoi(temp3[1]), i_texture_vertices);
							}
						}

						triangle_normal_vertex_idx[vertex_i] = -1;
						if (temp3.length > 2) {
							if (temp3[2].length != 0) {
								if (!isNumeric(temp3[2])) {
									throw new Exception("bad reference of normal vertex in line " ~ toString(n));
								}
								triangle_normal_vertex_idx[vertex_i] = gv(cast(int)atoi(temp3[2]), i_normal_vertices);
							}
						}

						if (temp3.length > 3) {
							throw new Exception("unknown reference in line " ~ toString(n));
						}
					}
				} else {
					throw new Exception("polygons other than triangles not supported in line " ~ toString(n));
				}

				if (triangles == 1) {
/*
						vertex_list[triangle_geometric_vertex_idx[0]].print();
						vertex_list[triangle_geometric_vertex_idx[1]].print();
						vertex_list[triangle_geometric_vertex_idx[2]].print();
						writefln();
*/
					scene.objs[face_off+face_i] = new Triangle(
						&vertex_list[triangle_geometric_vertex_idx[0]],
						&vertex_list[triangle_geometric_vertex_idx[1]],
						&vertex_list[triangle_geometric_vertex_idx[2]],
						 true);
					if (material) {
						scene.objs[face_off+face_i].setMaterial(material);
					}

					face_i++;
/*
				} else if (triangles == 2) {
					scene.objs[face_off+face_i] = new Triangle(get_vertex(), get_vertex(), get_vertex(), true);
					face_i++;
					scene.objs[face_off+face_i] = new Triangle(get_vertex(), get_vertex(), get_vertex(), true);
					face_i++;
					// or use BilinearQuadPatch
*/
				} else {
					throw new Exception("polygons other than triangles not supported in line " ~ toString(n));
					//triangulate();
				}


				i_faces++;
				i_triangles += triangles;
				
				break;

			case "curv": // curve
				throw new Exception("not supported element in line " ~ toString(n));
			case "curv2": // 2D curve
				throw new Exception("not supported element in line " ~ toString(n));
			case "surf": // surface
				throw new Exception("not supported element in line " ~ toString(n));

// Free-form curve/surface body statements

			case "parm": // paramater values
				throw new Exception("not supported element in line " ~ toString(n));
			case "trim": // outer trimming loop
				throw new Exception("not supported element in line " ~ toString(n));
			case "hole": // inner trimming loop
				throw new Exception("not supported element in line " ~ toString(n));
			case "scrv": // special curve
				throw new Exception("not supported element in line " ~ toString(n));
			case "sp": // special point
				throw new Exception("not supported element in line " ~ toString(n));
			case "end": // end statement
				throw new Exception("not supported element in line " ~ toString(n));

// Connectivity between free-form surfaces

			case "con": // connect
				throw new Exception("not supported element in line " ~ toString(n));

// Grouping
			case "g": // group name
				writefln("  group ", args[0]);
				i_groups++;
				break;
			case "s": // smoothing group
				throw new Exception("not supported element in line " ~ toString(n));
			case "mg": // merging group
				throw new Exception("not supported element in line " ~ toString(n));
			case "o": // object name
				i_objects++;
				break;

// Display/render atributes

			case "bevel": // bevel interpolation
				throw new Exception("not supported element in line " ~ toString(n));
			case "c_interp": // color interpolation
				throw new Exception("not supported element in line " ~ toString(n));
			case "d_interp": // dissolve interpolation
				throw new Exception("not supported element in line " ~ toString(n));
			case "lod": // level of detail
				throw new Exception("not supported element in line " ~ toString(n));
			case "usemtl": // material name
				i_materials++;
				break;
			case "mtllib": // material library
				break;
			case "shadow_obj": // shadow_casting
				throw new Exception("not supported element in line " ~ toString(n));
			case "trace_obj": // ray tracing
				throw new Exception("not supported element in line " ~ toString(n));
			case "ctech": // curve approximation technique
				throw new Exception("not supported element in line " ~ toString(n));
			case "stech": // surface approximation technique
				throw new Exception("not supported element in line " ~ toString(n));

// General

			case "call": // include another file
				throw new Exception("not supported element in line " ~ toString(n));
			case "csh": // executes unix command
				throw new Exception("not supported element in line " ~ toString(n));

			default:
				throw new Exception("unknown element in line " ~ toString(n));
		}
	}

	writefln("done. (%d triangles)", i_triangles);

	scene.objs_offset = face_off+face_i;


	s.close();
}
