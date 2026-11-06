# NovaCart Commerce — Autonomous Support Operations

Portfolio implementation for Anupom Mojumder. Fictional UK e-commerce business; synthetic data only. Refunds never move money.

**Status: implemented sandbox foundation; full AI acceptance blocked.** 15 saved n8n workflows, eight configured AI roles, live Supabase schema and seed data, React operations dashboard. OpenAI embedding calls failed with credit_balance_exhausted. No successful live eight-agent journey is claimed.

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

No GitHub repository has been created. Vercel project is paused pending explicit launch approval.
