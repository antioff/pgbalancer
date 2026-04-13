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
cp bctl/bctl %{buildroot}%_bindir/


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

