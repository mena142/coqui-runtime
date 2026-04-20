#!/bin/bash
echo "=== Coqui MicroQuickJS Rebuild ==="

rm -rf build
mkdir -p build
cd build

cmake .. -DCMAKE_BUILD_TYPE=Release

if [ $? -ne 0 ]; then
    echo "❌ CMake failed!"
    exit 1
fi

make -j4

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "UF2 file: build/coqui_mjs.uf2"
    echo ""
    echo "Now put your Pico in BOOTSEL mode and copy the .uf2 to it."
else
    echo "❌ Build failed!"
fi
