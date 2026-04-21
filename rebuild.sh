#!/bin/bash

# --- CONFIGURATION ---
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
TARGET="coqui_mjs"

# 1. Generate Version Hash and Start Timer
VERSION_HASH=$(date +%s | md5 | head -c 7)
LOG_FILE="$LOG_DIR/build_$VERSION_HASH.log"
START_TIME=$(date +%s)

echo "------------------------------------------------"
echo "🛠  BUILDING VERSION: $VERSION_HASH"
echo "📝 Log: $LOG_FILE"
echo "------------------------------------------------"

do_build() {
    # Keep the build folder to let ccache/picotool stay warm
    # but clear the internal CMake cache to ensure fresh flags
    mkdir -p build && cd build
    find . -maxdepth 1 ! -name '_deps' -exec rm -rf {} + 
    
    cmake .. -DCMAKE_BUILD_TYPE=Release
    
    echo "--- Compiling ---"
    make -j$(sysctl -n hw.ncpu)
}

# Execute build and capture all output
do_build 2>&1 | tee "$LOG_FILE"
BUILD_RESULT=${PIPESTATUS[0]}

# 2. Calculate Metrics
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $BUILD_RESULT -eq 0 ]; then
    # Get File Sizes
    ELF_SIZE=$(du -h "build/$TARGET.elf" | cut -f1)
    UF2_SIZE=$(du -h "build/$TARGET.uf2" | cut -f1)
    
    echo "------------------------------------------------"
    echo "✅ BUILD SUCCESSFUL"
    echo "⏱  Time:      ${DURATION}s"
    echo "📦 ELF Size:  ${ELF_SIZE}"
    echo "🚀 UF2 Size:  ${UF2_SIZE}"
    echo "------------------------------------------------"
    echo "👉 UPLOAD COMMAND (via Picotool):"
    echo "sudo picotool load -x build/$TARGET.uf2"
    echo "------------------------------------------------"
    echo "👉 SERIAL COMMAND (macOS):"
    echo "screen /dev/tty.usbmodem* 115200"
    echo "------------------------------------------------"
else
    echo "------------------------------------------------"
    echo "❌ BUILD FAILED in ${DURATION}s"
    echo "Check $LOG_FILE"
    echo "------------------------------------------------"
fi