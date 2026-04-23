# Knowledge-Work Plugin Reference

Full list of plugins in the Anthropic [`knowledge-work-plugins`](https://github.com/anthropics/knowledge-work-plugins) marketplace, as of this repo's v1.1 release.

All 11 are installed by the bundled install scripts in `scripts/`.

## Included plugins

| Plugin | What it does | Typical user | Connectors |
|---|---|---|---|
| **cowork-plugin-management** | Create, customize, and manage plugins for your org. Install this first — it's the meta-plugin that lets teammates adapt the others. | Admins, power users | — |
| **productivity** | Task, calendar, email, and personal-context management. Reduces time spent repeating yourself across apps. | Everyone | Slack, Notion, Asana, Linear, Jira, Monday, ClickUp, Microsoft 365 |
| **enterprise-search** | Unified search across email, chat, docs, and wikis. One query across all your company's tools. | Everyone | Slack, Notion, Guru, Jira, Asana, Microsoft 365 |
| **sales** | Prospect research, call prep, pipeline review, outreach drafting, battlecards. | AEs, SEs, sales leaders | Slack, HubSpot, Close, Clay, ZoomInfo, Notion, Jira, Fireflies, Microsoft 365 |
| **customer-support** | Ticket triage, response drafting, escalation packaging, knowledge-base authoring. | Support engineers, CSMs | Slack, Intercom, HubSpot, Guru, Jira, Notion, Microsoft 365 |
| **product-management** | Spec writing, roadmap planning, user-research synthesis, stakeholder updates, competitive tracking. | PMs | Slack, Linear, Asana, Monday, ClickUp, Jira, Notion, Figma, Amplitude, Pendo, Intercom, Fireflies |
| **marketing** | Content drafting, campaign planning, brand-voice enforcement, competitor briefing, performance reporting. | Marketers | Slack, Canva, Figma, HubSpot, Amplitude, Notion, Ahrefs, SimilarWeb, Klaviyo |
| **legal** | Contract review, NDA triage, compliance navigation, risk assessment, meeting prep, templated responses. | In-house counsel | Slack, Box, Egnyte, Jira, Microsoft 365 |
| **finance** | Journal entries, reconciliations, financial statements, variance analysis, close management, audit support. | Accounting, FP&A | Snowflake, Databricks, BigQuery, Slack, Microsoft 365 |
| **data** | SQL writing, dataset exploration, statistical analysis, dashboard building, validation. | Analysts, data scientists | Snowflake, Databricks, BigQuery, Definite, Hex, Amplitude, Jira |
| **bio-research** | Preclinical literature search, genomics analysis, target prioritization. | Life-sciences R&D | PubMed, BioRender, bioRxiv, ClinicalTrials.gov, ChEMBL, Synapse, Wiley, Owkin, Open Targets, Benchling |

## How they activate

Once installed, each plugin's **skills** fire automatically when Claude detects a relevant task — no command required. Each plugin's **slash commands** are always available in a Cowork chat; type `/` to browse them. Examples:

- `/productivity:plan-my-day`
- `/sales:call-prep`
- `/data:write-query`
- `/finance:reconciliation`
- `/product-management:write-spec`

## Connector authentication

Installing a plugin does not automatically log you into its connectors. For each tool the plugin uses (Slack, Notion, Jira, etc.), you'll be prompted to authenticate the first time a skill or command touches it. Authentication state is stored per-user, per-device.

## Customizing plugins for your org

These are generic starting points. To make them fit your company:

1. Install `cowork-plugin-management` first.
2. Use its commands to fork a plugin into your org's private marketplace.
3. Edit the plugin's `.mcp.json` (connector list), `skills/*.md` (domain knowledge), and `commands/*.md` (slash commands) to match your stack and terminology.
4. Share the forked marketplace with your team via GitHub or an internal repo.

Full authoring guide: [github.com/anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins).

## Security note

Every plugin in this set is authored by Anthropic and is open source — you can review its contents before installing. Plugins from the broader community directory are a different story; treat unverified plugins with the same caution you'd treat a browser extension.
