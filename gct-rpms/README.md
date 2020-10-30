# A workaround for no transfer log recorded in /var/log/storm/storm-globus-gridftp.log

The function `globus_i_gfs_log_transfer()` was accidently removed on the [commit](https://github.com/gridcf/gct/commit/9a8f75e26261580638d7e36c0aa845b2617e4891#diff-0d41fe5a384e8076fc8f2dc3424bc45a)

To build GCT locally:

```
% sudo yum install epel-release
% sudo yum install make autoconf automake libtool libtool-ltdl-devel patch curl git bison openssl openssl-devel rpm-build doxygen graphviz 'perl(Pod::Html)' fakeroot udt udt-devel glib2-devel libnice-devel gettext-devel libffi-devel libxml2-devel pam-devel voms-devel cyrus-sasl-devel openldap-devel voms-clients initscripts python-devel 'perl(DBI)' redhat-lsb-core m2crypto mod_ssl mod_wsgi pyOpenSSL python-crypto perl-generators 'perl(Test::More)' gcc-c++ 'perl(URI)' 'perl(DBD::SQLite)'
% git clone https://github.com/gridcf/gct.git
% cd gct/travis-ci
% ./make_source_tarballs.sh
% ./make_rpms.sh -C    # sudo required

# then, RPMs are in $HOME/gct/packaging/rpmbuild/RPMS
```

On the GridFTP server:

Replace these packages below installed from UMD4 repo:

- [`globus-gridftp-server-13.21-1.gct.x86_64.rpm`](globus-gridftp-server-13.21-1.gct.x86_64.rpm)
- [`globus-gridftp-server-progs-13.21-1.gct.x86_64.rpm`](globus-gridftp-server-progs-13.21-1.gct.x86_64.rpm)
- [`globus-gridftp-server-control-9.1-1.gct.x86_64.rpm`](globus-gridftp-server-control-9.1-1.gct.x86_64.rpm)


```
% sudo systemctl stop storm-globus-gridftp.service
% sudo yum install globus-gridftp-server-13.21-1.gct.x86_64.rpm globus-gridftp-server-progs-13.21-1.gct.x86_64.rpm globus-gridftp-server-control-9.1-1.gct.x86_64.rpm
% sudo systemctl start storm-globus-gridftp.service
```


See also: <https://github.com/gridcf/gct/issues/110>
