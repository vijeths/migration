#!/bin/bash
if [[ ! -f $1 ]]; then echo "$1 file not found"; exit 99; fi
:"
#read -p 'GitHub Username (not email): ' GH_USERNAME
#read -sp 'GitHub Password: ' GH_PASSWORD
#read -p 'BitBucket Username (not email): ' BB_USERNAME
#read -sp 'BitBucket Password: ' BB_PASSWORD

(cat "$1" ; echo) | tail -n +2 | tr -d '\r' | while IFS=, read -r bb_repo bb_org gh_repo gh_org description archive private
do
  if [ -z "$bb_repo" ]; then continue; fi # skip empty lines
  echo

  echo "###### Processing $bb_repo -> $gh_org/$gh_repo. Cloning from Bitbucket..."
  #next_url="https://api.bitbucket.org/2.0/repositories?role=member"
  #test=$(curl -s --user $BB_USERNAME:$BB_PASSWORD "$next_url")
  #echo "$test"
  git clone --mirror https://${{ secrets.BB_USERNAME }}:${ secrets.BB_PASSWORD }}@bitbucket.org/$bb_org/$bb_repo.git
  cd $bb_repo.git
  echo

  echo "=== $bb_repo cloned, now creating $gh_org/$gh_repo on GitHub with description [$description]..."
  PRIVATE_FLAG="true"
  if [ "$private" = "no" ]; then 
    echo "PUBLIC!"
    PRIVATE_FLAG="false"
  fi
  curl -u ${{ secrets.GH_USERNAME }}:${{ secrets.GH_PASSWORD }} https://api.github.com/orgs/$gh_org/repos -d "{\"name\": \"$gh_repo\", \"private\": $PRIVATE_FLAG, \"description\": \"$description\"}"
  echo

  echo "=== pushing $gh_org/$gh_repo to GitHub..."
  git push --mirror https://${{ secrets.GH_USERNAME }}:${{ secrets.GH_PASSWORD }}@github.com/$gh_org/$gh_repo.git
  echo

  if [ "$archive" = "yes" ]; then
    echo "=== archiving repository $gh_org/$gh_repo on GitHub..."
    curl -X PATCH -u $GH_USERNAME:$GH_PASSWORD https://api.github.com/repos/$gh_org/$gh_repo -d "{\"archived\": true}"
  fi

  cd ..  
done
