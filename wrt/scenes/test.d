module wrt.scenes.test;

import std.stdio : writef, writefln;
import std.math : cos, sin;

import wrt.objects.a3DObject : a3DObject;
import wrt.objects.Sphere : Sphere;
import wrt.objects.Rectangle : Rectangle;
import wrt.objects.Triangle : Triangle;

import wrt.Material : Material;
import wrt.textures.Texture : Texture;
import wrt.textures.PPMTexture : PPMTexture;

import wrt.objects.Light : Light, PointLight;

import wrt.Scene : Scene;
import wrt.Lights : Lights, lights;

import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;
import wrt.base.rgb : rgb;
import wrt.base.misc : cross, PI;


Scene create_scene_test(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();

	writefln("done.");

	a3DObject temp;

	writefln("Loading scene (objects, materials, textures, procedural objects, and textures)...");

/*
	temp = new Sphere(vec3(-1.0f, -1.0f, 40.0f), 0.5f);
	temp.getMaterial().reflectance = rgb(0.5f, 0.5f, 0.5f); // lustro+szklo
	temp.getMaterial().refractance = rgb(0.5f, 0.5f, 0.5f);
	scene ~= temp;
*/
/*
	temp = new Sphere(vec3(-4.0f, -2.5f, 34.0f), 15.0f);
	temp.getMaterial().color = rgb(0.0f, 0.2f, 0.0f);
	temp.getMaterial().reflectance = rgb(0.98f, 0.98f, 0.98f); // lustro
	temp.getMaterial().refractance = rgb(0.02f, 0.02f, 0.02f);
	temp.getMaterial().specular = rgb(0.8f, 0.8f, 0.8f);
	temp.getMaterial().phong_exponent = 30.0f;
	scene ~= temp;
*/
	temp = new Sphere(vec3(-0.1f, 0.2f, 0.1f), 0.3f);
	{
	Material tm = new Material(rgb(0.3f, 0.3f, 0.3f));
	tm.reflectance = rgb(0.02f, 0.02f, 0.02f);
	tm.refractance = rgb(0.98f, 0.98f, 0.98f); // szklo
	tm.specular = rgb(0.8f, 0.8f, 0.8f);
	tm.phong_exponent = 30.0f;
	temp.setMaterial(tm);
	}
	scene ~= temp;

	temp = new Sphere(vec3(0.1f, -0.4f, 0.15f), 0.3f);
	{
	Material tm = new Material(rgb(0.4f, 0.4f, 0.4f));
	tm.reflectance = rgb(0.05f, 0.05f, 0.05f);
	tm.refractance = rgb(0.98f, 0.98f, 0.98f); // szklo
	tm.specular = rgb(0.8f, 0.8f, 0.8f);
	tm.phong_exponent = 30.0f;
	temp.setMaterial(tm);
	}
	scene ~= temp;

	temp = new Sphere(vec3(0.4f, -0.7f, 2.8f), 0.4f);
	{
	Material tm = new Material(rgb(1.0f, 0.0f, 0.0f));
	tm.specular = rgb(0.8f, 0.8f, 0.8f);
	tm.phong_exponent = 30.0f;
	temp.setMaterial(tm);
	}
	scene ~= temp;

	temp = new Sphere(vec3(0.4f, 0.2f, 0.7f), 0.1f);
	{
	Material tm = new Material(rgb(1.0f, 0.0f, 0.0f));
	tm.specular = rgb(0.8f, 0.8f, 0.8f);
	tm.phong_exponent = 30.0f;
	temp.setMaterial(tm);
	}
	scene ~= temp;

	temp = new Sphere(vec3(0.5f, 0.8f, 1.0f), 0.3f);
	{
	Material tm = new Material(rgb(1.0f, 0.8f, 0.0f));
	tm.specular = rgb(0.8f, 0.8f, 0.8f);
	tm.phong_exponent = 30.0f;
	temp.setMaterial(tm);
	}
	scene ~= temp;

	temp = new Sphere(vec3(-0.5f, 0.8f, 1.0f), 0.3f);
	{
	Material tm = new Material(rgb(1.0f, 0.8f, 0.0f));
	tm.specular = rgb(0.8f, 0.8f, 0.8f);
	tm.phong_exponent = 30.0f;
	temp.setMaterial(tm);
	}
	scene ~= temp;

	temp = new Sphere(vec3(-0.5f, -0.8f, 1.0f), 0.3f);
	{
	Material tm = new Material(rgb(1.0f, 0.8f, 0.0f));
	tm.specular = rgb(0.8f, 0.8f, 0.8f);
	tm.phong_exponent = 30.0f;
	temp.setMaterial(tm);
	}
	scene ~= temp;

	for (int i = 0; i < 20; i++) {
		temp = new Sphere(vec3(-2.0f*sin(i/20.0f * 2.0f*PI), -2.0f*cos(i/20.0f * 2.0f*PI), 2.0f), 0.2f);
		{
		Material tm = new Material(rgb(1.0f, 0.8f*(i/20.0f), 8.0f*(1.0f-i/20.0f)));
		tm.specular = rgb(0.8f, 0.8f, 0.8f);
		tm.phong_exponent = 30.0f;
		temp.setMaterial(tm);
		}
		scene ~= temp;
		
	}

	for (int i = 0; i < 20; i++) {
		temp = new Sphere(vec3(-2.5f*sin(i/20.0f * 2.0f*PI), -2.5f*cos(i/20.0f * 2.0f*PI), 1.5f), 0.2f);
		{
		Material tm = new Material(rgb((1-i/20.0f)*0.8f, 0.8f*(i/20.0f), 8.0f*(0.5f+i/40.0f)));
		tm.specular = rgb(0.8f, 0.8f, 0.8f);
		tm.phong_exponent = 30.0f;
		temp.setMaterial(tm);
		}
		scene ~= temp;
	}

	for (int i = 0; i < 20; i++) {
		temp = new Sphere(vec3(-2.5f*sin(i/20.0f * 2.0f*PI), -2.5f*cos(i/20.0f * 2.0f*PI), 1.5f), 0.2f);
		{
		Material tm = new Material(rgb((1-i/20.0f)*0.8f, 0.8f*(i/20.0f), 8.0f*(0.5f+i/40.0f)));
		tm.specular = rgb(0.8f, 0.8f, 0.8f);
		tm.phong_exponent = 30.0f;
		temp.setMaterial(tm);
		}
		scene ~= temp;
	}

	for (int i = 0; i < 20; i++) {
		temp = new Sphere(vec3(-1.0f*(1.0f+0.1f*i)*sin(i/20.0f * 2.0f*PI), -1.0f*(1.0f+0.1f*i)*cos(i/20.0f * 2.0f*PI), 2.0f*(1.0f+0.1f*i)), 0.2f);
		{
		Material tm = new Material(rgb((i/20.0f)*0.8f, 0.8f, 8.0f*(1.0f-i/20.0f)));
		tm.specular = rgb(0.8f, 0.8f, 0.8f);
		tm.phong_exponent = 30.0f;
		temp.setMaterial(tm);
		}
		scene ~= temp;
	}


	Texture[char[]] textures;
	textures["texture2.ppm"] = new PPMTexture("input_files/textures/texture2.ppm"); // tekstura

	temp = new Rectangle(vec3(-0.5f, -0.6f, 5.0f), vec3(3.0f, 0.0f, 0.0f), vec3(0.0f, 5.0f, 0.0f));
	temp.setMaterial(new Material(textures["texture2.ppm"]));
	scene ~= temp;

	temp = new Rectangle(vec3(-0.5f, -0.6f, 5.0f), vec3(3.0f, 0.0f, 0.0f), vec3(0.0f, 5.0f, 0.0f));
	temp.setMaterial(new Material(textures["texture2.ppm"]));
	scene ~= temp;

	// podloga
	temp = new Rectangle(vec3(-10.0f, 5.0f, -0.0f), vec3(20.0f, 0.0f, 0.0f), vec3(0.0f, 0.0f, 100.0f));
	temp.setMaterial(new Material(rgb(4.9f, 4.9f, 4.9f)));
	scene ~= temp;

	writefln("done.");

	writefln("Loading lights...");

	lights = new Lights();

/*
	temp = new Sphere(vec3(-0.3f, -1.0f, 3.0f), 0.2f);
	tm.emittance = rgb(1.0f, 1.0f, 1.0f); // red light
	scene ~= temp;

	temp = new Sphere(vec3(3.0f, 0.0f, -1.5f), 0.2f);
	tm.emittance = rgb(1.0f, 1.0f, 0.0f); // red light
	scene ~= temp;
*/

	Light templ;

	templ = new PointLight(vec3(0.0f, -4.0f, -2.0f), rgb(2.0, 2.0f, 2.0f));
	lights ~= templ;

	templ = new PointLight(vec3(15.0f, 0.0f, 5.0f), rgb(23.0, 20.0f, 20.0f));
	lights ~= templ;

	writefln("done (%d objects).", lights.count);

	return scene;
}
