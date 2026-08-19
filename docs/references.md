# Reference survey

> **These are notes, not rules.** Ideas about the format, kept for the arguments in them.
> The format itself is [FORMAT.md](../FORMAT.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

What exists already, what each one gets right, and where each one hurts. This is the most
finished part of the repository — the notes elsewhere are speculation, but this is a survey
of things that shipped.

It is also the answer to the reasonable question "why not just use one of these?".

## Summary

| Source | Taken | Left behind, and why |
|---|---|---|
| [OpenSLO](https://github.com/OpenSLO/OpenSLO) | the k8s-style envelope (`apiVersion`/`kind`/`metadata`/`spec`), `op: lte\|gte\|lt\|gt`, the SLI ↔ SLO split, the idea of `ratioMetric`/`thresholdMetric`, `indicator` vs `indicatorRef` | error budgets and `budgetingMethod` — meaningless for a single run; the word `objective` — taken by a target with a budget; the absence of units (`target` vs `targetPercent` instead of a `unit`) |
| [Keptn slo.yaml](https://v1.keptn.sh/docs/1.0.x/reference/files/slo/) | two severity levels (pass/warning), comparison against a previous run, `weight`, `key_sli` | snake_case; string criteria such as `"<=+10%"` with no units; `total_score` in percent — a weighted sum is hard to explain to humans |
| [k6 thresholds](https://grafana.com/docs/k6/latest/using-k6/thresholds/) | the aggregation set (`p(95)`, `avg`, `min`, `max`, `med`, `rate`, `count`), tag-based selection, `abortOnFail` → `onViolation: abort` | the metric names (`http_req_duration`) — k6's local vocabulary; JS objects as the format |
| [Taurus PassFail](https://gettaurus.org/docs/PassFail/) | "criterion + window + action", `stop as failed` | the string DSL `avg-rt of IndexPage>150ms for 10s` — a bespoke grammar inside the spec; abbreviations like `avg-rt`, `rc500` |
| [gatling-picatinny](https://github.com/galax-io/gatling-picatinny/blob/main/docs/assertions.md) | the problem statement itself: metric → threshold per request and for "everything" | Russian-language keys; milliseconds with no unit; no operator; the `all` key (replaced by an empty `selector: {}`). The author deprecated the mechanism in v1.18.0 |
| [SLA4OAI](https://github.com/isa-group/SLA4OAI-Specification) | `guarantees` → `objectives` as boolean predicates over metrics; separating metrics from targets | coupling to OpenAPI; the billing-oriented `plans`/`quotas`/`rates` — a different problem |
| [api1st/opensla](https://github.com/api1st/opensla) | the idea of public and private SLA variants per consumer tier | the project is dead (4 commits, 2 stars), GPL-3.0 |
| [OpenTelemetry semconv](https://opentelemetry.io/docs/specs/semconv/http/http-metrics/) | **the metric and attribute names wholesale**, `test.*` and `cicd.*` for run identity, UCUM units, the namespace style | nothing |

## Adjacent projects

Surveyed to check whether this already exists.

| Project | What it does | Why it does not fit |
|---|---|---|
| [slok/sloth](https://github.com/slok/sloth) | generates Prometheus rules from SLOs | production SLOs, not a test run; tied to Prometheus |
| [pyrra](https://github.com/pyrra-dev/pyrra) | UI and rules for SLOs on top of Prometheus | same |
| [rsionnach/opensrm](https://github.com/rsionnach/opensrm) | a service reliability manifest as code | declares SLOs and dependencies with no link to a test run; draft |
| [slo-generator](https://github.com/globocom/slo-generator) | computes SLOs across several backends | no model of run requirements |
| Perfana | continuous performance testing, proprietary | closed format |

## Conclusion

No format covers "requirements for a load test run, tool-agnostic, strictly parseable,
OTel-compatible". The nearest neighbours solve either production SLOs (OpenSLO and its
ecosystem), or CI gates with a bespoke vocabulary (Keptn), or are the internal DSLs of
individual tools (k6, Taurus, picatinny).

Hence the two pillars of OpenNFR that none of them has:

1. metric and attribute names are not invented but taken from OTel semconv;
2. `inconclusive` — a run that never reached its target load does not count as a success.
