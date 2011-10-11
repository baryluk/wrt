module wrt.objects.NURBS;

/** http://www.cs.mtu.edu/~shene/COURSES/cs3621/NOTES/notes.html  */

import std.math;

/* f(u,v) = (x(u,v), y(u,v), z(u,v))
 *
 tangent vectors:
	  d = {\p f \over \p u} = ( {\p x \over \p u}, {\p y \over \p u}, {\p z \over \p u} )
	  e = {\p f \over \p v} = ( {\p x \over \p v}, {\p y \over \p v}, {\p z \over \p v} )
  normal:
	  n = normalized(cross(d,e))
*/

/*
Bezier surfaces:
   p(u,v) = \sum_i^m \sum_j^n B_{m,i}(u) B_{n,j}(v) p_{ij}

Rational Bezier surface
   p(u,v) = \sum_i^m \sum_j^n B_{m,i}(u) B_{n,j}(v) p_{ij} w_{ij} / N(u,v)
 where:
   N(u,v) = \sum_i^m \sum_j^n B_{m,i}(u) B_{n,j}(v) w_{ij}

B-spline Surface: essentially spline formed from Bezier pieces, with proper gluing.
		additionaly have something called knots.

NURBS Surface: Essentially Rational B-Spline Surface with non-uniformity (added knots, as in B-spline)

*/


// Non-uniform rational B-spline Surface
class NURBS_Surface {
	uint m, n; // order_n (u), order_m (v);
	vec3[][] P; // control_points; // (m+1)*(n+1)
	float[][] w; // control_points_weights; // (m+1)*(n+1)
	float[] U; // knot_vector_u; // h+1 values
	float[] V; // knot_vector_v; // k+1 values
	uint p, q; // degrees of B-splines
	bool u_closed, v_closed;

	invariant() {
		assert(U.length == m+p+1);
		assert(V.length == n+q+1);
	}

	/* note: in homogenous cordinates computations can be done essentially without division */

	/** Non-uniform rational Bazier surface - naive implementation (so probably numerically unstable. */
	vec3 get_point_bezier_surface(float u, float v) {
		vec3 point = vec3(0.0f, 0.0f, 0.0f);
version(derivatives) {
		vec3 d = vec3(0.0f, 0.0f, 0.0f);
		vec3 e = vec3(0.0f, 0.0f, 0.0f);
}
		float norm = 0.0;
		foreach (i; 0 .. m+1) {
			float c_u = bernstein_basis(i, p, U, u, 1.0f-u);
version(derivatives) {
			float c_u_deriv = bernstein_basis_deriv(i, p, U, u, 1.0f-u);
}
			foreach (j; 0 .. n+1) {
				float c_v = bernstein_basis(j, q, V, v, 1.0f-v);
version(derivatives) {
				float c_v_deriv = bernstein_basis_deriv(j, q, V, v, 1.0f-v);
}
				float alpha = c_u * c_v;
version(derivatives) {
				float alpha_u = c_u_deriv * c_v;
				float alpha_v = c_u * c_v_deriv;
}
				point += (alpha * w[i][j]) * p[i][j];
version(derivatives) {
				d += (alpha_u * w[i][j]) * p[i][j];
				e += (alpha_v * w[i][j]) * p[i][j];
}
				norm += (alpha * w[i][j]);
version(derivatives) {
				norm_deriv_u += (alpha_u * w[i][j]);
				norm_deriv_v += (alpha_v * w[i][j]);
}
			}
		}
		auto N = (1.0f / norm);
version(derivatives) {
		auto N2 = 1.0f / (norm * norm); // N*N

		//d = N2 * (d * norm + point * norm_deriv_u);
		//d = (d * (N2*norm) + point * (N2*norm_deriv_u));
		d = (d * N + point * (N2*norm_deriv_u));

		//e = N2 * (e * norm + point * norm_deriv_v);
		//e = (e * (N2*norm) + point * (N2*norm_deriv_v));
		e = (e * N + point * (N2*norm_deriv_v));

		vec3 normal = normalize(cross(d,e));
		// TODO: curvature
}
		return (1.0f / norm) * point;
	}


	// Get AABB of NURBS surface
	// If all weights are non-negtive, then we just need to computer AABB of all points in P (convex hull)
	AABB getAABB() {
	}

	// Get AABB of NURBS surface after transforming using matrix O
	// (this function will return an AABB more tight than just aplaying O to AABB returned from getAABB() function).
	AABB getAABB(mat4 O) {
		
	}
}

float b_spline(int i, int n, float[] knots, float x, float c_x) {
	return 1.0;
}

/* Bernstein basis polynomials */
/* TODO: make sure pow(t,0) == 1 for also for t==0 */
float bernstein_basis(int i, int n, float x, float c_x)
in {
	assert(0 <= i);
	assert(i <= n);
	assert(0.0f <= x);
	assert(x <= 1.0f);
	assert(c_x = 1.0f-x);
}
body {
	return binom(i,n)*pow(x,i)*pow(c_x, n-i);
}

float bernstein_basis_deriv(int i, int n, float x, float c_x)
in {
	assert(0 <= i);
	assert(i <= n);
	assert(0.0f <= x);
	assert(x <= 1.0f);
	assert(c_x = 1.0f-x);
}
body {
	/* binom(i,n)*( i*pow(x,i-1)*pow(c_x, n-i) - (n-i)*pow(x,i)*pow(c_x,n-i-1) ); */
	auto a = pow(x, i-1);
	auto b = pow(c_x, n-i-1);
	//return binom(i,n)*(i*a*b*c_x - (n-i)*a*x*b);
	//return binom(i,n)*a*b*(i*c_x - (n-i)*x);
	return binom(i,n)*a*b*(cast(float)i - cast(float)n*x);

	// or return n*(bernstein(i-1, n-1, x) - bernstein(i, n-1, x))
}


/*
 * TODO: write (or port), function for generating interpolating or aproximating bazier surface or b-spline surface from set of 3d points
 * This will be needed if we want to have dynamic point cloud data.
 */

/* automatic knot generation:
     uniform, chord length, centripetal, universal
*/

/* additionaly it would be good to have nurbs curves, b-spline curves, bezier curves and linear and cubic interpolation
 * for example for camera movement.
 */
