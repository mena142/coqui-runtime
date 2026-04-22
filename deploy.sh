#!/bin/bash

# --- 🐸 COHOBA BRAND COLORS ---
C_MAIN="\033[38;2;73;193;209m"    # #49c1d1 (Teal)
C_ACCENT="\033[38;2;234;35;124m"  # #ea237c (Pink)
C_COMP="\033[38;2;247;189;14m"    # #f7bd0e (Yellow)
C_GRAY="\033[38;5;244m"           # Gray
C_TEXT="\033[38;2;49;74;97m"      # Dark Text
C_BOLD="\033[1m"
NC="\033[0m"

# --- CONFIG ---
TARGET="coqui_mjs"
VERSION="0.9.12-stable"
IP_ADDR=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
STATUS="🟢 READY"
TEMP_VAL="--"
IS_HALTED=0

# --- TMUX ORCHESTRATION ---
if [ -z "$TMUX" ]; then
    tmux kill-server 2>/dev/null
    sleep 1
    tmux new-session -d -s coqui_dev
    tmux split-window -h -p 45
    
    # Left Pane: Serial Monitor
    tmux send-keys -t coqui_dev:0.0 "clear && while true; do for p in /dev/tty.usbmodem*; do if [ -e \"\$p\" ]; then minicom -D \"\$p\" -b 115200; fi; done; sleep 2; done" C-m
    
    # Right Pane: The Menu
    tmux send-keys -t coqui_dev:0.1 "export IN_TMUX=1; ./deploy.sh" C-m
    tmux attach-session -t coqui_dev
    exit 0
fi

trap 'tmux kill-server; exit' SIGINT

# --- UI COMPONENTS ---
draw_header() {
    clear
    echo -e "   ${C_MAIN}▄████▄${NC}"
    echo -e "  ${C_MAIN}██${C_ACCENT}█${C_MAIN}██${C_ACCENT}█${C_MAIN}██    ${C_BOLD}${C_MAIN}Welcome to coquiOS v$VERSION${NC}"
    echo -e "  ${C_MAIN}████████    ${C_TEXT}Hardware-JS Environment${NC}"
    echo -e " ${C_COMP}▄${C_MAIN}██${C_COMP}▄${C_MAIN}██${C_COMP}▄${C_MAIN}██${C_COMP}▄   ${C_COMP}Published by Cohoba Digital${NC}"
    echo -e " ${C_ACCENT}█${C_MAIN}██${C_ACCENT}█${C_MAIN}██${C_ACCENT}█${C_MAIN}██${C_ACCENT}█   ${C_GRAY}https://cohoba.digital${NC}"
    echo -e "              ${C_GRAY}IP: ${C_COMP}${IP_ADDR:-DISCONNECTED}${NC}"
}

draw_divider() {
    echo -e "\n${C_GRAY}==== ${C_TEXT}[ $1 ] ${C_MAIN}========================================${NC}\n"
}

draw_dashboard() {
    draw_header
    
    draw_divider "SYSTEM"
    echo -e "  ${C_TEXT}CHIP:      ${C_MAIN}RP2040${NC} | ${C_ACCENT}Dual-Core ARM Cortex-M0+${NC}"
    echo -e "  ${C_TEXT}SPEED:     ${C_COMP}133MHz${NC} | ${C_TEXT}RAM: ${C_MAIN}264KB${NC} | ${C_TEXT}QSPI: ${C_MAIN}16MB${NC}"
    echo -e "  ${C_TEXT}STATUS:    ${C_ACCENT}${STATUS}${NC}   ${C_TEXT}TEMP: ${C_COMP}${TEMP_VAL}°C${NC}"
    
    if [ -f "build/$TARGET.bin" ]; then
        SIZE=$(stat -f%z "build/$TARGET.bin")
        PER=$(( (SIZE * 100) / 16777216 ))
        BAR_W=$((PER / 5)); BAR=$(printf '█%.0s' $(seq 1 $BAR_W)); EMPTY=$(printf '░%.0s' $(seq 1 $((20 - BAR_W))))
        echo -e "  ${C_TEXT}FLASH:     [${C_MAIN}${BAR}${EMPTY}${C_TEXT}] ${C_ACCENT}${PER}% used${NC}"
    fi

    draw_divider "PORTS"
    MODEM_LIST=$(ls /dev/tty.usbmodem* 2>/dev/null | xargs -n 1 basename | tr '\n' ' ')
    echo -e "  ${C_TEXT}SERIAL:    ${C_COMP}${MODEM_LIST:-SEARCHING...}${NC}"

    draw_divider "MENU"
    echo -e "  1️⃣  ${C_TEXT}Rebuild Project${NC}         2️⃣  ${C_TEXT}Flash USB (UF2)${NC}"
    echo -e ""
    echo -e "  3️⃣  ${C_TEXT}Flash (nc)${NC}              4️⃣  ${C_TEXT}Dump Memory (.bin)${NC}"
    echo -e ""
    echo -e "  5️⃣  ${C_TEXT}Reset Board${NC}             6️⃣  ${C_ACCENT}${BOLD}HALT / UNHALT${NC}"
    echo -e ""
    echo -e "  7️⃣  ${C_MAIN}${BOLD}🚀 FULL DEPLOY (BUILD + NC FLASH)${NC}"
    
    echo -e "\n\n  ${C_GRAY}[q] Exit Session${NC}"
    echo -ne "\n${C_MAIN}🐸 ${C_ACCENT}${BOLD}> ${NC}"
}

# --- ACTIONS ---
perform_build() {
    STATUS="🛠 BUILDING"
    draw_dashboard
    mkdir -p build logs
    
    # Generate hash for the log filename
    LOG_HASH=$(date +%s | md5 | head -c 8)
    LOG_FILE="logs/build_${LOG_HASH}.log"
    
    echo -e "${C_MAIN}Starting build... Logging to $LOG_FILE${NC}"
    
    # Ensure we build INSIDE the build folder
    cd build
    cmake .. > "../$LOG_FILE" 2>&1
    make -j4 >> "../$LOG_FILE" 2>&1
    RET=$?
    cd ..
    
    if [ $RET -ne 0 ]; then
        STATUS="🔴 BUILD FAIL"
        echo -e "${C_ACCENT}Build failed! See $LOG_FILE for details.${NC}"
        read -n 1 -p "Press any key to return..."
    else
        STATUS="🟢 BUILD OK"
        # Move binaries if they were generated in root by accident (failsafe)
        [ -f "$TARGET.elf" ] && mv "$TARGET.elf" build/
        [ -f "$TARGET.bin" ] && mv "$TARGET.bin" build/
        arm-none-eabi-objcopy -O binary "build/$TARGET.elf" "build/$TARGET.bin" 2>/dev/null
    fi
}

nc_flash() {
    STATUS="🚀 FLASHING"
    draw_dashboard
    (echo "halt"; echo "program build/$TARGET.elf verify reset"; echo "exit") | nc -w 5 localhost 4444 | tee flash.log
    if grep -q "Verified OK" flash.log; then
        STATUS="🟢 SUCCESS"
    else
        STATUS="🔴 FAILED"
        read -n 1 -p "Check logs. Press any key..."
    fi
}

while true; do
    draw_dashboard
    read -n 1 -r opt
    case $opt in
        1) perform_build ;;
        2) cp build/$TARGET.uf2 /Volumes/RPI-RP2/ 2>/dev/null ;;
        3) nc_flash ;;
        4) (echo "halt"; echo "dump_image build/dump.bin 0x10000000 0x200000"; echo "resume"; echo "exit") | nc localhost 4444 ;;
        7) perform_build && nc_flash ;;
        5) (echo "reset run"; echo "exit") | nc localhost 4444 ;;
        6) [ $IS_HALTED -eq 0 ] && (echo "halt"; echo "exit") | nc localhost 4444 && IS_HALTED=1 || (echo "resume"; echo "exit") | nc localhost 4444 && IS_HALTED=0 ;;
        q|Q) tmux kill-server; exit ;;
    esac
done