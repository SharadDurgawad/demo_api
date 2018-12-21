#!/bin/bash

#################################################################################
# This script, run from the root of a Maven single or multi-module project, will
# update the pom files to increment the artifact version number on Develop branch.

# (existing --> after script run):
# 1.0.0-SNAPSHOT --> 1.1.0-SNAPSHOT
#################################################################################

# Check if a new release branch is created from develop
TEMP_FILE=`git pull >& temp.txt`
RELEASE_BRANCH_NAME=`cat test.txt | sed -n '2p' | awk '{print $6}' | cut -d/ -f2`
# NEW_RELEASE_BRANCH=`cat temp.txt | sed -n '2p' | awk '{print $2,$3}'`
if [ ! -z "${RELEASE_BRANCH_NAME}" ] ; then
    git checkout develop
else
   exit 0
fi
    

MAVEN_BIN=`which mvn`

MAVEN_VERSIONS_PLUGIN="org.codehaus.mojo:versions-maven-plugin:1.3.1"
MAVEN_VERSIONS_PLUGIN_SET_GOAL="${MAVEN_VERSIONS_PLUGIN}:set -DgenerateBackupPoms=false"
MAVEN_VERSIONS_PLUGIN_UPDATE_PARENT_GOAL="${MAVEN_VERSIONS_PLUGIN}:update-parent -DgenerateBackupPoms=false -DallowSnapshots=true"
MAVEN_VERSIONS_PLUGIN_UPDATE_DEPENDENCIES_GOAL="${MAVEN_VERSIONS_PLUGIN}:use-latest-versions -DgenerateBackupPoms=false -DallowSnapshots=false"

MAVEN_HELP_PLUGIN="org.apache.maven.plugins:maven-help-plugin:2.1.1"
MAVEN_HELP_PLUGIN_EVALUATE_VERSION_GOAL="${MAVEN_HELP_PLUGIN}:evaluate -Dexpression=project.version"

DRY_RUN=false
ALLOW_OUTSIDE_JENKINS=false
SKIP_BRANCH_SWITCH=false

function validateCIServerRun() {
  IS_JENKINS_SERVER=false
  if [ ! -z "${JENKINS_URL}" ] ; then
    echo "This job is being run on Jenkins. JENKINS_URL=${JENKINS_URL}"
    IS_JENKINS_SERVER=true
  fi

  if [ ${IS_JENKINS_SERVER} = false ] ; then
    echo "Detected that we're not on the Jenkins server. Exiting script with error status."
    exit 10
  fi
}

function validatePomExists() {
  CURRENT_DIRECTORY=`pwd`
  if [ -f pom.xml ] ; then
    echo "Found pom.xml file: [${CURRENT_DIRECTORY}/pom.xml]"
  else
    echo "ERROR: No pom.xml file detected in current directory [${CURRENT_DIRECTORY}]. Exiting script with error status."
    exit 50
  fi
}

function validatePom() {
  ${MAVEN_BIN} validate
  STATUS=`echo $?`
  if [ ${STATUS} -ne 0 ] ; then
    echo "ERROR: Maven POM did not validate successfully. Exiting script with error status."
    exit 40
  fi
}

function initCurrentProjectVersion() {
  echo -n "Detecting current project version number..."

  CURRENT_PROJECT_VERSION=`${MAVEN_BIN} ${MAVEN_HELP_PLUGIN_EVALUATE_VERSION_GOAL} | egrep '^[0-9\.]*(-SNAPSHOT)?$'`
  if [ -z ${CURRENT_PROJECT_VERSION} ] ; then
    echo "  ERROR: Couldn't detect current version. Validating pom in case there was a validation issue."
    validatePom
    echo "  ERROR: Couldn't detect current version. Exiting with error status."
    exit 20
  else
    echo "  Version found: [${CURRENT_PROJECT_VERSION}]"
  fi
}

function initNextProjectVersion() {
  local CLEANED=`echo ${CURRENT_PROJECT_VERSION} | sed -e 's/[^0-9][^0-9]*$//'` 
  local CURRENT_MAJOR_NUMBER=`echo ${CLEANED} | cut -d. -f1`
  local CURRENT_MINOR_NUMBER=`echo ${CLEANED} | cut -d. -f2`
  local CURRENT_PATCH_NUMBER=`echo ${CLEANED} | cut -d. -f3`
  local NEXT_MINOR_NUMBER=`expr ${CURRENT_MINOR_NUMBER} + 1`
  local SNAPSHOT_PART=`echo ${CURRENT_PROJECT_VERSION} | cut -d- -f2`

  echo "Sanitized current project version: [${CLEANED}]"
  echo "Current minor number in project version: [${CURRENT_MINOR_NUMBER}]"
  echo "Calculated next minor number: [${NEXT_MINOR_NUMBER}]"

  NEXT_PROJECT_VERSION=`echo $CURRENT_MAJOR_NUMBER.$NEXT_MINOR_NUMBER.${CURRENT_PATCH_NUMBER}-${SNAPSHOT_PART}` 

  echo "Next project version: [${NEXT_PROJECT_VERSION}]"
}

function updateProjectPomsToNextVersion() {
  echo "Updating project version to [${NEXT_PROJECT_VERSION}]..."
  ${MAVEN_BIN} ${MAVEN_VERSIONS_PLUGIN_SET_GOAL} -DnewVersion=${NEXT_PROJECT_VERSION}
}

function updateToLatestParentPom() {
  echo "Updating parent pom to latest version..."
  ${MAVEN_BIN} ${MAVEN_VERSIONS_PLUGIN_UPDATE_PARENT_GOAL}
}

function commitBuildNumberChanges() {
  echo "Preparing updated files for commit..."
  git status

  # add the now updated pom files
  echo "Adding pom files..."
  for POM in `find . -name pom.xml` ; do
    git add ${POM}
    echo "   - ${POM}"
  done

  echo "Committing changes..."
  local BUILD_NUMBER_CHANGES_COMMIT_MESSAGE="Auto commit from CI - incremented build number from [${CURRENT_PROJECT_VERSION}] to [${NEXT_PROJECT_VERSION}]."
  git commit -m "${BUILD_NUMBER_CHANGES_COMMIT_MESSAGE}"

  echo "Pushing changes to origin..."
  git push origin
}

# Make sure that there's a pom that we can do anything with.
validatePomExists

#################################################################################
# Update the project POMs with the new build number.
#################################################################################

initCurrentProjectVersion

initNextProjectVersion

updateProjectPomsToNextVersion

# updateToLatestParentPom

exit 0

#################################################################################
# Commit/Push updated files up to the repository
#################################################################################
if [ ${DRY_RUN} = false ] ; then
  commitBuildNumberChanges
else
  echo "Dry run specified. Skipping commit/push process."
fi

echo "Version updated successfully!"

