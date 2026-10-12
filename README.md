# KSP Setup

Run `bash install.sh` from a clone of this repository. The installer asks which
AI tools to configure: `claude`, `codex`, `both`, or `none`.

## Personal agent skills

Choose `both` on a new machine after installing Claude Code and Codex. The
installer links the settings from [fsw0422/.ksp](https://github.com/fsw0422/.ksp),
installs the Claude plugins from [fsw0422/skills](https://github.com/fsw0422/skills),
then reads that plugin's manifest and links each skill into `~/.agents/skills/`.
Codex reads the links directly; no Codex plugin install or version bump is needed.

Claude's `fsw0422` marketplace has `autoUpdate: true` in the shared `.ksp` settings.
It refreshes its checkout in the background after the first message in an
interactive Claude session, with a delay of up to ten minutes. Codex alone
doesn't fetch updates. Run `/reload-plugins` in Claude or start a new session to
apply updates; start a new Codex chat to discover newly linked skills.

To install or refresh just this part of setup:

```sh
bash setup-agent-skills.sh both
```

To recreate links from an existing checkout, without running Claude or fetching:

```sh
bash setup-agent-skills.sh link-only
```

Rerun the helper when the manifest gains a new skill. Changes to existing skill
files are visible through the existing links after Claude refreshes the checkout.
The helper preserves existing matching links and stops before replacing any
unrelated file, directory, or symlink. It does not remove links for deleted skills.

The `claude` mode only installs/updates the Claude plugins. The `codex` mode only
links an existing Claude marketplace checkout; if it is missing, install Claude
Code and run the helper in `both` mode first. The helper requires `jq` (included
by `install.sh`); installation requires Claude Code 2.1.292 or newer for the
`--marketplace` option. `link-only` needs no Claude executable. It honors
`CLAUDE_CONFIG_DIR` and `CLAUDE_CODE_PLUGIN_CACHE_DIR` when locating the checkout.

The `restore-session` skill manages Claude Code sessions, even when invoked from
Codex. For terminal browser automation, follow the Playwright browser installation
instructions in the skills repository.

## Test

Use the development container to test changes to the installation scripts:

```sh
python3 -m unittest discover -s tests -v
```

The tests use temporary marketplace folders and mock plugin commands. They do
not run the full machine installer, install plugins, or alter your home directory.
