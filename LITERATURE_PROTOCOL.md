# LITERATURE PROTOCOL - the targeted review behind the paper's positioning

The Related Work section of the paper positions the contribution against prior work on shared state and materialization and on startup transients, and says that the full protocol of that review is listed in this package. This file is that protocol: the questions the review asked, the criteria fixed before searching, every search route with its date, instrument and recorded counts, the matrices in which the nearest works were assessed, and the limits of the whole exercise.

The review was run in two passes. The **first pass** (2026-08-02) used five routes over the axis of the *technique* (plan normalization, rewriting, multi-query optimization) and over the clock-calculus literature. The **extension** (2026-08-24 and 2026-08-25) was started when the first pass turned out to have assessed the nearest neighbor of the sharing result on the wrong axis (section 5.1); it added the axis of the *shared resource*, two forward citation chases, two phrase sweeps, three subscription indexes, a manual Google Scholar pass and the four most recent volumes of the target venue. The coverage end date of the whole review is **2026-08-25**: nothing published or indexed after that date was searched.

The protocol is extracted from the authors' working notes of the review. What was left out is editorial: notes on how the paper text was to be changed, bibliography bookkeeping and internal decision records. Search records, counts, criteria and assessments are reproduced as recorded. One identifier in the recorded results was withheld for double-anonymous review; the places are marked.

Hypothesis numbers follow [`MAP.md`](MAP.md), *Hypotheses - state*: **H9** is the sharing result (`equivalence-guarded materialization sharing`), **H10** the startup-boundary result (`plan-derived startup boundaries`). The rule `R1` is the rate-matched shift identity and `R2` the canonical ordering of commutative stream-sum operands before subplan fingerprinting.

## 1. What the paper states and where it is recorded

### 1.1. The paragraph *Scope of the literature search*

| Statement in the paper | Recorded in |
|---|---|
| the recorded protocol combined citation chasing, term searches, subscription indexes, Google Scholar and all four DEBS proceedings from 2023 through 2026, none of which contained a gating work | citation chasing: 4.5, 5.2-5.4; term searches: 4.1-4.4, 5.5, 5.6; subscription indexes: 5.7, 5.9; Google Scholar: 5.8; DEBS 2023-2026: 4.1, 5.10; the enumeration of the routes: 6 |
| across 21 state-sharing works, none matched both the substrate unit and the compiler-established identity | the two-part test: 2.2; the 21 entries and how they are counted: 7.2 |
| this directed review does not establish absence universally | the limits: 9 |
| coverage is English-language apart from one cited Polish work | 9.3 |
| Simulink rate transitions and Kafka Streams state stores were excluded by decision, as neither has a peer-reviewed description | 3.3 |
| the protocol records the search routes and their limitations, including sparse cross-citation within the state-sharing literature | routes: 4, 5; limits: 9; sparse cross-citation: 8 |

A gating work, here and below, is a work that answers both parts of the relevant two-part test (section 2.2) the way the paper does. The review found none on either axis.

### 1.2. The figures behind the paragraph

| Figure | Section |
|---|---|
| six recorded routes, nine matching modes | 6 |
| the venue term counts (`n-synchronous`, `clock calculus`, `Beatty`, `Sturmian`, `Fraenkel`, `cyclo-static`, `synchronous dataflow`, `multirate`, `rational rate`: zero) and the hand-inspected single hits (`Lustre`, `StreamIt`, `interleav*`, `query merging`) | 4.1 |
| a backward sweep over the full text of thirty works: zero hits | 4.2 |
| the symmetric sweep: zero hits, the single crossing being SPL's rejection of the synchronous model | 4.3 |
| six recorded full-text search queries | 4.4 |
| 77 distinct citing works of the first two nodes; 70 further records from the other five, four already seen, an overlap of 6% | 5.2, 5.3 |
| ISQM reachable by no chase, found by a phrase sweep; GroupShare and the datacenter subexpression study reached through a bibliography | 5.4, 5.5, 8 |
| twelve structured queries: 110,651 hits in the ACM Digital Library, 2,134 in Scopus, 1,505 in IEEE Xplore | 5.7 |
| Google Scholar: 40 citing works of Shared Arrangements against 27 and 15 in the open graphs | 5.8 |
| six works reachable only through subscription access, obtained and read; the nearest shares the execution machine, not computation or state | 5.9 |
| five candidate works excluded under the criteria, with recorded reasons | 3.2 |
| the phrase sweep run twice, the second time over seventeen phrases, with different matching | 5.5, 9.2 |
| the startup-transient sweep, the daily budget of one index, five phrases with a count from the other index alone | 5.6, 9.2 |
| the one conceptual precedent on the startup-transient axis | 7.3 |
| ACM DL counts complete, ACM DL triage partial | 5.7, 9.1 |
| a technical report sought and not obtained | 9.3 |

## 2. Review questions and decision tests

### 2.1. Questions

The question the review had to answer:

> Is there earlier work that combines observability-preserving algebraic normalization of a plan with automatic sharing in a working compiler?

It was split into four questions, each with its own literature:

| # | Question | Answer recorded |
|---|---|---|
| Q1 | Does earlier work describe per-stream rational rates declaratively and let a compiler derive the schedule, buffers and delays? | **Yes** - the n-synchronous line and SDF/CSDF, outside databases (matrix group A, 7.1) |
| Q2 | Does earlier work normalize a plan algebraically **before** structural deduplication, to expose sharing? | **Yes** - the compiler canon (value numbering, hash consing) and ISQM, more generally than R2 (4.4, D3; 7.1, B1) |
| Q3 | Does earlier work have the shift identity for interleaving streams with a rational rate ratio (R1) as a plan-rewrite rule? | **Not found** |
| Q4 | Does earlier work put Q1 and Q2 together in a query engine with durable artifacts and public descriptors? | **Not found**; the two literatures are disjoint in vocabulary in both directions (4.2, 4.3) |

The novelty claim therefore rests on Q3 and Q4, not on Q1 and Q2.

### 2.2. Two-part tests

The first-pass matrix (7.1) rates each work by its threat to the novelty claim on a high/medium/low scale. That scale is a judgment and cannot be applied mechanically to a new work, so the extension replaced it on each axis by a pair of decision questions.

**Axis A - sharing of state and materialization:**

> **(A1) What is the unit of sharing** - an index over a relation, a plan, a machine resource, or a substrate stream whose identity is "rate + logical origin + startup tail"?
>
> **(A2) Who fixes its identity, and when** - the runtime, between independently submitted queries, or the compiler, over one query program?

A gating work answers both questions the way the paper does.

**Axis B - the startup transient:**

> **(B1) What is determined** - does the work separate two quantities (*which* records exist: the logical origin `O_S`; from *when* an existing record is ready: the startup tail `W_S`), or does it work with one merged quantity?
>
> **(B2) Where it comes from** - is the quantity computed statically from the plan alone, per operator class, at a stated cost, or from a timing model, a simulation, an unrolled schedule or observed execution?

A gating work answers yes to both. A work that answers yes to (B1) and no to (B2) is a **conceptual precedent**: it does not invalidate the result, but the separation itself cannot be presented as new.

## 3. Criteria

### 3.1. Inclusion and exclusion

Stated operationally, so that they apply without knowledge of the paper.

**Inclusion** - a work enters the corpus if it meets **at least one** of:

- **I1.** it defines a model of computation in which streams have statically known, different production/consumption rates (integer or rational);
- **I2.** it defines a language or type system in which the user declares the rate, clock or period of a stream and a compiler derives schedule, buffers or delays from it;
- **I3.** it rewrites query plans or dataflow graphs, preserving semantics, to share subexpressions between queries;
- **I4.** it formalizes determinism or repeatability of a streaming result as a property of the model, or provides a framework for repeatable streaming experiments.

**Exclusion** - a work is dropped if it meets **any** of:

- **E1.** its claims concern only distribution, fault tolerance, elasticity, operator placement, load shedding or serverless execution, areas in which the paper makes no claim;
- **E2.** it is an editorial commentary, an extended abstract or non-peer-reviewed material (exception: artifact-policy documents, cited explicitly as policy, not as work);
- **E3.** it is a longer version of a work already in the corpus and adds no point that the shorter version lacks (the version read is cited);
- **E4.** it concerns signal processing as approximation or compression, with no positional operator and no language boundary.

### 3.2. The five recorded exclusions

| Work | Reason |
|---|---|
| Fort, Forget, *Synchronous semantics of multi-mode multi-periodic systems*, SAC 2022 | the same group and line as Forget et al., HASE 2008 (matrix A5); superseded once that original was obtained (E3) |
| Yip, Girault, Roop, Biglari-Abhari, *Parallel Programming for Multi-Cores with ForeC*, TOPLAS 2023 | determinism and WCET on multicores, not clock calculus (E1/E4) |
| Kenwright et al., *Timetide: logically synchronous distributed systems* | distribution (E1) |
| Girault, *Technical Perspective: Toward a Formally Verified Compiler*, CACM | editorial commentary (E2) |
| Buck, doctoral dissertation, UCB/ERL M93/69, 1993 | the longer version of Buck and Lee, ICASSP 1993 (matrix D1), which is the version read (E3); the only one of the five in scope, see 9.3 |

### 3.3. Exclusions by decision

Two neighbors are absent from the comparison by decision, not because a search missed them: **Simulink** (`Rate Transition` blocks and explicit sample times) and the **state stores of Kafka Streams**. Neither has a peer-reviewed description; both are documented only by their vendors, and product documentation was not admitted as prior work. Both are named here so that the absence is not mistaken for a gap in the search. The neighboring Flink state-store entry needed no such decision: it is covered by a peer-reviewed description (*Disaggregated State Management in Apache Flink 2.0*, PVLDB 18(12), 2025).

### 3.4. Reading basis

Assessments carry the depth of reading they rest on:

- **L** - full reading;
- **A** - title page, abstract, introduction and the sections that carry the mechanism;
- **A+** - **A** plus an exhaustive full-text term search (`shar*`, `reus*`, `merg*`, `subexpression`, `equivalen*`, "multiple queries", "across queries") under both axis-A questions; it supports a negative statement ("the work does not share X") that an abstract alone does not.

Every work that the paper cites from this review was read in full (**L**). On 2026-08-25 the review's corpus held 126 files, every one with a recorded assessment.

## 4. First pass - five routes (2026-08-02)

No route is a single forward-citation sweep.

### 4.1. Route A - venue scan

**Goal:** find direct competition in the target venue. **Corpus:** the DEBS 2025 proceedings (38,805 lines of text) and the DEBS 2026 proceedings (23,569 lines). **Method:**

```bash
pdftotext -q debs2025-Proceedings.pdf debs2025.txt
pdftotext -q debs2026-Proceedings.pdf debs2026.txt
grep -o -i -F "<term>" debs2025.txt | wc -l     # occurrences, not lines
```

| Term | DEBS 2025 | DEBS 2026 |
|---|---:|---:|
| `n-synchronous` | 0 | 0 |
| `clock calculus` | 0 | 0 |
| `Beatty` | 0 | 0 |
| `Sturmian` | 0 | 0 |
| `Fraenkel` | 0 | 0 |
| `covering system` | 0 | 0 |
| `cyclo-static` / `cyclostatic` | 0 | 0 |
| `synchronous dataflow` / `synchronous data flow` | 0 | 0 |
| `multirate` / `multi-rate` | 0 | 0 |
| `rational rate` | 0 | 0 |
| `sample rate` | 0 | 0 |
| `subplan` | 0 | 0 |
| `common subexpression` | 0 | 0 |
| `plan normaliz*` | 0 | 0 |
| `canonicaliz*` | 0 | 0 |
| `startup latency` | 0 | 0 |
| `operator reordering` | 0 | 0 |
| `redundancy elimination` | 0 | 0 |
| `Kahn network` | 0 | 0 |
| `Ptolemy` | 0 | 0 |
| `SIGNAL language` | 0 | 0 |
| `Lustre` | 1 | 0 |
| `StreamIt` | 2 | 0 |
| `interleav*` | 3 | 0 |
| `query merging` | 0 | 1 |
| `multi-query` | 3 | 2 |
| `materializ*` | 6 | 2 |
| `sharing` | 30 | 54 |

Counts are occurrences (`grep -o`). An earlier count of 28 for `sharing` in DEBS 2025 counted lines; both are correct for their definitions.

Every isolated hit was read in context:

- `Lustre` (DEBS 2025) - a mention in the related work of a paper on query portability, next to the stream calculus of Soule et al. (matrix B5); not a clock-calculus paper.
- `StreamIt` (DEBS 2025) - one reference in the same paper plus its bibliography entry (matrix C1).
- `interleav*` (DEBS 2025) - interleaving of matches in a CEP `AND` operator, of state counters and of "stations"; none means interleaving samples of streams with a rational rate ratio.
- `query merging` (DEBS 2026) - only a bibliography entry pointing to ISQM (matrix B1).

The DEBS 2023 and 2024 volumes, and a review of all four tables of contents, were added in the extension (5.10).

### 4.2. Route B - backward sweep over the corpus

**Goal:** if any systems work had already used the Beatty apparatus, it would most likely cite it by name. **Corpus:** the full text of all 30 works of the first-pass corpus (matrix rows A1-A8b, B1-B8b, C1-C5, D1-D4, E1, E2a-E2c), extracted with `pdftotext`, and for two files with damaged fonts with `mutool draw -F txt`. They span the clock-calculus line, SDF/CSDF and the multi-query-optimization canon. **Terms:** `Beatty`, `Sturmian`, `Fraenkel`, `covering system`, `mechanical word`, `three distance`. **Result:** zero hits in 30 works.

This does not prove that no such work exists; it rules out that one is part of the awareness of any of these lines.

### 4.3. Route C - symmetric sweep in the other direction

**Goal:** the control symmetric to route B: if the database and stream literature knew the clock calculus, it would name it. **Corpus:** the works of matrix groups B, C, D and E (databases, streams, multi-query optimization, replay). **Terms:** `clock calculus`, `periodic clock`, `n-synchronous`, `Lustre`, `multirate`, `multi-rate`, `sample rate`, `rational`.

| Term | Hits |
|---|---|
| `clock calculus`, `periodic clock`, `n-synchronous` | 0 in every B/C/D/E work |
| `multirate`, `multi-rate`, `sample rate` | 0 in every B/C/D/E work |
| `Lustre` | 3 occurrences, only in SPL (TOPLAS 2017, matrix C5) |
| `rational` | isolated, meaning "rationale" or a rational number outside the context of rates |

Reverse control: in the core clock-calculus works (matrix A1, A2, A3, A5, A8a) the words `database`, `query language` and `SQL` occur zero times; `declarative` occurs once each in A3 and A8a, in the general sense.

The single recorded crossing between the literatures is SPL, which sets itself apart from Lustre and Esterel in one paragraph - operator firings in SPL are not one instantaneous reaction - and so explicitly *rejects* the synchronous model rather than carrying it over.

### 4.4. Route D - full-text search queries

**Date:** 2026-08-02. **Instrument:** a web search engine with a full-text index covering arXiv, the ACM DL, IEEE Xplore and author pages. The queries are recorded verbatim, in the order run.

| # | Query | What was found | Effect |
|---|---|---|---|
| D1 | `Beatty sequence stream processing query language database operator` | the top-ranked hit is an earlier preprint of the authors (identifier withheld for review); besides it StreamQL, SASE and sequence models, none using the Beatty apparatus | no threat; confirms 4.2 |
| D2 | `"rational rate" OR "multirate" stream query compiler algebraic normalization subplan sharing` | again the authors' preprint; Shared Arrangements (already cited); FlowLog (arXiv 2511.00865, 2025), an incremental Datalog that normalizes its IR to a canonical form and hashes subtrees, replacing duplicates by a pointer | new lead (9.4) |
| D3 | `canonicalization commutative operands before hash-based common subexpression detection query plan sharing stream` | a textbook answer: for commutative operations the dependency hashes are sorted before hashing; standard value numbering and hash consing, described in compiler material and in MLIR | lowers the novelty of R2 as a technique |
| D4 | `multirate dataflow "startup" latency index of first valid output computed from plan closed form exact` | no match; results concern pipeline latency in accelerators and exactly-once in Cloud Dataflow | no competition for H10 |
| D5 | `negative result multi-query sharing smaller plan does not reduce runtime stream processing ablation study` | no work with such a negative result; the works found (sketch-based MQO, AStream/AJoin, A-SEGO) treat sharing as conditional and cost-driven, but publish no measurement of the boundary | supports the originality of the negative plan-size result |
| D6 | `"n-synchronous" OR "clock calculus" applied to data stream management system continuous queries database` | no work joining the two; results split into two disjoint sets, clock calculus (Pouzet et al.) and DSMS (CQL, time management); DBSP/Feldera ("a synchronous streaming model") noted as a contemporary neighbor on the database side | new lead (9.4) |

The queries cover the identity (D1, D6), the canonicalization technique (D2, D3), the positional startup quantity (D4) and the negative sharing result (D5). All six are built around the *technique*; none names the shared resource, which is the construction gap that the extension corrected (5.1).

### 4.5. Route E - citation chase

**Backward:** the related-work sections and bibliographies of three nodes of highest degree in their lines were read: Cohen et al., *N-Synchronous Kahn Networks* (POPL 2006, matrix A1), ISQM (EDBT 2023, B1) and the stream-processing optimization catalog of Hirzel et al. (CSUR 2014, B4). From A1 came the Lustre line (A4), SIGNAL/Polychrony (A8) and the delimitation against SDF and StreamIt (A6, C1, C2); from B1 the context of containment-based merging (SPES, EQUITAS) and the signature line of sharing; from B4 the canonical names of the optimizations.

**Forward, from the venue bibliographies:** a lead in the DEBS 2026 bibliography ("operator placement ... often combined with query reordering, prefix sharing, and merging for multi-query workloads") led to B1 and B2; a lead in DEBS 2025 ("operator merging is successful in ...") led to B3. Reading B3 in context showed that "operator merging" there means fusing logical operators into physical ones under the same partitioning key, to avoid serialization cost - fusion in the vocabulary of B4, not sharing between queries.

## 5. Extension - the resource axis (2026-08-24 and 2026-08-25)

### 5.1. Why the extension exists

The first pass held the work nearest to H9 in its corpus and did not assess it as such. Shared Arrangements (McSherry, Lattuada, Schwarzkopf, Roscoe, PVLDB 13(10), 2020) shares maintained **index state** between concurrent queries and is the mechanism behind Materialize. It was already cited before the first pass closed, and route D noted it in query D2 as already cited, but it got no row in the matrix, passed through no criterion and was not named as the neighbor of H9.

The failure was in classification and in the construction of the axis, not in retrieval. The first pass searched and classified the axis of the *technique*; Shared Arrangements lies on the axis of the *resource*: what is shared - maintained state - rather than by which technique. A work sharing the same resource by another technique falls outside technique-built queries and, when it reaches the corpus by another route, has no cell in which to be assessed. The rule the extension adopted:

> For a claim about a mechanism, search the axis of the resource the mechanism concerns, not only the axis of the technique it uses. For H9 the resource is maintained materialized state, not the plan.

The extension also replaced the threat scale by the two-part tests of section 2.2.

### 5.2. Forward chase from Shared Arrangements and Noria (2026-08-24)

**Instruments:** queries by `curl` to the Semantic Scholar Graph API, OpenAlex, DBLP, Unpaywall and Crossref. **Target record:** Semantic Scholar `699da1789451e16f06a2d02b0a71e7687ad770d3`, DBLP `journals/pvldb/McSherryLSR20`, DOI `10.14778/3401960.3401974`.

The arXiv preprint 1812.02639 carries a different title (*K-Pg: Shared State in Differential Dataflows*) and is a separate Semantic Scholar record with its own citation list; a query by the published title alone loses that branch. Both were taken and their union used.

| Source | Citing works |
|---|---:|
| Semantic Scholar, PVLDB record | 25 |
| Semantic Scholar, arXiv record (K-Pg) | 2 |
| **Semantic Scholar union** | **27** |
| OpenAlex (three split records: W3046838028, W2997050548, W2903374573) | 17, a subset of Semantic Scholar |
| DBLP | no citation graph; used to verify identity (key, pages, DOI) |

The chase from one node leaks. Noria (OSDI 2018), a neighbor on the same axis, has 53 citing works in Semantic Scholar. A second query - works citing Noria and not Shared Arrangements, year 2020 or later - brought four works the first chase had missed: GraftDB, ParCuR, Snowflake Dynamic Tables and Flo. The union of the citing works of the two nodes is **77 distinct works**.

### 5.3. Forward chase from the other five nodes of the axis (2026-08-24)

The same method, Semantic Scholar plus OpenAlex with split records united and identity verified through DBLP. It was validated first by reproducing the earlier run: Shared Arrangements again gave 25 + 2 = 27 in Semantic Scholar, Noria again 53. For OpenAlex the validation run recorded 15 citing works of Shared Arrangements where the first run had recorded 17; 15 is also the count of the Google Scholar pass (5.8) and equals the Crossref counter shown on the ACM DL page.

| Node | Identifier | Semantic Scholar records | citing in Semantic Scholar | citing in OpenAlex | node union |
|---|---|---:|---:|---:|---:|
| ISQM | DOI `10.48786/edbt.2023.51`, OpenAlex `W6892209547` | 1 | 5 | 2 | 7 |
| DBSP | DOI `10.14778/3587136.3587137` (PVLDB), `10.1007/s00778-025-00922-y` (VLDB J. 2025), arXiv 2203.16684 | 3 | 50 | 32 | 54 |
| Nova | DOI `10.1109/TPDS.2021.3073253`, OpenAlex `W3156151555` | 1 | 3 | 3 | 4 |
| GraftDB | arXiv 2606.04303, OpenAlex `W7163567941`, `W7163720304` | 1 | 0 | 0 | 0 |
| iShare | DOI `10.1145/3448016.3457282`, OpenAlex `W3174346363` | 1 | 6 | 4 | 6 |
| **union** | | | **63** | **41** | **70 records** |

After collapsing index duplicates (four records of one work and one record that is an annual index of IEEE TPDS) the 70 records are 66 distinct works. Of the 70, **4** had already been seen in the chase from the first two nodes (DBSP in its VLDB J. 2025 version, Snowflake Dynamic Tables, Flo, RPAI): an overlap of **6%**. Here OpenAlex was not a subset of Semantic Scholar: it added seven records, two of them real works, so both indexes were queried throughout. GraftDB, dated 2026-06-03, had no citing work in either index; a chase from it is empty by date, not by omission.

### 5.4. Backward branch from a bibliography

Reading FunShare (ICDE 2026), found by the chase from iShare, surfaced two works on the resource axis that none of the seven chases sees: **GroupShare** (CIDR 2024), which defines functional isolation - queries are cross-optimized only if no individual query's performance is compromised - and **Jindal et al., PVLDB 2018**, an industrial selection of common subexpressions for materialization in datacenter workloads. Both were then checked as further chase nodes: FunShare had zero citing works in Semantic Scholar and OpenAlex, GroupShare one (FunShare itself), so this line leaves no open node.

### 5.5. Phrase sweeps on axis A

**First sweep (2026-08-24), Semantic Scholar**, years 2020-2026, phrase `sharing materialized state across continuous queries`. Semantic Scholar search is semantic and ranked. It returned two works visible from neither chase: ISQM and the DEBS 2024 best paper µWheel. ISQM was already in the first-pass corpus (matrix B1); the sweep confirmed it, and its assessment under the axis-A questions was new. ISQM cites neither Shared Arrangements nor Noria (its 49-item bibliography was checked in full text), so no chase from them reaches it.

**Second sweep (2026-08-25), seventeen phrases.** Semantic Scholar refused every request without an API key (HTTP 429, six attempts), so the sweep ran on **OpenAlex** (exact phrase over full text, `search="phrase"`) and **DBLP** (title search, prefix-AND, computer science only). This is a different instrument: the phrase of the first sweep returns **0** exact hits in OpenAlex although Semantic Scholar returned ISQM and µWheel for it. The counts of the two sweeps are therefore not comparable. A ranked OpenAlex variant without quotes was rejected: for `shared operator state` it returned 4,744 records led by shared scooters, electric-vehicle charging and telerobotics.

| # | Phrase | OpenAlex (exact) | DBLP (title) |
|---|---|---:|---:|
| 1 | `shared operator state` | 6 | 0 |
| 2 | `reusing materialized results across continuous queries` | 0 | 0 |
| 3 | `query merging` | 268 | 33 |
| 4 | `work sharing` | 13567 | 18137 |
| 5 | `view reuse` | 279 | 45 |
| 6 | `sharing materialized state` | 0 | 0 |
| 7 | `reusing materialized results` | 9 | 0 |
| 8 | `inter-query sharing` | 19 | 5 |
| 9 | `cross-query sharing` | 7 | 0 |
| 10 | `sharing computation across queries` | 0 | 0 |
| 11 | `shared state across queries` | 1 | 0 |
| 12 | `operator state sharing` | 0 | 0 |
| 13 | `shared intermediate results` | 267 | 0 |
| 14 | `subexpression reuse` | 14 | 1 |
| 15 | `multi-query execution` | 59 | 27 |
| 16 | `shared materialized view` | 5 | 3 |
| 17 | `sharing state across continuous queries` | 0 | 0 |

Phrases 1-5 were fixed before the sweep; 6-17 extend them, because the first sweep had shown that the phrase decides the result. `work sharing` is dominated by labor economics and `view reuse` by circular economy and heritage reuse; both were still screened by title. The zero-hit phrases are paraphrases, not terms in use. The sweep added Hamlet (SIGMOD 2021), whose adaptive runtime decision whether to share is the sharpest existing argument against a compile-time sharing decision; no gating work.

### 5.6. Sweep on axis B (2026-08-25)

**Instruments:** OpenAlex (exact phrase) and DBLP (title), as in 5.5; Semantic Scholar was skipped because it still refused requests without a key. DBLP refused service above one request per 8 s; all counts come from a run at that pace with retries.

The phrases ran in **two rounds of 22 each, 44 in all**. Round 1 (B1-a ... B4-c) holds the four terms the plan named plus extensions fixed before any result was seen. Round 2 (R2-a ... R2-v) holds phrases chosen **after** round 1, from terminology round 1 showed to be in actual use (*transient and periodic phase*, *self-timed schedule*, *earliest start time of an actor*). Three of the four planned terms turned out to be paraphrases with zero hits; without round 2 the sweep would have concluded "nothing on axis B" as an artifact of wording.

OpenAlex has a daily query budget, and it ran out at phrase R2-r (`Insufficient budget ... Resets at midnight UTC`). The last five phrases of round 2 therefore carry a DBLP count only. They are extending phrases, not planned ones, and their DBLP counts (6, 1, 0, 0, 0) do not suggest a line. DBLP covers 44 of 44 phrases, OpenAlex 39 of 44.

| # | Phrase | OpenAlex (exact) | DBLP (title) |
|---|---|---:|---:|
| B1-a | `prologue schedule` | 4 | 0 |
| B1-b | `initialization schedule` | 5692 | 2 |
| B1-c | `startup latency dataflow` | 0 | 0 |
| B1-d | `periodic admissible sequential schedule` | 11 | 0 |
| B1-e | `prologue and epilogue` | 3081 | 0 |
| B1-f | `software pipelining prologue` | 3 | 0 |
| B1-g | `transient schedule` | 93 | 14 |
| B1-h | `initialization phase of the schedule` | 55 | 0 |
| B1-i | `cyclo-static dataflow` | 324 | 22 |
| B1-j | `initial tokens` | 4121 | 1 |
| B2-a | `latency calculus` | 9 | 18 |
| B2-b | `latency analysis of dataflow graphs` | 0 | 1 |
| B2-c | `per-operator latency` | 31 | 2 |
| B2-d | `worst-case latency dataflow` | 0 | 1 |
| B2-e | `clock calculus` | 110 | 11 |
| B2-f | `static latency analysis` | 3 | 2 |
| B3-a | `transient response filter bank` | 0 | 0 |
| B3-b | `startup transient filter` | 0 | 0 |
| B3-c | `warm-up transient` | 95 | 1 |
| B4-a | `first valid output sample` | 4 | 0 |
| B4-b | `logical start time stream` | 0 | 0 |
| B4-c | `undefined prefix stream` | 0 | 0 |
| R2-a | `transient phase of the schedule` | 3 | 0 |
| R2-b | `transient and periodic phase` | 5 | 0 |
| R2-c | `self-timed schedule` | 108 | 2 |
| R2-d | `latency minimization for synchronous data flow` | 23 | 1 |
| R2-e | `earliest start time of an actor` | 4 | 0 |
| R2-f | `initial latency` | 5099 | 22 |
| R2-g | `pipeline fill time` | 14 | 1 |
| R2-h | `initiation interval` | 1476 | 11 |
| R2-i | `group delay` | 35275 | 641 |
| R2-j | `settling time of the filter` | 79 | 1 |
| R2-k | `region of support` | 21724 | 208 |
| R2-l | `valid convolution` | 428 | 51 |
| R2-m | `border effects filter bank` | 0 | 0 |
| R2-n | `boundary effects in filter banks` | 0 | 0 |
| R2-o | `n-synchronous` | 972 | 1563 |
| R2-p | `affine clock relations` | 5 | 0 |
| R2-q | `periodic clock` | 714 | 31 |
| R2-r | `startup transient` | budget | 6 |
| R2-s | `first output index` | budget | 1 |
| R2-t | `warm-up period of the filter` | budget | 0 |
| R2-u | `compile-time latency bound` | budget | 0 |
| R2-v | `static schedule prologue` | budget | 0 |

`group delay`, `region of support`, `valid convolution`, `per-operator latency`, `initial latency` and `initialization schedule` are field-wide textbook terms or belong to other fields (DSP at large, convolutional networks, LLM inference). The high count for `n-synchronous` is the known and cited line, a check that the instrument works rather than a discovery. The distribution of answers to the axis-B questions is in 7.3.

### 5.7. Subscription indexes - twelve structured queries (2026-08-25)

Twelve **structured** queries - fielded and Boolean, unlike the free phrases of 5.5 and 5.6: eight on axis A, three on axis B, one on the moment of decision. Each was written in three syntaxes (Scopus `TITLE-ABS-KEY`, IEEE Xplore `"All Metadata"`, ACM DL). Scopus was queried through its API with a key, IEEE Xplore through the public search endpoint of its web interface, and the ACM DL by hand in a browser (scripted requests got HTTP 403).

| # | Query | ACM DL | Scopus | IEEE Xplore |
|---|---|---:|---:|---:|
| A1 | `"state sharing"` AND (stream* OR dataflow) | 222 | 14 | 7 |
| A2 | (`"inter-query"` OR `"cross-query"`) AND (sharing OR reuse) | 363 | 16 | 17 |
| A3 | `"multi-query"` AND (sharing OR optimization OR execution OR merging) | 960 | 366 | 106 |
| A4 | (subexpression OR `"sub-expression"`) AND (reuse OR sharing OR materializ*) | 5337 | 258 | 111 |
| A5 | `"materialized view*"` AND (stream* OR `"continuous quer*"`) AND (shar* OR reus*) | 296 | 9 | 5 |
| A6 | (`"operator state"` OR `"indexed state"` OR `"maintained state"`) AND (shar* OR reus*) | 322 | 31 | 23 |
| A7 | `"query merging"` OR `"plan merging"` OR `"query consolidation"` | 107 | 84 | 37 |
| A8 | (`"work sharing"` OR `"computation sharing"`) AND (quer* OR stream*) | 495 | 112 | 39 |
| B1 | (startup OR initialization OR prologue) AND (latency OR schedule OR transient) AND (dataflow OR SDF) | 10497 | 9 | 11 |
| B2 | (`"prologue schedule"` OR `"initialization phase"` OR `"startup latency"`) AND (dataflow OR SDF OR stream*) | 2027 | 139 | 92 |
| B3 | transient AND (`"filter bank*"` OR multirate) AND (rational OR `"sampling rate"`) | 514 | 23 | 40 |
| C1 | (compiler OR `"compile-time"` OR static) AND shar* AND (`"continuous quer*"` OR stream* OR dataflow) | 89511 | 1073 | 1017 |
| | **total** | **110651** | **2134** | **1505** |

**The three columns are three different fields, not three indexes of one field.** Scopus searches title, abstract and keywords; IEEE Xplore adds index terms and the publication title; the ACM DL ran the queries as `[All: ...]`, over the **full text** of the ACM Full-Text Collection (858,715 records). Hence factors of 10-100 between the columns; the counts compare only within a column.

**Triage.** Scopus and IEEE Xplore results were screened by title up to one hundred records per query and index: 769 Scopus and 588 IEEE records. After a topical screen and removal of everything already known, 76 unknown on-topic items remained, of which six touch one of the axes; none answers both questions of either test. Of the ACM DL results only the first entry of each query (sorted by recency) was triaged; the counts are complete, the triage is partial (9.1). Those twelve first entries still gave four works the other two columns had not shown, among them a third work of the Geilen group on axis B (*Schedule Synthesis for SDF Models with Lower and Upper Timing Bounds*, ACM TECS 2025), visible only in full text because its abstract uses none of the words `startup`, `initialization` or `prologue`; read, it derives ASAP times but takes every upper bound as given.

Three queries proved unusable in Scopus and IEEE Xplore, and the ACM DL full text confirmed them and added a fourth: A7 is dominated by plan merging in multi-agent planning, B2 by proxy caching of streamed video, C1 is too broad (bandwidth sharing in LTE, deep-learning inference), and in the ACM DL A4 leads with subexpression reuse in grammatical evolution.

### 5.8. Google Scholar, by hand (2026-08-25)

A scripted route was tried first and is closed: without a logged-in browser session Google Scholar served truncated responses (the target records and the whole citation layer missing, a robot check on `cites=` requests), while a control query showed the index itself complete. The citing lists of three nodes were then walked by hand in a logged-in browser; screenshots of every result page were the basis of the transcription.

| Work | Google Scholar "Cited by" | versions in cluster | Semantic Scholar | OpenAlex |
|---|---:|---:|---:|---:|
| Shared Arrangements | **40** | 19 | 27 | 15 |
| Noria, OSDI 2018 | **90** | 16 | 53 | - |
| ISQM, EDBT 2023 | **20** | 2 | 5 | 2 |

The reference set was rebuilt from fresh Semantic Scholar citing lists of the four records (Shared Arrangements PVLDB, K-Pg arXiv, Noria, ISQM): 80 distinct works. The 150 Google Scholar entries collapse to 147 after index duplicates and to **135** distinct works across the three nodes; 65 are also in Semantic Scholar, **70** only in Google Scholar, 12 of those already known from other routes, leaving **58** to triage:

| Class | Count |
|---|---:|
| grey literature - dissertations, theses, course reports, talks, columns, tutorials, `[CITATION]` records without a file | 46 |
| peer-reviewed, off axis A (operator placement, recovery, privacy compliance, stateless functions, window-join order) | 10 |
| peer-reviewed, on axis A | 2 (SHARP, Veer) |

So 79% of the Google Scholar advantage is grey literature, which the open graphs do not index; the chases did not lose peer-reviewed work. Neither of the two on-axis works answers both axis-A questions as the paper does: SHARP shares partial matches in pattern detection and drops a subset under a budget, Veer establishes equivalence statically but between versions over time.

### 5.9. Six works behind a subscription paywall (2026-08-25)

Six named works reachable only through IEEE subscription access were obtained through institutional access and read to basis **A+** (3.4):

| Work | Unit of sharing | Who decides, and when | Outcome |
|---|---|---|---|
| NebulaStream, ICDE 2026 (an adaptive multi-query stream engine from the group that built ISQM) | the **execution machine** - worker threads and a common task queue; neither computation nor state is shared between queries | runtime, work-stealing scheduler, per task; no identity decision | on the resource axis in its machine variant; does not answer as the paper does |
| SASPAR, ICDE 2023 | the partitioning operation and the network transfer it causes; shareable only between queries with the same partitioner | runtime, adaptively | on the resource axis in its I/O variant; does not answer as the paper does |
| Zhou, Larson, Goldstein, Ding, *Dynamic Materialized Views*, ICDE 2007 | a subset of view rows selected by a control table | split: two parts of the test in the optimizer, a third as a guard predicate at execution | off axis A; the dynamic member of the materialization canon |
| Zhu et al., *Multiple Continuous Top-K Queries over Data Stream*, ICDE 2024 | a candidate set parameterized by the maximum `k` and `n` of the whole workload | no per-query decision; the structure serves all queries alike | on the axis in an index variant; does not answer as the paper does |
| Chaudhary et al., *Incremental Stream Query Placement*, ICDE 2025 | nothing shared; the global plan is taken as given from ISQM | runtime, on query and infrastructure changes | off axis A - the step after the sharing decision |
| Harn, Kllapi, Yan, *On Efficient Materialization in Data Lakes*, ICDE 2026 | the output file (number and size of shards); nothing shared between queries | within one materializing query, from runtime statistics | off both axes |

NebulaStream had been expected to be the closest of the six. Its "runtime compute caching" is a thread-local buffer of pointers to window slices, measured on single queries; its multi-query scaling compares work stealing with work dealing; ISQM is cited once, in the introduction. A full-text search gives one hit for `query merg*` (that bibliography title) and zero for `subexpression`, `equivalent quer` and `shared operator`.

### 5.10. Four DEBS volumes, 2023-2026 (2026-08-25)

The four complete proceedings of the target venue were reviewed: all four tables of contents in full, plus a term screen over both axes. No earlier route had covered the 2023 and 2024 volumes.

| Volume | Result |
|---|---|
| 2023 | nothing on axis A; nearest: *Adaptive Distributed Streaming Similarity Joins* and *A Hardware-Conscious Stateful Stream Compression Framework*, both about a single query |
| 2024 | *Safe Shared State in Dataflow Systems* (De Martini, Margara) - shares a machine resource (connection pool, dictionary table, LRU) declared by the programmer, not a maintained result; read in full, see 7.2; µWheel, read in full; a keynote whose sentence on sharing of computation and intermediate results describes ISQM |
| 2025 | nothing; nearest by title *PPOIJ: Shared-Nothing Parallel Patterns*, the opposite |
| 2026 | nothing on axis A; *BPFComposer* shares eBPF program state at operating-system level, *ZSS* is a Zenoh subscription, *SHIELD* is about privacy |

If someone occupied the cell of H9 - automatic sharing of materialization between streaming queries, decided at compile time - this venue would be the most likely place of publication. An argument from absence is weak in general and stronger when the place searched is the one where the work would have to appear.

## 6. Six routes, nine matching modes

The paper counts the protocol two ways. By **recorded route** there are six:

| Route | Content | Sections |
|---|---|---|
| (i) venue scan | DEBS 2023-2026 tables of contents and term screen; term counts over DEBS 2025 and 2026 | 4.1, 5.10 |
| (ii) backward sweep | the Beatty-apparatus terms over the full text of the thirty nearest works | 4.2 |
| (iii) symmetric sweep | the clock-calculus terms over the database and stream works | 4.3 |
| (iv) full-text search queries | six recorded queries D1-D6 | 4.4 |
| (v) citation chase, both directions | backward from three high-degree nodes and from the venue bibliographies; forward from seven state-sharing nodes; the bibliography branch | 4.5, 5.2-5.4 |
| (vi) structured index queries and Google Scholar | twelve queries in three subscription indexes; the manual Google Scholar pass; the six works behind a paywall | 5.7-5.9 |

By **matching mode** - which index matched what, and how - the result converges across nine:

| # | Mode | Sections |
|---|---|---|
| 1 | forward citation chase from Shared Arrangements and Noria (Semantic Scholar, OpenAlex) | 5.2 |
| 2 | forward citation chase from ISQM, DBSP, Nova, GraftDB and iShare | 5.3 |
| 3 | dictionary sweep on axis A (Semantic Scholar semantic; OpenAlex exact and DBLP title, 17 phrases) | 5.5 |
| 4 | dictionary sweep on axis B (OpenAlex exact and DBLP title, 2 x 22 phrases) | 5.6 |
| 5 | Scopus, title-abstract-keywords | 5.7 |
| 6 | IEEE Xplore, all metadata | 5.7 |
| 7 | ACM DL, full text | 5.7 |
| 8 | Google Scholar, by hand | 5.8 |
| 9 | the four DEBS volumes | 5.10 |

The working record of the extension enumerated its nine approaches slightly differently: Scopus and IEEE Xplore as one approach, and the acquisition and reading of the six paywalled works as a separate one. That count, too, is nine; the list above follows the paper, which counts search modes and treats the paywalled works as part of route (vi). None of the nine produced a gating work.

## 7. Matrices

### 7.1. Nearest works, first pass

"Relevance" rates the effect on the **novelty claim**, not the merit of the work: **high** = could pre-empt a contribution; **medium** = covers part of a contribution and needs explicit delimitation; **low** = positioning, one sentence suffices. This scale was later replaced by the tests of 2.2 for the two axes the extension covers.

**Group A - clock calculus, synchronous languages, multi-rate dataflow**

| # | Work | What it already solves | Difference | Relevance |
|---|---|---|---|---|
| A1 | Cohen et al., *N-Synchronous Kahn Networks*, POPL 2006 | clocks as infinite periodic binary words; synchronizability; subtyping; automatic inference of buffer size and minimal delay | a clock is a *type* describing presence/absence on a base clock; here the rate is a rational interval value, and `#` produces one output stream from two, which `on`/`when`/`merge` do not express; no plan rewriting, no subgraph deduplication, no multiple queries, no durable artifacts, no database vocabulary | high - the nearest work of the list |
| A2 | Cohen, Mandel, Plateau, Pouzet, *Abstraction of Clocks*, APLAS 2008 | clock envelopes as sets of concrete clocks | the abstraction is conservative by design (over-approximation); buffer sizes are "most precise correct", not exact | medium |
| A3 | Mandel, Plateau, Pouzet, *Lucy-n*, MPC 2010 | first implementation of the n-synchronous model; buffer sizes computed automatically | buffer *places* stay explicit in the program (`buffer`); here the user writes neither size nor place | medium |
| A4 | Colaco, Pouzet, *Clocks as First Class Abstract Types*, EMSOFT 2003 | foundation of the clock calculus in Lustre/Lucid Synchrone | Boolean clocks without quantitative rate | low |
| A5 | Forget et al., *A Multi-Periodic Synchronous Data-Flow Language*, HASE 2008 | per-stream period; strictly periodic clocks; rational phase shift | integer periods and integer over/under-sampling factors; no operator merging two streams with a rational ratio into one; targets task schedulability, no queries, no sharing | medium |
| A6 | Bilsen et al., *Cyclo-Static Dataflow*, IEEE TSP 44(2), 1996 | cyclically varying token counts; static schedule and buffer bounds | token model, no sample position and no invertible split | low |
| A7a | Ghamarian et al., *Throughput Analysis of SDF Graphs*, ACSD 2006 | throughput by self-timed execution | a temporal quantity, not a positional one | low |
| A7b | Ghamarian et al., *Latency Minimization for SDF Graphs*, DSD 2007 | latency as the maximum over firings, minimized over admissible executions, measured in time | the startup tail here is the index of the first fully defined output record, derived from the plan without execution or timing model | medium |
| A8a | Le Guernic et al., *Programming Real-Time Applications with SIGNAL*, Proc. IEEE 79(9), 1991 | polychronous model: many clocks without a master clock | clock relations are logical (presence/absence), not ratios | medium |
| A8b | Benveniste, Le Guernic, Jacquemot, *Synchronous programming with events and relations*, SCP 16, 1991 | static clock calculus as algebraic equations over a finite field | an algebra of presence, not of rational rates; no startup tail; transformations act on clocks, not on a query plan | medium |

**Group B - sharing, plan rewriting, multiple queries**

| # | Work | What it already solves | Difference | Relevance |
|---|---|---|---|---|
| B1 | Chaudhary, Karimov, Zeuch, Markl, *Incremental Stream Query Merging* (ISQM), EDBT 2023 | merges streaming queries despite syntactic and structural differences: rewrite to normal form, semantic signatures, equivalence by an SMT solver; incremental, for ad-hoc queries | no rate algebra and no positional interleave; more general than R2, which covers only sibling order in `STREAM_ADD` | high for R2 as a technique, none for the rate algebra |
| B2 | Kolchinsky, Schuster, *Real-Time Multi-Pattern Detection*, SIGMOD 2019 | shared subexpressions between CEP patterns | event patterns, not rates | low |
| B3 | Schmitz et al., DEBS 2025 (hybrid batch-stream workloads) | empirical characterization of production Flink queries | "operator merging" is fusion of logical into physical operators, not sharing between queries | low |
| B4 | Hirzel, Soule, Schneider, Gedik, Grimm, *A Catalog of Stream Processing Optimizations*, CSUR 2014 | named optimizations with safety and profitability conditions | R1 falls under operator reordering, R2 under redundancy elimination; the safety conditions of R1 are an instance of the catalog's | mandatory citation |
| B5 | Soule et al., *A Universal Calculus for Stream Processing Languages* (Brooklet), ESOP 2010 | a common calculus with proofs of transformation equivalence | a calculus over operators and state, without rate or sample position | medium |
| B6 | Krishnamurthy, Wu, Franklin, *On-the-Fly Sharing for Streamed Aggregation*, SIGMOD 2006 | sharing aggregates with different periodic windows and predicates without upfront MQO | time windows, not rational rates; dynamic sharing | medium |
| B7 | Chen, DeWitt, Tian, Wang, *NiagaraCQ*, SIGMOD 2000 | grouping continuous queries by common subexpressions | the historical origin of the line | low |
| B8a | Sellis, *Multiple-Query Optimization*, ACM TODS 13(1), 1988 | MQO as a cost problem | - | low for novelty, high for the phrasing of the negative plan-size result |
| B8b | Roy, Seshadri, Sudarshan, Bhobe, *Efficient and Extensible Algorithms for MQO*, SIGMOD 2000 | cost heuristics; sharing applied only when the cost model justifies it | - | as B8a |

**Group C - languages and systems for positioning**

| # | Work | Difference | Relevance |
|---|---|---|---|
| C1 | Thies et al., *StreamIt*, CC 2002 | statically declared integer token rates; `SplitJoin` round robin splits by integer weights, not positionally by a rational ratio; no queries or artifacts | low |
| C2 | Eker et al., *Taming Heterogeneity - the Ptolemy Approach*, Proc. IEEE 2003 | a modeling and simulation platform, not a query engine | low |
| C3 | Chandramouli et al., *Trill*, PVLDB 2014 | temporal-relational model with validity intervals; no rate algebra | low |
| C4 | Abadi et al., *Aurora*, VLDB J. 12(2), 2003 | the DSMS canon next to CQL | low |
| C5 | Hirzel, Schneider, Gedik, *SPL*, TOPLAS 39(1), 2017 | explicitly rejects the synchronous model; decentralized schedule with back-pressure | low |

**Group D - dataflow model variants**

| # | Work | Role in the argument | Relevance |
|---|---|---|---|
| D1 | Buck, Lee, *Scheduling Dynamic Dataflow Graphs with Bounded Memory Using the Token Flow Model* (BDF), ICASSP 1993 | why CSDF and not data-dependent control: the streams here are statically regular | low |
| D2 | Bhattacharya, Bhattacharyya, *Parameterized Dataflow Modeling for DSP Systems*, IEEE TSP 49(10), 2001 | dynamic parameters; the parameters here are static | low |
| D3 | Theelen et al., *A Scenario-Aware Data Flow Model*, MEMOCODE 2006 | scenarios; no operating modes in this scope | low |
| D4 | Ahmad, Kennedy, Koch, Nikolic, *DBToaster*, PVLDB 5(10), 2012 | another route to avoiding repeated work: higher-order deltas instead of subplan sharing | medium for H9, low for novelty |

**Group E - determinism, replay, artifacts**

| # | Work | Difference | Relevance |
|---|---|---|---|
| E1 | Zaharia et al., *Discretized Streams*, SOSP 2013 | determinism as a fault-tolerance mechanism at micro-batch granularity; here determinism is a property of the model, shared with the synchronous line and SDF; only its binding to an artifact readable after the fact is specific | medium |
| E2a | Boden et al., *PEEL*, TPCTC 2017 | orchestration of experiments; names hardware-dependent parameters as a threat to repeatability | low |
| E2b | Karimov et al., *Benchmarking Distributed Stream Data Processing Systems*, ICDE 2018 | benchmark methodology | low |
| E2c | Henning, Hasselbring, *Theodolite*, JSS 2023 | repeatability-oriented benchmarking | low |

### 7.2. The two-part test on axis A - 21 entries

The test of 2.2 applied to the works on the sharing axis. **The figure 21 counts the entries of this matrix.** Two counting conventions are explicit here so that the figure can be checked: entry 20 groups three works of one line (AStream, AJoin and their successor SASPAR); entries 17, 18 and 21 (a survey and two compiler-side works) are on the materialization side of the axis and record that they do not share between queries, which is itself an answer to (A1). Basis as in 3.4; "first pass" means the work was assessed in 7.1.

| # | Work | Unit of sharing (A1) | Who fixes identity, and when (A2) | Outcome | Basis |
|---|---|---|---|---|---|
| 1 | Shared Arrangements, PVLDB 2020 | an index (`arrangement`) over a relation, keyed by attributes | runtime, between independent queries | the nearest work to H9; different unit and different moment | L |
| 2 | Noria, OSDI 2018 | operators and indexes of a partially stateful graph | runtime, at dataflow transition - automatically, without the programmer | shares automatically, but the unit is an index over a relation | L |
| 3 | ISQM, EDBT 2023 | a query plan; equivalence proved by an SMT solver | runtime, incrementally, for ad-hoc queries | more general than R2 as a technique | L |
| 4 | Nova, TPDS 2021 | state under explicit programmer control inside one program, with time semantics of state access | none - it detects no equivalence | does not answer as the paper does | L |
| 5 | GraftDB, arXiv 2026 | operator state (hash table, accumulator) observed through a `state lens` | runtime, at query arrival - grafted onto a running execution | does not answer as the paper does | L |
| 6 | STREAM, Stanford | synopses and queues between operators; identity by window subsumption over one relation | the system, at plan build, within one plan and between plans | occupies the plan-build dimension with a different unit; a canonical precedent | L |
| 7 | Zhou, Larson, Freytag, Lehner, SIGMOD 2007 | similar, not only identical, subexpressions | the optimizer, at plan build | a second precedent of the plan-build dimension | L |
| 8 | iShare, SIGMOD 2021 | a shared plan under a per-query latency budget | runtime | nearest neighbor of the guarantee, not of the mechanism | L |
| 9 | GroupShare, CIDR 2024 | query groups under functional isolation (a per-query latency condition) | optimizer, over groups | the shape of its condition matches the latency half of the paper's admissibility condition and precedes it | L |
| 10 | FunShare, ICDE 2026 | as 9, carried over to streams; a per-query throughput constraint | runtime; groups merged and split continuously | as 9 | L |
| 11 | Hamlet, SIGMOD 2021 | aggregates of event trends | runtime; whether to share is decided adaptively | the sharpest existing argument against a compile-time sharing decision, backed by measurement | L |
| 12 | BigSubs / CloudViews (Jindal et al.), PVLDB 2018 | subexpressions selected for materialization at datacenter scale | offline, from workload history | the industrial anchor of the problem | L |
| 13 | Snowflake Dynamic Tables / Delayed View Semantics, SIGMOD Companion 2025 | a materialized view with a declared staleness bound (target lag) | the system decides when to refresh | on axes A and B at once; the nearest industrial counterpart of the paper's observability split | L |
| 14 | µWheel, DEBS 2024 | aggregates in a hierarchy of time wheels, independent of the query | no per-query decision | dissolves the identity question instead of answering it | L |
| 15 | Safe Shared State, DEBS 2024 | a **machine resource** - connection pool, dictionary table, LRU; typed API | declared by the programmer; safety guaranteed by the host-language compiler | a resource is shared, not a maintained result | L |
| 16 | SHARP, arXiv 2025 | partial matches indexed by the set of patterns that share them | runtime; above a budget a cost model **drops** a subset | a completeness contrast: the paper's value equivalence admits no such variable | L |
| 17 | Olteanu, *Recent Increments in Incremental View Maintenance*, 2024 | survey | - | outside the sharing cell; anchors the IVM canon | L |
| 18 | DBSP, PVLDB 2023 | nothing shared between queries; "sharing" occurs in the text only in the bibliography | the compiler, over one program - syntactic incrementalization without heuristics | occupies "compiler over one program" for incrementalization, without sharing | L |
| 19 | NebulaStream, ICDE 2026 | the **execution machine** - worker thread and common task queue | runtime, work-stealing scheduler | neither computation nor state shared between queries (5.9) | A+ |
| 20 | AStream / AJoin, 2019; SASPAR, ICDE 2023 | an execution resource; for SASPAR the partitioning operation and the network transfer it causes | runtime, adaptively | on the axis; does not answer as the paper does | A / L |
| 21 | FlowLog, PVLDB 2025 | - | IR canonicalization and subtree hashing, the counterpart of R2 outside streaming | outside the axis of the submission (R2 is not H9) | A |

**The answer to both questions together:** no entry answers both the way the paper does. The distribution is disjoint, not merely empty: the works that share **automatically** (Noria, ISQM, GraftDB, FunShare) take an index over a relation, a plan or operator state as the unit and decide at runtime, between independently submitted queries; the work that decides **in the compiler over one program** (DBSP) shares nothing between queries; STREAM and Zhou et al. occupy the plan-build dimension with synopses and similar subexpressions as the unit. The cell "unit = a materialized substrate stream identified by rate, logical origin and startup tail; identity established by the compiler over one query program" remains unoccupied.

Further works on the axis, assessed in the routes of section 5 and not entered as separate rows because their answers repeat a row above: ParCuR, TEGRA, SharedDB, QPipe, CJOIN, Nectar, Finkelstein (SIGMOD 1982), Roy et al. (B8b), Pequod, ShareFlow, MASC, SH2O, Veer and the Greenplum operator-state study.

### 7.3. The two-part test on axis B

| Work | Separates `O_S` and `W_S`? (B1) | Where the quantity comes from (B2) | Outcome |
|---|---|---|---|
| Geilen, Tripakis, Wiggers, HSCC 2011 | **yes** - timed actor interface theories keep both, encoding absence as an event at time infinity; refinement is "no fewer events and no later" | from a **timing model** over event traces; the quantity orders both cases but gives no index of the first of them | **conceptual precedent - the only one in the whole review** |
| PolyGraph, STTT 2021 | no - the startup quantity is a phase | **supplied by the designer**; the tool checks liveness; automatic inference of phases is named as future work | the nearest neighbor on the arithmetic itself (rational rates `p/q`, hyperperiod) |
| van Wanrooij, Basten, Geilen, ACM TECS 2025 | no - computes times, not indices | ASAP derived, all upper bounds supplied; infeasibility is a model error fixed by hand | does not answer as the paper does |
| Ghamarian et al. (A7a/A7b) | no | temporal quantities from self-timed execution | as in 7.1 |

| Answer to (B1) | Answer to (B2) | Who is there |
|---|---|---|
| yes | yes - statically from the plan | only the present work |
| yes | no - timing model, supremum over traces | Geilen, Tripakis, Wiggers |
| no - one temporal quantity | yes, but from actor execution times | the SDF/CSDF line (Ghamarian et al., self-timed scheduling) |
| no - one temporal quantity | no | filter banks, DSP |

No work computes both quantities statically from the plan. The separation of the two quantities has a conceptual precedent from 2010/2011 and is not presented as new; what is specific is deriving both from the plan.

## 8. Sparse cross-citation within the state-sharing line

The forward chases measured how little the nodes of the sharing line cite one another:

- the chase from Shared Arrangements alone missed four works visible from Noria (5.2);
- the five further nodes returned 70 records of which only **4** had been seen from the first two: an overlap of **6%** (5.3);
- ISQM cites neither of the first two nodes and is reachable by no chase from them; it entered through the term sweeps and was confirmed by the phrase sweep for shared materialized state across continuous queries (5.5);
- GroupShare and the datacenter subexpression study were reached by no index query and no chase, only by reading the bibliography of a work already retrieved (5.4).

The nodes belong to largely disjoint communities: DBSP collects citations from IVM theory and Datalog, ISQM from the NebulaStream line, iShare from the line that runs through QPipe, ParCuR and FunShare, Nova from distributed stream processing. This is a finding about the review rather than about the field: a forward chase from one node surveys one research line inside the axis, not the axis. Coverage of an axis is the union of chases from a node in **every** line plus a phrase sweep over the name of the resource, plus the bibliographies of works already read; the number of nodes, not the number of queries, measures it.

## 9. Limits

These limits concern the positioning of the paper, not its results.

### 9.1. Access

- The ACM DL ran its queries over the full text of the collection rather than over titles and abstracts, and its result lists were triaged from their leading entries rather than page by page: the ACM DL counts are complete, its triage is partial (5.7).
- Semantic Scholar refused service without an API key on 2026-08-25, so the second phrase sweep and the axis-B sweep ran on OpenAlex and DBLP (5.5, 5.6).
- Google Scholar has no interface for this task; scripted responses are truncated, and the pass was done by hand (5.8).
- SpringerLink and ScienceDirect were not queried separately.

### 9.2. Method

- The first pass searched and classified the technique axis only; the resource axis was added by the extension (5.1). This is a limit of the construction of the queries, recorded because it was corrected, not because it remains open.
- The phrase sweep on axis A ran twice on different instruments: the first ranked results semantically (Semantic Scholar), the second matched seventeen phrases literally (OpenAlex) and by title (DBLP). A line that names the resource in wording none of the phrases anticipates could still be missed, the way ISQM is missed by the chases.
- The axis-B sweep exhausted the daily OpenAlex budget, so five extending phrases carry a DBLP count only (5.6). This bounds the completeness of the positioning of the startup-boundary result, not its proofs.
- Counts are comparable only within one index and one field (5.5, 5.7).

### 9.3. Scope

- English-language work only, apart from one Polish-language item of the authors already in the bibliography.
- No survey of dissertations or technical reports. One technical report in scope - Buck's Berkeley dissertation on bounded-memory scheduling of dynamic dataflow graphs, UCB/ERL M93/69 (3.2) - was sought and not obtained; a file that had passed for it is the four-page ICASSP paper.
- Coverage is bounded above by the material available on 2026-08-25.
- Exclusions by decision: Simulink and Kafka Streams state stores (3.3).

### 9.4. Named items not resolved

| Item | State on 2026-08-25 |
|---|---|
| Buck, UCB/ERL M93/69 | sought, not obtained (9.3) |
| Feldera, the industrial continuation of DBSP, as a separate paper | not found; DBSP itself read in full (7.2, entry 18) |
| Materialize as a separate system description | not found; its mechanism is described by Shared Arrangements (7.2, entry 1) |
| RisingWave, a full version | not found; the four-page DEBS 2022 description is the version read |

The leads raised by the first pass (FlowLog, DBSP/Feldera, AStream/AJoin, SPES and EQUITAS, the Buck dissertation) were all assessed in the extension; only the Buck dissertation remained open.

## 10. Exploratory search for related systems

Separately from the corpus, an exploratory search for systems resembling RetractorDB was run before the first pass, in a conversation with a general-purpose language model. It is **not** part of the corpus: it pointed where to look and supplied no claims. Every item from it entered the paper only after its primary source was read.

### 10.1. Criteria

Systems were sought not only among databases and streaming platforms but among any showing at least one of: a declarative description of computation; a dependency or dataflow graph; regular streams and multi-rate processing; interpolation, decimation or resampling; a deterministic execution model with explicit time; DSP, embedded and edge applications; continuous queries, materialized state and durable data artifacts.

### 10.2. Map of the systems found

| Family | Systems | Main similarity | Main difference |
|---|---|---|---|
| synchronous and dataflow | SIGNAL/Polychrony, SDF, Ptolemy II, StreamIt | static rate relations, computation graph, schedule analysis and synthesis | no link between the model and a working query engine with artifacts and IPC |
| DSP and model-based design | GNU Radio, Faust, Simulink | filters, DSP graphs, multi-rate, resampling, embedded deployment | a different level of abstraction and another notion of the stream's regular interval |
| deterministic reactive systems | Lingua Franca, SIGNAL/Polychrony | logical time, dependencies, deterministic order, real time | events, reactions or clocks instead of an algebra of regular streams |
| streaming and continuous SQL | Apache Flink, Materialize, RisingWave | continuous computation, dataflow, state, declarative queries | events and timestamps; watermarks and windows (Flink, RisingWave), logical timestamps and frontiers (Materialize), instead of a rational sampling interval |

| System | State on 2026-08-25 |
|---|---|
| SIGNAL / Polychrony | cited (7.1, A8a/A8b) |
| SDF, Ptolemy II | cited, together with an executable SDF/CSDF comparison in the paper (7.1, A6, C2) |
| StreamIt | cited (7.1, C1) |
| GNU Radio | named in the paper as a tool that carries these operations in practice |
| Faust | cited |
| Simulink (`Rate Transition`, explicit sample times) | excluded by decision (3.3) |
| Lingua Franca | cited, read in full |
| Materialize | cited through Shared Arrangements; a separate description not found (9.4) |
| RisingWave | cited (DEBS 2022 description); a full version not found (9.4) |
| Apache Flink | cited; its state stores covered by a peer-reviewed description (3.3) |
| Kafka Streams state stores (added by the extension) | excluded by decision (3.3) |
