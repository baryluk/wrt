module wrt.scenes.sponza;

import std.stdio : writefln;

import wrt.objects.a3DObject : a3DObject;

import wrt.Material : Material;

import wrt.objects.Light : Light, PointLight;

import wrt.Scene : Scene;
import wrt.Lights : Lights, lights;

import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;
import wrt.base.rgb : rgb;

import wrt.models.ObjLoader : load_obj_into_scene;

Scene create_scene_sponza(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();

	scene.ambinet = 0.2f;

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

//	load_obj_into_scene(scene, "input_files/sponza/sponza_obj/sponza.obj");
	load_obj_into_scene(scene, "input_files/sponza_arauna/sponza_clean.obj", plymat,
//	load_obj_into_scene(scene, "input_files/sponza_arauna/refrtest.obj", plymat,
		mat4.scale_xyz(1.0f, 1.0f, 1.0f)
		);
	writefln("done (%d objects).", scene.count);
	}

	writefln("Loading lights...");

	lights = new Lights();

	Light templ;

	templ = new PointLight(vec3(-10.0f + frame_number*0.1f, -6.0f, 1.0f), rgb(11.0, 10.0f, 10.0f));
	templ = new PointLight(vec3(0.0f, -8.0f, 0.0f), rgb(5.0, 5.0f, 5.0f));
	templ = new PointLight(vec3(0.0f, 8.0f, 0.0f), rgb(5.0, 5.0f, 5.0f));
	templ = new PointLight(vec3(2.0f, 8.0f, -2.0f), rgb(5.0, 5.0f, 5.0f));
	templ = new PointLight(vec3(2.0f, 8.0f, 2.0f), rgb(5.0, 5.0f, 5.0f));
	templ = new PointLight(vec3(-2.0f, 8.0f, 0.0f), rgb(5.0, 5.0f, 5.0f));
	templ = new PointLight(vec3(2.0f, 8.0f, 2.0f), rgb(5.0, 5.0f, 5.0f));
	templ = new PointLight(vec3(-2.0f, 8.0f, 0.0f), rgb(5.0, 5.0f, 5.0f));
	lights ~= templ;

	writefln("done (%d objects).", lights.count);

	return scene;
}
