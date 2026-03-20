  GNU nano 7.2                                                                                                  ./update.sh                                                                                                  Изменён  
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

git tag -d $(git tag -l "postgres*")
git push origin --delete $(git ls-remote --refs origin postgres* | cut -d$'\t' -f2)

gear-store-tags -ac
git add -A
git commit -m "Update Vendor $TAG"

gear-create-tag -n "postgrespro-1c-18" -s pgver=postgrespro-1c-18
gear-create-tag -n "postgresql17" -s pgver=postgresql17
git add -A
git commit -m "Add specsubst tags"

git push
git push origin --tags

