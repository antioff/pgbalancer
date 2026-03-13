#!/bin/sh
PG_PRO=$(grep 'global PG_PRO' pgbalanser.spec | cut  -d" " -f3)
PG_VER=$(grep 'global PG_VER' pgbalancer.spec | cut  -d" " -f3)
if [ "$PG_PRO" == "1" ]; then
sudo ./pgpro_repo.sh $PG_VER
fi

. /etc/os-release
verid=${VERSION_ID#p}
ALT_ID=${verid%%.*}
if  [ "$ALT_ID" == "10" ]; then
sed -i 's/-D_FORTIFY_SOURCE=3/-D_FORTIFY_SOURCE=2/g'   pgBalancer/bctl/Makefile.am
elif  [ "$ALT_ID" == "11" ]; then
sed -i 's/-D_FORTIFY_SOURCE=2/-D_FORTIFY_SOURCE=3/g'   pgBalancer/bctl/Makefile.am
fi

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
