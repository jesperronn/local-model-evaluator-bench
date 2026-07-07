# Workshop A · 003 · IDE-agent: Continue.dev (eller Roo Code)

📋 [Agenda](~/src/obsidian-work-notes/projects/2026-06-nine-ai-local-workshops/agenda-workshop-a.md) · ← [002 · Øvelser](WORKSHOP-A-002-EXERCISES.md)

Vi skifter fra terminal-agenter til en agent inde i selve IDE'en. Vi bruger
**Continue.dev** som primært valg — den gemmer værktøjs-tilladelser i en
config-fil i stedet for at spørge dig hver session (i modsætning til Cline,
hvor godkendelserne har det med at "glemmes" mellem sessions).

Kan du ikke få Continue til at virke, er **Roo Code** (VS Code-only) et godt
alternativ — se afsnittet nederst.

## Modeller vi bruger i dag

Samme tre som resten af workshoppen — copy-paste den der matcher din maskine:

```
qwen/qwen2.5-coder-7b
qwen/qwen3.5-9b
qwen/qwen3.6-35b-a3b
```

---

## 1. Installer Continue.dev

**VS Code:**
- Extensions (⇧⌘X) → søg "Continue" → Install
- Eller: https://marketplace.visualstudio.com/items?itemName=Continue.continue

**IntelliJ / JetBrains:**
- Settings → Plugins → Marketplace → søg "Continue" → Install
- Eller: https://plugins.jetbrains.com/plugin/22707-continue

Genstart IDE'en efter installation, hvis den beder om det.

---

## 2. Peg Continue på din lokale LM Studio/Ollama-server

Åbn Continue-panelet i IDE'en (ikon i sidebaren) → tandhjul/settings → **Open
config file** (åbner `config.yaml`, typisk i `~/.continue/config.yaml`).

Tilføj din lokale model — brug en af de tre fra listen ovenfor:

```yaml
models:
  - name: Lokal Qwen
    provider: lmstudio
    model: qwen/qwen3.6-35b-a3b   # eller qwen/qwen3.5-9b, qwen/qwen2.5-coder-7b
    apiBase: http://localhost:1234/v1
    roles:
      - chat
      - edit
      - apply
```

(Kører du Ollama i stedet: `provider: ollama` og `apiBase: http://localhost:11434/v1`.)

Gem filen — Continue genindlæser konfigurationen automatisk.

**Test:** Åbn en fil, marker noget kode, tryk ⌘I (VS Code) eller den
tilsvarende genvej og bed om en simpel ændring.

---

## 3. Sæt værktøjs-tilladelser (så det ikke spørger hver gang)

I samme `config.yaml`, tilføj en `tools`-sektion der styrer hvilke handlinger
Continue må udføre uden at spørge. De præcise nøgler skifter lidt mellem
versioner — tjek den friske syntaks her, hvis nedenstående ikke matcher din
version: https://docs.continue.dev/customize/deep-dives/tools

```yaml
tools:
  policies:
    - tool: Read file
      policy: allow
    - tool: Edit file
      policy: allow
    - tool: Run terminal command
      policy: ask
```

**Pointen:** Fordi dette står i en fil (ikke i en runtime-tilstand), er det
ikke noget der kan "glemmes" mellem sessions — det er altid sådan indtil du
selv ændrer filen.

---

## 4. Alternativ: Roo Code (VS Code only)

Hvis Continue driller, eller I vil sammenligne:

1. Extensions → søg "Roo Code" → Install
   (https://marketplace.visualstudio.com/items?itemName=RooVeterinaryInc.roo-cline)
2. Åbn Roo Code-panelet → Settings → **Providers** → tilføj "OpenAI Compatible"
   → Base URL: `http://localhost:1234/v1` → Model: en af de tre fra listen ovenfor
3. Settings → **Auto-Approve** → slå de kategorier til I stoler på (Read,
   Write, Execute osv.) — disse gemmes pr. workspace og er langt mere
   granulære end Clines tilsvarende skærm.

---

## Fejlfinding

- **Ingen respons:** tjek at `lms server start` (eller `ollama serve`) kører,
  og at porten matcher `apiBase`/Base URL ovenfor.
- **Model ikke fundet:** kør `lms ls` (eller `ollama list`) og kopiér den
  præcise model-id ind i config'en.
- **Continue spørger stadig om alt:** du har sandsynligvis redigeret den
  forkerte `config.yaml` — brug "Open config file" fra Continue-panelet for at
  finde den rigtige.

---

Sidste dokument i rækken. ↑ [Tilbage til agenda](~/src/obsidian-work-notes/projects/2026-06-nine-ai-local-workshops/agenda-workshop-a.md)
