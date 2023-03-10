#!/bin/bash

####### Project name 
PROJECT_NAME="myproject"
EMAIL="abc@gmail.com"

###########################
####### SVN 
# SVN repository to be migrated
BASE_SVN="SVN-Repo_URL"

# Organization inside BASE_SVN
BRANCHES="branches"
TAGS="tags"
TRUNK="trunk"

###########################
####### Azure 
# Azure repository to migrate
AZURE_URL="Azure-Repo-URL"

###########################
#### Don't need to change from here
###########################

# Geral Configuration
ABSOLUTE_PATH=$(pwd)
TMP=$ABSOLUTE_PATH/"migration-"$PROJECT_NAME

# Branchs Configuration
SVN_BRANCHES=$BASE_SVN/$BRANCHES
SVN_TAGS=$BASE_SVN/$TAGS
SVN_TRUNK=$BASE_SVN/$TRUNK

AUTHORS=$PROJECT_NAME"-authors.txt"

echo '[LOG] Starting migration of '$SVN_TRUNK
echo '[LOG] Using: '$(git --version)
echo '[LOG] Using: '$(svn --version | grep svn,)

mkdir $TMP
cd $TMP

echo
echo '[LOG] Getting authors'
svn log -q $BASE_SVN | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2"@"$EMAIL">"}' | sort -u >> $AUTHORS

echo
echo '[RUN] git svn clone --authors-file='$AUTHORS' --trunk='$TRUNK' --branches='$BRANCHES' --tags='$TAGS $BASE_SVN $TMP
git svn clone --authors-file=$AUTHORS --trunk=$TRUNK --branches=$BRANCHES --tags=$TAGS $BASE_SVN $TMP

echo
echo '[LOG] Getting first revision'
FIRST_REVISION=$( svn log -r 1:HEAD --limit 1 $BASE_SVN | awk -F '|' '/^r/ {sub("^ ", "", $1); sub(" $", "", $1); print $1}' )

echo
echo '[RUN] git svn fetch -'$FIRST_REVISION':HEAD'
git svn fetch -$FIRST_REVISION:HEAD

echo
echo '[RUN] git remote add origin '$AZURE_URL
git remote add origin $AZURE_URL

echo
echo '[RUN] svn ls '$SVN_BRANCHES
for BRANCH in $(svn ls $SVN_BRANCHES); do
    echo git branch ${BRANCH%/} remotes/origin/${BRANCH%/}
    git branch ${BRANCH%/} remotes/origin/${BRANCH%/}
done

git for-each-ref --format="%(refname:short) %(objectname)" refs/remotes/origin/tags | grep -v "@" | cut -d / -f 3- |
while read ref
do
  echo git tag -a $ref -m 'import tag from svn'
  git tag -a $ref -m 'import tag from svn'
done

git for-each-ref --format="%(refname:short)" refs/remotes/origin/tags | cut -d / -f 1- |
while read ref
do
  git branch -rd $ref
done

echo
echo '[RUN] git push'
git push origin --all --force
git push origin --tags

echo 'Sucessufull.'
