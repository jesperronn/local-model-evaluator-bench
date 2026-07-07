# Workshop A · 003 · IDE-agent: Roo Code (eller Cline)

📋 [Agenda](~/src/obsidian-work-notes/projects/2026-06-nine-ai-local-workshops/agenda-workshop-a.md) · ← [002 · Øvelser](WORKSHOP-A-002-EXERCISES.md)

Vi skifter fra terminal-agenter til en agent inde i selve IDE'en. Vi bruger
**Roo Code** som primært valg — den har granulære, persistente auto-approve-
indstillinger pr. workspace, så den ikke spørger om det samme igen og igen.

Bruger du IntelliJ/JetBrains (Roo Code er VS Code-only), er **Cline** dit
alternativ — men vær opmærksom på at dens godkendelser har det med at
"glemmes" mellem sessions.

## Modeller vi bruger i dag

Samme tre som resten af workshoppen — copy-paste den der matcher din maskine:

```
qwen/qwen2.5-coder-7b
qwen/qwen3.5-9b
qwen/qwen3.6-35b-a3b
```

---

## 1. Installer Roo Code

**VS Code only:**
- Extensions (⇧⌘X) → søg "Roo Code" → Install
- Eller: https://marketplace.visualstudio.com/items?itemName=RooVeterinaryInc.roo-cline

Genstart IDE'en efter installation, hvis den beder om det.

---

## 2. Peg Roo Code på din lokale LM Studio/Ollama-server

Åbn Roo Code-panelet → Settings → **Providers** → tilføj "OpenAI Compatible":

- **Base URL:** `http://localhost:1234/v1`
- **Model:** en af de tre fra listen ovenfor, fx `qwen/qwen3.6-35b-a3b`
- **API key:** vilkårlig værdi, fx `lm-studio` (kræves af feltet, bruges ikke)

(Kører du Ollama i stedet: Base URL `http://localhost:11434/v1`.)

**Test:** Åbn en fil, marker noget kode, bed Roo Code om en simpel ændring.

---

## 3. Sæt auto-approve (så det ikke spørger hver gang)

Settings → **Auto-Approve** → slå de kategorier til I stoler på (Read, Write,
Execute osv.). Disse gemmes pr. workspace og er langt mere granulære end
Clines tilsvarende skærm — det er derfor vi bruger Roo Code som primærvalg.

---

## 4. Alternativ: Cline (VS Code + JetBrains)

Har du brug for IntelliJ-support, eller vil I sammenligne:

**VS Code:**
- Extensions → søg "Cline" → install
- Eller: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev

**IntelliJ:**
- Plugin: https://plugins.jetbrains.com/plugin/28247-cline

**Opsætning (begge):** Settings → API Provider: OpenAI Compatible → Base URL:
`http://localhost:1234/v1` → Model ID: en af de tre fra listen ovenfor.

**Kendt svaghed:** Cline spørger ofte om godkendelse igen efter en genstart
eller ny session, selvom du allerede har godkendt værktøjet før — irriterende
i en workshop med mange korte sessions. Roo Code er derfor førstevalget når I
kan.

---

## Fejlfinding

- **Ingen respons:** tjek at `lms server start` (eller `ollama serve`) kører,
  og at porten matcher Base URL ovenfor.
- **Model ikke fundet:** kør `lms ls` (eller `ollama list`) og kopiér den
  præcise model-id ind i konfigurationen.
- **Spørger stadig om alt (Roo Code):** tjek at Auto-Approve-kategorierne
  faktisk er slået til for det workspace du står i — indstillingen er pr.
  workspace, ikke global.

---

Sidste dokument i rækken. ↑ [Tilbage til agenda](~/src/obsidian-work-notes/projects/2026-06-nine-ai-local-workshops/agenda-workshop-a.md)
