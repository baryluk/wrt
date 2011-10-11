module wrt.scenes.bunny;

import std.stdio : writefln;

import wrt.objects.a3DObject : a3DObject;

import wrt.Material : Material;
import wrt.textures.Texture : Texture;
import wrt.textures.PPMTexture : PPMTexture;
import wrt.textures.PerlinTexture : PerlinTexture, PerlinTexture3D;
import wrt.textures.TextureCompositor : TextureCompositorTruncate, TextureCompositorAffine;

import wrt.objects.Light : Light, PointLight;

import wrt.Scene : Scene;
import wrt.Lights : Lights, lights;

import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;
import wrt.base.rgb : rgb;

import wrt.models.PlyLoader : load_ply_into_scene, load_simpleply_into_scene;

Scene create_scene_bunny(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();

	scene.ambinet = 0.7f;

	writefln("done.");

	a3DObject temp;

	writefln("Loading scene (objects, materials, textures, procedural objects, and textures)...");

	Material tmat = new Material();
	tmat.color = rgb(0.0f, 0.0f, 0.01f);
//	tmat.reflectance = rgb(0.2f, 0.2f, 0.2f);
	tmat.specular = rgb(0.8f, 0.8f, 0.8f);
	tmat.phong_exponent = 20.0f;
	tmat.refractance = rgb(0.8f, 0.8f, 0.8f); // szklo
	tmat.texture = new PPMTexture("input_files/textures/marble2_texture.pnm");

/*
	temp = new Triangle(vertex.fromvec3(vec3(-1.0f, -1.0f, 4.0f), 0.0f, 0.0f),
						vertex.fromvec3(vec3(-1.0f, 2.0f, 4.0f), 1.0f, 0.0f),
						vertex.fromvec3(vec3(2.0f, 2.0f, 4.0f), 0.0f, 1.0f),
						true
						);
	temp.setMaterial(tmat);
	scene ~= temp;

	tmat = new Material();
	tmat.color = rgb(0.0f, 0.0f, 0.01f);
//	tmat.reflectance = rgb(0.2f, 0.2f, 0.2f);
	tmat.specular = rgb(0.8f, 0.8f, 0.8f);
	tmat.phong_exponent = 20.0f;
//	tmat.refractance = rgb(0.8f, 0.8f, 0.8f); // szklo
	tmat.texture = new PPMTextureBilinear("textury/marble1_texture.pnm");

	temp = new Triangle(vertex.fromvec3(vec3(-2.5f, -2.5f, 4.0f), 0.0f, 0.0f),
						vertex.fromvec3(vec3(-3.0f, -1.0f, 3.0f), 1.0f, 0.0f),
						vertex.fromvec3(vec3(3.0f, 2.0f, 3.0f), 0.0f, 1.0f),
						true
						);
	temp.setMaterial(tmat);
	scene ~= temp;

	temp = new Triangle(vertex.fromvec3(vec3(-1.5f, 0.0f, 1.0f), 0.0f, 0.0f),
						vertex.fromvec3(vec3(-1.5f, 1.0f, 1.0f), 0.05f, 0.0f),
						vertex.fromvec3(vec3(0.0f, 1.0f, 2.0f), 0.0f, 0.05f),
						true
						);
	temp.setMaterial(tmat);
	scene ~= temp;

*/

	{
	Material plymat = new Material();
//	plymat.color = rgb(0.7f, 0.7f, 0.7f);
	plymat.color = rgb(0.4f, 0.4f, 0.4f);
//	plymat.reflectance = rgb(0.2f, 0.2f, 0.2f);
	plymat.specular = rgb(0.2f, 0.2f, 0.2f);
	plymat.phong_exponent = 50.0f;
//	plymat.refractance = rgb(0.9f, 0.9f, 0.9f); // szklo
//	plymat.texture = new PPMTexture("input_files/textures/marble2_texture.pnm");
//	plymat.texture3D = new PerlinTexture3D(18471131, rgb(0.8f, 0.1f, 0.2f), 8.0f);
//	plymat.texture3D = new PerlinTexture3D(71311351, rgb(0.4f, 0.15f, 0.5f), 4.0f);

//	plymat.texture3D = new PerlinTexture3D(71311351, rgb(0.5f, 0.5f, 0.5f), 8.0f);
// wood
	//plymat.texture3D = new PerlinTexture3D(71311351, rgb(0.42f, 0.32f, 0.26f), 2.0f);

//	load_simpleply_into_scene(scene, "input_files/obiekty/bunny.ply", plymat,

	load_ply_into_scene(scene, "input_files/stanford/rozpak/bun_zipper.ply", plymat,
		mat4.translation(vec3(1.0f, 5.0f, 8.0f))*
		mat4.rotation(vec3.X_AXIS, 0.1f)*
		mat4.rotation(vec3.Y_AXIS, 3.141592f - 0.6f + frame_number*0.02f)*
		mat4.rotation(vec3.Z_AXIS, 3.141592f)*
		mat4.scale(50.0f));
	}



/++
	// podloga
	temp = new Rectangle(vec3(-50.0f, 8.0f, 0.0f), vec3(100.0f, 0.0f, 0.0f), vec3(0.0f, 0.0f, 200.0f));
	tm.color = rgb(0.9f, 0.9f, 0.9f);
//	tm.texture = new PPMTexture("input_files/textures/marble1_texture.pnm");
	scene ~= temp;
++/

/++
	// sciana
	temp = new Rectangle(vec3(-50.0f, -50.0f, 30.0f), vec3(100.0f, 0.0f, 0.0f), vec3(0.0f, 100.0f, 0.0f));
	{
	Material tm = new Material();
	//tm.color = rgb(0.9f, 0.9f, 0.9f);
	tm.texture = new TextureCompositorTruncate(new TextureCompositorAffine(new PerlinTexture(71311351, rgb(0.2f, 0.1f, 0.6f), 128.0f), 20.0f));
	tm.texture = new PPMTexture("input_files/textures/marble1_texture.pnm");
	temp.setMaterial(tm);
	}
	scene ~= temp;
++/

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
