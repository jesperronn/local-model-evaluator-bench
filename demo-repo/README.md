# Workshop demo-repo

Otte små opgaver til at teste `pi` / `opencode` (eller Cline) på et rigtigt
projekt. Sværhedsgrad stiger fra 01 til 08. Hver mappe er uafhængig — du kan
`cd` ind i en enkelt mappe og starte agenten der, eller åbne hele
`demo-repo/` som ét projekt.

## Sådan bruger du det

1. `cd demo-repo/01-slugify-bug` (eller en anden opgave)
2. Start din agent i mappen, fx `pi --provider lmstudio --model qwen/qwen3.6-35b-a3b`
3. Copy-paste prompten fra opgavens `TASK.md` (se nedenfor)
4. Bed agenten køre testen (se tabellen) og blive ved med at rette indtil den er grøn

Der ligger en minimal [`AGENTS.md`](AGENTS.md) i roden — de fleste klienter
(pi, opencode, Cline m.fl.) læser den automatisk og ved dermed hvor testen
kører fra og hvornår opgaven er færdig, uden at vi skal proppe det ind i hver
prompt.

## Opgaverne (nemmest → sværest)

| # | Opgave | Type | Verificering |
|---|--------|------|--------------|
| 01 | [slugify-bug](01-slugify-bug/TASK.md) | Ret en bug i én fil | `npm test` |
| 02 | [debounce-feature](02-debounce-feature/TASK.md) | Implementér en funktion fra bunden | `npm test` |
| 03 | [multifile-cache](03-multifile-cache/TASK.md) | To filer skal spille sammen | `npm test` |
| 04 | [multifile-rename](04-multifile-rename/TASK.md) | Omdøb på tværs af filer | `npm test` |
| 05 | [lint-and-test](05-lint-and-test/TASK.md) | Bug + stil skal begge rettes | `npm test` && `npm run lint` |
| 06 | [multiselect-filter](06-multiselect-filter/TASK.md) | Ny feature + HTML-ændring | `npm test` |
| 07 | [topwords](07-topwords/TASK.md) | Bash-script fra bunden | `./test.sh` |
| 08 | [groupby](08-groupby/TASK.md) | Typed TypeScript-funktion | `npm test` |

Alle otte opgaver har nu en rigtig test, der fejler før rettelsen og består
efter — den bedste demo af en agent der selv opdager og retter fejl, ikke kun
"ser fornuftig ud".

## Kilde

Opgaverne er hentet direkte fra dette repos benchmark-cases
(`cases/*/task.md` + `cases/*/workdir/`) — samme opgaver vi bruger til at måle
model/tool-kombinationer i `bin/bench`. Se `../cases/` for den fulde harness
(inkl. de automatiske checks, som er fjernet her for at holde det simpelt).
