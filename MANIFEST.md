# MANIFEST — przypięcia pakietu artefaktów

Stan: **2026-08-20**. Budowany w ramach K9b
(`paper-arXiv/debs/done/plan-realizacji-K9b.md`). Każde przypięcie repozytorium jest
pełnym, czterdziestoznakowym SHA. Nazwa gałęzi nie jest identyfikatorem wersji.

## 1. Repozytoria i przypięty układ domyślny

Domyślne odtworzenie i wszystkie **nowe** uruchomienia używają przypiętego
snapshotu aktualnego HEAD. Jest to odrębna oś od historycznego provenance
kampanii z §2.2: dawnych pomiarów nie przepisuje się na nowszy kod.

| Repozytorium | URL | SHA domyślnego snapshotu | Rola | Lustro recenzenckie |
|---|---|---|---|---|
| `retractordb` | `https://github.com/michalwidera/retractordb.git` | `6dec187e6b0cc66d119d4d9a9dc384e93adf6839` | silnik i poprawione narzędzia | `retractordb-engine` |
| `rdb-experiment` | `https://github.com/michalwidera/rdb-experiment.git` | `b713e1df47a5f94357f708706b85f5603f261534` | kampanie i dane | `retractordb-experiment` |
| `dokumentacja-rdb` | `https://github.com/michalwidera/dokumentacja-rdb.git` | `ed00f6aa3f2d7b7bd1c91e2eb7248a1ee8de3bf1` | dokumentacja PL (kanoniczna) | `dokumentacja-rdb` |
| `documentation-rdb` | `https://github.com/michalwidera/documentation-rdb.git` | `8d543c8cbf95ab7cdb41049be3b30163e225bf5b` | dokumentacja EN (pochodna) | `documentation-rdb` |
| `paper-arXiv` | `https://github.com/michalwidera/paper-arXiv.git` | `b23aaf33ffef1cc15f77f83844da692fe9b1d96e` — tag `artifact/K9b` | artykuł i plan badawczy — **opcjonalne, prywatne do recenzji** (D-6) | — nie lustrzone |

Repozytorium `rdb-artifact` jest punktem wejścia, więc nie przypina własnego
SHA w tym samym commicie. Jego URL to
`https://github.com/michalwidera/rdb-artifact.git` i jest **publiczny od
2026-08-23**. Jego lustro recenzenckie dostanie identyfikator
`retractordb-artifact` i powstanie po zamknięciu przypięcia; cztery pozostałe
istnieją od 2026-08-26. Identyfikatory luster nie są losowane — wybiera je
autor, więc adresy mogą trafić do bibliografii przed utworzeniem luster.

**Przypięcie `paper-arXiv` wskazuje tag adnotowany `artifact/K9b`, nie czubek
gałęzi (decyzja 2026-08-23).** Cztery pozostałe repozytoria przypinają się przez
SHA snapshotu, bo ich `HEAD` rusza się rzadko i z powodów, które pakietu
dotyczą. Repozytorium artykułu zachowuje się inaczej: w czternaście dni przed
tym tagiem dostało **57 commitów**, z czego 28 dotknęło `debs/`, 19 `usecases/`,
a właściwego artykułu (`arxiv/`, `figures/`) — **dwa**. Przypięcie do `HEAD`
odpowiadałoby więc na pytanie „jaki jest ostatni commit repozytorium", a ma
odpowiadać na „do której rewizji artykułu należą te liczby".

Przypięcie rusza się przy kamieniu milowym, nie przy poprawce redakcyjnej.
Następny ruch: `artifact/submission` w K17. Jest to ten sam wzorzec, co tagi
`campaign/*` w §2.2, i z tego samego powodu.

**Cztery pierwsze repozytoria są publiczne i wymagane. Piąte nie jest ani jednym,
ani drugim (decyzja D-6, 2026-08-23).** `paper-arXiv` niesie artykuł przed
recenzją i pozostaje prywatne aż do publikacji; jest tu przypięte **wyłącznie
jako proweniencja** — żeby pytanie „do której rewizji artykułu należą te liczby"
miało odpowiedź. Żaden tryb odtworzenia go nie czyta: `bin/reproduce_analytic.sh`
i `bin/reproduce_measure.sh` nie mają do niego ani jednego odwołania.

`bin/checkout.sh` próbuje je sklonować i **idzie dalej**, jeżeli nie może;
`bin/verify_pins.sh` wypisuje wtedy `SKIP` z przypiętym SHA. Wymaganie go
blokowało cały pakiet: obcy z publicznym URL-em dostawał cztery repozytoria
i kod 2 z bramki proweniencji, bez możliwości zregenerowania czegokolwiek.

## 2. Dwie osie przypięcia

### 2.1. Kod do odtworzenia i nowych pomiarów

Kod silnika i narzędzia pochodzą z pełnego SHA `6dec187e6b0cc66d119d4d9a9dc384e93adf6839`.
Ten snapshot zawiera krytyczne poprawki narzędzi wprowadzone po rewizjach
pomiarowych. Wynik uzyskany na nim jest **nowym odtworzeniem**, nie historycznym
pomiarem z tabel artykułu.

Przypięcie podbito 2026-08-23 z `661635072872b2a3dbd432f3d4a2654f0fc1b32e`.
Podbicie nie rusza silnika: drzewo `src/` obu rewizji jest identyczne co do
obiektu.

```text
661635072872b2a3dbd432f3d4a2654f0fc1b32e:src
  == 6dec187e6b0cc66d119d4d9a9dc384e93adf6839:src
  == 661259115d5c9301e53d0b163796148e7812ea7b
```

Sześć commitów między nimi dotyczy `scripts/`, `.agents/`, `README.md`
i konfiguracji CI. Dlatego produkty trybu analitycznego — w tym `fig:qrs`,
zregenerowany na starszej z tych dwóch rewizji — pozostają ważne bez powtórzenia.

### 2.2. Rewizje, na których wykonano historyczne kampanie

| Tag silnika | Silnik zmierzony | Tag eksperymentu | Eksperyment | Artefakt w artykule |
|---|---|---|---|---|
| `campaign/K6c-W2-W7` | `e1e5181141f96965da4a092f7e7191f8cb0b2748` | `campaign/K6c` | `f4483ef20c3bb3b6936f96709a593d1922943ada` | `tab:k6-primary`, W2–W7 |
| `campaign/K6c-W8-W9` | `1bb2d2ce8bec35cd0ab46d168249b706ccbaf303` | `campaign/K6c` | `f4483ef20c3bb3b6936f96709a593d1922943ada` | `tab:k6-primary`, W8–W9 |
| `campaign/K18` | `bc37186ac87cb944d76cf74c7be92706a4a3a87f` | `campaign/K18` | `e1e38ebe650d4c2752b98e78b463f93fe81b3d0e` | przepustowość, opóźnienie, stabilność powtórzenia |
| `campaign/K22v5` | `dd733e3792fbcd5727db244b802610a6d710b8dc` | `campaign/K22v5` | `0390a8910d72ecaa80772f3fd31a5f18a05369aa` | `tab:k22-constructs` |
| `campaign/H9-K26v3` | `856ee54b0f4ab450a6b61e3c08e045f404a79488` | `campaign/H9-K26v3` | `81bf4bea00efb922678862c90462fb3c0dfe5fda` | `tab:h9-primary` |
| `campaign/H10-K24d` | `34db1a291fff686d63402270722edf9c772bd4b6` | `campaign/H10-K24d` | `15ee150a779e5374248f8172d197b976d604416d` | zastąpiony przez K24e |
| `campaign/H10-K24e` | `e2a61ffff77f0ec393aded2c220379db1564af44` | `campaign/H10-K24e` | `a9d5e18e75ef7cf5dd8a63619f469517e13aa4af` | `tab:tail-exactness` |

Tag silnika K24e wskazuje osiągalny commit `ef18105701158db9986d57fd74defdda72920871`,
którego drzewo `src/` jest obiektowo identyczne ze zmierzonym
`e2a61ffff77f0ec393aded2c220379db1564af44` — patrz
§2.4. W tabeli pole „Silnik zmierzony” zachowuje faktyczne provenance.

### 2.3. Trzy role rewizji K22v5

Rewizje K22 nie są konkurencyjnymi kandydatami do jednego pola:

| Rola | SHA `rdb-experiment` | Dowód |
|---|---|---|
| zamrożenie aparatury i korpusu | `3366f1379803f1d46db25c515b9964621372d52f` | `results_20260801_K22v5/manifest.md` |
| werdykt kampanii | `a9af1320c5679faf7f3746c82c3b500d65eb1541` | commit dodający raport, wyniki i pakiet dowodowy |
| komplet z analizą post hoc i tag kampanii | `0390a8910d72ecaa80772f3fd31a5f18a05369aa` | `campaign/K22v5` |

Do checkoutu historycznej kampanii służy ostatnia rewizja, bo zawiera
zamrożenie, werdykt i analizę post hoc. Manifest zachowuje wszystkie trzy role.

### 2.4. Wyjątek K24e — osiągalny tag i faktyczna rewizja pomiarowa

Kampanię K24e wykonano na `e2a61ffff77f0ec393aded2c220379db1564af44`.
Po squash-merge osiągalny tag przeniesiono na `ef18105701158db9986d57fd74defdda72920871`.
Drzewo kodu silnika jest identyczne co do obiektu:

```text
e2a61ffff77f0ec393aded2c220379db1564af44:src
  == ef18105701158db9986d57fd74defdda72920871:src
  == 5ddad0fc7d56fb9b468d31905a6689e9896ddb39
```

Metadane skasowanej rewizji zachowuje
`paper-arXiv/debs/k9b/e2a61ff-provenance.txt`. Różnice wobec squasha dotyczą
testów, nie drzewa `src/`.

## 3. Provenance tabel i figur artykułu

| Artefakt | Kampania | Katalog w `rdb-experiment` | Rewizja pomiarowa |
|---|---|---|---|
| `tab:operators` | definicyjna | — | nie dotyczy |
| `tab:repr` | strukturalna | `results_20260725/` | historyczny oracle, bez pomiaru czasu |
| `tab:gap` | przegląd K8 | `paper-arXiv/debs/related_work_k8.md` | nie dotyczy |
| `tab:tail-exactness` | K24e | `results_20260818_K24e/` | `e2a61ffff77f0ec393aded2c220379db1564af44` |
| `tab:k22-constructs` | K22v5 | `results_20260801_K22v5/` | `campaign/K22v5` i role z §2.3 |
| `tab:k6-primary` | K6c | `results_20260730_K6c/` | `campaign/K6c-W2-W7`, `campaign/K6c-W8-W9` |
| `tab:h9-primary` | K26v3 | `results_20260814_K26v3/` | `campaign/H9-K26v3` |
| `fig:arch` | diagram | — | nie dotyczy |
| `fig:qrs` | potok ECG | `retractordb/examples/ecg/rec205` | zregenerowany 2026-08-20 na `6616350…`; okno przypięte przez `-m 1671` |

Liczby wniesione do tekstu poza tabelami: 75 548 przypadków / 143 065 922
pozycji (K2/G3, `results_20260726_G3/`, `results/equivalence.json`, klucz
`totals`), 468 220 faz różnicy + 2 239 488 faz AGSE (K19,
`results_20260728_K19/`), **13 silnikowych sprawdzeń tożsamości** (K2/G3, most
oracle — silnik, `results/engine.json`, klucz `cases`) oraz liczby planów
i obserwacji z K24e (10 010 planów, 35 835 obserwacji węzłowych w próbie,
35 703 poza próbą).

Do 2026-08-20 te 13 sprawdzeń było w planie i w tym manifeście przypisane do
K18. Przypisanie było błędne: K18 wnosi do tego zdania artykułu **deterministyczne
artefakty** (67 porównanych plików z dwóch przebiegów replay plus sześć
sprawdzeń round-trip, `results_20260728_K18/exactness/`), a nie sprawdzenia
tożsamości. Sama liczba 13 jest poprawna i nie zmienia się — zmienia się jej
źródło (znalezisko K9b-F4).

## 4. Surowe archiwa

Istnieje 16 plików indeksów. Opisują one 18 archiwów, ponieważ indeks K26v3 P8
obejmuje trzy osobne rodziny. **Klon niesie wszystkie 18** — siedemnaście jako
pliki, osiemnaste (`study_06_W8`) w czterech częściach.

Kolumna „bajty treści” jest sumą rozmiarów wpisów indeksu, „bajty archiwum”
rzeczywistym rozmiarem skompresowanego pliku, a „w git” mówi, czy `git clone`
przynosi tę pozycję — bo to jest jedyne pytanie, które obchodzi obcego.

| Archiwum | Wpisów | Bajty treści | Bajty archiwum | w git | SHA-256 archiwum |
|---|---:|---:|---:|:---:|---|
| `results_20260728_K4/results/raw.tar.gz` | 820 | 405526 | 65666 | tak | `407cb32400c57fdc7c9f969821de134062120bce57399ac051c6162618d79968` |
| `results_20260729_K5/results/raw.tar.gz` | 2701 | 1233361 | 85273 | tak | `975af64bc94cef2949fdfbc442866c8486deadc9acfee7bde840e35ecea99460` |
| `results_20260729_K5_rerun/results/raw.tar.gz` | 4213 | 3555141 | 194945 | tak | `cd20f8d38984ac4164a9b45a4aee601441271215ff223785b0790d2df59503dd` |
| `results_20260729_hygiene/results/raw.tar.gz` | 813 | 518514 | 139161 | tak | `340872b0f338bd92bb2ae204456eefd308b85b3047002353fc48f96ba9aeec9b` |
| `results_20260730_K6b/ablation/study_01_W2/raw.tar.gz` | 1440 | 17596571 | 8062371 | tak | `8bc8b52bda07c3e29b5e341b163587069002139fa3751c3dd81dc30d60e6e0e7` |
| `results_20260730_K6c/ablation/study_01_W2/raw.tar.gz` | 1440 | 20778051 | 9537281 | tak | `3380390d2af43c768387f0da7e8d0f0f5dfceaaa7563201c382339b04baf92ee` |
| `results_20260730_K6c/ablation/study_02_W3/raw.tar.gz` | 960 | 16516075 | 7593722 | tak | `105c211b951f06a429591a95273c2e85f08c2dc305bedf49459bc5392cd63618` |
| `results_20260730_K6c/ablation/study_03_W4/raw.tar.gz` | 960 | 11321161 | 5066701 | tak | `841a882a3dec0a83dde685ae19dd3d7996e81673b08de5cd16de012766c2d401` |
| `results_20260730_K6c/ablation/study_04_W5/raw.tar.gz` | 480 | 7323997 | 3259508 | tak | `ce46589c8c850d9eb0a538e63c93bd6bf1f27ed7453b1c6d2394b95ce99023ed` |
| `results_20260730_K6c/ablation/study_05_W7/raw.tar.gz` | 480 | 5977472 | 2712636 | tak | `3d6bf640c7a0ddbe4bb32f87dcb084cabebbf5efa119352473ba5621d684dec4` |
| `results_20260730_K6c/ablation/study_06_W8/results_20260730_K6c_study_06_W8_raw.tar.gz` | 1080 | 642032935 | 162167985 | części | `03f503fee2504ef46d8d5f367807442be28593f8081a487911475726609d4e51` |
| `results_20260730_K6c/ablation/study_07_W9/results_20260730_K6c_study_07_W9_raw.tar.gz` | 960 | 154719433 | 8945852 | tak | `0f0b504a0dd3f50f12ae4ef5bd60e90c2e2702215388fd84d6dc54ee06055280` |
| `results_20260730_hygiene/results/raw.tar.gz` | 813 | 533667 | 140821 | tak | `b582f33356f73bf0a4e2f200733d5cc0c8a5bd2cac2c5367f61c61db290695b5` |
| `results_20260731_hygiene/results/raw.tar.gz` | 1370 | 607518 | 163996 | tak | `42bc80319943ad697dede45e1cab78b4b9fb9ff94c0671ed66217872ca54b50f` |
| `results_20260731_hygiene220/results/raw.tar.gz` | 1371 | 623740 | 167437 | tak | `6993a2877741d65e480167a7068370b06416dee278c00f4f156c4232a205963c` |
| `artifacts/K26v3/k26v3_archives/K26v3-P8-F9-R1.tar.gz` | 27432 | — | 37667672 | tak | `8c4ac248eb8e5f91f35ca90ce61f1f3ff10eef7db58042ab62238cd349b256a3` |
| `artifacts/K26v3/k26v3_archives/K26v3-P8-F9-R2.tar.gz` | 26788 | — | 20536480 | tak | `62b065a89e82126c08f2a973195e10688bd1adfcbdb2840d5f57ea22248c0db7` |
| `artifacts/K26v3/k26v3_archives/K26v3-P8-F9-X.tar.gz` | 34298 | — | 38023659 | tak | `3deb300733f3662dd042ca0109eb73aa696c4eb5da7d8b3b62745735c94c2e04` |

URL/DOI zewnętrznego depozytu pozostaje `TBA` zgodnie z decyzją D-2 — ale nie
jest już warunkiem dostępu do danych, bo dane są w repozytorium.

### 4.1. Co się zmieniło 2026-08-23

**Trzy archiwa uznane wcześniej za nieobecne odnalazły się** na komputerze
stacjonarnym, zgodnie z przypuszczeniem zapisanym 2026-08-19: `study_06_W8`,
`study_07_W9` i `hygiene220`. Nie przyjęto samej obecności za dowód. Dla
każdego porównano **każdy wpis** indeksu `raw.index.tsv` — ścieżkę, rozmiar
i SHA-256 — ze strumieniem odczytanym z archiwum:

| Archiwum | Wpisów indeksu | Plików w archiwum | Niezgodnych | Spoza indeksu |
|---|---:|---:|---:|---:|
| `study_06_W8` | 1080 | 1080 | 0 | 0 |
| `study_07_W9` | 960 | 960 | 0 | 0 |
| `hygiene220` | 1371 | 1371 | 0 | 0 |

### 4.2. Dlaczego trafiły do repozytorium, a nie do przypisu

Odzyskanie ujawniło, że stan zastany był **mieszany, nie spójny**. Polityka
z 2026-07-31 kierowała każde `*raw.tar.gz` poza git, ale `.gitignore` nie
przestaje śledzić tego, co już było śledzone — piętnaście archiwów sprzed tej
daty nigdy z repozytorium nie wyszło. Klon niósł więc 15 z 18 pozycji i o trzech
pozostałych mówił jedynie, że istnieją gdzieś na jednej maszynie.

Wersja manifestu sprzed tej korekty zapisywała je jako „obecne", co przechodziło
na dysku autora i **oblewało na każdym świeżym klonie** — dokładnie klasa błędu
z K9b-F5: bramka, której nikt nie uruchomił z cudzego katalogu.

Decyzja z 2026-08-23 wyrównuje stan w drugą stronę: trzy pozycje wchodzą do
repozytorium (`rdb-experiment` commit `b713e1d`). `study_07_W9` (8,5 MiB)
i `hygiene220` (0,1 MiB) mieszczą się w limitach GitHuba i wchodzą wprost.
`study_06_W8` (154,6 MiB) przekracza twardy limit 100 MB na plik, więc wchodzi
w **czterech częściach po 45 MiB** obok indeksu `.parts.tsv` z SHA-256 całości
i każdej części.

```bash
# odtworzenie calosci ze sledzonych czesci, z weryfikacja
rdb-experiment/lib/raw_parts.sh join \
  results_20260730_K6c/ablation/study_06_W8/results_20260730_K6c_study_06_W8_raw.tar.gz
```

Sama całość W8 pozostaje poza git świadomie: składalna, nie przechowywana dwa
razy. Koszt decyzji jest trwały i przyjęty — `.git` rośnie o ~171 MB, których
gzip nie delta-kompresuje, i każdy klon je ciągnie.

Milczenie nadal nie jest traktowane jako dostępność. `bin/verify_pins.sh
snapshot` sprawdza siedemnaście archiwów po sumie, cztery części W8 po sumie
i rozmiarze, obecność indeksu części, a złożoną całość tylko wtedy, gdy leży na
dysku — bez niej wypisuje `SKIP` z przepisem, nigdy błąd.

## 5. Znane granice tego pakietu

1. `fig:qrs` jest jedyną pozycją §3 wymagającą działającego silnika, więc
   `bin/reproduce_analytic.sh` odtwarza ją tylko wtedy, gdy poda mu się
   `--xretractor` i `--xqry`; bez nich zgłasza `SKIP` wraz z przepisem.
   Okno jest przypięte limitem `-m 1671` (próbki `[1271,1670]`, piki na
   `x=128` i `x=371`) — patrz `REPRODUCE.md` §3.
2. Wszystkie 18 archiwów raw jest obecnych, zweryfikowanych wpis po wpisie
   i **w repozytorium** (2026-08-23) — patrz §4. Klon niesie siedemnaście jako
   pliki i osiemnaste w czterech częściach; `lib/raw_parts.sh join` odtwarza je
   bajtowo. Zewnętrzny depozyt (D-2) przestał być warunkiem dostępu do danych.
3. Tryb pomiarowy nie obiecuje identycznych czasów. Sprawdza platformę
   i provenance przed startem i **niczego nie uruchamia**: start wielodniowego
   przebiegu jest osobnym, świadomym poleceniem wydanym maszynie pomiarowej.
4. Autonomia przebiegu (W-1) jest **sprawdzona empirycznie 2026-08-23** na
   maszynie pomiarowej `pi400` (`6.8.0-2049-raspi-realtime`), z faktycznie
   odciętym kanałem sterującym — patrz `bin/w1_trial/README.md` i dowody
   w `tables/w1/`. Granica, która zostaje: sprawdzono **osprzęt autonomii**,
   nie trzydobowy przebieg K26v3. Odcinek próby liczy ~76 s, więc próba mówi,
   że łańcuch przeżywa restarty i brak hosta, a nie że konkretna kampania
   zmieści się w oknie termicznym.
5. DOI nie jest jeszcze nadany — decyzja D-2: po decyzji o zgłoszeniu artykułu.
6. `paper-arXiv` jest przypięte, ale **nieosiągalne dla obcego** i takie zostanie
   do recenzji (D-6). Skutek praktyczny jest jeden: nie da się sprawdzić, czy
   przypięta rewizja artykułu odpowiada tej, którą czytasz. Wszystko, co służy
   odtworzeniu wyników, jest publiczne.
6. Dwie kampanie niosą aparaturę związaną z miejscem i chwilą pomiaru, co
   `bin/reproduce_analytic.sh` obchodzi jawnie, nie po cichu:
   * K22v5 — `analyze.py` woła `freeze_check.sh`, bramkę **proweniencji
     pomiaru** (gałąź `experiment/20260801_K22`, `retractordb` na `dd733e3`,
     dwa binaria po SHA-256). Po scaleniu gałęzi bramka nie może już przejść
     i nie jest potrzebna do ponownego wyprowadzenia tabeli z danych.
     Proweniencję trybu analitycznego poświadcza `bin/verify_pins.sh`.
   * K22v5 — `manual_hits_review.csv` przechowuje **ścieżki bezwzględne**
     z chwili przeglądu, więc `verify_hits()` przechodzi wyłącznie pod
     `/home/michal/github/rdb-experiment`. `bin/analytic_k22v5.py` powtarza tę
     bramkę na ścieżkach względnych wobec korzenia repozytorium: sprawdza to
     samo (każde trafienie przejrzane i potwierdzone), bez zależności od
     jednego układu katalogów (znalezisko K9b-F3).
