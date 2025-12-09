#pragma once
#include <vector>
#include <string>

struct Image {
    int width, height;
    std::vector<float> data;

    Image(int w, int h);
    void addColor(int x, int y, float r, float g, float b, float a);
    void savePNG(const std::string& filename);
};
