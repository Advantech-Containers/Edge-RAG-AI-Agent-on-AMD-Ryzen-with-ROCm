#!/bin/bash
# ==========================================================================
# Advantech AMD ROCm Wise-Bench Hardware Diagnostics Script
# ==========================================================================
# Version:      2.0.0
# Author:       Adapted from Samir Singh <samir.singh@advantech.com>
# Created:      2026-03-09
# Last Updated: 2026-03-09
#
# Description:
#   Comprehensive hardware and AI framework diagnostics for AMD ROCm devices.
#   This version only checks components that are actually working in your environment.
# ==========================================================================

clear
LOG_FILE="/workspace/wise-bench.log"
mkdir -p "$(dirname "$LOG_FILE")"
{
    echo "==========================================================="
    echo ">>> ROCm Diagnostic Run Started at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==========================================================="
} >> "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
MODEL_NAME="deepseek-r1:1.5b"
OLLAMA_API_BASE="http://localhost:11434"

# Print banner (REPLACED with Advantech_COE style)
echo -e "${BLUE}${BOLD}+------------------------------------------------------+${NC}"
echo -e "${BLUE}${BOLD}|    ${PURPLE}Advantech_COE AMD ROCm Diagnostics Tool${BLUE}         |${NC}"
echo -e "${BLUE}${BOLD}+------------------------------------------------------+${NC}"
echo
echo -e "${BLUE}"
echo "       █████╗ ██████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗███████╗ ██████╗██╗  ██╗     ██████╗ ██████╗ ███████╗"
echo "      ██╔══██╗██╔══██╗██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██╔═══██╗██╔════╝"
echo "      ███████║██║  ██║██║   ██║███████║██╔██╗ ██║   ██║   █████╗  ██║     ███████║    ██║     ██║   ██║█████╗  "
echo "      ██╔══██║██║  ██║╚██╗ ██╔╝██╔══██║██║╚██╗██║   ██║   ██╔══╝  ██║     ██╔══██║    ██║     ██║   ██║██╔══╝  "
echo "      ██║  ██║██████╔╝ ╚████╔╝ ██║  ██║██║ ╚████║   ██║   ███████╗╚██████╗██║  ██║    ╚██████╗╚██████╔╝███████╗"
echo "      ╚═╝  ╚═╝╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚══════╝"
echo -e "${WHITE}                                  Center of Excellence - ROCm Edition${NC}"
echo
echo -e "${YELLOW}${BOLD}▶ Starting AMD ROCm hardware acceleration tests...${NC}"
echo -e "${CYAN}  This may take a moment...${NC}"
echo
sleep 2

# ==========================================================================
# Helper Functions (KEPT the same)
# ==========================================================================
print_header() {
    echo
    echo "+--- $1 ----$(printf '%*s' $((47 - ${#1})) | tr ' ' '-')+"
    echo "|$(printf '%*s' 50 | tr ' ' ' ')|"
    echo "+--------------------------------------------------+"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_table_header() {
    echo "+--------------------------------------------------+"
    echo "| $1$(printf '%*s' $((47 - ${#1})) | tr ' ' ' ')|"
    echo "+--------------------------------------------------+"
}

print_table_row() {
    printf "| %-25s | %-20s |\n" "$1" "$2"
}

print_table_footer() {
    echo "+--------------------------------------------------+"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ==========================================================================
# 1️⃣ System Information
# ==========================================================================
print_header "SYSTEM INFORMATION"
print_table_header "SYSTEM DETAILS"

HOSTNAME=$(hostname)
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")
KERNEL=$(uname -r)
ARCH=$(uname -m)
CPU_MODEL=$(lscpu | grep "Model name" | head -1 | cut -d':' -f2 | sed 's/^ *//' || echo "Unknown")
CPU_CORES=$(nproc --all)
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
UPTIME=$(uptime -p | sed 's/^up //')

print_table_row "Hostname" "$HOSTNAME"
print_table_row "OS" "$OS"
print_table_row "Kernel" "$KERNEL"
print_table_row "Architecture" "$ARCH"
print_table_row "CPU" "$CPU_MODEL ($CPU_CORES cores)"
print_table_row "Memory" "$MEM_USED used of $MEM_TOTAL"
print_table_row "Uptime" "$UPTIME"
print_table_row "Date" "$(date '+%Y-%m-%d %H:%M:%S')"
print_table_footer

# ==========================================================================
# 2️⃣ ROCm / HIP Detection
# ==========================================================================
print_header "ROCm / HIP DETECTION"
echo -e "${YELLOW}"
echo "       ██████╗  ██████╗ ██████╗███╗   ███╗"
echo "      ██╔══██╗██╔═══██╗██╔════╝████╗ ████║"
echo "      ██████╔╝██║   ██║██║     ██╔████╔██║"
echo "      ██╔══██╗██║   ██║██║     ██║╚██╔╝██║"
echo "      ██║  ██║╚██████╔╝╚██████╗██║ ╚═╝ ██║"
echo "      ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝     ╚═╝"
echo -e "${NC}"
echo -ne "▶ Detecting ROCm installation... "
for i in {1..10}; do
    echo -ne "▮"
    sleep 0.05
done
echo

print_table_header "ROCm COMPONENTS"

ROCM_STATUS=0
HIP_STATUS=0

# Check ROCm path
if [ -d "/opt/rocm" ]; then
    print_table_row "ROCm Path" "/opt/rocm"
    ROCM_STATUS=1
else
    print_table_row "ROCm Path" "Not found"
fi

# Check hipcc
HIPCC_PATH=$(command -v hipcc)
if [ -n "$HIPCC_PATH" ]; then
    HIP_VERSION=$($HIPCC_PATH --version 2>&1 | head -1 | grep -o 'HIP version: [0-9.]*' || echo "Unknown")
    print_table_row "hipcc Path" "$HIPCC_PATH"
    print_table_row "HIP Version" "$HIP_VERSION"
    HIP_STATUS=1
else
    print_table_row "hipcc" "Not found"
fi

# Check rocminfo
if command -v rocminfo &> /dev/null; then
    print_table_row "rocminfo" "Available"
else
    print_table_row "rocminfo" "Not found"
fi

print_table_footer

# ==========================================================================
# 3️⃣ AMD GPU Detection
# ==========================================================================
print_header "AMD GPU DEVICES"
echo -ne "▶ Enumerating AMD GPUs... "
for i in {1..10}; do echo -ne "▮"; sleep 0.05; done
echo

print_table_header "GPU DETAILS"

GPU_COUNT=0
GPU_DEVICE_ACCESS=0

# Check device nodes
if [ -e "/dev/kfd" ]; then
    print_table_row "/dev/kfd" "✓ Present"
    GPU_DEVICE_ACCESS=$((GPU_DEVICE_ACCESS + 1))
else
    print_table_row "/dev/kfd" "✗ Missing"
fi

if [ -e "/dev/dri" ]; then
    RENDER_COUNT=$(ls -la /dev/dri/render* 2>/dev/null | wc -l)
    print_table_row "/dev/dri" "✓ Present ($RENDER_COUNT render nodes)"
    [ $RENDER_COUNT -gt 0 ] && GPU_DEVICE_ACCESS=$((GPU_DEVICE_ACCESS + 1))
else
    print_table_row "/dev/dri" "✗ Missing"
fi

# Try rocm-smi if available (but don't fail if not)
if command -v rocm-smi &> /dev/null; then
    GPU_USE=$(rocm-smi --showuse 2>/dev/null | grep "GPU Use" | head -1)
    GPU_MEM=$(rocm-smi --showmeminfo vram 2>/dev/null | grep "Total" | head -1)
    [ -n "$GPU_USE" ] && print_table_row "GPU Utilization" "$(echo $GPU_USE | awk '{print $3}')"
    [ -n "$GPU_MEM" ] && print_table_row "GPU Memory" "$(echo $GPU_MEM | awk '{print $3$4}')"
fi

# Get GPU count from PyTorch (more reliable)
GPU_COUNT=$(python3 -c "
import torch
print(torch.cuda.device_count() if torch.cuda.is_available() else 0)
" 2>/dev/null || echo "0")

print_table_row "GPU Count" "$GPU_COUNT"
if [ $GPU_DEVICE_ACCESS -ge 2 ]; then
    print_table_row "Device Access" "✓ Good"
else
    print_table_row "Device Access" "⚠ Limited"
fi
print_table_footer

# ==========================================================================
# 4️⃣ PyTorch ROCm Test
# ==========================================================================
print_header "PYTORCH ROCm TEST"
echo -ne "▶ Testing PyTorch with ROCm... "
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
for i in {1..15}; do
    echo -ne "\b${SPINNER_CHARS:i%10:1}"
    sleep 0.1
done
echo -ne "\b✓\n"

print_table_header "PYTORCH DETAILS"

PYTORCH_INFO=$(python3 -c "
import sys
try:
    import torch
    print(torch.__version__)
    try:
        hip_ver = torch.version.hip
        print(hip_ver if hip_ver else 'N/A')
    except:
        print('N/A')
    print(torch.cuda.is_available())
    print(torch.cuda.device_count())
    if torch.cuda.is_available():
        print(torch.cuda.get_device_name(0))
        print(torch.cuda.get_device_properties(0).total_memory / 1024**3)
    else:
        print('N/A')
        print('0')
except ImportError:
    print('Not installed')
    print('N/A')
    print('False')
    print('0')
    print('N/A')
    print('0')
except Exception as e:
    print(f'Error: {e}')
    print('N/A')
    print('False')
    print('0')
    print('N/A')
    print('0')
" 2>/dev/null)

# Parse the output
PYTORCH_VERSION=$(echo "$PYTORCH_INFO" | sed -n '1p')
CUDA_AVAILABLE=$(echo "$PYTORCH_INFO" | sed -n '3p')
DEVICE_COUNT=$(echo "$PYTORCH_INFO" | sed -n '4p')
DEVICE_NAME=$(echo "$PYTORCH_INFO" | sed -n '5p')
GPU_MEMORY=$(echo "$PYTORCH_INFO" | sed -n '6p')

print_table_row "PyTorch Version" "$PYTORCH_VERSION"
print_table_row "HIP Version" "$HIP_VERSION"
if [[ "$CUDA_AVAILABLE" == "True" ]]; then
    print_table_row "CUDA Available" "Yes"
else
    print_table_row "CUDA Available" "No"
fi
print_table_row "GPU Count" "$DEVICE_COUNT"
print_table_row "GPU Name" "$DEVICE_NAME"
if [ "$GPU_MEMORY" != "0" ] && [ "$GPU_MEMORY" != "0.0" ]; then
    print_table_row "GPU Memory" "${GPU_MEMORY}GB"
else
    print_table_row "GPU Memory" "N/A"
fi

if [[ "$CUDA_AVAILABLE" == "True" ]] && [ "$DEVICE_COUNT" -gt 0 ]; then
    print_table_row "Status" "✓ ROCm Accelerated"
    PYTORCH_STATUS=1
else
    print_table_row "Status" "⚠ CPU Only"
    PYTORCH_STATUS=0
fi
print_table_footer

# ==========================================================================
# 5️⃣ ONNX Runtime ROCm Test
# ==========================================================================
print_header "ONNX RUNTIME ROCm TEST"
echo -ne "▶ Checking ONNX providers... "
BAR_SIZE=20
for ((i=0; i<$BAR_SIZE; i++)); do
    echo -ne "█"
    sleep 0.05
done
echo -e " ✓"

print_table_header "ONNX RUNTIME DETAILS"

ONNX_INFO=$(python3 -c "
import sys
try:
    import onnxruntime as ort
    print(ort.__version__)
    providers = ort.get_available_providers()
    print(','.join(providers))
    if 'ROCMExecutionProvider' in providers:
        print('Yes')
    else:
        print('No')
except ImportError:
    print('Not installed')
    print('None')
    print('No')
except Exception as e:
    print(f'Error: {e}')
    print('None')
    print('No')
" 2>/dev/null)

ONNX_VERSION=$(echo "$ONNX_INFO" | sed -n '1p')
ONNX_PROVIDERS=$(echo "$ONNX_INFO" | sed -n '2p')
ONNX_ROCM=$(echo "$ONNX_INFO" | sed -n '3p')

print_table_row "ONNX Version" "$ONNX_VERSION"
print_table_row "Providers" "$ONNX_PROVIDERS"
if [ "$ONNX_ROCM" = "Yes" ]; then
    print_table_row "ROCM Provider" "✓ Available"
    ONNX_STATUS=1
else
    print_table_row "ROCM Provider" "⚠ Not available"
    ONNX_STATUS=0
fi
print_table_footer

# ==========================================================================
# 6️⃣ Ollama + LangChain + FAISS Check
# ==========================================================================
print_header "OLLAMA + LANGCHAIN + FAISS CHECK"
echo -ne "▶ Checking LLM/RAG stack... "
for i in {1..10}; do echo -ne "▮"; sleep 0.05; done
echo -e " ✓"

print_table_header "LLM/RAG COMPONENTS"

OLLAMA_STATUS=0
MODEL_STATUS=0
LANGCHAIN_STATUS=0
FAISS_STATUS=0

# Check Ollama
if command -v curl &> /dev/null; then
    if curl -s -o /dev/null -w "%{http_code}" "$OLLAMA_API_BASE/api/tags" 2>/dev/null | grep -q "200"; then
        print_table_row "Ollama Server" "✓ Running"
        OLLAMA_STATUS=1
        
        # Check models
        MODEL_LIST=$(curl -s "$OLLAMA_API_BASE/api/tags" 2>/dev/null)
        MODEL_COUNT=$(echo "$MODEL_LIST" | grep -o '"name"' | wc -l)
        print_table_row "Models Found" "$MODEL_COUNT"
        
        if echo "$MODEL_LIST" | grep -q "$MODEL_NAME"; then
            print_table_row "DeepSeek-R1-1.5B" "✓ Available"
            MODEL_STATUS=1
        else
            print_table_row "DeepSeek-R1-1.5B" "⚠ Not found"
        fi
    else
        print_table_row "Ollama Server" "⚠ Not running"
    fi
else
    print_table_row "Ollama Server" "⚠ curl not installed"
fi

# Check LangChain
LANGCHAIN_CHECK=$(python3 -c "
try:
    import langchain
    print(langchain.__version__)
except:
    print('Not installed')
" 2>/dev/null)

if [ "$LANGCHAIN_CHECK" != "Not installed" ]; then
    print_table_row "LangChain" "✓ Installed ($LANGCHAIN_CHECK)"
    LANGCHAIN_STATUS=1
else
    print_table_row "LangChain" "⚠ Not installed"
fi

# Check FAISS
FAISS_CHECK=$(python3 -c "
try:
    import faiss
    print(faiss.__version__)
    if hasattr(faiss, 'StandardGpuResources'):
        print('GPU')
    else:
        print('CPU')
except:
    print('Not installed')
    print('N/A')
" 2>/dev/null)

FAISS_VERSION=$(echo "$FAISS_CHECK" | head -1)
FAISS_MODE=$(echo "$FAISS_CHECK" | tail -1)

if [ "$FAISS_VERSION" != "Not installed" ]; then
    print_table_row "FAISS" "✓ Installed ($FAISS_VERSION)"
    print_table_row "FAISS Mode" "$FAISS_MODE"
    FAISS_STATUS=1
else
    print_table_row "FAISS" "⚠ Not installed"
fi

print_table_footer

# ==========================================================================
# 7️⃣ Diagnostics Summary
# ==========================================================================
print_header "DIAGNOSTICS SUMMARY"
print_table_header "COMPONENT STATUS"

MAX=6

# ROCm Installation
if [ "$ROCM_STATUS" -eq 1 ]; then
    print_table_row "ROCm Installation" "✓ Available"
    ROCM_SCORE=1
else
    print_table_row "ROCm Installation" "⚠ Not detected"
    ROCM_SCORE=0
fi

# HIP Compiler
if [ "$HIP_STATUS" -eq 1 ]; then
    print_table_row "HIP Compiler" "✓ Available"
    HIP_SCORE=1
else
    print_table_row "HIP Compiler" "⚠ Not detected"
    HIP_SCORE=0
fi

# GPU Device Access
if [ "$GPU_DEVICE_ACCESS" -ge 2 ]; then
    print_table_row "GPU Device Access" "✓ Available"
    GPU_SCORE=1
else
    print_table_row "GPU Device Access" "⚠ Limited access"
    GPU_SCORE=0
fi

# PyTorch ROCm
if [ "$PYTORCH_STATUS" -eq 1 ]; then
    print_table_row "PyTorch ROCm" "✓ Accelerated"
    PYTORCH_SCORE=1
else
    print_table_row "PyTorch ROCm" "⚠ CPU Only"
    PYTORCH_SCORE=0
fi

# ONNX ROCm
if [ "$ONNX_STATUS" -eq 1 ]; then
    print_table_row "ONNX Runtime ROCm" "✓ Accelerated"
    ONNX_SCORE=1
else
    print_table_row "ONNX Runtime ROCm" "⚠ CPU Only"
    ONNX_SCORE=0
fi

# Ollama Service
if [ "$OLLAMA_STATUS" -eq 1 ]; then
    print_table_row "Ollama Service" "✓ Running"
    OLLAMA_SCORE=1
else
    print_table_row "Ollama Service" "⚠ Not Running"
    OLLAMA_SCORE=0
fi

# Calculate total
TOTAL=$((ROCM_SCORE + HIP_SCORE + GPU_SCORE + PYTORCH_SCORE + ONNX_SCORE + OLLAMA_SCORE))
PERCENTAGE=$((TOTAL * 100 / MAX))

print_table_row "Overall Score" "$PERCENTAGE% ($TOTAL/$MAX)"

# Progress Bar
BAR_SIZE=20
FILLED=$((BAR_SIZE * TOTAL / MAX))
EMPTY=$((BAR_SIZE - FILLED))
BAR=""

for ((i=0; i<FILLED; i++)); do
    BAR="${BAR}█"
done

for ((i=0; i<EMPTY; i++)); do
    BAR="${BAR}░"
done

print_table_row "Progress" "$BAR"

# System status
if [ "$PERCENTAGE" -ge 80 ]; then
    STATUS="✓ Excellent"
elif [ "$PERCENTAGE" -ge 60 ]; then
    STATUS="⚠ Good"
elif [ "$PERCENTAGE" -ge 40 ]; then
    STATUS="⚠ Fair"
else
    STATUS="⚠ Poor"
fi

print_table_row "System Status" "$STATUS"

print_table_footer


# ==========================================================================
# RECOMMENDATIONS
# ==========================================================================
print_header "RECOMMENDATIONS"

ISSUE_COUNT=0

if [ "$ROCM_SCORE" -eq 0 ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    print_warning "Issue $ISSUE_COUNT: ROCm not detected"
    print_info "  Install ROCm: https://rocm.docs.amd.com"
fi

if [ "$GPU_SCORE" -eq 0 ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    print_warning "Issue $ISSUE_COUNT: GPU device access limited"
    print_info "  Run container with:"
    print_info "  --device=/dev/kfd --device=/dev/dri --group-add=video --group-add=render"
fi

if [ "$PYTORCH_SCORE" -eq 0 ] && [ "$ROCM_SCORE" -eq 1 ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    print_warning "Issue $ISSUE_COUNT: PyTorch ROCm support not detected"
    print_info "  Install:"
    print_info "  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1"
fi

if [ "$ONNX_SCORE" -eq 0 ] && [ "$ROCM_SCORE" -eq 1 ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    print_warning "Issue $ISSUE_COUNT: ONNX Runtime ROCm provider missing"
    print_info "  Install: pip install onnxruntime-rocm"
fi

if [ "$OLLAMA_SCORE" -eq 0 ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    print_warning "Issue $ISSUE_COUNT: Ollama service not running"
    print_info "  Start service: ollama serve &"
    print_info "  Pull model: ollama pull deepseek-r1:1.5b"
fi

if [ "$LANGCHAIN_STATUS" -eq 0 ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    print_warning "Issue $ISSUE_COUNT: LangChain not installed"
    print_info "  Install: pip install langchain langchain-community langchain-ollama"
fi

if [ "$FAISS_STATUS" -eq 0 ]; then
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    print_warning "Issue $ISSUE_COUNT: FAISS not installed"
    print_info "  Install: pip install faiss-cpu"
fi

if [ "$ISSUE_COUNT" -eq 0 ]; then
    print_success "No issues found! System is fully configured for ROCm."
fi

# ==========================================================================
# Quick Commands
# ==========================================================================
print_header "QUICK COMMANDS"

echo -e "${CYAN}  ROCm Commands:${NC}"
echo "    rocminfo                    # Show ROCm system info"
echo
echo -e "${CYAN}  Model Serving:${NC}"
echo "    ollama list                  # List installed models"
echo "    ollama run deepseek-r1:1.5b   # Run model interactively"
echo "    curl http://localhost:11434/api/tags  # API test"
echo
echo -e "${CYAN}  Python Environment:${NC}"
echo "    python3 -c \"import torch; print(torch.cuda.is_available())\""
echo

# ==========================================================================
# Diagnostics Complete
# ==========================================================================
print_header "DIAGNOSTICS COMPLETE"

print_success "All AMD ROCm diagnostics completed at $(date '+%H:%M:%S')"
print_info "Log saved to: $LOG_FILE"
echo
echo -e "${BLUE}${BOLD}+------------------------------------------------------+${NC}"
echo -e "${BLUE}${BOLD}|${NC}  To re-run: ./wise-bench.sh                      ${BLUE}${BOLD}|${NC}"
echo -e "${BLUE}${BOLD}|${NC}  View log: cat $LOG_FILE                            ${BLUE}${BOLD}|${NC}"
echo -e "${BLUE}${BOLD}+------------------------------------------------------+${NC}"
echo
