# Scripts

Development tooling for the SUMM-Powers skill library.

## lint-skills.sh

Validates all skills against format and quality rules.

```bash
# Check all skills
./scripts/lint-skills.sh

# Check a specific skill
./scripts/lint-skills.sh skills/test-driven-development

# Quiet mode (only errors)
./scripts/lint-skills.sh -q

# Verbose mode (show passing checks)
./scripts/lint-skills.sh -v
```

## skill-template.md

Template for creating new skills. Copy and fill in:

```bash
cp scripts/skill-template.md skills/my-new-skill/SKILL.md
```