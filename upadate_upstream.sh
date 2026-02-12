#!/bin/sh
git add -A
git commit -m "Update"
git checkout upstream
rm -Rf pgBalancer
git clone https://github.com/pgElephant/pgBalancer.git

cd pgBalancer
OrigTAG=$(git describe --tags --abbrev=0)

rm -Rf .git




echo "Enter version " $OrigTAG " : "
read TAG
git tag $TAG 
git add -A
git commit -m "Update upstream"
git push
git push origin $TAG 
cd ../

git checkout main
git merge upstream -m "Merge with upstream $TAG"

gear-store-tags -ac
git add -A
git commit -m "Update Vendor $TAG"
git push
