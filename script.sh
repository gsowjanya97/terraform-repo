#cloud-config
package_upgrade: true
packages:
    - nginx
runcmd:
    - cd /var/www/
    - sudo chmod 757 html