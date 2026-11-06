# Architecture and contracts

The implementation uses n8n as orchestration and Supabase PostgreSQL as the operational authority. Browser clients authenticate with Supabase Auth and use RLS-protected RPCs. Agent inference is configured against the existing OpenAI credential; no secret is exported.

## Processing path
Trusted staff webhook or manual synthetic envelope → prepare RPC → query embedding → semantic policy retrieval → eight sequential role workflows → finalize RPC → held outbox and human review. Gmail intake takes a separate unverified path that creates a review ticket without joining private order facts.

The Orchestrator role recommends a plan; deterministic n8n sequencing currently invokes all eight roles. It is not a dynamic autonomous tool router. Roles are Orchestrator, Intent Classification, Knowledge Retrieval, Order Resolution, Refund Decision, Customer Response, Human Escalation and QA Evaluation.

## Contracts
Input envelope: external_id, email, order_id, message, verified_identity. verified_identity is trusted only at the staff/service boundary; a public caller cannot authenticate by setting this boolean. Context contains ticket identity, verified customer/order facts, policies and accumulated agent_results.
Each role returns summary, action, policy_ids, needs_human, confidence and flags through a structured parser. Policy identifiers are checked against context. Exact prompts/schema are under agents/. Each subworkflow appends its named result and returns the full context to the next role.

Database finalization requires all eight distinct roles. It independently checks current order eligibility, creates pending approvals and records role outputs. The final held customer draft is deterministic; the AI draft is retained as an execution result. This reduces unsupported promises but does not prove model correctness.

## RAG
Knowledge uses 1536-dimensional embeddings, HNSW cosine index and bounded semantic retrieval. The embedding workflow is configured for OpenAI. Zero policies currently have embeddings because the provider rejected calls for exhausted credit. No lexical fallback is represented as successful semantic RAG.

## Security
All NovaCart tables have RLS; anonymous access is revoked. Staff membership gates reads. Only service-role workflows mutate operational state except the authenticated approval wrapper. A private security-definer function checks approver/admin membership, locks the refund and records approval plus audit. No payment SDK is connected.

## Recovery
External identifiers and order-level refund uniqueness constrain duplicates. Provider calls have bounded retries. Failure handling marks tickets error and creates escalation; maintenance detects stale processing. retry_case exists but is not yet wired into a dedicated retry workflow. Outbox remains held; no delivery adapter is operational.
