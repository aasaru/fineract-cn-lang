#!/usr/bin/env bash

set -e
BUILD_SNAPSHOTS_BRANCH=travis
EXIT_STATUS=0

# Builds and Publishes a SNAPSHOT
function build_snapshot() {
  echo -e "Building and publishing a snapshot out of branch [$TRAVIS_BRANCH]"
  ./gradlew -DbuildInfo.build.number=${TRAVIS_COMMIT::7} clean artifactoryPublish --stacktrace || EXIT_STATUS=$?
}

# Builds a Pull Request
function build_pullrequest() {
  echo -e "Building pull request #$TRAVIS_PULL_REQUEST of branch [$TRAVIS_BRANCH]. Won't publish anything to Artifactory."
  ./gradlew clean build || EXIT_STATUS=$?
}

# Builds other branches that we don't create snapshots and tags out from
function build_otherbranch() {
  echo -e "Building non-snapshots branch [$TRAVIS_BRANCH]. Won't publish anything to Artifactory."
  ./gradlew clean build || EXIT_STATUS=$?
}

# Builds and Publishes a Tag
function build_tag() {
  echo -e "Building tag [$TRAVIS_TAG] and publishing it as a release"
  ./gradlew -PversionFromGitTag=$TRAVIS_TAG clean artifactoryPublish --stacktrace || EXIT_STATUS=$?

}

echo -e "TRAVIS_BRANCH=$TRAVIS_BRANCH"
echo -e "TRAVIS_TAG=$TRAVIS_TAG"
echo -e "TRAVIS_COMMIT=${TRAVIS_COMMIT::7}"
echo -e "TRAVIS_PULL_REQUEST=$TRAVIS_PULL_REQUEST"

# TODO - switch branch to develop!

# Build Logic
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  build_pullrequest
elif [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" != "$BUILD_SNAPSHOTS_BRANCH" ] && [ "$TRAVIS_TAG" == "" ]  ; then
  build_otherbranch
elif [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "$BUILD_SNAPSHOTS_BRANCH" ] && [ "$TRAVIS_TAG" == "" ] ; then
  build_snapshot
elif [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_TAG" != "" ]; then
  build_tag
else
  echo -e "WARN: Unexpected env variable values => Branch [$TRAVIS_BRANCH], Tag [$TRAVIS_TAG], Pull Request [#$TRAVIS_PULL_REQUEST]"
  ./gradlew clean build
fi

exit ${EXIT_STATUS}

