# Reviewer mirror specification

This file is the pre-submission recipe for the double-anonymous artifact.
Creating the public mirrors is deliberately a separate, authenticated action:
Anonymous GitHub requires a GitHub sign-in. The mirror ID is chosen by the
author rather than randomized -- what is typed into the form is what appears in
the URL -- so the paper can carry the addresses before the mirrors exist. What
must not precede the mirrors is the availability claim, which waits for the
acceptance trial below.

## Sources and revisions

Create five read-only mirrors, each pinned to the revision below. The artifact
entry point is pinned only after its pending documentation correction has been
reviewed and committed; record that full SHA here before creating its mirror.

| Role | Source repository | Revision to mirror |
|---|---|---|
| Artifact entry point | `rdb-artifact` | `TBA_AFTER_REVIEW` |
| Engine snapshot | `retractordb` | `6dec187e6b0cc66d119d4d9a9dc384e93adf6839` |
| Experiments and data | `rdb-experiment` | `b713e1df47a5f94357f708706b85f5603f261534` |
| Canonical documentation | `dokumentacja-rdb` | `ed00f6aa3f2d7b7bd1c91e2eb7248a1ee8de3bf1` |
| English documentation | `documentation-rdb` | `8d543c8cbf95ab7cdb41049be3b30163e225bf5b` |

The historical H9 measurement revisions remain the pair already recorded in
`MANIFEST.md`: engine
`856ee54b0f4ab450a6b61e3c08e045f404a79488` and experiment
`81bf4bea00efb922678862c90462fb3c0dfe5fda`.

## Redaction configuration

Use the same replacement rules for all five mirrors. At minimum, redact the
author's name in accented and ASCII forms, GitHub account, email addresses,
ORCID, personal domains, affiliation, local absolute paths, and any preprint
title that resolves to the author. The term field takes regular expressions, so
escape the dots in addresses and identifiers. Leave all four display options
off, leave automatic branch updates off, pin a commit rather than a moving
branch and set expiry beyond the review period.

The form has no file-exclusion field, so a mirror carries the whole pinned tree
and differs from it only by redaction. Anything that must not be published has
to be handled by a term, or by a commit -- and a commit changes the pin.
Full operational detail, including the term list this artifact was redacted
with, is in `paper-arXiv/debs/procedura_anonimizacji.md`.

Inspect the rendered mirror and its downloadable archive for every configured
term. Automatic owner redaction is not enough: manifests and shell scripts
contain source URLs, and prior-work citations can contain author identifiers.

Keep the five repository names off the term list. Section 0 of
`bin/verify_pins.sh` finds each pin by grepping `MANIFEST.md` for a table row
that begins with the repository name and `checkout.sh` for a variable named
after it; redacting those names leaves the pins undeclared and step 4 below
fails on a mirror that is otherwise correct. The account name in the URL column
is redacted without affecting either grep.

## Paper integration

After all mirrors exist, replace the placeholders in
`paper-arXiv/debs/references.bib` with the randomized URLs. Cite the artifact
entry point plus the experiment mirror; expose the engine and both documentation
mirrors from the entry point. Keep the full revisions visible in the anonymized
manifest. Do not claim availability before the acceptance trial below passes.

## Unauthenticated acceptance trial

Run the trial in a browser profile and shell with no GitHub or Anonymous GitHub
session:

1. Open every URL exactly as printed in the generated paper.
2. Download all five archives and verify that no request returns `401`.
3. Search paths and text for all configured identifying terms.
4. Arrange the extracted directories as siblings under one workspace, named
   `retractordb`, `rdb-experiment`, `dokumentacja-rdb` and `documentation-rdb`,
   and run the mirror mode of the pin checker from the artifact entry point:

   ```bash
   RDB_MIRROR=1 RDB_WORKSPACE=<workspace> ./bin/verify_pins.sh snapshot
   ```

   Expect `RESULT: declarations and archives match; revision identity NOT
   verified`, six `SKIP` lines, and exit status 0. Mirror mode exists because a
   mirror is a snapshot without `.git`: sections 1 to 3 ask git which commit a
   directory is, which a redacted copy cannot answer even in principle, since
   the redaction rewrites file contents and no hash of it can equal the pinned
   one. Without `RDB_MIRROR=1` the script stops at the first missing `.git`,
   which is the correct behaviour for a broken clone and was, until 2026-08-26,
   the reason this step could not be run at all.

   A mismatch in section 4 is the finding to watch for: the raw archives are
   binary and must survive the mirror byte for byte. If one of them fails its
   SHA-256, the anonymizer rewrote a binary file, and the archives have to be
   excluded from redaction before the mirror is usable.

5. Reproduction is verified on a clone, not on the mirror.
   `bin/reproduce_analytic.sh` reads stored products with `git show HEAD:<path>`
   and detects regeneration diffs with `git status`, so it has no meaning on a
   snapshot without history. Clone each source at the SHA pinned above, run
   `bin/verify_pins.sh snapshot` (no `RDB_MIRROR`) and then
   `bin/reproduce_analytic.sh --workspace <workspace>`, and compare all
   regenerated tables with the preserved products. What the mirror has to
   deliver is the same bytes as that clone; step 4 is what checks it.

6. Record the mirror IDs, pinned revisions, UTC time, command transcript, and
   generated checksums in the submission handoff, together with the six skipped
   checks from step 4 and where they were verified instead.

Only after all six steps pass may the paper say that the artifact is available
to reviewers through an anonymized mirror. The claim that step 4 supports is
availability and integrity of the delivered bytes. It is not a claim that a
reviewer can reproduce the analysis from the mirror alone: today that needs a
clone, and making the analytic path work without history is an open item.
