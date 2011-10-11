module wrt.scenes.bunnys;

import std.stdio : writefln;

//import std.random : rand;
uint rand() {
	static x = 0;
	return x++;
}


import wrt.objects.a3DObject : a3DObject;

import wrt.Material : Material;

import wrt.objects.Light : Light, PointLight;

import wrt.Scene : Scene;
import wrt.Lights : Lights, lights;

import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;
import wrt.base.rgb : rgb;

import wrt.models.PlyLoader : load_ply_into_scene, load_simpleply_into_scene;

Scene create_scene_bunnys(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();
	scene.objs.length = 100*70000; // preallokacja
	scene.objs_offset = 0;

	scene.ambinet = 0.01f;

	writefln("done.");

	a3DObject temp;

	writefln("Loading scene (objects, materials, textures, procedural objects, and textures)...");

	for (int i = 0; i < 10; i++) {
	for (int j = 0; j < 8; j++) {
	{
	Material plymat = new Material();
	plymat.color = rgb(0.7f, 0.7f, 0.7f);
//	plymat.reflectance = rgb(0.2f, 0.2f, 0.2f);
	plymat.specular = rgb(0.7f, 0.7f, 0.7f);
	plymat.phong_exponent = 30.0f;
//	plymat.refractance = rgb(0.8f, 0.8f, 0.8f); // szklo
//	plymat.texture = new PPMTexture("input_files/textures/marble2_texture.pnm");

//	load_simpleply_into_scene(scene, "input_files/obiekty/bunny.ply", plymat,
	load_ply_into_scene(scene, "input_files/stanford/rozpak/bun_zipper.ply", plymat,
		mat4.translation(vec3((rand() % 20)*0.03f, (rand() % 20)*0.03f, (rand() % 20)*0.3f))*
		mat4.translation(vec3(3.0f*(i-5), 3.0f*(j-5), 0.0f))*
		mat4.translation(vec3(2.0f, 8.0f, 26.0f))*
		mat4.rotation(vec3.X_AXIS, 0.1f+(rand() % 20)*0.03f)*
		mat4.rotation(vec3.Y_AXIS, 3.141592f - 0.6f+(rand() % 20)*0.03f)*
		mat4.rotation(vec3.Z_AXIS, 3.141592f+(rand() % 20)*0.03f)*
		mat4.scale(18.0f));
	}

	}
	}

	writefln("done (%d objects).", scene.count);

	writefln("Loading lights...");

	lights = new Lights();

	Light templ;

	templ = new PointLight(vec3(-10.0f, -6.0f, 1.0f), rgb(10.0, 10.0f, 10.0f));
	lights ~= templ;

	templ = new PointLight(vec3(15.0f, 0.0f, 5.0f), rgb(10.0, 10.0f, 10.0f));
	lights ~= templ;

	templ = new PointLight(vec3(0.0f, -3.0f, -5.0f), rgb(10.0, 10.0f, 10.0f));
	lights ~= templ;

	writefln("done (%d objects).", lights.count);

	return scene;
}
