module wrt.scenes.cat_and_glock;

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

Scene create_scene_cat_and_glock(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();

	scene.ambinet = 0.7f;

	writefln("done.");

	a3DObject temp;

	writefln("Loading scene (objects, materials, textures, procedural objects, and textures)...");


	{
	Material plymat = new Material();
//	plymat.color = rgb(0.7f, 0.7f, 0.7f);
	plymat.color = rgb(0.4f, 0.4f, 0.4f);
//	plymat.reflectance = rgb(0.2f, 0.2f, 0.2f);
	plymat.specular = rgb(0.2f, 0.2f, 0.2f);
	plymat.phong_exponent = 50.0f;

	load_ply_into_scene(scene, "input_files/shapes/rozp/kitten_final.ply", plymat,
		mat4.translation(vec3(1.0f, 5.0f, 20.0f))*
		mat4.rotation(vec3.X_AXIS, 0.1f)*
		mat4.rotation(vec3.Y_AXIS, 3.141592f - 0.6f + frame_number*0.02f)*
		mat4.rotation(vec3.Z_AXIS, 3.141592f)*
		mat4.scale(0.1f));

	load_ply_into_scene(scene, "input_files/shapes/rozp/glock21-.45C.ply", plymat,
		mat4.translation(vec3(-1.0f, 0.0f, 12.0f))*
		mat4.rotation(vec3.X_AXIS, 0.1f)*
		mat4.rotation(vec3.Y_AXIS, 3.141592f - 1.5f + frame_number*0.02f)*
		mat4.rotation(vec3.Z_AXIS, 3.141592f - 0.1f)*
		mat4.scale(0.025f));

	}

	writefln("done (%d objects).", scene.count);

	writefln("Loading lights...");

	lights = new Lights();

	Light templ;

	//templ = new PointLight(vec3(0.0f, -4.0f*(frame_number-50)/25.0f, -2.0f), rgb(20.0, 20.0f, 20.0f));

	templ = new PointLight(vec3(0.0f, -6.0f, -4.0f), rgb(10.0, 10.0f, 10.0f));
	lights ~= templ;

	templ = new PointLight(vec3(-10.0f, -6.0f, 1.0f), rgb(10.0, 10.0f, 10.0f));
	lights ~= templ;

	templ = new PointLight(vec3(15.0f, 0.0f, 5.0f), rgb(10.0, 10.0f, 10.0f));
	lights ~= templ;

	writefln("done (%d objects).", lights.count);

	return scene;
}
