#!/bin/bash

# Shared checkout: Claude updates it; Codex follows links to its skill folders.
link_codex_skills() {
	local marketplace_dir="$1" skills_dir="$2"
	local manifest="${marketplace_dir}/.claude-plugin/plugin.json"
	local skill_paths skill_path skill_name source target

	if ! command -v jq >/dev/null 2>&1; then
		echo "Install jq before linking Codex skills." >&2
		return 1
	fi
	if [[ ! -f "${manifest}" ]]; then
		echo "Claude's fsw0422 checkout is missing at ${marketplace_dir}." >&2
		echo "Install Claude Code, then run: bash setup-agent-skills.sh both" >&2
		return 1
	fi
	# This marketplace keeps each skill in a named directory at its root.
	skill_paths=$(jq -er '
		.skills | if type == "array" and length > 0 and
			all(.[]; type == "string" and test("^\\./[a-z0-9]+(-[a-z0-9]+)*$"))
		then .[] else error("Expected a non-empty skills array of ./skill-name paths") end
	' "${manifest}") || return 1

	# Check every source and destination before creating any links.
	while IFS= read -r skill_path; do
		skill_name="${skill_path#./}"
		source="${marketplace_dir}/${skill_name}"
		target="${skills_dir}/${skill_name}"
		if [[ ! -f "${source}/SKILL.md" ]]; then
			echo "Missing skill entrypoint: ${source}/SKILL.md" >&2
			return 1
		fi
		if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
			continue
		fi
		if [[ -e "${target}" || -L "${target}" ]]; then
			echo "Keeping existing entry: ${target}. Move it aside before retrying." >&2
			return 1
		fi
	done <<< "${skill_paths}"

	mkdir -p "${skills_dir}" || return 1
	while IFS= read -r skill_path; do
		skill_name="${skill_path#./}"
		source="${marketplace_dir}/${skill_name}"
		target="${skills_dir}/${skill_name}"
		if [[ ! -L "${target}" ]]; then
			ln -s "${source}" "${target}" || return 1
		fi
		echo "Codex skill: ${skill_name} -> ${source}"
	done <<< "${skill_paths}"
}

install_claude_plugins() {
	if ! command -v claude >/dev/null 2>&1; then
		echo "Install Claude Code first, then rerun this script." >&2
		return 1
	fi
	# --marketplace adds the source on a new machine and refreshes it on reruns.
	claude plugin install skills --marketplace fsw0422/skills --scope user || return 1
	claude plugin update skills@fsw0422 --scope user || return 1
	claude plugin install playwright-chromium-browser@fsw0422 --scope user || return 1
	claude plugin update playwright-chromium-browser@fsw0422 --scope user || return 1
}

main() {
	local mode="${1:-both}"
	local claude_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
	local plugin_dir="${CLAUDE_CODE_PLUGIN_CACHE_DIR:-${claude_dir}/plugins}"
	case "${mode}" in
		claude|codex|both|link-only) ;;
		*) echo "Usage: bash setup-agent-skills.sh [claude|codex|both|link-only]" >&2; return 1 ;;
	esac
	if [[ "${mode}" == "claude" || "${mode}" == "both" ]]; then
		install_claude_plugins || return 1
	fi
	if [[ "${mode}" != "claude" ]]; then
		link_codex_skills "${plugin_dir}/marketplaces/fsw0422" "${HOME}/.agents/skills" || return 1
	fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -euo pipefail
	main "$@"
fi
