# Metric and attribute names

Which names to write in a document, and where they come from.

> **Partly enforced, partly borrowed on trust.** The schema does not enumerate metric or
> attribute names and never will — enumerating them would make every new metric a change to the
> format. So nothing here is checked by `scripts/verify.sh`. What makes it reference rather than
> opinion is that the names below are **taken verbatim from OpenTelemetry semantic conventions**,
> which is a source outside this repository. The one exception is called out by name at the
> bottom of this page.

## The rule

[Principle II](../.specify/memory/constitution.md) is the shortest statement of it:

- a metric or attribute name **must** come from OpenTelemetry semantic conventions whenever an
  equivalent exists there;
- names of our own are permitted only under the `loadtest.*` namespace, and only where semconv
  has none;
- aliases and second spellings for one concept are forbidden, human-friendly shorthands
  included;
- derived quantities — throughput, error rate, apdex — must not become metrics. They are
  computed by aggregation from metrics that already exist.

The payoff is not tidiness. A report written in borrowed names correlates with the traces of
the same run without glue, because both sides already agree on what an endpoint is called.

## Metrics, taken verbatim

| Name | Type | Unit | Role |
|---|---|---|---|
| `http.client.request.duration` | Histogram | `s` | the primary latency metric. A load generator **is** an HTTP client, so the client-side metric is the semantically correct one — not `http.server.*`, and not the tool's own `http_req_duration` |
| `http.client.request.body.size` | Histogram | `By` | volume sent |
| `http.client.response.body.size` | Histogram | `By` | volume received |
| `http.server.request.duration` | Histogram | `s` | when a requirement is stated over the system's own data rather than the generator's. Not interchangeable with the client-side one — see the vantage-point rule below |

**Vantage point is not a detail.** A load generator measures latency as a client; a production
stack usually measures it as a server. The two numbers are not comparable, and letting one stand
in for the other is the failure the whole format exists to prevent. Pick the metric that matches
where the measurement is taken.

## Selection attributes, taken verbatim

These are the keys of a [`selector`](../schema/README.md#selector).

| Attribute | Example | Note |
|---|---|---|
| `http.request.method` | `POST` | |
| `http.route` | `/api/v1/checkout` | the preferred way to address an endpoint |
| `url.template` | `/api/v1/orders/{id}` | client-side, when `http.route` is unavailable |
| `server.address`, `server.port` | `api.example.com` | |
| `http.response.status_code` | `500` | |
| `error.type` | `timeout`, `500`, `"*"` | `"*"` means the attribute is present with any value — this is how "an error" is expressed, and why there is no errors metric |
| `network.protocol.version` | `1.1`, `2` | |

## Run identity, taken verbatim

Nothing of our own is defined for this. Should anything ever emit a result document, this is the
vocabulary it uses.

| Attribute | Source in semconv |
|---|---|
| `service.name`, `service.version` | resource |
| `deployment.environment.name` | resource |
| `test.suite.name`, `test.case.name` | registry/test |
| `test.suite.run.status`, `test.case.result.status` | registry/test |
| `cicd.pipeline.name`, `cicd.pipeline.run.id` | registry/cicd |
| `vcs.ref.head.name`, `vcs.ref.head.revision` | registry/vcs |

## Addressing a request

| | `http.route` | `loadtest.request.name` |
|---|---|---|
| Status | **preferred** | pragmatic fallback |
| Portable across tools | yes | no — the name is arbitrary |
| Correlates with the service's production metrics | yes | no |
| Actually emitted by load generators | almost none | all of them |

Write requirements against `http.route` wherever an adapter can reconstruct it.
`loadtest.request.name` — k6's `name` tag, Gatling's request name, JMeter's sampler label — is
for the case where no route exists in principle, with the understanding that such a requirement
does not travel between tools unchanged. It is the worse option, not an equal one.

## The one name this repository has not borrowed

`loadtest.request.name`, `loadtest.group.name` and the rest of the `loadtest.*` namespace are
**not** OpenTelemetry names. They are a proposal that has been submitted nowhere, and nothing
emits them today.

Two of them nevertheless appear in the validated corpus, in
[`examples/six-statements.yaml`](../examples/six-statements.yaml), because the alternative was to
have no way of writing down the case every real tool actually presents. That is a debt, recorded
here rather than hidden: the corpus depends on names no standard carries.

The proposal itself, with the full list and the argument for each name, is a note and is
deliberately not linked from this page — it lives at `docs/semconv/loadtest.md`.

## What no tool emits

Every name above is what a document should say. What a tool actually publishes is a different
question, answered by [compatibility.md](compatibility.md), and the answer is that no load
generator publishes semantic convention names at all. An adapter is therefore always required,
and it is where units are converted — tools report milliseconds where the conventions require
seconds, an error three orders of magnitude wide.
