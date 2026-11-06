# NovaCart Commerce — Autonomous Support Operations

Portfolio implementation for Anupom Mojumder. Fictional UK e-commerce business; synthetic data only. Refunds never move money.

**Status: sandbox in progress; not production-ready.** Eight Groq-powered agents, Supabase with 36 Mistral policy embeddings, n8n workflows and a protected React dashboard are implemented. A synthetic manual request reached refund review, eight recorded agents and QA. Gmail intake, automated Slack notification and authenticated browser journey need full verification.

Start with docs/final-report.md, docs/setup.md and evidence/resource-inventory.json. Source, database migrations, actual exported workflows, prompts, generated datasets and executable SQL tests are included.

Run `npm ci` then `npm run build` or `npm run dev`. Authenticated staff membership is required for data access. Do not put a service-role secret in the browser.

## Directory map
- database: ordered SQL migrations and synthetic seeds
- data: generated source datasets
- agents: eight role configurations and JSON output contracts
- workflows: actual n8n exports plus generation source
- tests: SQL suites and scenario inventory
- evidence: recorded test outcomes and remote resource identifiers
- docs: requirements, policies, architecture, operations and portfolio case study

The project is hosted in this GitHub repository. The Vercel deployment is protected by Vercel Authentication. Read docs/implementation-update.md for current evidence and limitations.
