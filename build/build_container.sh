#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare -r CONTAINER='NGINX'

export TZ=America/New_York 
declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  


declare -r NGINX_PKGS="bash nginx shadow openssl ca-certificates tzdata"

#directories
declare WWW=/var/www

#  groups/users
declare nginx_user=${nginx_user:-'nginx'}
declare nginx_uid=${nginx_uid:-1001}
declare nginx_group=${nginx_group:-'nginx'}
declare nginx_gid=${nginx_gid:-1001} 
declare www_user=${www_user:-'www-data'}
declare www_uid=${www_uid:-82}
declare www_group=${www_group:-'www-data'}
declare www_gid=${www_gid:-82}

# global exceptions
declare -i dying=0
declare -i pipe_error=0


#----------------------------------------------------------------------------
# Exit on any error
function catch_error() {
    echo "ERROR: an unknown error occurred at $BASH_SOURCE:$BASH_LINENO" >&2
}

#----------------------------------------------------------------------------
# Detect when build is aborted
function catch_int() {
    die "${BASH_SOURCE[0]} has been aborted with SIGINT (Ctrl-C)"
}

#----------------------------------------------------------------------------
function catch_pipe() {
    pipe_error+=1
    [[ $pipe_error -eq 1 ]] || return 0
    [[ $dying -eq 0 ]] || return 0
    die "${BASH_SOURCE[0]} has been aborted with SIGPIPE (broken pipe)"
}

#----------------------------------------------------------------------------
function die() {
    local status=$?
    [[ $status -ne 0 ]] || status=255
    dying+=1

    printf "%s\n" "FATAL ERROR" "$@" >&2
    exit $status
}  

#############################################################################
function cleanup()
{
    printf "\nclean up\n"
}

#############################################################################
function configure_NGINX()
{
    usermod -u ${nginx_uid} ${nginx_user}
    groupmod -g ${nginx_gid} ${nginx_group}

    [[ -d /var/nginx/client_body ]] || mkdir -p /var/nginx/client_body
    [[ -d /var/nginx/fastcgi_temp ]] || mkdir -p /var/nginx/fastcgi_temp
    [[ -d /var/nginx/proxy_temp ]] || mkdir -p /var/nginx/proxy_temp
    [[ -d /var/nginx/scgi_temp ]] || mkdir -p /var/nginx/scgi_temp
    [[ -d /var/nginx/uwsgi_temp ]] || mkdir -p /var/nginx/uwsgi_temp
    
    mkdir -p "${WWW}"
    mkdir -p /opt/ssl
    mkdir -p /etc/nginx/ssl

    echo ">> GENERATING SSL CERT"
    cd /etc/nginx/ssl
    openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
    openssl rsa -passin pass:x -in server.pass.key -out server.key
    rm server.pass.key

    openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
    openssl req -new -key server.key -out server.csr -subj "/C=US/ST=Massachusetts/L=Mansfield/O=ballantyne.io/OU=docker.nginx.io/CN=ubuntu-s3"
    openssl x509 -req -sha256 -days 300065 -in server.csr -signkey server.key -out server.crt 
    echo ">> GENERATING SSL CERT ... DONE"
}

#############################################################################
function createUserAndGroup()
{
    local -r user=$1
    local -r uid=$2
    local -r group=$3
    local -r gid=$4
    local -r homedir=$5
    local -r shell=$6
    local result
    
    local wanted=$( printf '%s:%s' $group $gid )
    local nameMatch=$( getent group "${group}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    local idMatch=$( getent group "${gid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: group/gid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"           

    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "\ncreate group:  %s\n" $group
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && groupdel "$( getent group ${group} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && groupdel "$( getent group ${gid} | awk -F ':' '{ print $1 }' )"
        /usr/sbin/groupadd --gid "${gid}" "${group}"
    fi

    
    wanted=$( printf '%s:%s' $user $uid )
    nameMatch=$( getent passwd "${user}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    idMatch=$( getent passwd "${uid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: user/uid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"    
    
    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "create user: %s\n" $user
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && userdel "$( getent passwd ${user} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && userdel "$( getent passwd ${uid} | awk -F ':' '{ print $1 }' )"

        /usr/sbin/useradd --home-dir "$homedir" --uid "${uid}" --gid "${gid}" --no-create-home --shell "${shell}" "${user}"
    fi
}

#############################################################################
function header()
{
    local -r bars='+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    printf "\n\n\e[1;34m%s\nBuilding container: \e[0m%s\e[1;34m\n%s\e[0m\n" $bars $CONTAINER $bars
}
 
#############################################################################
function install_CUSTOMIZATIONS()
{
    printf "\nAdd configuration and customizations\n"
    cp -r "${TOOLS}/etc"/* /etc
    cp -r "${TOOLS}/usr"/* /usr
    cp -r "${TOOLS}/var"/* /var

    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh
    
    if [[ -h /var/lib/nginx/logs ]]; then
        rm /var/lib/nginx/logs
        ln -s /var/log /var/lib/nginx/logs
    fi

    [[ -d /run/nginx ]]   || mkdir -p /run/nginx
}

#############################################################################
function installAlpinePackages()
{
    apk update
    apk add --no-cache $NGINX_PKGS
}

#############################################################################
function installTimezone()
{
    echo "$TZ" > /etc/TZ
    cp /usr/share/zoneinfo/$TZ /etc/timezone
    cp /usr/share/zoneinfo/$TZ /etc/localtime
}

#############################################################################
function setPermissions()
{
    printf "\nmake sure that ownership & permissions are correct\n"

    chmod u+rx,g+rx,o+rx,a-w /usr/local/bin/docker-entrypoint.sh

    chown "${nginx_user}":"${nginx_group}" -R /opt
    chown "${nginx_user}":"${nginx_group}" -R /var/log/nginx
    chown "${nginx_user}":"${nginx_group}" -R /var/nginx
    chown "${www_user}":"${www_group}" -R "${WWW}"
}

#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

set -o verbose

header
installAlpinePackages
installTimezone
#createUserAndGroup "${nginx_user}" "${nginx_uid}" "${nginx_group}" "${nginx_gid}" "${WWW}" /sbin/nologin
createUserAndGroup "${www_user}" "${www_uid}" "${www_group}" "${www_gid}" "${WWW}" /sbin/nologin
configure_NGINX
install_CUSTOMIZATIONS
setPermissions
cleanup
exit 0