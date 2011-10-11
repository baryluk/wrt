module wrt.target.ScreenSDL;

import std.stdio : writef, writefln;
import std.string : toStringz;

import derelict.sdl.sdl;

import wrt.base.rgb : rgb;
import wrt.base.vec3 : vec3;
import wrt.base.mat4 : mat4;

import wrt.target.Screen : Screen, Pixel;

final class ScreenSDL : Screen {
	SDL_Surface* screen;

	this(int xsize_ = 640, int ysize_ = 480, float d_ = 1.0f, int bpm_ = 32)
	body {
		super(xsize_, ysize_, d_);

    	// initialize the SDL Derelict module
		DerelictSDL.load();

    	// initialize SDL's VIDEO module
		SDL_Init(SDL_INIT_VIDEO);

	    // create our OpenGL window
		// SDL_FULLSCREEN
		// SDL_HWSURFACE
		screen = SDL_SetVideoMode(xsize_, ysize_, bpm_, SDL_HWSURFACE | SDL_DOUBLEBUF);
		if (screen is null) {
			throw new Error("error setting video mode");
		}
		SDL_WM_SetCaption(toStringz("WRT"), null);

		SDL_ShowCursor(0);
	}

	// be nice and release all resources
	~this() {
		// tell SDL to quit
		SDL_Quit();

		// release SDL's shared lib
		DerelictSDL.unload();
	}

	override void setPixel(int x, int y, rgb k)
	in {
		assert(0 <= x && x < xsize);
		assert(0 <= y && y < ysize);
	}
	body {
		uint color = SDL_MapRGB(screen.format, 
			cast(ubyte)(k.r <= 1.0f ? k.r*255.0f : 255),
			cast(ubyte)(k.g <= 1.0f ? k.g*255.0f : 255),
			cast(ubyte)(k.b <= 1.0f ? k.b*255.0f : 255));
		switch (screen.format.BytesPerPixel) {
			case 4: // Probably 32-bpp
				*(cast(uint*)screen.pixels + y*screen.pitch/4 + x) = color;
				break;
		    case 2: // Probably 15-bpp or 16-bpp
				*(cast(ushort*)screen.pixels + y*screen.pitch/2 + x) = cast(ushort)color;
				break;
		    case 3: // Slow 24-bpp mode, usually not used
				{
				ubyte* bufp = cast(ubyte*)(screen.pixels + y*screen.pitch + x*3);
				if (SDL_BYTEORDER == SDL_LIL_ENDIAN) {
					bufp[0] = cast(ubyte)(color);
					bufp[1] = cast(ubyte)(color >> 8);
					bufp[2] = cast(ubyte)(color >> 16);
				} else {
					bufp[2] = cast(ubyte)(color);
					bufp[1] = cast(ubyte)(color >> 8);
					bufp[0] = cast(ubyte)(color >> 16);
				}
				}
				break;
			case 1: // Assuming 8-bpp
				*(cast(ubyte*)screen.pixels + y*screen.pitch + x) = cast(ubyte)color;
				break;
			default:
				assert(0);
		}
	}

	void slock() {
		if (SDL_MUSTLOCK(screen)) {
			if (SDL_LockSurface(screen) < 0) {
				return;
			}
		}
	}

	void sulock() {
		if (SDL_MUSTLOCK(screen)) {
			SDL_UnlockSurface(screen);
		}
	}

	void flip() {
		SDL_Flip(screen);
	}

	void main_loop(int delegate() dg) {
		static float coef_updown = 0.3f;
		static float coef_leftright = 0.3f;
		static float coef_backforward = 0.3f;
		static float coef_rotx = 0.1f;
		static float coef_roty = 0.1f;
		static float coef_rotxm = 0.01f;
		static float coef_rotym = 0.01f;

		int done = 0;

		while (done == 0) {
			SDL_Event event;

			vec3 move = vec3(0.0f, 0.0f, 0.0f);
			float rotx = 0.0f;
			float roty = 0.0f;

			while (SDL_PollEvent(&event)) {
				switch (event.type) {
					case SDL_QUIT:
						done = 1;
						break;
					case SDL_KEYDOWN:
						if (event.key.keysym.sym == SDLK_ESCAPE) {
							done = 1;
						}
						break;
					case SDL_MOUSEMOTION:
						rotx += coef_rotxm*event.motion.xrel;
						roty -= coef_rotym*event.motion.yrel;
						break;
					case SDL_MOUSEBUTTONDOWN:
//						writefln("Mouse button %d pressed at (%d,%d)\n", event.button.button, event.button.x, event.button.y);
						break;
					default:
						break;
				}
			}

			auto keys = SDL_GetKeyState(null);

			void update_keys_handler() {
				if (keys[SDLK_UP]) { roty += coef_roty; }
				if (keys[SDLK_DOWN]) { roty -= coef_roty; }
				if (keys[SDLK_LEFT]) { rotx -= coef_rotx; }
				if (keys[SDLK_RIGHT]) { rotx += coef_rotx; }

				if (keys[SDLK_w]) { move += coef_backforward*zaxis; }
				if (keys[SDLK_s]) { move -= coef_backforward*zaxis; }
				if (keys[SDLK_a]) { move -= coef_leftright*vec3(zaxis.y, -zaxis.x, 0.0f); }
				if (keys[SDLK_d]) { move += coef_leftright*vec3(zaxis.y, -zaxis.x, 0.0f); }

				if (keys[SDLK_r]) { move.y += coef_updown; }
				if (keys[SDLK_f]) { move.y -= coef_updown; }
			}

			update_keys_handler();

			pos += move;
			zaxis = mat4.rotation(vec3.X_AXIS, roty)*(mat4.rotation(vec3.Y_AXIS, rotx)*zaxis);

			setCamera(pos, zaxis);

			slock();
			dg();
			sulock();

			flip();
		}
	}
}
