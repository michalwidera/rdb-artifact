# MAPA KAMPANII — co która odpowiada i czy nadal obowiązuje

Ten plik istnieje po to, żeby czterdzieści dwa katalogi `results_*`
w `rdb-experiment` dały się przeczytać przez kogoś, kto ich nie tworzył.
Manifest mówi, **na czym** mierzono; mapa mówi, **co** mierzono i **czy odczyt
nadal obowiązuje**.

Status ma trzy wartości:

* **obowiązujący** — wynik niesiony przez artykuł albo aktualny zapis projektu;
* **zastąpiony przez X** — wynik poprawny w swoim czasie, wycofany przez
  późniejszy przebieg; zostaje w pakiecie jako zapis historyczny;
* **kontrola** — badanie higieniczne albo diagnostyka aparatury, nigdy nie było
  wynikiem artykułu.

Uzupełnianie tej tabeli jest zadaniem **K9b/Krok 2**; poniżej wypełnione są
pozycje, na których stoi artykuł, oraz te, których status jest już rozstrzygnięty
w dzienniku badawczym. Pozycje `[Krok 2]` czekają na przepisanie z
`paper-arXiv/debs/research_plan.md` §14.9–§14.22.

## Kampanie niosące treść artykułu

| Katalog | Kryptonim | Pytanie, na które odpowiada | Status |
|---|---|---|---|
| `results_20260818_K24e` | K24e / H10 | Czy statyczny rachunek początku logicznego i ogona startowego jest dokładny w każdej klasie operatorów? | **obowiązujący** — dziewięć klas dokładnych na dziewięć; źródło `tab:tail-exactness` |
| `results_20260814_K26v3` | K26v3 / H9 | Czy współdzielenie podplanów daje redukcję planu bez kosztu czasowego? | **obowiązujący w klasie `Q=8`**, 3/3 rodziny; upoważnienie **nie** rozciąga się na ogólną przewagę wydajnościową; źródło `tab:h9-primary` |
| `results_20260801_K22v5` | K22v5 / H8 | Jaki jest koszt specyfikacji i modyfikacji zapytania wobec rozwiązań proceduralnych? | **obowiązujący** — wynik opisowy `C1=C3=C4=0`; metryka ma podłogę jednostkową i tak jest opisana; źródło `tab:k22-constructs` |
| `results_20260730_K6c` | K6c | Gdzie leży granica zasobowa planu wielozapytaniowego? | **obowiązujący** — granica zmierzona; **model kosztu slotu nieudany** (MAE_test 258%) i tak opisany; źródło `tab:k6-primary` |
| `results_20260728_K18` | K18 | Czy powtórzenie nagrania daje bitowo identyczne artefakty i czy przeplot/rozplot jest tożsamością? | **obowiązujący** — 67 plików bez różnicy poza 8-bajtowym znacznikiem czasu; 13 sprawdzeń tożsamości |
| `results_20260728_K19` | K19 | Skala korpusu faz różnicy i AGSE | **obowiązujący** — 468 220 + 2 239 488 faz |
| `results_20260726_G3` | K2 / G3 | Most SDF/CSDF: zgodność z oracle'em na korpusie planów | **obowiązujący** — 75 548 przypadków / 143 mln pozycji |

## Kampanie zastąpione — zapis historyczny

| Katalog | Kryptonim | Czym był | Status |
|---|---|---|---|
| `results_20260807_K24d` | K24d | Ten sam pomiar co K24e, na silniku `34db1a2`: sześć klas dokładnych z dziewięciu | **zastąpiony przez K24e** (2026-08-18) |
| `results_20260807_K24p` | K24p | Powtórzenie po zmianie silnika, opisuje `db4a360` | **zastąpiony przez K24d** |
| `results_20260803_K24` | K24 | Pierwsza kampania łuku; ujawniła pięć defektów silnika | **zastąpiony przez K24p** |
| `results_20260804_K24r` | K24r | Potwierdzenie poza próbą członu (a) | **zastąpiony przez K24d** |
| `results_20260804_K24b` | K24b | Domknięcie członu (b), ziarno `20260805` | **zastąpiony przez K24d** |
| `results_20260810_K26v2` | K26v2 | Iteracja H9 bez werdyktu | **zastąpiony przez K26v3** |
| `results_20260809_K26` | K26 | Iteracja H9 zamknięta jako `apparatus` | **zastąpiony przez K26v3** |
| `results_20260808_K23v2` | K23 iter. 2 | Iteracja H9; dwie rodziny odpadły na bramce poprawności, werdykt: **brak werdyktu** | **zastąpiony przez K26v3** |
| `results_20260808_K23` | K23 iter. 1 | Pierwsza iteracja łuku H9 | **zastąpiony przez K23v2** |
| `results_20260801_K22`, `_K22v2`, `_K22v3`, `_K22v4` | K22 v1–v4 | Wcześniejsze wersje kampanii kosztu specyfikacji | **zastąpione przez K22v5** |
| `results_20260730_K6`, `_K6b` | K6, K6b | Wcześniejsze wersje kampanii kosztowej | **zastąpione przez K6c** |
| `results_20260729_K5`, `_K5_rerun` | K5 | Kampania semantyczna sprzed naprawy F9 | **zastąpiony** — rodzina W4 dotknięta naprawą F9 (2026-08-09) |

## Kontrole i diagnostyka aparatury

| Katalog | Czym jest | Status |
|---|---|---|
| `results_20260729_hygiene`, `results_20260730_hygiene`, `results_20260731_hygiene`, `_hygiene217`, `_hygiene220` | badania higieniczne aparatury pomiarowej | **kontrola** — nigdy nie były wynikiem artykułu |
| `results_20260731_instrument` | wprowadzenie sondy pomiarowej | **kontrola** |
| `results_20260731_costmodel3` | trzecia próba modelu kosztu slotu | **kontrola** — model nieudany, opisany w K6c |
| `results_20260721_bufferfix` | diagnostyka odczytu bez bufora (`facctxtsrc`) | **kontrola** |

## Pozostałe — do przepisania w Kroku 2

`results_20260716`, `results_20260717`, `results_20260718`, `results_20260719`,
`results_20260721`, `results_20260722_thick_mesh`, `results_20260725`,
`results_20260726_G1`, `results_20260728_K4`, `results_20260728_extend`

`[K9b/Krok 2]` — pytanie i status z `research_plan.md` §14 oraz `JOURNAL.md`
repozytorium eksperymentu. Do czasu wypełnienia traktować jako **materiał
przed-G1**, do którego artykuł się nie odwołuje w twierdzeniach o bieżącej
rewizji.

## Hipotezy — stan

| Hipoteza | Treść | Werdykt |
|---|---|---|
| **H8** | koszt specyfikacji i modyfikacji niższy niż w rozwiązaniach proceduralnych | **podzielona**; wynik opisowy, nigdzie nie pada „H8 obalona" (K22v5) |
| **H9** | współdzielenie podplanów redukuje plan bez kosztu czasowego | **wsparta w klasie `Q=8`**, 3/3 rodziny (K26v3, 2026-08-16) |
| **H10a** | statyczny rachunek ogona jest dokładny | **wsparta**, dziewięć klas na dziewięć (K24e, 2026-08-18) |
| **H10b** | rachunek jest lokalny dla węzłów `#` o obu składowych deklarowanych | **wsparta**, 2310/2310 (K24b, potwierdzenie K24d) |
