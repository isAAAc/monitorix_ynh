#=================================================
# SET ALL CONSTANTS
#=================================================

## Adapt md5sum while you update app
sha256sum="a974dd05f67562de85ce4a994cec7f0dcbe3cadad2c5f305131e3867af33a7ad"

app=$YNH_APP_INSTANCE_NAME
APP_VERSION=$(ynh_app_upstream_version)

#=================================================
# DEFINE ALL COMMON FONCTIONS
#=================================================

install_dependances() {
	ynh_install_app_dependencies rrdtool perl libwww-perl libmailtools-perl libmime-lite-perl librrds-perl libdbi-perl libxml-simple-perl libhttp-server-simple-perl libconfig-general-perl pflogsumm
}

get_install_source() {
    wget -q -O '/tmp/monitorix.deb' "http://www.monitorix.org/monitorix_${APP_VERSION}-izzy1_all.deb"

    if [[ ! -e '/tmp/monitorix.deb' ]] || [[ $(sha256sum '/tmp/monitorix.deb' | cut -d' ' -f1) != $sha256sum ]]
    then
        ynh_die "Error : can't get monitorix debian package"
    fi
	ynh_package_update
	dpkg --force-confdef --force-confold -i /tmp/monitorix.deb
	ynh_secure_remove /etc/monitorix/conf.d/00-debian.conf
	ynh_package_install -f
}

config_nginx() {
    ynh_add_nginx_config

    # Add special hostname for monitorix status
	nginx_status_conf="/etc/nginx/conf.d/monitorix_status.conf"
	cp ../conf/nginx_status.conf $nginx_status_conf
	ynh_replace_string __PORT__ $nginx_status_port $nginx_status_conf

    systemctl reload nginx
}

config_monitorix() {
	monitorix_conf=/etc/monitorix/monitorix.conf
	cp ../conf/monitorix.conf $monitorix_conf 
	ynh_replace_string __SERVICE_PORT__ $port $monitorix_conf
	ynh_replace_string __YNH_DOMAIN__ $domain $monitorix_conf
	ynh_replace_string __NGINX_STATUS_PORT__ $nginx_status_port $monitorix_conf
	ynh_replace_string "__YNH_WWW_PATH__/" "${path_url%/}/" $monitorix_conf
	ynh_replace_string __YNH_WWW_PATH__ $path_url $monitorix_conf
	ynh_replace_string __MYSQL_USER__ $dbuser $monitorix_conf
	ynh_replace_string __MYSQL_PASSWORD__ $dbpass $monitorix_conf
}

set_permission() {
    chown www-data:root -R /etc/monitorix
    chmod u=rX,g=rwX,o= -R /etc/monitorix
    chown www-data:root -R /var/lib/monitorix
    chmod u=rwX,g=rwX,o= -R /var/lib/monitorix
}