# Workshop A · 001 · Onboarding: Forbered dig inden vi mødes

📋 [Agenda](~/src/obsidian-work-notes/projects/2026-06-nine-ai-local-workshops/agenda-workshop-a.md)

Hejsa venner,

For at vi kommer så hurtigt i gang som muligt, vil det være bedst hvis I downloader LM Studio og en model eller to, inden vi mødes. Jeg frygter lidt ventetiden hvis vi alle skal downloade 10+ GB samtidig for at komme i gang med workshoppen.

Vi kommer primært til at bruge LM Studio-modeller — det er min erfaring at de kører bedst på de fleste computere.

Derfor: hvis I kan nå det inden i morgen, så følg denne vejledning.

## 1. Installer LM Studio

For Mac-brugere er det nemmeste nok kommandolinje-værktøjet `lms` (LM Studio's CLI til headless-deployment):

https://lmstudio.ai/download (bemærk linket for LLMster, bedst for Mac brugere)

Når det er installeret, bør du kunne starte serveren:

```
$ lms --help
$ lms server start
The server is running on port 1234.
```

(windows brugere kan starte applikationen som derefter vil starte serveren på port 1234)

## 2. Installer modeller

Når serveren kører, er vi klar til at hente modeller.

**Har du 32 GB RAM eller mindre**, så hent disse to:

```
lms get qwen/qwen2.5-coder-7b
lms get qwen/qwen3.5-9b
```

(windows-brugere: alternativt kan du hente fra LM Studio GUI)

**Har du mere end 32 GB RAM**, så hent også denne:

```
lms get qwen/qwen3.6-35b-a3b
```

## 3. Resten tager vi sammen

Resten af opsætningen tager vi i morgen på workshoppen.

Det vil være virkelig godt hvis I kan nå ovenstående inden da, for det kan tage tid at downloade modellerne — så har vi mere tid til at nørde på selve workshoppen.

Vi ses!

---

→ Næste: [002 · Øvelser](WORKSHOP-A-002-EXERCISES.md)
