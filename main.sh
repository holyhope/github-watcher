#!/bin/bash

read -r -d '' TEMPLATE <<EOF
{
	name:         .repo.full_name,
	watchers:     .repo.watchers_count,
	forks:        .repo.forks_count,
	subscribers:  .repo.subscribers_count,
	lastPush:     .repo.pushed_at,
	IssuesSolved: .issues.solved | length,
	issuesOpened: .issues.opened | length
}
EOF
GITHUB_DATE_FORMAT='+%Y-%m-%dT%H:%M:%S'
REPOSITORIES_FILE="repositories.txt"

function github() {
	curl -sS -u ${USERNAME}:${API_TOKEN} "$@"
}

function init_function() {
	if [ -z "$INTERVAL_EXEC_HOURS" ] ; then
		echo "variable INTERVAL_EXEC_HOURS not set" >&2
		exit 1
	fi
}

function get_since() {
	if [ "${OSTYPE:0:6}" == "darwin" ] ; then
		date -v"-${1}H" "$GITHUB_DATE_FORMAT"
	else
		date --date="-$1 hour" "$GITHUB_DATE_FORMAT"
	fi
}

function github_fetch() {
	REPOSITORY=$(github "https://api.github.com/repos/$1")

	SINCE=$(get_since ${INTERVAL_EXEC_HOURS})

	ISSUES_SOLVED=$(github "https://api.github.com/repos/$1/issues?state=closed&since=$SINCE")
	ISSUES_OPENED=$(github "https://api.github.com/repos/$1/issues?state=open&since=$SINCE")

	read -r -d '' RESULT <<EOF
{
	"repo": $REPOSITORY,
	"issues": {
		"solved": $ISSUES_SOLVED,
		"opened": $ISSUES_OPENED
	}
}
EOF
	echo $RESULT | jq "$TEMPLATE"
}

function push_result() {
	if [ -n "$POST_URL" ] ; then
		return curl --fail -sS -H 'Content-Type:application/json' -d "$1" "$POST_URL"
	fi
}

function fetch_and_store() {
	RESULT="$(github_fetch "$1")"
	echo $RESULT >&2
	push_result "$RESULT" >&2
}

function run() {
	init_function

	if [ -n "$1" ] ; then
		fetch_and_store "$repo"
	else
		repositories=$(cat "$REPOSITORIES_FILE")
		for repo in $repositories ; do
			fetch_and_store "$repo"
		done
	fi
}
