# CI/CD Action Playbooks

Use this index to select the correct playbook.

- Analyze Repository: `prompts/analyze-repository.prompt.md`
- Create Pipeline: `prompts/create-pipeline.prompt.md`
- Validate Pipeline: `prompts/validate-pipeline.prompt.md`
- Trigger Build: `prompts/trigger-build.prompt.md`
- Configure Signing: `prompts/configure-signing.prompt.md`
- Firebase Distribute: `prompts/firebase-distribute.prompt.md`
- Open Pull Request: `prompts/open-pr.prompt.md`
- View Build Status: `prompts/view-build-status.prompt.md`
- Fix Pipeline Issues: `prompts/fix-pipeline-issues.prompt.md`

All action playbooks must run `scripts/preflight_validate.sh` first, then return output in this format:

1. Status
2. Findings
3. Missing Prerequisites
4. Recommended Actions
5. Next Action
