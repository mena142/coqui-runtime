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
VERSION="1.0.0-gold"
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
    
    # Left Panel (0.0): Persistent Netcat connection to OpenOCD Telnet
    # We use a loop so if OpenOCD isn't up yet or restarts, the panel stays alive.
    tmux send-keys -t coqui_dev:0.0 "clear && while true; do echo -e '${C_MAIN}Attempting connection to OpenOCD (4444)...${NC}'; nc localhost 4444; sleep 2; done" C-m
    
    # Right Panel (0.1): The Dashboard
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
        SIZE=$(stat -f%z "build/$TARGET.bin" 2>/dev/null || echo 0)
        PER=$(( (SIZE * 100) / 16777216 ))
        BAR_W=$((PER / 5)); BAR=$(printf '█%.0s' $(seq 1 $BAR_W 2>/dev/null)); EMPTY=$(printf '░%.0s' $(seq 1 $((20 - BAR_W)) 2>/dev/null))
        echo -e "  ${C_TEXT}FLASH:     [${C_MAIN}${BAR}${EMPTY}${C_TEXT}] ${C_ACCENT}${PER}% used${NC}"
    fi

    draw_divider "DEBUG INTERFACE"
    echo -e "  ${C_TEXT}TELNET:    ${C_COMP}localhost:4444 (via nc)${NC}"

    draw_divider "MENU"
    echo -e "  1️⃣  ${C_TEXT}Rebuild Project${NC}         2️⃣  ${C_TEXT}Flash USB (UF2)${NC}"
    echo -e ""
    echo -e "  3️⃣  ${C_TEXT}Flash (nc)${NC}              4️⃣  ${C_TEXT}Dump Memory (.bin)${NC}"
    echo -e ""
    echo -e "  5️⃣  ${C_TEXT}Reset Board${NC}             6️⃣  ${C_ACCENT}${C_BOLD}HALT / UNHALT${NC}"
    echo -e ""
    echo -e "  7️⃣  ${C_MAIN}${C_BOLD}🚀 FULL DEPLOY (BUILD + NC FLASH)${NC}"
    
    echo -e "\n\n  ${C_GRAY}[q] Exit Session${NC}"
    echo -ne "\n${C_MAIN}🐸 ${C_ACCENT}${C_BOLD}> ${NC}"
}

# --- ACTIONS ---
perform_build() {
    STATUS="🛠 BUILDING"
    draw_dashboard
    mkdir -p build logs
    
    LOG_HASH=$(date +%s | md5 | head -c 8)
    LOG_FILE="logs/build_${LOG_HASH}.log"
    
    echo -e "${C_MAIN}Starting build... STREAMING TO SCREEN AND $LOG_FILE${NC}\n"
    
    cd build || return
    cmake .. 2>&1 | tee "../$LOG_FILE"
    make -j4 2>&1 | tee -a "../$LOG_FILE"
    RET=$?
    cd ..
    
    if [ $RET -ne 0 ]; then
        STATUS="🔴 BUILD FAIL"
        echo -e "\n${C_ACCENT}${C_BOLD}!!! BUILD FAILED !!!${NC}"
    else
        STATUS="🟢 BUILD OK"
        arm-none-eabi-objcopy -O binary "build/$TARGET.elf" "build/$TARGET.bin" 2>/dev/null
        echo -e "\n${C_MAIN}${C_BOLD}--- BUILD SUCCESSFUL ---${NC}"
    fi
    
    echo -e "${C_GRAY}Press any key to return to dashboard...${NC}"
    read -n 1
}

nc_flash() {
    STATUS="🚀 FLASHING"
    draw_dashboard
    echo -e "${C_MAIN}Connecting to OpenOCD on port 4444...${NC}\n"

    if ! nc -z localhost 4444 2>/dev/null; then
        echo -e "${C_ACCENT}❌ OpenOCD is not running on port 4444${NC}"
        echo -e "\n${C_GRAY}Press any key to return...${NC}"
        read -n 1
        return 1
    fi

    {
        echo "halt"
        sleep 0.2
        echo "program build/$TARGET.elf verify reset"
        sleep 0.8
        echo "resume"
        sleep 0.3
        echo "exit"
    } | nc localhost 4444 | tee flash.log

    if grep -q "Verified OK" flash.log || grep -q "Flash writing" flash.log; then
        STATUS="🟢 SUCCESS"
        echo -e "\n${C_MAIN}${C_BOLD}✅ FLASH VERIFIED AND RUNNING${NC}"
    else
        STATUS="🔴 FAILED"
        echo -e "\n${C_ACCENT}${C_BOLD}❌ FLASH FAILED${NC}"
    fi

    echo -e "\n${C_GRAY}Press any key to return to dashboard...${NC}"
    read -n 1
}

# --- MAIN LOOP ---
while true; do
    draw_dashboard
    read -n 1 -r opt
    case $opt in
        1) perform_build ;;
        2) cp build/$TARGET.uf2 /Volumes/RPI-RP2/ 2>/dev/null ;;
        3) nc_flash ;;
        4) (echo "halt"; echo "dump_image build/dump.bin 0x10000000 0x200000"; echo "resume"; echo "exit") | nc localhost 4444 ;;
        5) (echo "reset run"; echo "exit") | nc localhost 4444 ;;
        6) 
            if [ $IS_HALTED -eq 0 ]; then
                (echo "halt"; echo "exit") | nc localhost 4444 && IS_HALTED=1
                STATUS="⏸ HALTED"
            else
                (echo "resume"; echo "exit") | nc localhost 4444 && IS_HALTED=0
                STATUS="🟢 RUNNING"
            fi 
            ;;
        7) perform_build && [ "$STATUS" == "🟢 BUILD OK" ] && nc_flash ;;
        q|Q) tmux kill-server; exit ;;
    esac
done