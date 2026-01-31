# Setting Up Self-Hosted LLaVA with Ollama

Complete guide for setting up Ollama with LLaVA vision model for gym equipment recognition on your
RTX 3060.

## Quick Start

### 1. Install Ollama

```bash
# Linux
curl -fsSL https://ollama.com/install.sh | sh

# macOS
brew install ollama

# Windows (WSL2 recommended)
# Download from https://ollama.com/download
```

### 2. Start Ollama Service

```bash
# Start Ollama server (in a separate terminal)
ollama serve
```

**Note for Docker users**: The backend runs in Docker, so it needs to access Ollama on your host
machine. The `.env` file is already configured with `host.docker.internal:11434`.

### 3. Pull LLaVA Model

```bash
# Pull the llava model (~4.5GB)
ollama pull llava

# Verify it's installed
ollama list
```

**Expected output:**

```
NAME                    ID              SIZE    MODIFIED
llava:latest           abc123def45     4.5 GB  5 minutes ago
```

### 4. Test Ollama

```bash
# Test with a simple prompt
ollama run llava "Describe this image" --image /path/to/test/image.jpg
```

### 5. Start Your Backend

```bash
# Make sure .env has:
# AI_PROVIDER=llava
# OLLAMA_URL=http://host.docker.internal:11434
# OLLAMA_MODEL=llava

# Restart backend container
docker-compose restart backend

# Or rebuild if needed
docker-compose up -d --build backend
```

### 6. Verify It's Working

```bash
# Check backend health
curl http://localhost:8000/health

# Should show:
# {
#   "status": "healthy",
#   "ai_provider": "llava",
#   "ai_provider_healthy": true
# }
```

## GPU Configuration

### Verify GPU is Detected

```bash
# Check NVIDIA GPU
nvidia-smi

# Expected output should show your RTX 3060
```

### Ollama GPU Settings

Ollama automatically detects and uses your GPU. To verify:

```bash
# Check GPU usage while running
nvidia-smi -l 1

# You should see Ollama using GPU memory when processing images
```

### Memory Usage

- **LLaVA model**: ~4.5GB on disk
- **VRAM usage**: ~6-8GB during inference (fits perfectly in your 12GB)
- **System RAM**: ~2-4GB for model loading

## Available Models

### Vision Models (Recommended)

```bash
# LLaVA 7B (Default - Best balance)
ollama pull llava                    # 4.5GB, fast, good accuracy

# LLaVA 13B (More capable, slower)
ollama pull llava:13b               # 8GB, better quality

# LLaVA 34B (Best quality, requires more VRAM)
ollama pull llava:34b               # 19GB, highest quality
```

### Text-Only Models (Backup)

If you want to experiment with text-only models:

```bash
# Llama 2 7B
ollama pull llama2:7b               # 3.8GB

# Mistral 7B (Fast and capable)
ollama pull mistral                 # 4.1GB

# Llama 3.1 8B (Latest, very capable)
ollama pull llama3.1:8b             # 4.7GB
```

## Configuration Options

### Environment Variables

Edit `backend/.env`:

```bash
# AI Provider Selection
AI_PROVIDER=llava                    # Use LLaVA via Ollama

# Ollama Configuration
OLLAMA_URL=http://host.docker.internal:11434  # Ollama endpoint
OLLAMA_MODEL=llava                   # Model name (llava, llava:13b, etc.)

# GPU Settings (auto-detected by Ollama)
USE_GPU=true                         # Enable GPU features (optional)
GPU_DEVICE=cuda:0                    # GPU device (if multiple GPUs)
```

### Docker Configuration

If running Ollama in Docker (advanced):

```yaml
# docker-compose.yml - add Ollama service
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

volumes:
  ollama_data:
```

## Performance Optimization

### 1. Keep Model Warm

```bash
# Preload model to keep it in memory
ollama run llava "warmup" --image /dev/null
```

### 2. Adjust Temperature

In `llava_provider.py`, you can tune these parameters:

```python
"options": {
    "temperature": 0.1,  # Lower = more consistent (0.0-1.0)
    "top_p": 0.9,  # Nucleus sampling (0.0-1.0)
    "num_ctx": 4096,  # Context window size
}
```

### 3. Monitor Performance

```bash
# Watch GPU usage
nvidia-smi -l 1

# Check Ollama logs
journalctl -u ollama -f  # If using systemd
```

## Troubleshooting

### Issue: Backend Can't Connect to Ollama

**Symptom:** `Cannot connect to Ollama` error

**Solutions:**

1. **Verify Ollama is running:**

   ```bash
   curl http://localhost:11434/api/tags
   ```

1. **Check Docker network:**

   ```bash
   # From inside backend container
   docker-compose exec backend curl http://host.docker.internal:11434/api/tags
   ```

1. **Try localhost instead:**

   ```bash
   # Edit backend/.env
   OLLAMA_URL=http://localhost:11434
   ```

### Issue: Model Not Found

**Symptom:** `Model 'llava' not found in Ollama`

**Solution:**

```bash
# Pull the model
ollama pull llava

# Verify it's installed
ollama list
```

### Issue: GPU Not Being Used

**Symptom:** Slow inference, GPU usage at 0%

**Solutions:**

1. **Check NVIDIA drivers:**

   ```bash
   nvidia-smi
   ```

1. **Verify CUDA:**

   ```bash
   nvcc --version
   ```

1. **Check Ollama GPU support:**

   ```bash
   ollama run llava --verbose "test" --image /path/to/image.jpg
   ```

### Issue: Out of Memory

**Symptom:** CUDA OOM errors

**Solutions:**

1. **Use smaller model:**

   ```bash
   ollama pull llava:7b  # Instead of 13b or 34b
   ```

1. **Close other GPU applications:**

   ```bash
   # Kill processes using GPU
   nvidia-smi
   kill <PID>
   ```

1. **Reduce batch size in code** (if implemented)

### Issue: Slow First Request

**Normal behavior:** First request takes 10-30 seconds while model loads into VRAM.

**Subsequent requests:** 2-5 seconds per image.

## Advanced: Custom Models

### Using Different Models

```bash
# List all available models
ollama list

# Try different vision models
ollama pull bakllava          # BakLLaVA (alternative)
ollama pull llava-phi3        # Lighter weight option
```

Update `.env`:

```bash
OLLAMA_MODEL=bakllava  # Or other model name
```

### Model Comparison

| Model     | Size  | VRAM    | Speed  | Quality |
| --------- | ----- | ------- | ------ | ------- |
| llava:7b  | 4.5GB | 6-8GB   | Fast   | Good    |
| llava:13b | 8GB   | 10-12GB | Medium | Better  |
| llava:34b | 19GB  | 24GB+   | Slow   | Best    |
| bakllava  | 4.5GB | 6-8GB   | Fast   | Good    |

**For RTX 3060 (12GB VRAM):** Use `llava:7b` or `llava:13b`

## Testing Your Setup

### 1. Direct Ollama Test

```bash
# Test Ollama directly with an image
ollama run llava "What gym equipment is this?" \
  --image /path/to/gym/equipment.jpg
```

### 2. Backend API Test

```bash
# Test via backend API
curl -X POST "http://localhost:8000/api/v1/analyze" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@/path/to/equipment.jpg"
```

### 3. Dashboard Test

1. Open http://localhost:8050
1. Upload gym equipment image
1. Click "Analyze Image"
1. Verify results show `"provider": "llava-ollama"`

## Performance Benchmarks

**Hardware:** RTX 3060 (12GB VRAM), 32GB RAM

| Operation               | Time    |
| ----------------------- | ------- |
| Model load (first time) | 10-15s  |
| Image analysis (warm)   | 2-5s    |
| Cached result           | \<100ms |

**Comparison with other providers:**

| Provider       | Speed | Cost             | Quality   |
| -------------- | ----- | ---------------- | --------- |
| OpenAI GPT-4V  | 2-3s  | $0.01-0.03/image | Excellent |
| LLaVA (Ollama) | 2-5s  | Free             | Good      |
| CLIP           | \<1s  | Free             | Limited   |

## Best Practices

### 1. Keep Ollama Running

```bash
# Set up as systemd service (Linux)
sudo systemctl enable ollama
sudo systemctl start ollama
```

### 2. Monitor Resource Usage

```bash
# Create monitoring script
cat > monitor.sh << 'EOF'
#!/bin/bash
while true; do
  clear
  echo "=== GPU Usage ==="
  nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total --format=csv
  echo ""
  echo "=== Ollama Status ==="
  curl -s http://localhost:11434/api/tags | jq '.models[] | {name, size}'
  sleep 2
done
EOF

chmod +x monitor.sh
./monitor.sh
```

### 3. Regular Model Updates

```bash
# Update Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Update models
ollama pull llava
```

## Cost Comparison

### Self-Hosted (LLaVA + Ollama)

- **Setup cost:** $0 (using existing hardware)
- **Per image:** $0
- **Monthly:** $0 (electricity ~$5-10)
- **Unlimited usage:** ✓

### OpenAI GPT-4 Vision

- **Setup cost:** $0
- **Per image:** $0.01-0.03
- **Monthly (1000 images):** $10-30
- **API limits:** Yes

### Verdict for Your Use Case

✓ **Use LLaVA** if:

- Privacy is important
- High volume of images (>1000/month)
- Want full control
- Have GPU (RTX 3060 ✓)

✗ **Use OpenAI** if:

- Need absolute best quality
- Low volume (\<100/month)
- Want zero maintenance

## Next Steps

1. ✓ Ollama installed and running
1. ✓ LLaVA model pulled
1. ✓ Backend configured
1. Test with real gym equipment images
1. Fine-tune prompt in `llava_provider.py` if needed
1. Monitor performance and adjust settings
1. Consider caching strategies for common equipment

## Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [LLaVA Model Card](https://huggingface.co/liuhaotian/llava-v1.5-7b)
- [Ollama Model Library](https://ollama.com/library)
- [GPU Optimization Guide](https://github.com/ollama/ollama/blob/main/docs/gpu.md)

## Support

If you encounter issues:

1. Check Ollama logs: `journalctl -u ollama -f`
1. Verify GPU: `nvidia-smi`
1. Test model: `ollama run llava "test"`
1. Check backend logs: `docker-compose logs backend`

Happy self-hosting! 🚀
