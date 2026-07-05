# fzf Support - Enhanced Interactive Experience

## What's New

The interactive setup script now has **intelligent fzf support**:
- ✅ If `fzf` is installed → Beautiful interactive menus
- ✅ If `fzf` is missing → Graceful fallback to simple input
- ✅ No additional dependencies required (fzf is optional)
- ✅ Same workflow either way

---

## With fzf (Premium Experience)

### Installation

```bash
# macOS
brew install fzf

# Linux
apt-get install fzf
# or
yum install fzf

# Or build from source
git clone https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

### Experience with fzf

```bash
bash agents-setup
```

**Phase 2: Agent Selection**
```
🎯 Which agents would you like to configure?

🔲 omp
🔲 qwen
🔲 vibe
🔲 shai

> Select agents (Tab to toggle, Enter to confirm)
```

Features:
- **Tab** to select/deselect
- **Enter** to confirm
- Search by typing
- Preview descriptions
- Beautiful interface

**Phase 3: Model Selection**
```
ℹ️ Selecting model for omp

> Select primary model
  ollama/qwen3.5:9b
  ollama/phi4:latest
  ollama/gemma4:12b-mlx
  ollama/qwen2.5-coder:7b

> omp (searching)
```

Features:
- Searchable list
- Arrow keys to navigate
- Enter to select
- Shows all options

---

## Without fzf (Simple Input)

### Experience without fzf

```bash
bash agents-setup
```

**Phase 2: Agent Selection**
```
ℹ️ Which agents would you like to configure?

🎯 omp (Pi Coding Agent)
   Best for: Production automation, benchmarking
   Why: Auto-detects models, fallback chains, JSON output
   Speed: ⚡⚡⚡ (fast, reliable)

Configure omp? (y/n) [y]: y

🎯 qwen (Alibaba's Agent)
   ...

Configure qwen? (y/n) [y]: y
```

Features:
- Clear explanations shown
- Simple yes/no prompts
- Type `y` or `n`
- Default is shown in brackets

**Phase 3: Model Selection**
```
ℹ️ Selecting model for omp

Top models available:
  1. ollama/qwen3.5:9b
  2. ollama/phi4:latest
  3. ollama/qwen2.5-coder:7b
  4. ollama/gemma4:12b-mlx
  5. ollama/gemma4-claude:latest

Enter number (1-5): 1

✅ Selected: ollama/qwen3.5:9b
```

Features:
- Numbered menu
- Type a number
- Press Enter
- Works everywhere

---

## Why This Design?

### Best of Both Worlds

| Aspect | With fzf | Without fzf |
|--------|----------|------------|
| User Experience | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Dependencies | 1 optional | 0 required |
| Portability | Works on most systems | Works everywhere |
| Speed | Faster navigation | Slightly slower |
| Accessibility | Keyboard-driven | Simple text |

### Philosophy

- **No hard dependencies** - works even in minimal environments
- **Graceful enhancement** - better experience if you have fzf
- **Same workflow** - user doesn't need to know which mode they're in
- **Self-informing** - tells user how to improve their setup

---

## Installation Hints

The script will tell you:

```
ℹ️ fzf not found - using simple input mode
ℹ️ Install fzf for nicer menus: brew install fzf
```

### Quick Install

**macOS (with Homebrew):**
```bash
brew install fzf
```

**Ubuntu/Debian:**
```bash
sudo apt-get install fzf
```

**Fedora/RHEL:**
```bash
sudo yum install fzf
```

**Generic (clone from GitHub):**
```bash
git clone https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

---

## Implementation Details

### Detection

```bash
HAS_FZF=false
if command -v fzf &> /dev/null; then
  HAS_FZF=true
fi
```

### Dual Functions

Every interactive element has two implementations:

```bash
select_from_list() {
  # ... prompt and items ...

  if [ $HAS_FZF = true ]; then
    # Use fzf for rich selection
    printf '%s\n' "${items[@]}" | fzf --height 40% --border
  else
    # Fallback to numbered menu
    for i in "${!items[@]}"; do
      echo "  $((i+1)). ${items[$i]}"
    done
    read -p "Enter number: " choice
    echo "${items[$((choice-1))]}"
  fi
}
```

### Benefits

- Single codebase for both modes
- Automatic detection
- No conditional branches visible to user
- Easy to maintain

---

## Comparison: Side-by-Side

### Agent Selection

**With fzf:**
```
Press Tab to select multiple agents, arrow keys to navigate
[✓] omp
[ ] qwen
[ ] vibe
[ ] shai
> _
```

**Without fzf:**
```
1. omp
2. qwen
3. vibe
4. shai

Enter numbers (space-separated): 1 2
```

### Model Selection

**With fzf:**
```
> qwen3.5:9b
  phi4:latest
  gemma4:12b-mlx
  qwen2.5-coder:7b
```

**Without fzf:**
```
1. ollama/qwen3.5:9b
2. ollama/phi4:latest
3. ollama/gemma4:12b-mlx

Enter number: 1
```

---

## Testing Both Modes

### Test with fzf
```bash
# Make sure fzf is installed
fzf --version

# Run setup
bash agents-setup
```

### Test without fzf
```bash
# Temporarily hide fzf
PATH_BACKUP=$PATH
export PATH=$(echo $PATH | sed 's|:.*fzf.*||g')

# Run setup
bash agents-setup

# Restore PATH
export PATH=$PATH_BACKUP
```

---

## Performance Impact

### With fzf
- Slight startup overhead (~0.5s) for fzf initialization
- Faster navigation (keyboard driven)
- Better for many options

### Without fzf
- Instant startup
- Simple text I/O
- Works in restricted environments (SSH, containers, CI)

---

## Troubleshooting

### fzf not showing up even though installed

```bash
# Verify fzf is in PATH
which fzf

# Verify it's executable
fzf --version

# Check if shell can find it
command -v fzf
```

### fzf is slow

fzf is very fast. If it's slow:
- Your system might be under load
- Try closing other applications
- Check disk I/O

### Want to force simple mode?

Edit script line 1, change:
```bash
HAS_FZF=false  # Force simple mode
```

---

## Future Enhancements

Possible additions:
- Preview descriptions while selecting with fzf
- Custom fzf themes
- Keyboard shortcuts for common operations
- Configuration profiles in fzf

---

## Summary

The script automatically uses **fzf if available**, providing:
- ✅ Beautiful interactive experience
- ✅ Keyboard-driven navigation
- ✅ Searchable lists
- ✅ Multi-select support

But still works **without fzf**:
- ✅ Simple numbered menus
- ✅ Works everywhere
- ✅ No additional setup required

**Install fzf for the best experience, but it's totally optional!** 🎉
