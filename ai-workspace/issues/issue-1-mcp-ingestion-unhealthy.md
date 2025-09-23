# Issue: content-automation-mcp-ingestion container repeatedly restarting / healthcheck failing

## Summary
The `content-automation-mcp-ingestion` service in the stack is repeatedly restarting and never reaches a healthy state after recent Dockerfile/compose changes. API and UI services are healthy. The ingestion service shows "Restarting / health: starting" in `docker-compose ps`.

## Observed behavior
- docker-compose ps (stack): ingestion service status = "Up Less than a second (health: starting)" or "Restarting".
- API: healthy (http://localhost:3000/health returned JSON with status "ok")
- UI: healthy (HTTP 200 at http://localhost:3001)
- No stable /health response from ingestion (http://localhost:3002/health)
- Recent operations: stack-level Dockerfile and compose updates were propagated to submodules (UI/API Dockerfiles updated and committed). The ingestion service has not been fixed yet.

## Reproduction
1. From repo root: cd content-automation-platform/content-automation-stack
2. Run: docker-compose up -d
3. Run: docker-compose ps
4. Observe ingestion service status; optionally:
   - docker-compose logs -f content-automation-mcp-ingestion
   - curl -s http://localhost:3002/health

## Files to inspect
- content-automation-platform/content-automation-stack/docker-compose.yml (service config, env)
- content-automation-platform/content-automation-mcp-ingestion/Dockerfile
- content-automation-platform/content-automation-mcp-ingestion/src/index.ts (entrypoint)
- content-automation-platform/content-automation-mcp-ingestion/mcp.json
- Any .env files referenced by docker-compose

## Likely causes
- Missing/incorrect environment variables or secrets in compose or .env
- Entrypoint or required dependency failing at runtime (uncaught exception)
- Healthcheck command failing due to absence of `curl` or other binary in the image
- Permission/volume mount issues preventing startup
- Port mismatch between container and compose mapping

## Suggested debugging steps
- Inspect container logs:
  ```bash
  docker-compose -f content-automation-platform/content-automation-stack/docker-compose.yml logs -f content-automation-mcp-ingestion
  ```
- Reproduce the crash by running an interactive shell in the image to run the entrypoint manually:
  ```bash
  docker-compose run --rm --service-ports content-automation-mcp-ingestion /bin/sh
  ```
- Verify environment variables used by the service are present and correct.
- Check healthcheck command in docker-compose; replace with Node-based check if image lacks curl.
- If required, add missing packages or update Dockerfile to align with the other services (Node 22, minimal runtime, non-root user).
- Once a fix is applied, rebuild and start:
  ```bash
  docker-compose up --no-deps --build -d content-automation-mcp-ingestion
  curl -s http://localhost:3002/health
  ```

## Acceptance criteria
- Ingestion container moves to `Up (healthy)` status.
- `curl http://localhost:3002/health` returns a JSON status object similar to API.
- Logs no longer show crash loops on startup.

## Checklist
- [ ] Collect ingestion container logs and paste relevant error lines in this issue
- [ ] Confirm required env vars and add missing ones to docker-compose or .env
- [ ] Fix Dockerfile or entrypoint as needed
- [ ] Update healthcheck to use an available command
- [ ] Rebuild container and verify healthy state
- [ ] Document fix in ai-workspace/completion-reports and update changelog

## Labels / metadata
- labels: bug, docker, mcp-ingestion
- priority: medium
- assignee: unassigned

## Created
Date: 2025-09-22 21:13:00 EST
Context: Post-implementation of GitHub issue #1 Docker compose stack orchestration
Related: content-automation-platform/content-automation-stack/ai-workspace/completion-reports/docker-container-fixes-completion-report.md
