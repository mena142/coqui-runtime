#!/bin/bash

# --- 🐸 COHOBA COLORS ---
C_MAIN="\033[38;2;73;193;209m"
C_ACCENT="\033[38;2;234;35;124m"
NC="\033[0m"

echo -e "${C_MAIN}Searching for coquiOS device...${NC}"

# 1. Find the device
DEVICE=$(ls /dev/tty.usbmodem* 2>/dev/null | head -n 1)

if [ -z "$DEVICE" ]; then
    echo -e "${C_ACCENT}❌ No Pico found! Check your USB cable.${NC}"
    exit 1
fi

echo -e "${C_MAIN}Found device at: ${C_ACCENT}$DEVICE${NC}"
echo -e "${C_MAIN}Triggering BOOTSEL via Minicom (1200 baud)...${NC}"

# 2. Create a temporary minicom "runscript" to exit immediately
# This ensures minicom doesn't hang open.
echo "! killall -9 minicom" > /tmp/minicom_exit.run
echo "expect \"\"" >> /tmp/minicom_exit.run
echo "exit" >> /tmp/minicom_exit.run

# 3. Launch minicom at 1200 baud, run the exit script, and shut down
# -D: Device, -b: Baud, -S: Runscript, -C: Capture (optional)
minicom -D "$DEVICE" -b 1200 -S /tmp/minicom_exit.run > /dev/null 2>&1

echo -e "${C_MAIN}Waiting for RPI-RP2 drive to mount...${NC}"

# 4. Wait for macOS to mount the volume
ITER=0
while [ ! -d "/Volumes/RPI-RP2" ] && [ $ITER -lt 10 ]; do
    sleep 0.8
    ((ITER++))
    echo -ne "${C_ACCENT}.${NC}"
done

echo -e "" # New line after the dots

if [ -d "/Volumes/RPI-RP2" ]; then
    echo -e "${C_MAIN}✅ Success! Drive is ready at ${C_ACCENT}/Volumes/RPI-RP2${NC}"
    rm /tmp/minicom_exit.run
else
    echo -e "${C_ACCENT}❌ Failed to mount. Try the physical button if code is hung.${NC}"
    rm /tmp/minicom_exit.run
    exit 1
fi