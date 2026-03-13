%global PG_VER 18
%global PG_PRO 1

Summary:        Modern PostgreSQL %{PG_VER} connection pooler with REST API and YAML configuration
Version:        1.0.0
Release:        alt1
Packager:       antioff <nobody@altlinux.org>
License:        MIT
URL:            https://github.com/pgelephant/pgbalancer
Group:          Databases

Source0: pgBalancer-%version.tar
Patch0: pgBalancer-%version-%release.patch

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
BuildRequires:  libpq5-devel
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  libyaml-devel
BuildRequires:  flex

%if %PG_PRO
%global PG_PREFIX /opt/pgpro/1c-18
Name:           pgbalancer-pro
BuildRequires:  postgrespro-1c-%{PG_VER}-devel
%else
%global PG_PREFIX %_usr
Name:           pgbalancer
BuildRequires:  postgres%{PG_VER}-server-devel
%endif

Requires:	libyaml2
Requires:	openssl
Requires:	libpq5

%description
pgbalancer is a modern, production-ready PostgreSQL connection pooler and load
balancer built as a fork of pgpool-II. It provides a comprehensive REST API,
professional CLI tool (bctl), and YAML configuration support.

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

%setup -q -n pgBalancer-%{version}
%autopatch -p1

%build

export PG_CONFIG=%PG_PREFIX/bin/pg_config
export PG_INCLUDE=$($PG_CONFIG --includedir)
export PG_LIB=$($PG_CONFIG --libdir)
echo #################
echo $PG_CONFIG

%autoreconf

./configure \
    --disable-rpath \
    --with-openssl \
    --with-pam \
    --with-ldap

make
make -C bctl

%install
make prefix=%buildroot%_usr install
mkdir -p %buildroot{%_sysconfdir/pgbalancer,%_logdir/pgbalancer,%_runtimedir/pgbalancer,%_libdir/pgbalancer}
find "src" -name "*.a" -exec cp -v {} "%buildroot%_libdir/pgbalancer/" \;
cp -Rf %buildroot/usr/etc/* %buildroot%_sysconfdir/pgbalancer/
install -m 644 src/sample/pgbalancer.conf.sample %{buildroot}/etc/pgbalancer/pgbalancer.conf.sample

%files
%doc README.md
%dir %_sysconfdir/pgbalancer
%dir %_logdir/pgbalancer
%dir %_runtimedir/pgbalancer
%dir %_libdir/pgbalancer
%_bindir/*
%_sysconfdir/pgbalancer/*
%_datadir/pgbalancer/*
%_libdir/pgbalancer/*

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

