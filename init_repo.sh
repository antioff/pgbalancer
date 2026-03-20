#!/bin/sh
git init
git branch -M main
git clone https://github.com/pgElephant/pgBalancer.git
rm -Rf pgBalancer/.git
git add -A
git commit -m "clone upstream"
git remote add origin git@github.com:antioff/pgbalancer.git
git push -u origin main
git branch upstream
git merge -s ours upstream
git checkout upstream
git push --set-upstream origin upstream
git checkout main

ln -s pgBalancer/README.md ./
mkdir .gear
###########
cat > ".gear/rules" << \EOF
#pgver postgresql17 postgresql18 postgrespro-1c-18 etc
specsubst: pgver
tar: v@version@:pgBalancer name=pgbalancer-@version@
diff: v@version@:pgBalancer pgBalancer name=pgbalancer-@version@-@release@.patch
EOF
##########
cat > "pgbalancer.spec" << \EOF
%define PG_VER @pgver@
%define PG_NUM %(echo %PG_VER | tail -c 3)
%define PG_PREFIX %([[ %PG_VER =~ "pro" ]] && echo "/opt/pgpro/1c-%PG_NUM" || echo "%_usr")
%define PG_LIB %([[ %PG_VER =~ "pro" ]] && echo "%PG_PREFIX/lib" || echo "%_libdir/pgsql")
%define PG_DATADIR %([[ %PG_VER =~ "pro" ]] && echo "%PG_PREFIX/share" || echo "%_datadir/pgsql")
%define sname pgbalancer

Name:           %PG_VER-%sname
Summary:        Modern PostgreSQL %{PG_VER} connection pooler with REST API and YAML configuration
Version:        1.0.0
Release:        alt1
Packager:	antioff <nobody@altlinux.org>
License:        MIT
URL:            https://github.com/pgelephant/pgbalancer
Group:          Databases

Source0: %sname-%version.tar
Patch0: %sname-%version-%release.patch

BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  openssl-devel
BuildRequires:  pam-devel
BuildRequires:  openldap-devel
BuildRequires:  libcurl-devel
BuildRequires:  libjson-c-devel
BuildRequires:  libpaho-mqtt1
BuildRequires:  libpaho-mqtt-devel
BuildRequires:  libpq-devel
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  libyaml-devel
BuildRequires:  flex
BuildRequires:  %([[ %PG_VER =~ "pro" ]] && echo "%PG_VER-devel" || echo "%PG_VER-server-devel")


Requires:       libyaml2
Requires:       openssl
Requires:       libpq5
Requires:       %PG_VER-server


%description
pgbalancer is a modern, production-ready PostgreSQL connection pooler and load
balancer built as a fork of pgpool-II. It provides a comprehensive REST API,
professional CLI tool (bctl), a
Features:
- Modern REST API with 17 endpoints for complete cluster control
- Unified CLI tool (bctl) replacing fragmented pcp_* commands
- YAML configuration with validation
- Optional pgraft consensus integration for leader election
- AI-based load balancing algorithms
- JWT authentication for API security
- Connection pooling and load balancing
- Automatic failover and recovery
- Health monitoring and performance statistics
- Compatible with PostgreSQL 13, 14, 15, 16, 17, 18


%prep

%setup -q -n %sname-%version
%autopatch -p1

%build

export PG_INCLUDE=$($PG_CONFIG --includedir)
export PG_LIB=$($PG_CONFIG --libdir)

%autoreconf

./configure \
    --disable-rpath \
    --with-openssl \
    --with-pam \
    --with-ldap

make PG_CONFIG=%PG_PREFIX/bin/pg_config

[[ $(cat /etc/os-release | grep VERSION_ID | cut -d"=" -f2| cut -d. -f1) == "10" ]] && sed -i 's/-D_FORTIFY_SOURCE=3/-D_FORTIFY_SOURCE=2/g' bctl/Makefile.am || sed -i 's/-D_FORTIFY_SOURCE=2/-D_FORTIFY_SOURCE=3/g' bctl/Makefile.am
make PG_CONFIG=%PG_PREFIX/bin/pg_config -C bctl

%install
make prefix=%buildroot%_usr install
mkdir -p %buildroot{%_sysconfdir/%sname,%_logdir/%sname,%_runtimedir/%sname,%_libdir/%sname}
find "src" -name "*.a" -exec cp -v {} "%buildroot%_libdir/%sname/" \;
cp -Rf %buildroot/usr/etc/* %buildroot%_sysconfdir/%sname/
install -m 644 src/sample/pgbalancer.conf.sample %{buildroot}/etc/pgbalancer/pgbalancer.conf.sample

%files
%doc README.md
%dir %_sysconfdir/%sname
%dir %_logdir/%sname
%dir %_runtimedir/%sname
%dir %_libdir/%sname
%_bindir/*
%_sysconfdir/%sname/*
%_datadir/%sname/*
%_libdir/%sname/*

%post
# Create pgbalancer user if doesn't exist
if ! id -u pgbalancer >/dev/null 2>&1; then
    useradd -r -d /var/lib/pgbalancer -s /bin/bash pgbalancer
fi
# Set permissions
chown -R pgbalancer:pgbalancer /var/log/pgbalancer /var/run/pgbalancer

%changelog
* Wed Feb 04 2026 antioff <nobody@altlinux.org> 1.0.0-alt1
- Initial gear
* Thu Oct 24 2024 pgElephant Team <team@pgelephant.org> - 1.0.0-1
- Initial release
- Raft consensus implementation
- Automatic leader election
- Fast failover (2s timeout)
- Integration with pgbalancer

EOF
#########

cat > "pgpro_repo.sh" << \EOF
#!/bin/sh
PG_VER=18

LISTNAME="pgpro_${PG_VER}"
if [ ! -f /etc/apt/sources.list.d/$LISTNAME.list ]; then

. /etc/os-release
verid=${VERSION_ID#p}
ALT_ID=${verid%%.*}
ARCH=$(rpm -q --qf="%{arch}" rpm)

REPO="https://repo.postgrespro.ru/1c/1c-$PG_VER/altlinux/$ALT_ID"
LISTNAME="pgpro_${PG_VER}"

if [ ! -d /etc/pki/$LISTNAME ]; then
     mkdir -p /etc/pki/$LISTNAME
fi

keyfile=/etc/pki/$LISTNAME/RPM-GPG-KEY-POSTGRESPRO

cat > "$keyfile" << KEY-PGPRO
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFWdEjABCAC6QeLt0UJUQlDI2Z+R/y1OyOMU+5Te176I0+/Xpc2v5NsucW2M
kLTdOif0iW+q5h1djL+Pc5yu1fojZCvcihhbURnWECF52BmRnOC9jI0eTHq3fcPZ
IE3gqMJSn5sx2kJZ7n8XE0RbQ/hr51BLI+lzeqR3JAKBIqpVDKRrdP9Y1xVR/7Ne
q4FNR+osm6W4sM9G+TA/YADrWX3/TPXA4AN+2uNCNY0wK7em8V0oSZJVpEzvu5EP
djC6GX08XSvhPNo52o3u3tpFWH7ICw2BEYe672bJTjmi8wFgPW04pw49Jpvw4i1R
RhkpQqQ/b9bSveoNpvN32ElAJSaize76+q/TABEBAAG0KlJvYm90IChTaWduaW5n
IHJlcG9zKSA8ZGJhQHBvc3RncmVzcHJvLnJ1PokBOAQTAQIAIgUCVZ0SMAIbAwYL
CQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQf5rlpi0t8LQpKQgAuJkOKNdnCSCt
GbNTwAbk414UPYa2B1M1DD6MfcSd6NnJNBVtRoaSWWISQB6gP+/w1jmD8XZbj/oH
5HAHjOyh9Lb3z1xeMIQnBnfGtcqmU5QrF55Yi0H9G0s+fn9oodfNXqAa/zARpBw6
q3LRSBCjT50/XA5G3AzUr7fIDb68FmEOCQukzs0uWBr5fkrRC21b1DcuhzbBay8X
pnlpB+Ma1PTIFgRdRl/KwYTzO80TWFMCeYfXQRh8StuQxRcVCqnv4F6seHqmbL7A
vOZ7GMymsz/IRHGVk4eVC6/94Y3vkV/0eQ+Yom+NtAFnep6G4OhxIeviZ697eFYF
+j4YsyDD+g==
=Q7MS
-----END PGP PUBLIC KEY BLOCK-----
KEY-PGPRO

apt-get install -y apt-https 
echo "rpm $REPO $ARCH pgpro" > "/etc/apt/sources.list.d/$LISTNAME.list"
echo "rpm $REPO noarch pgpro" >> "/etc/apt/sources.list.d/$LISTNAME.list"
chmod 0644 "/etc/apt/sources.list.d/$LISTNAME.list"
apt-get update 
fi

EOF
############
chmod +x pgpro_repo.sh
############
cat > "update.sh" << \EOF
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

EOF
############
chmod +x update.sh

git add -A
git commit -m "Init gear"

patch -p1 << EOF
--- a/pgBalancer/bctl/bctl.c
+++ b/pgBalancer/bctl/bctl.c
@@ -1755,7 +1755,7 @@ rest_get(const char *url, RestResponse *response)
     }

     curl_easy_setopt(curl_handle, CURLOPT_URL, url);
-    curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, write_callback);
+    curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION,(void *)write_callback);
     curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, response);
     curl_easy_setopt(curl_handle, CURLOPT_TIMEOUT, 30L);

@@ -1820,4 +1820,4 @@ rest_post(const char *url, const char *data, RestResponse *response)
     print_verbose_response(response);

     return 0;
-}
\ No newline at end of file
+}
--- a/pgBalancer/configure.ac
+++ b/pgBalancer/configure.ac
@@ -489,4 +489,4 @@ AC_MSG_RESULT([enable cassert = $enable_cassert])
 
 AM_CONFIG_HEADER(src/include/config.h)
 
-AC_OUTPUT([Makefile doc/Makefile  doc/src/Makefile doc/src/sgml/Makefile doc.ja/Makefile  doc.ja/src/Makefile doc.ja/src/sgml/Makefile src/Makefile src/include/Makefile src/parser/Makefile src/libs/Makefile src/tools/Makefile src/tools/pgmd5/Makefile src/tools/pgenc/Makefile src/tools/pgproto/Makefile src/tools/watchdog/Makefile src/watchdog/Makefile])
+AC_OUTPUT([Makefile bctl/Makefile doc/Makefile  doc/src/Makefile doc/src/sgml/Makefile doc.ja/Makefile  doc.ja/src/Makefile doc.ja/src/sgml/Makefile src/Makefile src/include/Makefile src/parser/Makefile src/libs/Makefile src/tools/Makefile src/tools/pgmd5/Makefile src/tools/pgenc/Makefile src/tools/pgproto/Makefile src/tools/watchdog/Makefile src/watchdog/Makefile]) 
EOF


./update.sh
git add -A
git commit -m "bctl repair"
git push



