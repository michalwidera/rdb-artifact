# MANIFEST — przypięcia pakietu artefaktów

Stan: **2026-08-19**. Budowany w ramach K9b (`paper-arXiv/debs/plan-realizacji-K9b.md`).
Każde SHA jest pełne, czterdziestoznakowe. Nazwa gałęzi **nigdy** nie jest tu
identyfikatorem wersji — służy wyłącznie do wskazania, gdzie commit leży.

## 1. Repozytoria

| Repozytorium | URL | Gałąź główna | Rola |
|---|---|---|---|
| `retractordb` | `git@github.com:michalwidera/retractordb.git` | `master` | silnik |
| `rdb-experiment` | `git@github.com:michalwidera/rdb-experiment.git` | `main` | kampanie i dane |
| `rdb-artifact` | `git@github.com:michalwidera/rdb-artifact.git` | `main` | ten pakiet |
| `dokumentacja-rdb` | — | `main` | dokumentacja PL (kanoniczna) |
| `documentation-rdb` | — | `main` | dokumentacja EN (pochodna) |
| `paper-arXiv` | — | `main` | artykuł |

## 2. Dwie osie przypięcia

Pakiet **nie ma jednego SHA silnika**. Oś pierwsza to wersja wydana, oś druga to
rewizja pomiarowa każdej kampanii. Mylenie ich jest błędem, który ten manifest
istnieje po to, żeby uniemożliwić.

### 2.1. Wersja wydana

| Pozycja | SHA | Uwaga |
|---|---|---|
| `retractordb` `master` | `02ef34ab62c4889b6f9971e7bbe06c91794b3838` | stan na 2026-08-19; **żadna liczba w artykule nie pochodzi z tej rewizji** |
| `rdb-experiment` `main` | `a9d5e18e75ef7cf5dd8a63619f469517e13aa4af` | zbiega się z przypięciem K24e |

### 2.2. Rewizje pomiarowe per kampania

Każda pozycja jest utrwalona tagiem adnotowanym o tej samej nazwie w obu
repozytoriach i leży na gałęzi głównej.

| Tag | Silnik (`retractordb`) | Eksperyment (`rdb-experiment`) | Artefakt w artykule |
|---|---|---|---|
| `campaign/K6c-W2-W7` | `e1e5181141f96965da4a092f7e7191f8cb0b2748` | `f4483ef20c3bb3b6936f96709a593d1922943ada` (tag `campaign/K6c`) | `tab:k6-primary`, rodziny W2–W7 |
| `campaign/K6c-W8-W9` | `1bb2d2ce8bec35cd0ab46d168249b706ccbaf303` | jak wyżej — **do rozdzielenia, K9b/Krok 2** | `tab:k6-primary`, rodziny W8–W9 |
| `campaign/K18` | `bc37186ac87cb944d76cf74c7be92706a4a3a87f` | `e1e38ebe650d4c2752b98e78b463f93fe81b3d0e` | przepustowość, opóźnienie, stabilność powtórzenia |
| `campaign/K22v5` | `dd733e3792fbcd5727db244b802610a6d710b8dc` | `0390a8910d72ecaa80772f3fd31a5f18a05369aa` | `tab:k22-constructs` |
| `campaign/H9-K26v3` | `856ee54b0f4ab450a6b61e3c08e045f404a79488` | `81bf4bea00efb922678862c90462fb3c0dfe5fda` | `tab:h9-primary` |
| `campaign/H10-K24d` | `34db1a291fff686d63402270722edf9c772bd4b6` | `15ee150a779e5374248f8172d197b976d604416d` | **zastąpiona przez K24e** — zapis historyczny |
| `campaign/H10-K24e` | `ef18105701158db9986d57fd74defdda72920871` | `a9d5e18e75ef7cf5dd8a63619f469517e13aa4af` | `tab:tail-exactness` |

Artykuł podaje dla K22 dodatkowo rewizje `3366f13` (aparatura, korpus, progi)
i `a9af132` (werdykt), różne od `0390a89` z tagu. Uzgodnienie: **K9b/Krok 2**.

### 2.3. Wyjątek K24e — przypięcie przeniesione na pozycję gałęzi głównej

Kampanię K24e wykonano na rewizji `e2a61ffff77f0ec393aded2c220379db1564af44`,
na gałęzi `issue_232-k24h10`. Gałąź scalono **squashem** jako `ef18105`
i usunięto; `e2a61ff` przestał być osiągalny z jakiegokolwiek klonu.

Przypięcie przeniesiono na `ef18105` po sprawdzeniu, że drzewo `src/` obu
rewizji jest identyczne **co do obiektu**:

```
e2a61ff:src == ef18105:src == 5ddad0fc7d56fb9b468d31905a6689e9896ddb39
```

Różnice między `e2a61ff` a `ef18105` dotyczą wyłącznie testów (`k24h10_exact_tails`,
`test_h10aGate.cpp`, `research_gate/h10`). Dowód jest sprawdzalny bez `e2a61ff`:

```bash
git -C retractordb rev-parse campaign/H10-K24e^{}:src
# 5ddad0fc7d56fb9b468d31905a6689e9896ddb39
```

Metadane skasowanej rewizji zachowane w `paper-arXiv/debs/k9b/e2a61ff-provenance.txt`.
Oba pliki `.tex` artykułu niosą nadal `e2a61ff`; decyzja o podmianie należy do
K9b/Krok 9.

## 3. Provenance tabel i figur artykułu

`[K9b/Krok 2]` — kolumny „pytanie" i „status" wypełnia mapa: [`MAP.md`](MAP.md).

| Artefakt | Kampania | Katalog w `rdb-experiment` | Rewizja pomiarowa |
|---|---|---|---|
| `tab:operators` | definicyjna | — | nie dotyczy |
| `tab:repr` | strukturalna | — | nie dotyczy |
| `tab:gap` | przegląd K8 | `paper-arXiv/debs/related_work_k8.md` | nie dotyczy |
| `tab:tail-exactness` | K24e | `results_20260818_K24e/` | `campaign/H10-K24e` |
| `tab:k22-constructs` | K22v5 | `results_20260801_K22v5/` | `campaign/K22v5` |
| `tab:k6-primary` | K6c | `results_20260730_K6c/` | `campaign/K6c-W2-W7`, `campaign/K6c-W8-W9` |
| `tab:h9-primary` | K26v3 | `results_20260814_K26v3/` | `campaign/H9-K26v3` |
| `fig:arch` | diagram | — | nie dotyczy |
| `fig:qrs` | potok ECG | `retractordb/examples/ecg/rec205` | **obraz z 2026-07-14, sprzed napraw silnika — patrz §5** |

Liczby wniesione do tekstu poza tabelami: 75 548 przypadków / 143 mln pozycji
(K2/G3, `results_20260726_G3/`), 468 220 faz różnicy + 2 239 488 faz AGSE
(K19, `results_20260728_K19/`), 13 silnikowych sprawdzeń tożsamości
(K18, `results_20260728_K18/`), liczby planów i obserwacji z K24e.

## 4. Surowe archiwa poza git

Polityka: `*raw.tar.gz` nie wchodzi do git (mogą przekroczyć limit 100 MB
GitHub), indeks SHA-256 zawartości zostaje w git obok archiwum.

**Parzystość na 2026-08-19: 16 indeksów, 12 archiwów obecnych, 4 nieobecne.**

| Archiwum | Rozmiar | Stan |
|---|---|---|
| `results_20260730_K6c/ablation/study_06_W8/..._raw.tar.gz` | 155 MB | **nieobecne** — poszukiwane na komputerze stacjonarnym autora |
| `results_20260730_K6c/ablation/study_07_W9/..._raw.tar.gz` | ~8,6 MB | **nieobecne** — jw. |
| `results_20260731_hygiene220/results/raw.tar.gz` | nieznany | **nieobecne** — jw. |
| `results_20260814_K26v3/K26v3-P8_raw.tar.gz` | nieznany | **nieobecne** — jw. |
| `results_20260730_K6c/ablation/study_01_W2 … study_05_W7` | 9,1 / 7,3 / 4,9 / 3,2 / 2,6 MB | obecne |
| `results_20260730_K6b/ablation/study_01_W2` | 7,7 MB | obecne |
| `results_20260728_K4`, `K5`, `K5_rerun`, 3× `hygiene` | 68 KB – 192 KB | obecne |

**Treść nieobecnych archiwów nie jest utracona jako opis:** indeks SHA-256
każdego pliku wewnątrz archiwum jest w git. Utracona jest możliwość
rozpakowania. Ustalenie losu czterech pozycji: przewidziane na tydzień od
2026-08-24. `[K9b/Krok 3]`

## 5. Znane granice tego pakietu

1. **`fig:qrs` jest spoza trybu analitycznego.** Obraz w artykule powstał
   2026-07-14, na silniku sprzed napraw rachunku ogona. Dziś silnik ma dziewięć
   klas dokładnych na dziewięć, więc regeneracja da inny przebieg brzegowy.
   Rozstrzygnięcie: regeneracja w ramach K9b. `[K9b/Krok 5]`
2. **Cztery archiwa raw są nieobecne** — patrz §4.
3. **Tryb pomiarowy nie obiecuje identycznych czasów.** Sprawdza platformę
   i provenance przed startem; wyniki czasowe zależą od sprzętu.
4. **DOI nie jest jeszcze nadany** — decyzja D-2 planu K9b: po decyzji
   o zgłoszeniu artykułu.
