#include "image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"


Image::Image(int w, int h) : width(w), height(h) {
    data.resize(w * h * 3, 0.0f);
}

void Image::addColor(int x, int y, float r, float g, float b, float a)
{
    if(x < 0 || x >= width || y < 0 || y >= height) return;

    int idx = (y * width + x) * 3;

    data[idx + 0] = data[idx + 0] * (1.0f - a) + r * a;
    data[idx + 1] = data[idx + 1] * (1.0f - a) + g * a;
    data[idx + 2] = data[idx + 2] * (1.0f - a) + b * a;
}

void Image::savePNG(const std::string& filename)
{
    std::vector<unsigned char> out(width * height * 3);

    for(int i = 0; i < width * height * 3; i++) {
        float v = data[i];
        v = std::max(0.0f, std::min(1.0f, v));
        out[i] = (unsigned char)(v * 255);
    }

    stbi_write_png(filename.c_str(), width, height, 3, out.data(), width * 3);
}
