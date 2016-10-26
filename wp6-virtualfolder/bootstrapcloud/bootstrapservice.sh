#!/usr/bin/env sh
# 17.10.2016 replaced postgresql by sqlite3
# 10.10.2016 moved mono 4.5 build to cvmfs
# 02.06.2016 replaced mysql by postgres
# install mono,  TODO reduce monodevelop to only needed packages

#apt-get install -y mono-complete
#apt-get install -y mono-devel

# install mysql
#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password changeit'
#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password changeit'
#sudo apt-get -y install mysql-server
#mysqladmin -u root --password=changeit create westlifewp6

# install postgresql
#apt-get install -y postgresql

##service postgresql start
#yum -y install postgresql-server postgresql-contrib
#postgresql-setup initdb
##allow postgresql md5 authentication
#gawk '{gsub(/ident/,"md5",$5); print}' /var/lib/pgsql/data/pg_hba.conf > pg_hba_new.conf
#mv pg_hba_new.conf /var/lib/pgsql/data/pg_hba.conf

##start postgresql
#systemctl start postgresql
#systemctl enable postgresql
##set default db account password
#sudo -u postgres psql template1 -c "ALTER USER postgres with encrypted password 'changeit';"

#install mono
#remove default mono
#yum -y remove mono-* monodoc
#install mono repository
#yum -y --installroot=/opt/tools/latest/ install yum-utils
#rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
#yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
#yum -y install --installroot=/opt/tools/latest/ mono-devel
#install nuget package tool
#sudo yum -y --nogpgcheck --installroot=/opt/tools/latest/ install nuget
#fix mono configuration
#sed -i '{s/\$mono_libdir/\/usr\/lib64/}' /opt/tools/latest/etc/mono/config

# build metadataservice
cp -R $WP6SRC/src /home/vagrant
# download depended nuget packages DLL
#wget https://nuget.org/nuget.exe
#/bin/sh
source /cvmfs/west-life.egi.eu/tools/mono/mono-dev-env
# fix http://stackoverflow.com/questions/15181888/
mozroots --import --sync
#certmgr -ssl -m https://go.microsoft.com
#certmgr -ssl -m https://nugetgallery.blob.core.windows.net
#certmgr -ssl -m https://nuget.org
# restore nuget packages 
nuget restore /home/vagrant/src/WP6Service2/WP6Service2.sln
# build project EXEcutable, workaround on xbuild bug - hangs after compilation 
xbuild /home/vagrant/src/WP6Service2/WP6Service2.sln 
#& sleep 90; killall /cvmfs/west-life.egi.eu/tools/mono/4.6.1/bin/mono
