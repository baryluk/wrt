module wrt.scenes.balls;

import std.stdio : writefln;
import std.math : sqrt, asin, acos;

//import std.random : rand;

import wrt.objects.a3DObject : a3DObject;
import wrt.objects.Sphere : Sphere;
import wrt.objects.Rectangle : Rectangle;

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
import wrt.base.misc : PI, cross;

Scene create_scene_balls(int frame_number = 0) {
	Scene scene;

	writefln("Creating scene...");

	scene = new Scene();

	scene.ambinet = 0.05f;

	writefln("done.");

	a3DObject temp;

	writefln("Loading scene (objects, materials, textures, procedural objects, and textures)...");

	// prepare
	final float dist = 1.0f/sqrt(2.0f);	
	final vec3 trio_dir[3] = [
		vec3(dist, dist, 0.0f),
		vec3(dist, 0.0f, -dist),
		vec3(0.0, dist, -dist)
	];

	vec3 axis = vec3(1.0, -1.0, 0.0);
	axis.normalize();

	mat4 mx = mat4.rotation(axis, asin(2.0f/sqrt(6.0f)));

	for (int i = 0; i < 3; i++) {
		trio_dir[i] *= mx;
	}

	vec3 objset[9];

	for (int i = 0; i < 3; i++) {
		mx = mat4.rotation(vec3.Z_AXIS, i*2.0f*PI/3.0f+2.0f*cast(float)frame_number*(3.141592f*2.0f/180.0f));
		//mx = mat4.rotation(vec3.Z_AXIS, i*2.0f*PI/3.0f);
		for (int j = 0; j < 3; j++) {
			objset[3*i+j] = mx*trio_dir[j];
		}
	}

	Material tmat = new Material();
	//tmat.color = rgb(0.3f, 0.3f, 0.1f);
	tmat.color = rgb(0.03f, 0.03f, 0.03f);
	tmat.reflectance = rgb(0.9f, 0.9f, 0.9f);
	//tmat.reflectance = rgb(0.3f, 0.3f, 0.3f);
	//tmat.reflectance = rgb(0.2f, 0.2f, 0.2f);
	//tmat.diffusion = rgb(0.4f, 0.2f, 0.1f);
	tmat.specular = rgb(0.8f, 0.8f, 0.8f);
	tmat.phong_exponent = 20.0f;
	//tmat.refractance = rgb(0.1f, 0.1f, 0.1f); // szklo
	//tmat.refractance = rgb(0.5f, 0.5f, 0.5f); // szklo
	//tmat.texture = new PPMTexture("textury/marble1_texture.pnm");
	//tmat.texture = new TextureCompositorTruncate(new PerlinTexture(7131133, rgb(0.2f, 0.1f, 0.6f), 32.0f));
	//tmat.texture = new TextureCompositorTemplate!("4.0f*x")(new PerlinTexture(71311, rgb.RED), 3.0f);

	int ball_count = 0;

	Material tmat2 = new Material();
	//tmat2.color = rgb(0.3f, 0.3f, 0.1f);
	tmat2.color = rgb(0.01f, 0.01f, 0.01f);
	//tmat2.reflectance = rgb(0.8f, 0.8f, 0.8f);
	//tmat2.reflectance = rgb(0.99f, 0.99f, 0.99f);
	//tmat2.reflectance = rgb(0.4f, 0.4f, 0.4f);
	//tmat2.reflectance = rgb(0.1f, 0.1f, 0.1f);
	//tmat2.reflectance = rgb(0.3f, 0.3f, 0.3f);
	//tmat2.reflectance = rgb(0.05f, 0.05f, 0.05f);
	//tmat2.diffusion = rgb(0.4f, 0.2f, 0.1f);
	tmat2.specular = rgb(0.4f, 0.4f, 0.4f);
	tmat2.phong_exponent = 100.0f;
	//tmat2.refractance = rgb(0.1f, 0.1f, 0.1f); // szklo
	//tmat2.refractance = rgb(0.8f, 0.8f, 0.8f); // szklo
	tmat2.texture = new PPMTexture("input_files/textures/marble1_texture.pnm");
	//tmat2.texture = new TextureCompositorTruncate(new PerlinTexture(71311351*ball_count, rgb(0.3f, 0.3f, 0.3f), 64.0f));
	//tmat2.texture = new TextureCompositorTemplate!("4.0f*x")(new PerlinTexture(71311, rgb.RED), 3.0f);


	void output_ball(int depth, vec3 center, vec3 direction, float radius, float direction_w) {
		ball_count++;
		temp = new Sphere(center, radius);


		temp.setMaterial(tmat2);
		
		scene ~= temp;
		if (depth > 0) {
			depth--;

			mat4 mx;

			if (direction.z >= 1.0f) {
				mx = mat4.I;
			} else if (direction.z <= -1.0f) {
				mx = mat4.rotation(vec3.Y_AXIS, PI);
			} else {
				axis = cross(vec3.Z_AXIS, direction);
				axis.normalize();
				mx = mat4.rotation(axis, acos(vec3.Z_AXIS*direction));
			}

			float scale = radius * (1.0f + direction_w);
			for (int i = 0; i < 9; i++) {
				vec3 child_direction = mx*objset[i];
				vec3 child_pt = scale*child_direction + center;
				float child_radius = radius * direction_w;
				float child_direction_w = direction_w;
				output_ball(depth, child_pt, child_direction, child_radius, child_direction_w);
			}
		}
	}


	vec3 center = vec3(0.0f, 0.0f, 1.0f);
	float radius = 4.0f;

// TODO: najpierw zaalokowac duzo miejsca

	output_ball(6, vec3(0.0f, 0.0f, 5.0f), vec3(0.0f, 0.0f, -1.0f), radius/2.0f, 1.0f/3.0f);

	// podloga
	temp = new Rectangle(vec3(-50.0f, 8.0f, 0.0f), vec3(100.0f, 0.0f, 0.0f), vec3(0.0f, 0.0f, 200.0f));
	{
	Material tm = new Material(rgb(4.9f, 4.9f, 4.9f));
	tm.texture = new PPMTexture("input_files/textures/marble1_texture.pnm");
	temp.setMaterial(tm);
	}
	scene ~= temp;

	// sciana
	temp = new Rectangle(vec3(-50.0f, -50.0f, 20.0f), vec3(100.0f, 0.0f, 0.0f), vec3(0.0f, 100.0f, 0.0f));
	{
	Material tm = new Material(rgb(14.9f, 4.9f, 4.9f));
	tm.texture = new TextureCompositorTruncate(new TextureCompositorAffine(new PerlinTexture(71311351, rgb(0.2f, 0.1f, 0.6f), 128.0f), 20.0f));
	//new PPMTexture("input_files/textures/marble1_texture.pnm"), 30.0f));
	temp.setMaterial(tm);
	}
	scene ~= temp;


	writefln("done (%d objects).", scene.count);

	writefln("Loading lights...");

	lights = new Lights();

	Light templ;

	//templ = new PointLight(vec3(0.0f, -4.0f*(frame_number-50)/25.0f, -2.0f), rgb(20.0, 20.0f, 20.0f));
	templ = new PointLight(vec3(0.0f, -4.0f, -2.0f), rgb(10.0, 8.0f, 8.0f));
	lights ~= templ;

	templ = new PointLight(vec3(-10.0f, -6.0f, 1.0f), rgb(10.0, 10.0f, 12.0f));
	lights ~= templ;

	templ = new PointLight(vec3(15.0f, 0.0f, 5.0f), rgb(10.0, 10.0f, 12.0f));
	lights ~= templ;

	writefln("done (%d objects).", lights.count);

	return scene;
}
