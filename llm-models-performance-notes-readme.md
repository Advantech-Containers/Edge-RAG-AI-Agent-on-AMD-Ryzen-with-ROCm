#LLM Model Performance Notes

The following results were obtained on a Rocm 8GB module configured in 25W power mode to ensure optimal performance. Rocm clocks were enabled to maximize CPU and GPU frequency during benchmarking and evaluation. These models were pulled from the official repository of Ollama.

| Model Family | Parameters | Quantization | Size | Performance  |
|--------------|------------|--------------|------|--------------|
| DeepSeek R1 | 1.5 B | Q4_K_M | 1.1 GB | ~16-22 tokens/sec |
| DeepSeek R1 | 7 B | Q4_K_M | 4.7 GB | ~6-8 tokens/sec |
| DeepSeek Coder | 1.3 B | Q4_0 | 776 MB | ~28-32 tokens/sec |
| Llama 3.2 | 1 B | Q8_0 | 1.3 GB | ~16-20 tokens/sec |
| Llama 3.2 | 3 B | Q4_K_M | 2 GB | ~10-12 tokens/sec |
| Llama 2 | 7 B | Q4_0 | 3.8 GB | ~5-7 tokens/sec |
| Tinyllama | 1.1 B | Q4_0 | 637 MB | ~36-38 tokens/sec |
| Qwen 2.5 | 0.5 B | Q4_K_M | 398 MB | ~54-56 tokens/sec |
| Qwen 2.5 | 1.5 B | Q4_K_M | 986 MB | ~22-24 tokens/sec |
| Qwen 2.5 Coder | 0.5 B | Q8_0 | 531 MB | ~54-67 tokens/sec |
| Qwen 2.5 Coder | 1.5 B | Q4_K_M | 986 MB | ~18-20 tokens/sec |
| Qwen | 0.5 B | Q4_0 | 395 MB | ~60-68 tokens/sec |   N
| Qwen | 1.8 B | Q4_0 | 1.1 GB | ~20-24 tokens/sec |
| Gemma 2 | 2 B | Q4_0 | 1.6 GB | ~13-15 tokens/sec |
| Mistral | 7 B | Q4_0 | 4.1 GB | ~5-7 tokens/sec |

