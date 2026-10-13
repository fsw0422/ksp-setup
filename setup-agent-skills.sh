#!/bin/bash

# Both platforms read the same checkout; adding a platform only adds links.
platform_installed() {
	case "$1" in
		claude)
			command -v claude >/dev/null 2>&1 ||
				[[ -d "/Applications/Claude.app" || -d "${HOME}/Applications/Claude.app" ||
					-d "/Applications/Claude Code.app" || -d "${HOME}/Applications/Claude Code.app" ]]
			;;
		codex)
			command -v codex >/dev/null 2>&1 ||
				[[ -d "/Applications/Codex.app" || -d "${HOME}/Applications/Codex.app" ||
					-d "/Applications/ChatGPT.app" || -d "${HOME}/Applications/ChatGPT.app" ]]
			;;
		*) return 1 ;;
	esac
}

select_installed_mode() {
	local requested="$1"
	local want_claude=false want_codex=false
	local use_claude=false use_codex=false

	case "${requested}" in
		auto|both) want_claude=true; want_codex=true ;;
		claude) want_claude=true ;;
		codex) want_codex=true ;;
		*) return 1 ;;
	esac
	if [[ "${want_claude}" == "true" ]]; then
		if platform_installed claude; then
			use_claude=true
		else
			echo "Claude is not installed; skipping Claude skill links." >&2
		fi
	fi
	if [[ "${want_codex}" == "true" ]]; then
		if platform_installed codex; then
			use_codex=true
		else
			echo "Codex is not installed; skipping Codex skill links." >&2
		fi
	fi
	if [[ "${use_claude}" == "true" && "${use_codex}" == "true" ]]; then
		echo both
	elif [[ "${use_claude}" == "true" ]]; then
		echo claude
	elif [[ "${use_codex}" == "true" ]]; then
		echo codex
	else
		echo "No requested AI platform is installed." >&2
		return 1
	fi
}

link_skills() {
	local repo_dir="$1" skills_dir="$2" old_marketplace="$3"
	local skill_entry skill_name source target link_target
	local skill_names=()

	if [[ ! -d "${repo_dir}" ]]; then
		echo "Skill source directory is missing: ${repo_dir}" >&2
		return 1
	fi
	for skill_entry in "${repo_dir}"/*/SKILL.md; do
		[[ -f "${skill_entry}" ]] || continue
		source="${skill_entry%/SKILL.md}"
		skill_name="${source##*/}"
		if [[ ! "${skill_name}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
			echo "Invalid skill directory name: ${skill_name}" >&2
			return 1
		fi
		skill_names+=("${skill_name}")
	done
	if [[ ${#skill_names[@]} -eq 0 ]]; then
		echo "No top-level skill directories found in ${repo_dir}." >&2
		return 1
	fi

	# Check every source and destination before creating or removing any links.
	for skill_name in "${skill_names[@]}"; do
		source="${repo_dir}/${skill_name}"
		target="${skills_dir}/${skill_name}"
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
	done

	mkdir -p "${skills_dir}" || return 1
	# Remove only stale links that this checkout owns. Preserve all unrelated entries.
	for target in "${skills_dir}"/*; do
		[[ -L "${target}" ]] || continue
		link_target=$(readlink "${target}")
		case "${link_target}" in
			"${repo_dir}/"*)
				skill_name="${target##*/}"
				if [[ ! -f "${repo_dir}/${skill_name}/SKILL.md" ]]; then
					unlink "${target}" || return 1
					echo "Removed stale skill link: ${target}"
				fi
				;;
		esac
	done
	for skill_name in "${skill_names[@]}"; do
		source="${repo_dir}/${skill_name}"
		target="${skills_dir}/${skill_name}"
		ln -sfn "${source}" "${target}" || return 1
		echo "${target} -> ${source}"
	done
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
		if command -v claude >/dev/null 2>&1; then
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
		else
			echo "Claude desktop app found without the Claude CLI; skipping Claude MCP registration." >&2
		fi
	fi
	if [[ "${mode}" == "codex" || "${mode}" == "both" ]]; then
		if command -v codex >/dev/null 2>&1; then
			mcp_command=$(jq -er '.command' <<< "${server_json}") || return 1
			while IFS= read -r argument; do
				mcp_args+=("${argument}")
			done < <(jq -r '.args[]' <<< "${server_json}")
			codex mcp add "${server_name}" -- "${mcp_command}" "${mcp_args[@]}" || return 1
		else
			echo "Codex desktop app found without the Codex CLI; skipping Codex MCP registration." >&2
		fi
	fi
}

main() {
	local requested_mode="${1:-auto}" mode
	local link_only=false
	local claude_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
	local plugin_dir="${CLAUDE_CODE_PLUGIN_CACHE_DIR:-${claude_dir}/plugins}"
	local source_dir="${HOME}/skills"
	local project_skill_source="${HOME}/projects/shared-skills"
	local project_codex_skills="${HOME}/projects/.agents/skills"
	local project_claude_skills="${HOME}/projects/.claude/skills"
	case "${requested_mode}" in
		auto|claude|codex|both) ;;
		link-only) link_only=true; requested_mode=auto ;;
		*) echo "Usage: bash setup-agent-skills.sh [auto|claude|codex|both|link-only]" >&2; return 1 ;;
	esac
	mode=$(select_installed_mode "${requested_mode}") || return 1
	if [[ "${link_only}" != "true" ]]; then
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
	# Keep provider-neutral project skills in one source and link installed clients to it.
	if [[ -d "${project_skill_source}" ]]; then
		if [[ "${mode}" != "codex" ]]; then
			link_skills "${project_skill_source}" "${project_claude_skills}" "${HOME}/projects/.agents/skills" || return 1
		fi
		if [[ "${mode}" != "claude" ]]; then
			link_skills "${project_skill_source}" "${project_codex_skills}" "${HOME}/projects/.codex/skills" || return 1
		fi
	fi
	if [[ "${link_only}" != "true" ]]; then
		configure_browser_mcp "${mode}" "${source_dir}" || return 1
	fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -euo pipefail
	main "$@"
fi
