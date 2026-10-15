#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tag-release
#
# Tags an Opencast release. Run it on a release branch (e.g. release/5.7).
#
#   1. Sets the Maven version to <release-version> and commits it
#   2. Creates the git tag <release-version>; the tag build (.github/workflows/build.yml)
#      deploys the release to repo.orbitalhq.com
#   3. Sets the Maven version to the next -SNAPSHOT and commits it, so later
#      branch builds publish snapshots again
#
# Usage:
#   ./tag-release.sh [-f] [-p] <release-version>
#
# Arguments:
#   <release-version>   e.g. 5.7.0-opencast-1. Must be <major>.<minor>.<patch>-opencast-<n>:
#                       Hazelcast parses its own version at runtime, so other formats break.
#
# Options:
#   -f    Force: allow moving an existing tag to the new commit
#   -p    Push:  push the commits and tag to origin
#
# Examples:
#   ./tag-release.sh 5.7.0-opencast-1
#       Release 5.7.0-opencast-1 locally, then move the branch to 5.7.0-opencast-2-SNAPSHOT
#
#   ./tag-release.sh -p 5.7.0-opencast-1
#       Same as above, and push the branch and tag
###############################################################################

usage() {
  echo "Usage: $0 [-f] [-p] <release-version>"
  echo "  -f   force: allow existing tag to be moved"
  echo "  -p   push:  push commits and tag to origin"
  exit 1
}

FORCE=false
PUSH=false

while getopts ":fp" opt; do
  case "$opt" in
    f) FORCE=true ;;
    p) PUSH=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

[ $# -eq 1 ] || usage
VERSION="$1"

if [[ ! "$VERSION" =~ ^([0-9]+\.[0-9]+\.[0-9]+-opencast-)([0-9]+)$ ]]; then
  echo "❌ Version '${VERSION}' must look like 5.7.0-opencast-1 (no 'v' prefix, no -SNAPSHOT)."
  exit 1
fi
NEXT_VERSION="${BASH_REMATCH[1]}$((BASH_REMATCH[2] + 1))-SNAPSHOT"

# Ensure working tree is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ Working tree has uncommitted changes. Commit or stash first."
  exit 1
fi

# Check if tag exists
if git rev-parse -q --verify "refs/tags/${VERSION}" >/dev/null 2>&1; then
  if [ "$FORCE" = false ]; then
    echo "❌ Tag '${VERSION}' already exists. Use -f to move it."
    exit 1
  else
    echo "⚠️  Tag '${VERSION}' exists and will be moved (force)."
  fi
fi

set_version() {
  ./mvnw -q -B versions:set -DnewVersion="$1" -DgenerateBackupPoms=false -DprocessAllModules=true
}

echo "🔧 Setting Maven version to ${VERSION}"
set_version "${VERSION}"

echo "🔍 Checking for SNAPSHOT versions..."
if git grep -n -- '-SNAPSHOT</version>' -- '*pom.xml'; then
  echo "❌ SNAPSHOT versions remain (listed above). Fix them before releasing."
  git checkout -- .
  exit 1
fi

git add -A
if ! git diff --cached --quiet; then
  echo "📝 Committing version bump"
  git commit -m "chore(release): ${VERSION}"
else
  echo "ℹ️ No changes to commit (version already ${VERSION})."
fi

if [ "$FORCE" = true ]; then
  git tag -fa "${VERSION}" -m "Release ${VERSION}"
else
  git tag -a  "${VERSION}" -m "Release ${VERSION}"
fi

echo "🔧 Setting Maven version to ${NEXT_VERSION}"
set_version "${NEXT_VERSION}"
git add -A
git commit -m "chore(release): prepare ${NEXT_VERSION}"

if [ "$PUSH" = true ]; then
  echo "🚀 Pushing to origin"
  # Push the tag first: the branch head is now a SNAPSHOT, so only the tag run deploys the release
  if [ "$FORCE" = true ]; then
    git push --force-with-lease origin "refs/tags/${VERSION}"
  else
    git push origin "refs/tags/${VERSION}"
  fi
  git push origin HEAD
fi

echo "✅ Done. Tagged '${VERSION}'; branch is now at ${NEXT_VERSION}."
