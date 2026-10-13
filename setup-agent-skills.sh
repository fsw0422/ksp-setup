#!/bin/bash

# Both platforms read the same checkout; adding a platform only adds links.
link_skills() {
	local repo_dir="$1" skills_dir="$2" old_marketplace="$3"
	local manifest="${repo_dir}/.claude-plugin/plugin.json"
	local skill_paths skill_path skill_name source target

	if ! command -v jq >/dev/null 2>&1; then
		echo "Install jq before linking skills." >&2
		return 1
	fi
	if [[ ! -f "${manifest}" ]]; then
		echo "The fsw0422 checkout is missing at ${repo_dir}." >&2
		echo "Run: bash setup-agent-skills.sh codex" >&2
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
		source="${repo_dir}/${skill_name}"
		target="${skills_dir}/${skill_name}"
		if [[ ! -f "${source}/SKILL.md" ]]; then
			echo "Missing skill entrypoint: ${source}/SKILL.md" >&2
			return 1
		fi
		if [[ -L "${target}" ]]; then
			# Migrate only links made by earlier versions of this helper.
			case "$(readlink "${target}")" in
				"${source}"|"${old_marketplace}/${skill_name}"|"${HOME}/.agents/sources/fsw0422/${skill_name}") continue ;;
			esac
		fi
		if [[ -e "${target}" || -L "${target}" ]]; then
			echo "Keeping existing entry: ${target}. Move it aside before retrying." >&2
			return 1
		fi
	done <<< "${skill_paths}"

	mkdir -p "${skills_dir}" || return 1
	while IFS= read -r skill_path; do
		skill_name="${skill_path#./}"
		source="${repo_dir}/${skill_name}"
		target="${skills_dir}/${skill_name}"
		ln -sfn "${source}" "${target}" || return 1
		echo "${target} -> ${source}"
	done <<< "${skill_paths}"
}

configure_browser_mcp() {
	local mode="$1" repo_dir="$2"
	local server_name="playwright-chromium-browser"
	local server_json mcp_command argument installed_plugins plugin
	local mcp_args=()
	# Resolve HOME for both clients and let npx install without an interactive prompt.
	server_json=$(jq -ce --arg home "${HOME}" '
		.mcpServers.browser | .type = "stdio" |
		.args |= map(split("${HOME}") | join($home)) |
		if .command == "npx" then
			.args = (["-y"] + (.args | map(select(. != "-y" and . != "--yes"))))
		else . end
	' "${repo_dir}/playwright-chromium-browser/.mcp.json") || return 1

	if [[ "${mode}" == "claude" || "${mode}" == "both" ]]; then
		if claude mcp get "${server_name}" >/dev/null 2>&1; then
			claude mcp remove --scope user "${server_name}" || return 1
		fi
		claude mcp add-json --scope user "${server_name}" "${server_json}" || return 1
		# Disable earlier marketplace installs to avoid duplicate skills and servers.
		installed_plugins=$(claude plugin list --json) || return 1
		for plugin in skills@fsw0422 playwright-chromium-browser@fsw0422; do
			if jq -e --arg id "${plugin}" 'any(.[]; .id == $id and .scope == "user" and .enabled)' <<< "${installed_plugins}" >/dev/null; then
				claude plugin disable "${plugin}" --scope user || return 1
			fi
		done
	fi
	if [[ "${mode}" == "codex" || "${mode}" == "both" ]]; then
		mcp_command=$(jq -er '.command' <<< "${server_json}") || return 1
		while IFS= read -r argument; do
			mcp_args+=("${argument}")
		done < <(jq -r '.args[]' <<< "${server_json}")
		codex mcp add "${server_name}" -- "${mcp_command}" "${mcp_args[@]}" || return 1
	fi
}

main() {
	local mode="${1:-both}"
	local claude_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
	local plugin_dir="${CLAUDE_CODE_PLUGIN_CACHE_DIR:-${claude_dir}/plugins}"
	local source_dir="${HOME}/skills"
	case "${mode}" in
		claude|codex|both|link-only) ;;
		*) echo "Usage: bash setup-agent-skills.sh [claude|codex|both|link-only]" >&2; return 1 ;;
	esac
	if [[ "${mode}" != "link-only" ]]; then
		if [[ -d "${source_dir}/.git" ]]; then
			if [[ "$(git -C "${source_dir}" branch --show-current)" != "main" ]]; then
				echo "${source_dir} is not on main; keeping its branch unchanged." >&2
				return 1
			fi
			git -C "${source_dir}" pull --ff-only || return 1
		else
			git clone --branch main https://github.com/fsw0422/skills.git "${source_dir}" || return 1
		fi
	fi
	if [[ "${mode}" != "codex" ]]; then
		link_skills "${source_dir}" "${claude_dir}/skills" "${plugin_dir}/marketplaces/fsw0422" || return 1
	fi
	if [[ "${mode}" != "claude" ]]; then
		link_skills "${source_dir}" "${HOME}/.agents/skills" "${plugin_dir}/marketplaces/fsw0422" || return 1
	fi
	if [[ "${mode}" != "link-only" ]]; then
		configure_browser_mcp "${mode}" "${source_dir}" || return 1
	fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -euo pipefail
	main "$@"
fi
