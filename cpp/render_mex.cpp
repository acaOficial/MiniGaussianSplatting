#include "mex.h"
#include <vector>
#include <cmath>
#include <algorithm>

// ------------------------------------
// Estructura de Gaussiana
// ------------------------------------
struct Gaussian {
    float x, y, z;
    float scale;
    float r, g, b;
    float opacity;
};

// ------------------------------------
// Estructura de Cámara
// ------------------------------------
struct Camera {
    float K[9];
    float R[9];
    float t[3];
    int width;
    int height;
};

// ------------------------------------
// Proyección 3D → 2D
// ------------------------------------
inline void projectPoint(const Gaussian& g, const Camera& cam,
                         float& u, float& v, float& Zc)
{
    float Xc = cam.R[0]*g.x + cam.R[1]*g.y + cam.R[2]*g.z + cam.t[0];
    float Yc = cam.R[3]*g.x + cam.R[4]*g.y + cam.R[5]*g.z + cam.t[1];
         Zc = cam.R[6]*g.x + cam.R[7]*g.y + cam.R[8]*g.z + cam.t[2];

    if (Zc <= 0) {
        u = v = -1e9;
        return;
    }

    float fx = cam.K[0];   // K(1,1)
    float fy = cam.K[4];   // K(2,2)
    float cx = cam.K[6];   // K(1,3)
    float cy = cam.K[7];   // K(2,3)

    // Convertimos a coordenadas 0-based para rasterización
    u = fx * (Xc / Zc) + cx - 1.0f;
    v = fy * (Yc / Zc) + cy - 1.0f;


}

// ------------------------------------
// MEX ENTRY POINT
// ------------------------------------
void mexFunction(int nlhs, mxArray* plhs[],
                 int nrhs, const mxArray* prhs[])
{
    if (nrhs != 6) {
        mexErrMsgIdAndTxt("render_mex:args",
            "Se requieren 6 argumentos: gaussians, K, R, t, width, height");
    }

    // -------------------------
    // Leemos las gaussianas
    // -------------------------
    const mxArray* Gmat = prhs[0];
    int N = mxGetM(Gmat);
    if (mxGetN(Gmat) != 8)
        mexErrMsgIdAndTxt("render_mex:gaussians",
            "La matriz de gaussianas debe ser Nx8");

    double* Gptr = mxGetPr(Gmat);
    std::vector<Gaussian> G(N);

    for (int i = 0; i < N; i++) {
        G[i].x       = Gptr[i + 0*N];
        G[i].y       = Gptr[i + 1*N];
        G[i].z       = Gptr[i + 2*N];
        G[i].scale   = Gptr[i + 3*N];
        G[i].r       = Gptr[i + 4*N];
        G[i].g       = Gptr[i + 5*N];
        G[i].b       = Gptr[i + 6*N];
        G[i].opacity = Gptr[i + 7*N];
    }

    // -------------------------
    // Cámara
    // -------------------------
    Camera cam;

    double* Kptr = mxGetPr(prhs[1]);
    for (int i = 0; i < 9; i++) cam.K[i] = Kptr[i];

    double* Rptr = mxGetPr(prhs[2]);
    for (int i = 0; i < 9; i++) cam.R[i] = Rptr[i];

    double* tptr = mxGetPr(prhs[3]);
    cam.t[0] = tptr[0];
    cam.t[1] = tptr[1];
    cam.t[2] = tptr[2];

    cam.width  = (int) mxGetScalar(prhs[4]);
    cam.height = (int) mxGetScalar(prhs[5]);

    // -------------------------
    // Crear imagen Matlab H×W×3
    // -------------------------
    mwSize dims[3] = { (mwSize)cam.height, (mwSize)cam.width, (mwSize)3 };
    plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    double* img = mxGetPr(plhs[0]);

    auto addColor = [&](int x, int y, float r, float g, float b, float a)
    {
        if(x < 0 || x >= cam.width || y < 0 || y >= cam.height) return;

        mwSize idxR = y + cam.height*(x + cam.width*0);
        mwSize idxG = y + cam.height*(x + cam.width*1);
        mwSize idxB = y + cam.height*(x + cam.width*2);

        img[idxR] = img[idxR] * (1.0 - a) + r * a;
        img[idxG] = img[idxG] * (1.0 - a) + g * a;
        img[idxB] = img[idxB] * (1.0 - a) + b * a;
    };

    // -------------------------
    // Rasterización
    // -------------------------

    std::sort(G.begin(), G.end(),
          [](const Gaussian& a, const Gaussian& b) {
              return a.z > b.z; // back-to-front
          });
          
    for (const auto& g : G)
    {
        float u, v, Zc;
        projectPoint(g, cam, u, v, Zc);
        if (Zc <= 0) continue;

        // sigma correcto (tamaño aparente en pantalla)
        float fx = cam.K[0];
        float sigma = g.scale * (fx / Zc);

        // 3 sigmas → 99.7%
        int radius = std::max(1, (int)std::ceil(3.0f * sigma));

        int xmin = std::max(0, (int)(u - radius));
        int xmax = std::min(cam.width - 1, (int)(u + radius));
        int ymin = std::max(0, (int)(v - radius));
        int ymax = std::min(cam.height - 1, (int)(v + radius));

        for (int y = ymin; y <= ymax; y++) {
            for (int x = xmin; x <= xmax; x++) {

                float dx = x - u;
                float dy = y - v;

                // MANTENER EL sigma BUENO
                float w = std::exp(-(dx*dx + dy*dy) / (2*sigma*sigma));

                float a = w * g.opacity;

                addColor(x, y, g.r, g.g, g.b, a);
            }
        }
    }
}
