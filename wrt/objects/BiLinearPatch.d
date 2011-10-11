module wrt.objects.BiLinearPatch;

import std.math : abs;

import wrt.objects.a3DObject : a3DObject;
import wrt.base.vec3 : vec3;
import wrt.base.rgb : rgb;
import wrt.base.Ray : Ray;

import wrt.base.misc : cross, min, max;

import wrt.base.AABB : AABB;

import wrt.Material : Material;

import std.stdio : writefln, writef;

import wrt.objects.Triangle : vertex;

/*
 * Given a ray o+tv and a patch with vertices p00, p01, p11, and p10 we have
 *
 * o + tv = (1-u)(1-v)p00 + u(1-v)p10 + (1-u)v p01 + uv p11
 *
 * Another possibility is to use Kajiya's old trick. Consider the ray as the intersection of two planes 
 *
 * (p - p0) dot N0 = 0
 * (p - p1) dot N1 = 0
 *
 * If you substitute 
 * p = (1-u)(1-v)p00 + u(1-v)p10 + (1-u)v p01 + uv p11
 *
 * into both the plane equations above then you get two equations in uv of the form:
 * Auv + Bu + Cv + D = 0 (1)
 * auv + bu + cv + d = 0 (2)
 *
 * If you solve one of those for u and then plug it into the other, you get a quadratic in v. That leaves four possibilities of what to do first:
 *
 * solve (1) for u
 * solve (1) for v
 * solve (2) for u
 * solve (2) for v
 *
 * There is also a degree of freedom for which planes to use. In any case seems more stable than the three equations, 2 unknowns method above.
 */

