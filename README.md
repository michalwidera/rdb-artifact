# rdb-artifact — pakiet artefaktów RetractorDB

To repozytorium jest **wejściem do wyników**. Nie zawiera ani silnika, ani danych
badawczych — zawiera przypięcia do nich, mapę kampanii i instrukcję odtworzenia.
Jeśli trafiłeś tu z artykułu i nie wiesz, od czego zacząć, czytaj w tej kolejności:

1. [`MAP.md`](MAP.md) — **czym są te wyniki**: która kampania odpowiada na jakie
   pytanie, który werdykt obowiązuje, a który został zastąpiony. Bez tego
   czterdzieści katalogów `results_*` w repozytorium eksperymentu jest nieczytelne.
2. [`MANIFEST.md`](MANIFEST.md) — **na czym je zmierzono**: pełne SHA repozytoriów
   i rewizji pomiarowych, po jednej na kampanię, plus sumy kontrolne archiwów.
3. [`REPRODUCE.md`](REPRODUCE.md) — **jak je powtórzyć**: tryb analityczny
   (regeneracja tabel i figur z zachowanych danych) i tryb pomiarowy.

## Czym jest RetractorDB

Silnik ciągłych zapytań nad strumieniami o deklarowanym takcie, z językiem RQL
i kompilatorem planów. Repozytorium silnika: `retractordb`. Repozytorium
eksperymentów: `rdb-experiment`. Oba są przypięte w [`MANIFEST.md`](MANIFEST.md).

## Zasada przypięcia

**Pakiet nie ma jednego historycznego SHA silnika.** Domyślne odtworzenie i nowe
pomiary używają przypiętego snapshotu aktualnego HEAD z poprawkami narzędzi.
Manifest osobno zachowuje faktyczne rewizje, na których wykonano kampanie.
Tryb historyczny służy do audytu provenance i nigdy nie przedstawia dawnego
pomiaru jako wyniku wykonanego na HEAD.

## Stan

Repozytorium powstaje w ramach kroku **K9b** planu badawczego
(`paper-arXiv/debs/plan-realizacji-K9b.md`). Stan na 2026-08-20:

* manifest, mapa kampanii, kontrola przypięć i kontrola binarium — **gotowe**;
* tryb analityczny (`bin/reproduce_analytic.sh`) — **gotowy**: osiem grup na
  osiem regeneruje się z zachowanych danych i zgadza z zachowanymi produktami;
* tryb pomiarowy (`bin/reproduce_measure.sh`) — kontrola wstępna platformy
  i proweniencji **gotowa**, wraz z odmową startu przy rozjeździe;
* otwarte: empiryczna próba autonomii przebiegu na sprzęcie pomiarowym,
  trzy nieobecne archiwa raw, DOI i upublicznienie repozytorium.

Granice pakietu są wypisane w [`MANIFEST.md`](MANIFEST.md) §5 — czytaj je,
zanim uznasz brak za usterkę.

## Licencja i cytowanie

Patrz [`CITATION.cff`](CITATION.cff). DOI zostanie nadany przed zgłoszeniem
artykułu (decyzja D-2 planu K9b).
