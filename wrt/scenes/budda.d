module wrt.scenes.budda;

import std.stdio : writefln;

import wrt.objects.a3DObject : a3DObject;

import wrt.Material : Material;

import wrt.objects.Light : Light, PointLight;

import wrt.Scene : Scene;
import wrt.Lights : Lights, lights;

import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;
import wrt.base.rgb : rgb;

import wrt.models.PlyLoader : load_ply_into_scene, load_simpleply_into_scene;

Scene create_scene_budda(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();

	scene.ambinet = 0.01f;

	writefln("done.");

	a3DObject temp;

	writefln("Loading scene (objects, materials, textures, procedural objects, and textures)...");

	{
	Material plymat = new Material();
	plymat.color = rgb(0.7f, 0.7f, 0.7f);
//	plymat.reflectance = rgb(0.2f, 0.2f, 0.2f);
	plymat.specular = rgb(0.7f, 0.7f, 0.7f);
	plymat.phong_exponent = 30.0f;
//	plymat.refractance = rgb(0.8f, 0.8f, 0.8f); // szklo
//	plymat.texture = new PPMTexture("input_files/textures/marble2_texture.pnm");

	load_ply_into_scene(scene, "input_files/stanford/rozpak/happy.ply", plymat,
		mat4.translation(vec3(0.0f, 9.0f, 22.0f))*
		mat4.rotation(vec3.X_AXIS, 0.1f)*
		mat4.rotation(vec3.Y_AXIS, 3.141592f - 0.6f + frame_number*0.05f)*
		mat4.rotation(vec3.Z_AXIS, 3.141592f)*
		mat4.scale(60.0f));
	}

	writefln("done (%d objects).", scene.count);

	writefln("Loading lights...");

	lights = new Lights();

	Light templ;

	templ = new PointLight(vec3(-10.0f, -6.0f, 1.0f), rgb(11.0, 10.0f, 10.0f));
	lights ~= templ;

	templ = new PointLight(vec3(15.0f, 0.0f, 5.0f), rgb(10.0, 10.0f, 11.0f));
	lights ~= templ;

	templ = new PointLight(vec3(0.0f, -3.0f, -5.0f), rgb(10.0, 9.0f, 9.0f));
	lights ~= templ;

	writefln("done (%d objects).", lights.count);

	return scene;
}
