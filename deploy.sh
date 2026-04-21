#!/bin/bash

# --- CONFIGURATION ---
TARGET="coqui_mjs"
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# Function to handle the actual build process
perform_build() {
    VERSION_HASH=$(date +%s | md5 | head -c 7)
    LOG_FILE="$LOG_DIR/build_$VERSION_HASH.log"
    
    echo "------------------------------------------------"
    echo "🛠  BUILDING: $VERSION_HASH"
    echo "------------------------------------------------"
    
    START_TIME=$(date +%s)
    
    mkdir -p build && cd build
    # Clean everything except dependencies to keep it fast
    find . -maxdepth 1 ! -name '_deps' -exec rm -rf {} + 
    
    cmake .. -DCMAKE_BUILD_TYPE=Release 2>&1 | tee -a "../$LOG_FILE"
    make -j$(sysctl -n hw.ncpu) 2>&1 | tee -a "../$LOG_FILE"
    
    BUILD_EXIT=${PIPESTATUS[0]}
    cd ..

    if [ $BUILD_EXIT -ne 0 ]; then
        echo "❌ BUILD FAILED. Check $LOG_FILE"
        return 1
    else
        DURATION=$(( $(date +%s) - START_TIME ))
        echo "✅ BUILD SUCCESSFUL (${DURATION}s)"
        return 0
    fi
}

# Function to handle the flashing process
perform_flash() {
    DEST=$(ls -d /Volumes/RPI-RP2 2>/dev/null)
    if [ -z "$DEST" ]; then
        echo "⚠️  PICO NOT FOUND! (Hold BOOTSEL while plugging in)"
        return 1
    else
        echo "🚀 Flashing build/$TARGET.uf2 to $DEST..."
        cp "build/$TARGET.uf2" "$DEST/"
        echo "✅ FLASH COMPLETE. Pico is rebooting."
        return 0
    fi
}

# Initial Build
perform_build

# --- INTERACTIVE LOOP ---
while true; do
    echo ""
    echo "================================================"
    echo "  COQUI-RUNTIME COMMAND CENTER"
    echo "================================================"
    echo " 1) Flash Existing Build"
    echo " 2) Rebuild Only"
    echo " 3) Zip for Distribution"
    echo " 4) [QUICK] Rebuild AND Flash"
    echo " 5) Exit"
    echo "================================================"
    read -p "Select option: " opt

    case $opt in
        1)
            perform_flash
            ;;
        2)
            perform_build
            ;;
        3)
            ZIP_NAME="dist_${TARGET}_$(date +%Y%m%d_%H%M).zip"
            zip -j "$ZIP_NAME" "build/$TARGET.uf2" "build/$TARGET.elf"
            echo "📦 Created $ZIP_NAME"
            ;;
        4)
            if perform_build; then
                # Small delay to give you time to hold the button if needed
                sleep 1
                perform_flash
            fi
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done