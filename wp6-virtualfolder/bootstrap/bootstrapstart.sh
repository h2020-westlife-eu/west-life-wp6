#!/usr/bin/env bash
# copy rc.local - custom script to start processes at boot
#touch /etc/rc.local
#cat /home/vagrant/bootstrap/rc.local >>/etc/rc.local
#chmod -R ugo+rwx /home/vagrant/scripts 
#chmod +x /etc/rc.local
#start the processes at first time - after that it will be started at boot
#/etc/rc.local
sed -i -e "s/\ExecStart.*$/ExecStart=\/home\/vagrant\/VRE-master\/rundevvre.sh/g" /etc/systemd/system/westlife-vre.service
sed -i -e "s/^\(WorkingDirectory\s*=\s*\).*$/\1\/home\/vagrant\/VRE-master/g" /etc/systemd/system/westlife-vre.service
sed -i -e "s/\ExecStart.*$/ExecStart=\/bin\/mono \/home\/vagrant\/MetadataService\/MetadataService.exe/g" /etc/systemd/system/westlife-metadata.service
sed -i -e "s/^\(WorkingDirectory\s*=\s*\).*$/\1\/home\/vagrant/g" /etc/systemd/system/westlife-metadata.service
chown -R vagrant:vagrant /home/vagrant

# SELinux setting, allow proxy from apache to other services and security context to dir
if hash setsebool 2>/dev/null; then
  setsebool -P httpd_can_network_connect 1
  chcon -R --reference=/var/www $WP6SRC/www
  firewall-cmd --zone=public --add-port=80/tcp --permanent
  firewall-cmd --reload
fi
service httpd start
systemctl enable westlife-metadata.service
service westlife-metadata start
sleep 2
/home/vagrant/scripts/addfilesystemprovider.sh
if [[ -n ${PORTAL_DEPLOYMENT} && ${PORTAL_DEPLOYMENT} -eq "1" ]]; then systemctl enable westlife-vre; fi
if [[ -n ${PORTAL_DEPLOYMENT} && ${PORTAL_DEPLOYMENT} -eq "1" ]]; then systemctl start westlife-vre; fi

# workaround for bug, reload,restart httpd fails on first attempt in SL7
service httpd reload
service httpd restart
