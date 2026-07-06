# Workshop A · 002 · Øvelser

📋 [Agenda](~/src/obsidian-work-notes/projects/2026-06-nine-ai-local-workshops/agenda-workshop-a.md) · ← [001 · Onboarding](WORKSHOP-A-001-ONBOARDING.md)

Praktisk øvelseshæfte til dagen. Følg det i rækkefølge — hvert afsnit bygger
på det forrige. Afkryds efterhånden.

---

## Øvelse 1: Verificér motoren

```bash
lms server start                    # eller: ollama serve
bin/verify --lms --verbose          # eller: --ollama
```

- [ ] Server svarer (trin 1)
- [ ] Modeller listet — genkend `qwen/qwen3.5-9b` i output (trin 2)
- [ ] Model loadet uden fejl (trin 3)
- [ ] Modellen svarer på et rigtigt spørgsmål (trin 4) — læs svaret, giver det mening?

**Hvis noget fejler:** scriptet fortæller dig præcis hvilket trin og hvorfor —
læs `[FAIL]`-linjen højt for gruppen, det er ofte en fælles fejl.

---

## Øvelse 2: Installér og verificér en terminal-agent

Vælg **pi** (hovedspor) eller **opencode**:

```bash
bin/verify --agent pi --lms --verbose
# eller
bin/verify --agent opencode --lms --verbose
```

- [ ] CLI'en er installeret
- [ ] Prøv den interaktive kommando, scriptet printer (åbn i et andet terminalvindue) — stil den et spørgsmål om et af dine egne projekter
- [ ] Smoketest består — agenten skrev `hello.txt` korrekt

**Bonus:** kør begge (`pi` og `opencode`) og sammenlign hastighed på smoketesten.

---

## Øvelse 3: Løs opgaver i demo-repoet

Demo-repoet ligger i [`demo-repo/`](../demo-repo/) — 8 uafhængige opgaver,
sværhedsgrad stiger fra 01 til 08. Der ligger en `AGENTS.md` i roden som de
fleste agenter læser automatisk.

1. `cd demo-repo/01-slugify-bug` (eller en anden — se tabellen i
   [`demo-repo/README.md`](../demo-repo/README.md))
2. Start din agent i mappen, fx:
   ```bash
   pi --provider lmstudio --model qwen/qwen3.6-35b-a3b
   ```
3. Copy-paste opgaveteksten fra `TASK.md` ind til agenten
4. Bed agenten køre testen og blive ved med at rette, indtil den er grøn:
   - de fleste opgaver: `npm test`
   - opgave 05: `npm test` **og** `npm run lint`
   - opgave 07 (bash): `./test.sh`

- [ ] Løst mindst **2 opgaver** med grøn test
- [ ] Prøvet mindst **1 flerfils-opgave** (03 eller 04) — bemærk om agenten selv finder ud af at redigere begge filer
- [ ] Prøvet **opgave 05 eller 06** (indbygget test-loop) — observér om agenten selv opdager og retter fejl, eller om den erklærer sig færdig for tidligt

**Refleksionsspørgsmål til gruppen:**
- Hvor mange forsøg/rettelser tog opgaven, før testen blev grøn?
- Var der noget agenten "gættede forkert" på, som en tydeligere prompt havde løst?
- Følte det sig hurtigere eller langsommere end du havde forventet?

---

## Øvelse 4: Prøv en anden opgave med plan → refine → implement → verify → review

Vælg en opgave I ikke har løst endnu. Denne gang, opdel arbejdet eksplicit i
faser i stedet for én lang prompt:

1. **Plan:** bed agenten *kun* beskrive hvad den vil gøre — ingen kodeændringer endnu
2. **Refine:** læs planen, ret den hvis noget er upræcist (filnavne, edge-cases)
3. **Implement:** bed den udføre planen
4. **Verify:** kør testen
5. **Review:** kig selv diff'en igennem — er der noget testen ikke fangede?

- [ ] Gennemført alle 5 faser på én opgave
- [ ] Sammenlignet: var resultatet bedre end i øvelse 3, hvor I gik direkte til implementering?

---

## Øvelse 5: IDE-agent (Continue.dev)

Se [003 · IDE-agent](WORKSHOP-A-003-IDE-AGENT.md) for fuld installationsvejledning.

- [ ] Continue.dev installeret (VS Code eller JetBrains)
- [ ] `config.yaml` peger på din lokale model (LM Studio/Ollama)
- [ ] Værktøjs-politik sat, så den ikke spørger om alt
- [ ] Løst **en opgave fra demo-repoet** (gerne en du ikke nåede før) med Continue i stedet for pi/opencode

**Refleksionsspørgsmål:**
- Følte det anderledes at arbejde i IDE'en frem for terminalen?
- Spurgte den om godkendelse mindre end du husker fra Cline (hvis du har prøvet det før)?

---

## Hvis du bliver hurtigt færdig

- Prøv den samme opgave med en **anden model** (fx den lille `qwen/qwen3.5-9b`
  vs. `qwen/qwen3.6-35b-a3b`) — mærk forskellen i hastighed og kvalitet
- Prøv en opgave i **dit eget projekt** i stedet for demo-repoet
- Sammenlign `pi`, `opencode` og Continue på **samme opgave** — hvilken føltes bedst?

---

→ Næste: [003 · IDE-agent](WORKSHOP-A-003-IDE-AGENT.md)
