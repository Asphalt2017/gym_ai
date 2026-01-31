# 🚀 Quick Start: Self-Hosted LLaVA Setup

## Installation (5 Minutes)

### Automated Setup (Recommended)

```bash
# Run the setup script
./scripts/setup-ollama.sh
```

This script will:

- ✓ Install Ollama
- ✓ Pull LLaVA model (~4.5GB)
- ✓ Configure backend
- ✓ Verify GPU access
- ✓ Test the model

### Manual Setup

```bash
# 1. Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# 2. Start Ollama
ollama serve

# 3. Pull LLaVA model (in another terminal)
ollama pull llava

# 4. Update backend/.env
echo "AI_PROVIDER=llava" >> backend/.env

# 5. Restart backend
docker-compose restart backend
```

## Verify Installation

```bash
# 1. Check Ollama
curl http://localhost:11434/api/tags

# 2. Check backend health
curl http://localhost:8000/health

# Should show: "ai_provider": "llava"
```

## Test with Image

### Option 1: Dashboard (Visual)

1. Open http://localhost:8050
1. Upload gym equipment photo
1. Click "Analyze Image"
1. See results in 2-5 seconds!

### Option 2: API (Command Line)

```bash
curl -X POST "http://localhost:8000/api/v1/analyze" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@path/to/equipment.jpg"
```

## Performance on Your Hardware

**RTX 3060 (12GB VRAM) + 32GB RAM:**

| Metric          | Performance                     |
| --------------- | ------------------------------- |
| Model load time | 10-15 seconds (first time only) |
| Analysis time   | 2-5 seconds per image           |
| Cached results  | \<100ms                         |
| VRAM usage      | 6-8GB                           |
| Cost per image  | $0 (FREE!)                      |

## Comparison: LLaVA vs OpenAI vs CLIP

| Feature                   | LLaVA (Ollama) | OpenAI GPT-4V    | CLIP       |
| ------------------------- | -------------- | ---------------- | ---------- |
| **Cost**                  | Free ✓         | $0.01-0.03/image | Free ✓     |
| **Speed**                 | 2-5s           | 2-3s             | \<1s ✓     |
| **Quality**               | Good ✓         | Excellent ✓      | Limited    |
| **Privacy**               | 100% Local ✓   | Cloud-based      | Local ✓    |
| **GPU Required**          | Recommended    | No               | Optional   |
| **Setup**                 | 5 minutes      | Instant          | 10 minutes |
| **Detailed Instructions** | Yes ✓          | Yes ✓            | No         |
| **Custom Training**       | Possible ✓     | No               | Possible ✓ |

### When to Use Each

**Use LLaVA (Your Setup)** ✓

- ✓ You have GPU (RTX 3060 perfect!)
- ✓ Privacy is important
- ✓ High volume (>1000 images/month)
- ✓ Want detailed instructions
- ✓ No ongoing costs

**Use OpenAI**

- Absolute best quality needed
- No GPU available
- Low volume (\<100 images/month)
- Quick prototyping

**Use CLIP**

- Ultra-fast classification
- Limited categories
- No detailed instructions needed

## Troubleshooting

### Ollama Not Connecting

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not, start it
ollama serve
```

### GPU Not Detected

```bash
# Check NVIDIA driver
nvidia-smi

# If not found, install CUDA drivers
# Ubuntu: sudo apt install nvidia-cuda-toolkit
```

### Model Not Found

```bash
# Pull the model
ollama pull llava

# Verify
ollama list
```

## Advanced Options

### Use Larger Model (Better Quality)

```bash
# 13B model (requires 10-12GB VRAM) - Works on your RTX 3060!
ollama pull llava:13b

# Update backend/.env
OLLAMA_MODEL=llava:13b
```

### Multiple Models

```bash
# Pull alternative models
ollama pull bakllava      # Alternative implementation
ollama pull llava-phi3    # Lighter weight

# Switch in .env
OLLAMA_MODEL=bakllava
```

## Monitoring

### GPU Usage

```bash
# Watch GPU in real-time
nvidia-smi -l 1
```

### Performance Logs

```bash
# Backend logs
docker-compose logs -f backend

# Ollama logs
journalctl -u ollama -f
```

## Next Steps

1. ✓ Run `./scripts/setup-ollama.sh`
1. ✓ Test with dashboard (http://localhost:8050)
1. ✓ Try different gym equipment images
1. Read full docs: `docs/OLLAMA_SETUP.md`
1. Fine-tune prompts in `backend/app/services/ai/providers/llava_provider.py`

## Resources

- 📖 Full Setup Guide: [docs/OLLAMA_SETUP.md](../docs/OLLAMA_SETUP.md)
- 🔧 Ollama Docs: https://github.com/ollama/ollama
- 🤖 LLaVA Model: https://ollama.com/library/llava
- 💬 Get Help: Create an issue on GitHub

______________________________________________________________________

**You're all set! Your self-hosted AI is ready to recognize gym equipment! 💪**
