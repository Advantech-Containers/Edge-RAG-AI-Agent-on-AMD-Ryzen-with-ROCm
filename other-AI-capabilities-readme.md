# Supported AI Capabilities
The following AI capabilities are also supported by the container image:

## Supported AI Model Formats

| Format | Support Level | Compatible Versions | Notes |
|--------|---------------|---------------------|-------|
| ONNX | Full | 1.10.+ - 1.16.+ | Recommended for cross-framework compatibility |
| PyTorch (.pt, .pth, JIT) | Full | 2.1+ - 2.5+ | Directly load the model weights. No format conversion required. |
| TensorFlow SavedModel | Full | 2.10 - 2.14.0 | Recommended TF deployment format |
| TFLite | Partial | Up to 2.12+ | May have limited hardware acceleration |
| GGUF | Full | llama.cpp b3000+ Ollama latest | Optimized for efficient edge inference, llama.cpp or Ollama with HIPBLAS/ROCm backend compiled must be used  |

## Hardware Acceleration Support

| Accelerator | Support Level | Compatible Libraries | Notes |
|-------------|---------------|----------------------|-------|
| HIP | Full | PyTorch, TensorFlow, OpenCV, ONNX Runtime | Primary acceleration method |

## Video/Camera Processing—GStreamer Integration

Built with VA-API amd VDPAU:

| Feature | Support Level | Compatible Versions | Notes |
|---------|---------------|---------------------|-------|
| H.264/AVC Encoding | Full | Up to High Profile | Hardware accelerated via VCN |
| H.265/HEVC Encoding | Full | Up to Main10 profile | Hardware accelerated via VCN |
| AV1 Encoding | Partial | Limited feature set | Experimental support |
| Hardware Decoding | Full | H.264/H.265/VP9/AV1 | Via VCN |
