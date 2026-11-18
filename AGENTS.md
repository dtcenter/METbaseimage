# METbaseimage repository conventions

Guidance for AI coding agents working in this repository, and a useful summary
for human contributors.

## Read the Contributor's Guides first

The [METplus Contributor's
Guide](https://metplus.readthedocs.io/en/latest/Contributors_Guide/index.html) covers the process shared by every METplus component.
Its [GitHub Workflow](https://metplus.readthedocs.io/en/latest/Contributors_Guide/github_workflow.html) chapter applies here in full:
how issues, labels, milestones, and project boards are used, how branches are
named, and how pull requests are opened, reviewed, and merged.

METbaseimage has no Contributor's Guide of its own. `README.md` describes the
repository and keeps its version history.

This file is the short form: the steps that are easy to miss. The guides are
authoritative. Where this file and a guide genuinely conflict, say so in the
pull request rather than silently following one.

## Version history

For each new release, add an entry under "Version History" in `README.md` on
the `develop` branch, listing the changes in that version. This includes bugfix
releases made from a `main_vX.Y` branch, so that `develop` keeps the complete
history. Insert each entry in version order, newest first.

## Pull requests

Fill in `.github/pull_request_template.md`. Change `- [ ]` to `- [x]` on every
item that has been answered or filled in, and leave unanswered items and the
action items under "Pull Request Checklist" unchecked.
