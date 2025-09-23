# Documentation

This directory contains additional documentation for the Content Automation Stack project.

## Available Documentation

### [Docker Compose V2 Upgrade Guide](docker-compose-v2-upgrade.md)
Comprehensive guide for upgrading from Docker Compose V1 (legacy `docker-compose`) to Docker Compose V2 (modern `docker compose`).

**Contents:**
- Why upgrade to V2
- Installation methods (Docker Desktop vs manual)
- Key differences between V1 and V2
- Step-by-step migration process
- Troubleshooting common issues
- Rollback procedures if needed

**When to use:** If you see warnings about legacy docker-compose during setup, or if you want to upgrade to the latest Docker Compose version for better security and performance.

## Quick Reference

### Check Your Docker Compose Version
```bash
# Check for V2 (modern)
docker compose version

# Check for V1 (legacy)
docker-compose version
```

### Upgrade to V2 (Recommended)
1. **Easiest**: Update Docker Desktop
2. **Linux manual**: Follow the [upgrade guide](docker-compose-v2-upgrade.md)
3. **Verify**: Run `docker compose version`

### Project-Specific Notes

This project's scripts automatically detect and work with both V1 and V2, but V2 is strongly recommended for:
- Security (V1 stopped receiving updates in July 2023)
- Performance improvements
- Better Docker CLI integration
- Continued feature development

## Related Documentation

- [Main README](../README.md) - Project overview and usage instructions
- [CHANGELOG](../CHANGELOG.md) - Project change history
- [Docker Compose Official Docs](https://docs.docker.com/compose/) - Official Docker documentation
