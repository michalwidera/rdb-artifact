# CAMPAIGN MAP — what each one answers and whether it still holds

This file exists so that the forty-two `results_*` directories in
`rdb-experiment` can be read by someone who did not create them. The manifest
says **on what** the measurements were taken; the map says **what** was measured
and **whether the reading still holds**.

Status has three values:

* **current** — a result carried by the paper, or the project's present record;
* **superseded by X** — a result that was correct at its time, or diagnostic,
  whose role was taken over by a later run;
* **control** — a hygiene study or apparatus diagnostic; never a standalone
  result of the paper.

Each of the 42 `results_*` directories has its own row below. The classification
comes from `paper-arXiv/debs/research_plan.md` §3.6 and §14, and from
`rdb-experiment/JOURNAL.md`.

## Campaigns carrying the paper's present content

| Directory | Code name | The question it answers | Status |
|---|---|---|---|
| `results_20260818_K24e` | K24e / H10 — *plan-derived startup boundaries* | Is the static calculus of the logical origin and the startup tail exact in every operator class? | **current** — nine exact classes out of nine, on both seeds; source of `tab:tail-exactness` |
| `results_20260814_K26v3` | K26v3 / H9 — *equivalence-guarded materialization sharing* | Having allowed sharing only after a proof of subplan equivalence, does the compiler arrive at a common materialized subplan on its own — and does the reduction in **logical materialization write volume** come without a time penalty? | **current in the `Q=8` class**, 3/3 families; the primary measure is logical bytes of materialization writes per public record (50.0–58.3% against ablation, 84.4–87.5% against Flink's natural plan), with a time penalty below the 1.05 threshold; the warrant does not extend to peak resident state size or to general performance advantage; source of `tab:h9-primary` |
| `results_20260801_K22v5` | K22v5 / H8 | What is the cost of specifying and modifying a query relative to procedural solutions? | **current** — descriptive result `C1=C3=C4=0`; the metric has a unit floor and is described as such; source of `tab:k22-constructs` |
| `results_20260730_K6c` | K6c | Where does the resource boundary of a multi-query plan lie? | **current** — boundary measured; the slot cost model failed (`MAE_test=258%`) and is described as such; source of `tab:k6-primary` |
| `results_20260728_K18` | K18 | Does repeating a recording produce bit-identical artifacts, and is interleave/de-interleave an identity? | **current** — 67 files with no difference beyond the 8-byte header field; 13 identity checks |
| `results_20260728_K19` | K19 | Do the `SUBTRACT` and AGSE phase formulas and their boundaries agree with the engine? | **current** — 468,220 + 2,239,488 phases; the capacity coverage gap was later measured in `results_20260728_extend` |
| `results_20260728_K4` | K4 | Which R1/R2 rule fires in the existing corpus, and how often? | **current** — five profiles, 400 results; the limitation of the non-reproducible path is stated explicitly |
| `results_20260728_extend` | extend | Did the AGSE capacity defect invalidate K18/K19/K4, and does the corrected revision preserve determinism? | **current as an audit** — no result was invalidated; the 360 Hz timing stage was repeated and exactness confirmed byte for byte |
| `results_20260726_G3` | K2 / G3 | Do the R1 oracle and the bridge to the engine agree over the full corpus? | **current** — 75,548 cases / 143,065,922 positions, plus a 13/13 bridge |
| `results_20260725` | SDF/CSDF axis | Do the four interleave representations share one trace, and what is their structural cost? | **current** — the basis of `tab:repr`; the later K2/G3 extends the bridge to the present semantics but does not replace the comparison of representations |

## Historical context still cited in the paper

These campaigns predate G1. The paper uses them solely as explicitly historical
context, never as evidence of the present performance boundary.

| Directory | Question | Status |
|---|---|---|
| `results_20260716` | The first rate/clients/FIR campaign: where do the execution and emission costs lie? | **current only as historical context** — superseded, for claims about the present revision, by K6c and K18 |
| `results_20260717` | How do the historical NumPy baselines and one Flink configuration compare? | **current only as historical context** — it establishes no ranking between systems |
| `results_20260718` | Are the artifacts deterministic and consistent across architectures? | **current only as a historical cross-architecture result**; present replay is checked by K18 |
| `results_20260719` | Do the 40 ms cost isolation and the subsequent rate/clients measurements localize the source of the tail? | **superseded, for present claims, by `results_20260721_bufferfix` and K18** |
| `results_20260721` | What is the rate threshold, and the influence of clients and FIR depth, before the buffer fix? | **superseded by `results_20260721_bufferfix`**, kept as a reference point |
| `results_20260722_thick_mesh` | Where, in a dense sweep, does the historical threshold between 480 and 510 Hz lie? | **current only as historical context** — it is not the present ceiling |

## Superseded campaigns — the historical record

| Directory | Code name | What it was | Status |
|---|---|---|---|
| `results_20260807_K24d` | K24d | H10 measurement on engine `34db1a2`: six exact classes out of nine | **superseded by K24e** |
| `results_20260807_K24p` | K24p | A repeat after an engine change, describing `db4a360` | **superseded by K24d** |
| `results_20260804_K24r` | K24r | Out-of-sample confirmation of part (a) | **superseded by K24d** |
| `results_20260804_K24b` | K24b | Closing of part (b), seed `20260805` | **superseded by K24d** |
| `results_20260803_K24` | K24 | The arc's first campaign; it exposed five engine defects | **superseded by K24p** |
| `results_20260810_K26v2` | K26v2 | An H9 iteration with no verdict | **superseded by K26v3** |
| `results_20260809_K26` | K26 | An H9 iteration closed as `apparatus` | **superseded by K26v3** |
| `results_20260808_K23v2` | K23 iter. 2 | An H9 iteration; two families fell at the correctness gate | **superseded by K26v3** |
| `results_20260808_K23` | K23 iter. 1 | The first iteration of the H9 arc | **superseded by K23v2** |
| `results_20260801_K22v4` | K22 v4 | A halted iteration of the specification cost study | **superseded by K22v5** |
| `results_20260801_K22v3` | K22 v3 | A halted iteration of the specification cost study | **superseded by K22v4** |
| `results_20260801_K22v2` | K22 v2 | A halted iteration of the specification cost study | **superseded by K22v3** |
| `results_20260801_K22` | K22 v1 | A pilot and a record of apparatus development, with no H8 verdict | **superseded by K22v2** |
| `results_20260730_K6b` | K6 v2 | A cost campaign halted on a client defect and a wrong slot definition | **superseded by K6c** |
| `results_20260730_K6` | K6 v1 | The first pre-declaration of the cost campaign | **superseded by K6b** |
| `results_20260729_K5_rerun` | K5 | The repeated go/no-go point after the interval fix | **superseded as a structural result by K6c**, retains the GO verdict |
| `results_20260729_K5` | K5 iter. 1 | A semantic campaign halted after defect F9 was found | **superseded by `results_20260729_K5_rerun`** |
| `results_20260726_G1` | G1 / K1 | The observability probe that exposed the dependence of semantics on the plan and opened the G1 repairs | **superseded, for the present semantics, by K2/G3 and K18** |

## Controls and apparatus diagnostics

| Directory | What it is | Status |
|---|---|---|
| `results_20260731_instrument` | per-slot work probe, 43 cell-scales | **control** — K20 stage 1b, a singular layout, no verdict |
| `results_20260731_hygiene220` | hygiene of the E4 probe on `abe075e` | **control** — no effect; a precondition of stages 1b/1c |
| `results_20260731_hygiene217` | hygiene of the client fix on `1bb2d2c` | **control** — no effect; exposes a ratio bias |
| `results_20260731_hygiene` | hygiene of the client patch on `e1e5181` | **control** — no effect |
| `results_20260731_costmodel3` | third attempt at a slot cost model | **control** — the window-family feature adds nothing |
| `results_20260730_hygiene` | hygiene of the measurement probe | **control** — no effect |
| `results_20260729_hygiene` | hygiene of the interval fix and of apparatus determinism | **control** — no effect; it caught empty comparisons posing as success |
| `results_20260721_bufferfix` | a rate/clients/FIR repeat after `facctxtsrc` buffering was restored | **apparatus-repair control** — the source of the historical context, not the present ceiling |

## Hypotheses — state

The `H*` numbers are hypothesis identifiers in the research plan and in campaign
directory names. **The paper text the reviewer sees does not use them** — since
2026-08-25 both hypotheses carrying present content appear there under names
describing the result. The table below gives both wordings, so that moving from
the paper to this package requires no guessing:

| Number | Name in the paper (EN) | Name in the paper (PL) | Anchor in the typeset text |
|---|---|---|---|
| **H9** | `equivalence-guarded materialization sharing` | współdzielenie materializacji warunkowane równoważnością | `tab:h9-primary`, section `sec:eval-sharing` |
| **H10** | `plan-derived startup boundaries` | granice startowe wyprowadzane z planu | `tab:tail-exactness`, section `sec:foundations` |

| Hypothesis | Statement | Verdict |
|---|---|---|
| **H8** | the cost of specification and modification is lower than in procedural solutions | **split**; a descriptive result — nowhere is "H8 refuted" stated (K22v5) |
| **H9** | materialization sharing, admitted only after a proof of subplan equivalence, reduces the **logical bytes of materialization writes per public record** without a time penalty | **supported in the `Q=8` class**, 3/3 families (K26v3, 2026-08-16) |
| **H10a** | the static tail calculus is exact | **supported**, nine classes out of nine (K24e, 2026-08-18) |
| **H10b** | the calculus is **non-local** for `#` nodes with both components declared: the natural local rule underestimates, and the shortfall has the pre-declared closed form `ceil((p+q-1)/p)` | **supported**, 2310/2310 divergences of that form (K24b, confirmed by K24d) |

**H9 is not a claim about plan size**, and this row's earlier wording ("reduces
the plan") was misleading here. The primary measured quantity is the cumulative
canonical width of records appended to or overwritten in materialized substrates,
divided by the number of public records. That is a logical write volume, not a
peak resident state size. Plan size as a cost measure **failed** on its own — K6c
showed it (0/13 cells, tokens smaller by 8–28% with no improvement in slot cost).
Taken together the two campaigns therefore say that a node count does not
suffice, and that what must be measured is materialization traffic or work
performed. Corrected 2026-08-26.

**H10b was written the wrong way round relative to the hypothesis** — the row
asserted that the calculus was local, whereas what was measured was its
**absence**. In the plan H10 is named "the exact and **non-local** determinacy
boundary of a multi-rate plan", and the criterion for part (b) reads: supported
when the natural local rule **diverges** from the exact one in at least 5% of the
corpus and the divergence has the form `ceil((p+q-1)/p)` in 100% of cases
(`paper-arXiv/debs/research_plan.md`, criterion H10b). The figure 2310/2310
counts the nodes at which the local rule **underestimated**, not those at which
it sufficed; the paper carries the same point in the paragraph *"Why the
interleave tail is not local"*. The verdict is unchanged. Corrected 2026-08-25.
