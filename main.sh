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

[ -z "$INTERVAL_EXEC_HOURS" ] && echo "variable INTERVAL_EXEC_HOURS not set" >&2 && exit 1

REPOSITORIES_FILE="repositories.txt"
CURL="curl -u ${USERNAME}:${API_TOKEN}"

function fetch() {
	REPOSITORY=$($CURL -sS "https://api.github.com/repos/$1")

	# MACOS: SINCE=$(date -v-${INTERVAL_EXEC_HOURS}d "$GITHUB_DATE_FORMAT")
	SINCE=$(date --date="-${INTERVAL_EXEC_HOURS} hour" "$GITHUB_DATE_FORMAT")

	ISSUES_SOLVED=$($CURL -sS "https://api.github.com/repos/$1/issues?state=closed&since=$SINCE")
	ISSUES_OPENED=$($CURL -sS "https://api.github.com/repos/$1/issues?state=open&since=$SINCE")

	read -r -d '' RESULT <<EOF
{
	"repo": $REPOSITORY,
	"issues": {
		"solved": $ISSUES_SOLVED,
		"opened": $ISSUES_OPENED
	}
}
EOF
	echo $RESULT >&2
	echo $RESULT | jq "$TEMPLATE"
}

function run() {
	if [ -z "$1" ] ; then
		while IFS='' read -r repo || [[ -n "$repo" ]]; do
			RESULT=$(fetch "$repo" 2> /dev/null) && \
			[ -z "$POST_URL" ] || curl -sS -H 'Content-Type:application/json' -d "$RESULT" "$POST_URL" &
		done < "$REPOSITORIES_FILE"
	else
		fetch "$1"
	fi
}
