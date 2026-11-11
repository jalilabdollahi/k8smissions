## Mistakes on this level

- **Editing the rules of `ticket-viewer` again.** The aggregation controller rewrites them from the labelled contributors, so the edit vanishes within seconds. Fix the labels on the contributors.
- **Fixing only one of the two contributors.** The jobs role has a typo in the label value and the events role uses a different key; both have to match exactly before support can do its work.
- **Binding `support` to `cluster-admin` or adding wildcard rules.** The dashboards work, but support could delete jobs and read Secrets. The validator checks everything that must stay forbidden.
- **Removing the `aggregationRule` and writing static rules.** That would hold until someone adds a contributor, and it throws away the design: `ticket-viewer` must stay aggregated.
