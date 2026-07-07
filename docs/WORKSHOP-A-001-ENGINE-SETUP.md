# Workshop A · 001 · Motor-opsætning og verificering

📋 [Agenda](~/src/obsidian-work-notes/projects/2026-06-nine-ai-local-workshops/agenda-workshop-a.md) · ← [000 · Onboarding](WORKSHOP-A-000-ONBOARDING.md)

Stint 1 i workshoppen. Nåede du ikke [000 · Onboarding](WORKSHOP-A-000-ONBOARDING.md)
inden i dag? Ingen problemer — de samme skridt er gentaget her, så du kan
følge med fra bunden.

## Modeller vi bruger i dag

```
qwen/qwen2.5-coder-7b
qwen/qwen3.5-9b
qwen/qwen3.6-35b-a3b
```

- `qwen/qwen3.6-35b-a3b` — primær, bedst alt-om-alt (kræver 32 GB+ RAM)
- `qwen/qwen3.5-9b` — fallback, under 32 GB RAM
- `qwen/qwen2.5-coder-7b` — lille/hurtig, god til at mærke forskellen i tempo

---

## 1. Installer motoren (hvis du ikke allerede har)

**Mac:** brug `lms` (LM Studio's CLI) — hent fra https://lmstudio.ai/download

```bash
lms --help
lms server start
```

**Windows:** start LM Studio-applikationen — den starter selv en server på port 1234.

**Ollama-alternativ:** `brew install ollama && brew services start ollama`

---

## 2. Hent modeller (hvis du ikke allerede har)

```bash
lms get qwen/qwen2.5-coder-7b
lms get qwen/qwen3.5-9b
lms get qwen/qwen3.6-35b-a3b   # kun hvis du har 32 GB+ RAM
```

(Ollama: `ollama pull qwen2.5-coder:7b` osv. — se `models-ollama.txt` i repoet for præcise tags.)

---

## 3. Verificér motoren trin for trin

I stedet for at gætte på om det virker, kør scriptet der viser hvert skridt,
før det udføres:

```bash
bin/verify --lms --verbose
# eller: bin/verify --ollama --verbose
```

Det gennemgår fire trin, hver med et **[PASS]**/**[FAIL]**:

| Trin | Hvad tjekkes | Kommando bag kulissen |
|------|--------------|-------------------------|
| 1 | Server svarer | `curl .../v1/models` |
| 2 | Hvilke modeller er hentet | `lms ls` |
| 3 | En model kan loades | `lms load qwen/qwen3.5-9b` |
| 4 | Modellen kan kaldes | `curl .../chat/completions` |

Kør det igen med `--model <id>` hvis du vil teste en bestemt model:

```bash
bin/verify --lms --model qwen/qwen3.6-35b-a3b --verbose
```

---

## Fejlfinding

**Trin 1 fejler — server ikke svarer:**
- Er serveren overhovedet startet? `lms server start` (eller `ollama serve`)
- Kører den på en anden port? Tjek `LMS_BASE_URL`/`OLLAMA_BASE_URL` i `config.sh`
- Firewall/VPN der blokerer localhost? Prøv `curl http://localhost:1234/v1/models` direkte

**Trin 2 — ingen modeller listet:**
- Du har ikke hentet nogen endnu — kør `lms get <model>` (se afsnit 2 ovenfor)
- `lms ls` viser kun modeller *downloadet*, ikke nødvendigvis *loadet* — det er trin 3's job

**Trin 3 fejler — model kan ikke loades:**
- Tjek stavning/ID: `lms ls` viser det præcise ID at bruge
- Løbet tør for RAM? Prøv en mindre model (`qwen/qwen2.5-coder-7b`) i stedet
- Er en anden, stor model allerede loadet og optager hukommelsen? `lms ps` viser hvad der kører — `lms unload <model>` frigør plads

**Trin 4 fejler — modellen svarer ikke:**
- Modellen er loadet (trin 3 bestod), men selve kaldet fejler — ofte en
  midlertidig timeout på en stor model første gang den skal "varme op"
- Prøv igen — lykkes det stadig ikke, kør trin 3 igen for at bekræfte modellen
  stadig er loadet (`lms ps`)

**Generelt:** scriptets `[FAIL]`-linje fortæller altid *hvilket* trin og
*hvorfor* — læs den højt for gruppen, det er ofte en fælles fejl (forkert
port, glemt `server start`, tomt RAM-budget).

---

→ Næste: [002 · Øvelser](WORKSHOP-A-002-EXERCISES.md)
