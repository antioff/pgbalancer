%global pg_majorversion 18

Summary:        Modern PostgreSQL %{pg_majorversion} connection pooler with REST API and YAML configuration
Name:           pgbalancer
Version:        1.0.0
Release:        alt1
Packager:	antioff <nobody@altlinux.org>
License:        MIT
URL:            https://github.com/pgelephant/pgbalancer
Group:          Databases

Source0: pgbalancer-%version.tar
Patch0: pgbalancer-%version-%release.patch

BuildRequires:  postgresql%{pg_majorversion}-server
BuildRequires:  postgresql%{pg_majorversion}-server-devel
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  libyaml-devel
BuildRequires:  openssl-devel
BuildRequires:  pam-devel

Requires:       libyaml
Requires:       openssl-libs


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
%setup -q -n pgbalancer-%{version}
%autopatch -p1

%build 
export PG_CONFIG=%_usr/bin/pg_config
./configure \
    --prefix=%_usr \
    --with-pgsql=%{pginstdir} \
    --with-openssl \
    --with-pam \
    --enable-rest-api

make %{?_smp_mflags}


%install
make install DESTDIR=%{buildroot}

# Create directories
mkdir -p %{buildroot}/etc/pgbalancer
mkdir -p %{buildroot}/var/log/pgbalancer
mkdir -p %{buildroot}/var/run/pgbalancer

# Install sample config
install -m 644 src/sample/pgpool.conf.sample %{buildroot}/etc/pgbalancer/pgbalancer.conf.sample



%files
%doc README.md
%_usr/bin/pgbalancer
%_usr/bin/bctl
%_usr/bin/pcp_*
%_usr/bin/pg_enc
%_usr/bin/pg_md5
%_usr/bin/pgpool_setup
%_usr/etc/pgbalancer.conf.sample*
%_usr/share/pgbalancer/
%dir /etc/pgbalancer
%config(noreplace) /etc/pgbalancer/pgbalancer.conf.sample
%dir /var/log/pgbalancer
%dir /var/run/pgbalancer


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

