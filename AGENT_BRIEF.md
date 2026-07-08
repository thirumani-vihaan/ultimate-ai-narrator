You are an autonomous coding agent with terminal + filesystem access.

MISSION: Build "Ultimate AI Narrator" from the spec at
C:\Users\kathyayanit\Desktop\v\ultimate-ai-narrator\project challenge.pdf, into
C:\Users\kathyayanit\Desktop\v\ultimate-ai-narrator, fully testable without any real
API keys or hardware, then run a bounded improvement loop until further changes stop
being worth their cost.

----------------------------------------------------------------
OPERATOR CONSTRAINTS (from the product owner — override defaults)
----------------------------------------------------------------
- FRAMEWORK: Flutter. It is the only framework that can be built AND tested on this
  Windows build machine (Flutter 3.44.2 / Dart 3.12.2 installed at
  C:\Users\kathyayanit\flutter\bin; Swift/iOS cannot be compiled or tested here).
- SINGLE-SCREEN IS A *SOFT* GUIDELINE. The spec's "single screen" is not a hard limit.
  A 2-screen flow is acceptable — and preferred — IF it demonstrably improves the
  child's experience AND does not jeopardise the hard constraint below.
- HARD CONSTRAINT (the only hard limit besides correctness): the app must stay smooth
  and lightweight on mid-range ~3GB-RAM Android devices — animations at ~60fps, low
  memory footprint, small install size, no jank, no leaks. NOTHING may cross this line.
  Any "delight" feature that risks the 3GB budget is rejected, not shipped.
- PRODUCT GOAL: this submission must stand out among ALL possible submissions and go
  "10 steps beyond" a baseline entry on delight, polish, and production-mindedness —
  strictly within the hard performance/memory budget above. Going beyond must never
  create a disadvantage against the hard limits.

DO NOT ask me questions unless you hit a hard blocker after 3 retries
on the same task, or a HARD STOP condition below triggers.

DO NOT write implementation code before Phase 1 (Architecture &
Planning) is reviewed and confirmed. Planning mistakes are cheap to
fix on paper and expensive to fix in code — do the thinking first.

DO NOT report a feature as "done," "wired up," or "working" unless
you have concrete evidence it runs end-to-end — a test that actually
exercises the real call path, or a log line proving the real
implementation (not just its fixture) executed at least once. **[v2]**
A component existing and being correctly built is not the same claim
as a component being reachable from the actual entry point — verify
the second claim separately, explicitly, every time.

SECURITY:
- git push IS authorized to the personal remote whose URL contains
  "thirumani-vihaan" — push after every meaningful update (do not
  push to any other remote).
- Do NOT commit real API keys/secrets; use .env + .gitignore.
- Before every commit, grep the diff for credential-shaped strings
  (API keys, tokens, anything matching common secret patterns) and
  confirm no backup/scratch files (e.g. `.env.backup`) are staged.
  **[v2]** — a real credential reaching a local commit is a near-miss
  worth actively guarding against, not just relying on the remote's
  secret scanner to catch it.
- Local filesystem operations only unless told otherwise.

================================================================
PHASE 0 — INTAKE
================================================================
1. Read C:\Users\kathyayanit\Desktop\v\ultimate-ai-narrator\project challenge.pdf in full.
2. Produce SPEC_SUMMARY.md: goals, hard constraints, tech stack,
   acceptance criteria, performance budgets, explicit non-goals.
3. Produce DEPENDENCY_INVENTORY.md: list every external dependency
   the spec implies — APIs, paid services, physical hardware (mics,
   cameras, specific drivers), anything requiring a credential or a
   device that might not be present on the build machine. For each,
   note its known platform-specific gotchas if any are foreseeable
   (e.g. "macOS screen capture requires an explicit permission-
   request API call beyond the entitlement — some capture libraries
   never trigger the native dialog on their own"). **[v2]** — don't
   wait to discover these live; if the dependency has a well-known
   platform quirk, surface it during intake so Phase 1 can design
   around it instead of hitting it as a live debugging session later.
4. Flag anything ambiguous or missing (don't guess silently on
   things that materially change scope).
CHECKPOINT: wait for me to confirm SPEC_SUMMARY.md and
DEPENDENCY_INVENTORY.md before Phase 1.

================================================================
PHASE 1 — ARCHITECTURE & PLANNING (no code written yet)
================================================================
Goal: make the design decisions that are expensive to change later
BEFORE any of them are expressed in code. A bug in a module boundary
found during planning costs a rewrite of a paragraph; the same bug
found in Phase 3 costs a rewrite of a subsystem plus every test that
assumed the old shape.

--- 1.1 ARCHITECTURE.md ---
- List every component/module and its single responsibility.
- Draw the data flow: what calls what, what's async vs sync, what's
  event/queue-driven vs direct call, where state lives and who owns
  mutating it (prefer immutable state + explicit transitions over
  scattered mutable state — this alone prevents a large class of
  concurrency bugs).
- Identify every module boundary where two components meet. These
  boundaries are where integration bugs happen — call them out
  explicitly, don't leave them implicit in prose.
- **[v2]** For every async producer/consumer pair (a background
  thread feeding an event loop, a socket being written to while also
  being read from, anything with two concurrent flows over one
  channel), explicitly state the concurrency model in prose: which
  side runs first, whether they run simultaneously, and what happens
  if one side is unbounded/long-lived while the other expects a
  finite sequence. Sequential (`do all of A, then all of B`) and
  concurrent (`A and B run at once`) are both valid designs — but
  the choice must be a stated decision, not an accident of how the
  first draft happened to be written.

--- 1.2 INTERFACES.md ---
Before writing any implementation, define the exact contract at
every boundary identified in 1.1:
- Function/method signatures, or message shapes for async/queue
  boundaries.
- Data schemas for anything crossing a module boundary (this is the
  "schema.py is an immutable contract" idea, applied to every
  boundary, not just top-level dataclasses).
- For every item in DEPENDENCY_INVENTORY.md: the exact injectable
  interface it will sit behind (see Phase 2's mock-first protocol —
  the interface shape is decided HERE, in planning, not improvised
  when the integration code gets written).
- **[v2]** For every injectable interface: explicitly name the ONE
  place in the codebase (the real entry point — `main()`, app
  startup, whatever actually runs in production) where the real
  implementation gets constructed and passed in. Write this down
  now, as a contract, so Phase 2 has a named target to satisfy and
  Phase 2's own checklist (2.3) has something concrete to verify
  against.
- Error contract per boundary: what exceptions/error values can
  cross it, and who is responsible for handling vs propagating them.
  Undefined error-handling responsibility is one of the most common
  sources of bugs that "no single person's tests catch." **[v2]**
  Explicitly forbid bare `except Exception: pass`-shaped handling at
  any boundary without a same-line log/print of what was caught —
  a silently swallowed exception at a boundary is indistinguishable
  from that boundary simply not existing, and is one of the hardest
  bug classes to find later because it produces no evidence at all.

--- 1.3 TASK_PLAN.md ---
- Break the build into ordered tasks with explicit dependencies
  between them (task B needs task A's interface finished, etc).
- Mark each task's RISK: how uncertain or novel is this piece
  (e.g. "first time wiring this SDK," "concurrency-heavy," "spec
  was ambiguous here"). Order HIGH-risk tasks earlier, not later —
  you want to find out a risky assumption is wrong while the rest
  of the system is still small, not after ten other modules were
  built assuming it was right.
- For any HIGH-risk task, plan a small throwaway spike/prototype to
  validate the risky assumption before committing to the full
  implementation against it.
- **[v2]** Add an explicit final task, after every dependency's
  integration is built: "wire every injectable interface from
  INTERFACES.md into its named real-entry-point location, and add
  one test per dependency proving the real factory is actually
  reachable from that entry point" (not just that the fake works in
  isolation). This is its own task with its own checkbox, not an
  assumed side effect of building the integration.

--- 1.4 RISK_LOG.md ---
- List the specific ways this build could go wrong: ambiguous spec
  areas, dependencies with known-flaky behavior, performance budgets
  that look tight, anything you're genuinely unsure about.
- For each: what's the mitigation (spike, extra test coverage, a
  design choice that avoids the risk entirely, or "accept and
  monitor" if it's low-stakes)?

CHECKPOINT: present ARCHITECTURE.md, INTERFACES.md, TASK_PLAN.md,
and RISK_LOG.md together. Wait for me to confirm the design before
any implementation code is written. This is the single most
important checkpoint in the whole loop — a bad plan approved here
propagates into everything after it.

================================================================
PHASE 2 — BASELINE BUILD (MOCK-FIRST, FOLLOWS THE PLAN)
================================================================
Implement TASK_PLAN.md in order, against the contracts fixed in
INTERFACES.md. If reality forces a deviation from the plan (the
contract doesn't actually work once you're implementing against
it), STOP, update INTERFACES.md/ARCHITECTURE.md explicitly, note
the deviation and why in RISK_LOG.md, and only then continue —
never silently drift from the agreed design, since that's how the
plan stops being trustworthy for the rest of the build.

--- 2.1 Mock-first external dependency protocol ---
For EVERY item in DEPENDENCY_INVENTORY.md, using the interface
shape already decided in INTERFACES.md:

1. Write the real integration completely — real client, real request/
   response shapes, real error handling and retry logic, matching
   whatever the actual API/SDK/device expects. This is not stubbed
   out or left as a TODO; it is production code. **[v2]** If the
   dependency is a continuous/streaming/long-lived connection (not a
   single request-response), the concurrency model decided in
   ARCHITECTURE.md §1.1 must be implemented as stated — a sequential
   send-then-receive implementation is a silent contract violation
   if the design called for concurrent send/receive, and will
   typically fail invisibly (the connection looks "open" but never
   processes anything) rather than raising an obvious error.

2. Call it only through the injectable interface from INTERFACES.md
   — business logic never imports the real SDK directly outside
   that one integration module.

3. Build a fixture-backed fake implementation of the same interface:
   - a `fixtures/{dependency_name}/` folder with realistic synthetic
     sample data: normal responses, edge cases (empty results, huge
     payloads, unicode/unusual input), and error cases (timeouts,
     4xx/5xx, malformed responses, rate-limit/429s).
   - the fake implementation samples from these fixtures — randomly
     by default (so repeated test runs exercise different cases),
     or deterministically via a seed when a test needs a specific
     scenario reproduced.
   - the fake must be able to simulate failure modes on request
     (e.g. `FakeClient(force_error="timeout")`), not just happy path.

4. Config decides which implementation loads — default to the fake
   unless a real credential/device is actually present:
     if ELEVENLABS_API_KEY is set → use real implementation
     else → use fixture-backed fake, and log clearly that fixture
     mode is active (never silently pretend to be live).
   NOTE: the native device TTS engine (flutter_tts) is the DEFAULT,
   credential-free narration path and must fully work on its own;
   ELEVENLABS_API_KEY only enables the optional bonus remote-TTS
   path and must never be required for any test to pass.

5. Document the swap-over in REAL_API_SETUP.md: exactly which env
   vars to set, where to get real credentials, and confirmation that
   no code changes are needed — setting the keys is the entire
   handoff to live mode.

--- 2.2 Standard build steps ---
- Pin dependencies: pubspec.yaml (ranges) → resolve → smoke test →
  commit the resulting pubspec.lock. **[v2]** When a dependency is
  later migrated (e.g. a deprecated package replaced with its
  successor), update pubspec.yaml in the SAME commit as the code
  migration — never leave the old package importable/installable
  after the code stops using it; a stale manifest will silently
  reintroduce the deprecated dependency on the next fresh resolve.
- Write tests against the CONTRACTS in INTERFACES.md, using the fake
  implementations — the whole test suite must be runnable offline,
  by anyone, with no keys. (Run headlessly: `flutter test`.)
- Acceptance tests are behavior-based, not test-gamed (don't hardcode
  expected outputs where real logic should run; do assert against
  the range/shape of what fixtures can produce). In particular, the
  quiz renderer must be proven data-driven: a test feeds it JSON with
  3, 4, AND 5 options and asserts the UI renders each without code
  changes.
- For each HIGH-risk task from TASK_PLAN.md, run its spike first;
  if the spike invalidates the plan, go back to Phase 1 for that
  piece before building the full version.

--- 2.3 Wiring verification (mandatory, before Phase 2 checkpoint) --- **[v2, new section]**
For every injectable interface named in INTERFACES.md §1.2:
1. Grep-confirm the real implementation's constructor is called at
   least once OUTSIDE its own module and outside test files — the
   actual production entry point (`main()`, app startup, whatever
   the real "the app is now running for a user" path is).
2. If it is not called there, this is not a minor gap — it means the
   entire integration, however correctly built and tested in
   isolation, does not exist from the user's perspective. Fix this
   before considering the task done, not as a follow-up.
3. Write (or confirm existing) one integration-shaped test per
   dependency that constructs the app via its REAL entry point
   (`main()`/`build_app()`/equivalent) with the real factory
   supplied, and asserts the real implementation was actually
   instantiated — not just that the interface/fake pattern works.
4. Record the result of this check explicitly in TASK_PLAN.md next
   to each dependency's task (a simple ✅/❌ + the grep evidence),
   so "wired" is a verified claim, not an assumed one.

CHECKPOINT: v1 exists, matches the agreed architecture (deviations
logged, not silent), passes all acceptance tests using fixtures only
(zero real credentials needed), passes the §2.3 wiring verification
for every dependency, committed locally. Wait for my "continue"
before Phase 3.

================================================================
PHASE 3 — MEASURED IMPROVEMENT LOOP
================================================================
Goal: improve the product past baseline, sweeping every dimension
below, but STOP once further changes aren't worth it — measured,
not vibes.

--- 3.0 Baseline metrics ---
Before the first iteration, capture METRICS.md covering whatever's
measurable per dimension (see taxonomy below). **[v2]** Before
trusting any baseline number, confirm the instrumentation actually
covers what it claims to measure — e.g. if "end-to-end latency" is a
tracked metric, confirm every hop between "user action" and "user
sees result" has its own timer, not just the first and last steps
with everything in between assumed. An incomplete measurement chain
produces a confident-looking number that silently omits whichever
hop nobody instrumented — worse than no number, since it invites
false confidence.
NOTE: for THIS project the performance budget is load-bearing — the
metrics suite MUST include the ~3GB-RAM Android budget proxies:
frame build/raster times (target ~60fps / <16ms), widget rebuild
counts on the story→quiz transition and animations (shake, confetti),
memory/asset footprint, and cold-start time. Track these every
iteration; a regression here is treated as high severity.

Every iteration re-runs the same measurement suite against fixtures.
Anything that can't be measured this way goes in FUTURE_IDEAS.md
instead of the loop.

--- 3.1 Improvement dimension taxonomy ---
Each iteration's candidate list must draw from ALL of these, not
just whichever keeps producing easy wins. Track dimension coverage
in BACKLOG.md; every dimension must get at least one real candidate
considered every 3 iterations, even if it's ultimately rejected.

1. CORRECTNESS — bugs, wrong edge-case handling, spec deviations.
   Measure: failing/flaky test count, known-bug count.
2. PERFORMANCE — latency, throughput, memory, against the spec's
   own budgets if it has them. Measure: p50/p95 timings, profiler
   output. **[v2]** When measuring anything that calls a real rate-
   limited external API, explicitly separate "genuine processing
   latency" from "time spent waiting on retry/backoff due to a quota
   or rate limit" in the reported number — conflating the two makes
   a quota exhaustion look like a performance regression, and can
   send the loop chasing a fix for a problem that isn't actually
   about speed.
3. RELIABILITY / RESILIENCE — retry logic, graceful degradation,
   reconnect handling, partial-failure behavior. Measure: fault-
   injection test pass rate (using the fixture error cases).
4. SECURITY — input validation, injection risks, secret handling,
   dependency CVEs. Measure: static-analysis/lint-security tool
   output, count of unvalidated external inputs.
5. ERROR HANDLING & EDGE CASES — empty/null/huge/malformed inputs,
   boundary values. Measure: edge-case fixture coverage %.
6. OBSERVABILITY — logging, metrics, tracing, clear error messages.
   Measure: % of failure paths that log actionable context. **[v2]**
   Specifically include: % of `except` blocks that log the caught
   exception's content (not just that *something* was caught) —
   this is the single highest-leverage observability check, since a
   silent except block can hide any other bug class behind it
   indefinitely.
7. UX / ERGONOMICS (for anything user-facing, including CLIs and
   APIs) — clarity of output, sensible defaults, discoverability.
   Measure: manual walkthrough checklist, or usability heuristics.
   For THIS project: the joyful, child-first feel is a first-class
   metric — narration clarity, delight of the correct-answer
   celebration, gentleness of the wrong-answer retry, accessibility
   (tap-target size, contrast, reduced-motion option).
8. CODE QUALITY / MAINTAINABILITY — duplication, complexity,
   naming, module boundaries. Measure: lint/complexity scores
   (`flutter analyze` clean).
9. TEST DEPTH — coverage of the fixture-based scenarios themselves,
   not just line coverage. Measure: % of documented edge/error
   fixtures actually exercised by a test.
10. COST EFFICIENCY — token usage, API call counts, compute cost
    per operation, caching opportunities. Measure: calls per
    operation, estimated $ per operation. For THIS project: remote
    TTS audio should be cached so a repeated story never re-hits the
    API; measure cache hit rate.
11. SCALABILITY — behavior under concurrency or larger inputs than
    the spec's examples. Measure: load-test results if applicable
    (e.g. very long story text, a quiz with many options).
12. DOCUMENTATION — README accuracy, setup instructions, inline
    docs for non-obvious logic. Measure: manual doc-vs-code
    accuracy check. The README must answer every question the spec's
    submission section asks (framework choice, transition-state
    handling, data-driven quiz, caching, audio loading/failure
    states, performance profiling before/after, lightweight-on-
    Android approach, AI usage & judgment).
13. EXTENSIBILITY — how easily the spec's likely next feature could
    be added without a rewrite. Measure: qualitative review against
    ARCHITECTURE.md and SPEC_SUMMARY.md's stated goals.
14. FEATURE COMPLETENESS vs SPEC INTENT — not just literal
    acceptance criteria, but the spirit of the mission statement.
    Measure: qualitative gap review against SPEC_SUMMARY.md.
15. **[v2, new dimension]** WIRING INTEGRITY — for every injectable
    interface, is the real implementation still reachable from the
    real entry point after this iteration's change? Measure: rerun
    the §2.3 wiring verification checks; treat any regression here
    (a previously-passing wiring check now failing) as a CORRECTNESS
    bug at the highest severity, since it means a working feature
    silently became unreachable — the exact failure mode that is
    otherwise invisible to a metrics suite that only tests fakes.

--- 3.2 Each iteration ---
1. GENERATE CANDIDATES: propose up to 5 concrete, scoped improvements,
   pulling from underrepresented dimensions first per the coverage
   rule above. Each candidate gets:
     - dimension (from the taxonomy)
     - one-line description
     - Impact estimate (1-10)
     - Confidence in that estimate (0.0-1.0)
     - Effort estimate (1-10, time/complexity to implement)
     - predicted_ROI = (Impact × Confidence) / Effort

2. SELECT: take the single highest predicted_ROI candidate above
   1.5. If none clears the bar, the loop ends here — go to Phase 4.

3. IMPLEMENT: make ONE change only. No batching multiple risky
   changes into one iteration — each must be independently
   measurable and revertible. All testing stays fixture-based;
   never require real credentials mid-loop. If a change would
   violate an existing INTERFACES.md contract, update the doc and
   flag it — don't drift silently here either.

4. RE-MEASURE: run the full metrics suite again, including the §3.1
   dimension-15 wiring-integrity check every iteration regardless of
   which dimension this iteration's candidate targeted. **[v2]** —
   wiring regressions can be introduced by a change in an unrelated
   dimension (e.g. a refactor for CODE QUALITY accidentally drops
   the real-factory wire in `main()`), so this check cannot be
   skipped just because the iteration wasn't explicitly about
   dependency wiring.

5. LOG to IMPROVEMENT_LOG.md, append-only, one entry per iteration:
     iteration | dimension | change | predicted_ROI | measured_delta | decision

6. DECIDE:
   - Metrics improved (or a real qualitative win with no regression)
     → keep, commit.
   - Metrics flat or worse → revert, mark candidate "no-op" in
     BACKLOG.md so it's never retried.

--- 3.3 Stopping conditions (ANY of these ends the loop) ---
a. SOFT — ROI trend: rolling average of measured_delta-based ROI
   over the last 5 iterations falls below 1.5.
b. SOFT — empty backlog: no candidate this iteration clears the
   ROI bar across ANY dimension.
c. HARD — iteration cap: 30 reached, regardless of what ROI looks
   like. This exists because an agent's own ROI math can be wrong or
   self-serving — it is a ceiling that doesn't trust the loop's own
   judgment.
d. HARD — budget cap: 2h wall-clock spent (token budget governed by
   the time + iteration caps).
e. HARD — 3 consecutive reverted/no-op iterations in a row →
   stop even if the cap isn't reached; this pattern means the
   remaining backlog is noise.
f. **[v2, new]** HARD — any wiring-integrity regression (§3.1 #15)
   detected: stop immediately, before evaluating any other stopping
   condition, and fix the regression as the very next action — do
   not continue the improvement loop with a known-broken real-world
   wire, even if the rest of the metrics look fine.

Hitting a HARD condition always wins over a SOFT one still looking
promising. Report which condition triggered the stop.

--- 3.4 Guardrails during the loop ---
- Never modify the immutable schema/contract files from INTERFACES.md
  as a "polish" change without flagging it as its own high-visibility
  candidate — contract changes aren't small.
- Never require a real credential to pass a test, at any point in
  the loop. If a candidate can only be validated against a live
  API, implement it behind the same fixture pattern as Phase 2 and
  note in REAL_API_SETUP.md that it should be spot-checked live
  after keys are added.
- Never ship a "delight" change that regresses the ~3GB-RAM Android
  performance/memory budget — that budget is the hard limit and wins
  over any polish candidate.
- Every kept change is its own atomic commit: message includes
  dimension, predicted ROI, and measured delta, so it's cleanly
  revertible on its own.
- CHECKPOINT every 5 iterations regardless of stopping conditions:
  print a short status (iteration #, current metrics vs baseline,
  dimension coverage so far, top of backlog) and wait for
  "continue" — this is a real pause, not decorative.

================================================================
PHASE 4 — WRAP-UP
================================================================
Produce FINAL_REPORT.md:
- baseline metrics vs final metrics, side by side, broken out by
  dimension
- every kept change with its measured impact
- every reverted/no-op candidate (so it's not re-proposed later)
- remaining BACKLOG.md items that never cleared the ROI bar
- which stopping condition ended the loop
- confirmation that the full test suite still passes on fixtures
  only, zero real credentials required
- confirmation that ARCHITECTURE.md/INTERFACES.md still match the
  actual code (any logged deviations reconciled into the docs, not
  left stale)
- **[v2]** confirmation that the §2.3/§3.1-15 wiring verification
  passes for every dependency in DEPENDENCY_INVENTORY.md, listed
  individually — this is the final report's most load-bearing line,
  since everything else in the report describes a system that is
  worthless if its real dependencies were never actually reachable.

Also confirm REAL_API_SETUP.md is current and complete: every env
var needed, where to get each credential, and that setting them is
the entire remaining step to go live — no code changes required.

Wait for my sign-off. Push meaningful updates to the authorized
"thirumani-vihaan" personal remote as you go.

BEGIN NOW at Phase 0.
