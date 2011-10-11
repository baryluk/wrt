module wrt.scenes.bvhtest;

import std.stdio : writefln;

//import std.random : rand;
uint rand() {
	static x = 0;
	return x++;
}

import wrt.objects.a3DObject : a3DObject;
import wrt.objects.Sphere : Sphere;

import wrt.Material : Material;
import wrt.textures.Texture : Texture;
import wrt.textures.PPMTexture : PPMTexture;
import wrt.textures.PerlinTexture : PerlinTexture, PerlinTexture3D;
import wrt.textures.TextureCompositor : TextureCompositorTruncate, TextureCompositorAffine;

import wrt.objects.Light : Light, PointLight;

import wrt.Scene : Scene;
import wrt.Lights : Lights, lights;

import wrt.base.vec3 : vec3;

Scene create_scene_bvhtest(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();

	writefln("done.");

	a3DObject temp;

	writefln("Loading scene (objects, materials, textures, procedural objects, and textures)...");

	for (int i = 0; i < 1000; i++) {

	for (int j = 0; j < 1000; j++) {

	temp = new Sphere(vec3(0.5f*i + (rand() % 20)*0.03f, 0.5f*j + (rand() % 20)*0.03f, 2.8f+(rand() % 10)*0.3f), 0.2f+(rand() % 10)*0.03f);
	scene ~= temp;

	}
	}

	writefln("done.");

	writefln("Loading lights...");

	lights = new Lights();

	writefln("done (%d objects).", lights.count);

	return scene;
}
