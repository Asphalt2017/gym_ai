#!/bin/bash
# Helper script to activate llm13 conda environment
# Usage: source .activate-llm13.sh

if [ -n "$BASH_VERSION" ]; then
    eval "$(conda shell.bash hook)"
    conda activate llm13
    echo "✓ Activated llm13 conda environment"
    echo "Python: $(which python)"
    echo "Pre-commit: $(which pre-commit)"
elif [ -n "$ZSH_VERSION" ]; then
    eval "$(conda shell.zsh hook)"
    conda activate llm13
    echo "✓ Activated llm13 conda environment"
    echo "Python: $(which python)"
    echo "Pre-commit: $(which pre-commit)"
fi
