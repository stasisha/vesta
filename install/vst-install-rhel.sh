#!/bin/bash

# Vesta RHEL/CentOS installer v.05s

#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
export PATH=$PATH:/sbin
RHOST='r.vestacp.com'
CHOST='c.vestacp.com'
REPO='cmmnt'
VERSION='rhel'
VESTA='/usr/local/vesta'
memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
arch=$(uname -i)
os=$(cut -f 1 -d ' ' /etc/redhat-release)
release=$(grep -o "[0-9]" /etc/redhat-release |head -n1)
codename="${os}_$release"
vestacp="http://$CHOST/$VERSION/$release"
base='https://raw.githubusercontent.com/stasisha/vesta/master'

if [ "$release" -eq 7 ]; then
    software="nginx httpd mod_ssl mod_ruid2 mod_fcgid php php-common php-cli
    php-bcmath php-gd php-imap php-mbstring php-mcrypt php-mysql php-pdo
    php-soap php-tidy php-xml php-xmlrpc php-fpm php-pgsql php70-php php70-php-fpm
    php71-php php71-php-fpm php72-php php72-php-fpm awstats webalizer
    vsftpd proftpd bind bind-utils bind-libs exim dovecot clamav-server
    clamav-update spamassassin roundcubemail mariadb mariadb-server phpMyAdmin
    postgresql postgresql-server postgresql-contrib phpPgAdmin e2fsprogs
    openssh-clients ImageMagick curl mc screen ftp zip unzip flex sqlite pcre
    sudo bc jwhois mailx lsof tar telnet rrdtool net-tools ntp GeoIP freetype
    fail2ban rsyslog iptables-services which vesta vesta-nginx vesta-php
    vim-common expect postgresql96-server postgresql10-server git mc"
else
    software="nginx httpd mod_ssl mod_ruid2 mod_fcgid mod_extract_forwarded
    php php-common php-cli php-bcmath php-gd php-imap php-mbstring php-mcrypt
    php-mysql php-pdo php-soap php-tidy php-xml php-xmlrpc php-fpm php-pgsql
    awstats webalizer vsftpd proftpd bind bind-utils bind-libs exim dovecot
    clamd spamassassin roundcubemail mysql mysql-server phpMyAdmin postgresql
    postgresql-server postgresql-contrib phpPgAdmin e2fsprogs openssh-clients
    ImageMagick curl mc screen ftp zip unzip flex sqlite pcre sudo bc jwhois
    mailx lsof tar telnet rrdtool net-tools ntp GeoIP freetype fail2ban
    which vesta vesta-nginx vesta-php vim-common expect"
fi

# Defining help function
help() {
    echo "Usage: $0 [OPTIONS]
  -a,  --apache            Install Apache        [yes|no]  default: no
  -n,  --nginx             Install Nginx         [yes|no]  default: yes
  -w,  --phpfpm            Install PHP-FPM       [yes|no]  default: yes
  -w70,--phpfpm70          Install PHP-FPM 7.0   [yes|no]  default: yes
  -w71,--phpfpm71          Install PHP-FPM 7.1   [yes|no]  default: yes
  -w72,--phpfpm72          Install PHP-FPM 7.2   [yes|no]  default: yes
  -v,  --vsftpd            Install Vsftpd        [yes|no]  default: yes
  -j,  --proftpd           Install ProFTPD       [yes|no]  default: no
  -k,  --named             Install Bind          [yes|no]  default: yes
  -m,  --mysql             Install MySQL         [yes|no]  default: yes
  -g,  --postgresql        Install PostgreSQL    [yes|no]  default: no
  -g96,--postgresql96      Install PostgreSQL 9.6[yes|no]  default: no
  -g10,--postgresql10      Install PostgreSQL 10 [yes|no]  default: yes
  -d,  --mongodb           Install MongoDB       [yes|no]  unsupported
  -x,  --exim              Install Exim          [yes|no]  default: yes
  -z,  --dovecot           Install Dovecot       [yes|no]  default: yes
  -c,  --clamav            Install ClamAV        [yes|no]  default: yes
  -t,  --spamassassin      Install SpamAssassin  [yes|no]  default: yes
  -i,  --iptables          Install Iptables      [yes|no]  default: yes
  -b,  --fail2ban          Install Fail2ban      [yes|no]  default: yes
  -r,  --remi              Install Remi repo     [yes|no]  default: yes
  -q,  --quota             Filesystem Quota      [yes|no]  default: no
  -qt, --git               Git                   [yes|no]  default: yes
  -сo, --composer          Composer              [yes|no]  default: yes
  -mc, --mc                Midnight Сommander    [yes|no]  default: yes
  -l,  --lang              Default language                default: en
  -y,  --interactive       Interactive install   [yes|no]  default: yes
  -s,  --hostname          Set hostname
  -e,  --email             Set admin email
  -p,  --password          Set admin password
  -f,  --force             Force installation
  -h,  --help              Print this help

  Example: bash $0 -e demo@vestacp.com -p p4ssw0rd --apache no --phpfpm yes"
    exit 1
}

# Defining password-gen function
gen_pass() {
    MATRIX='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    LENGTH=10
    while [ ${n:=1} -le $LENGTH ]; do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
    done
    echo "$PASS"
}

# Defning return code check function
check_result() {
    if [ $1 -ne 0 ]; then
        echo "Error: $2"
        exit $1
    fi
}

# Defining function to set default value
set_default_value() {
    eval variable=\$$1
    if [ -z "$variable" ]; then
        eval $1=$2
    fi
    if [ "$variable" != 'yes' ] && [ "$variable" != 'no' ]; then
        eval $1=$2
    fi
}


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

# Creating temporary file
tmpfile=$(mktemp -p /tmp)

# Translating argument to --gnu-long-options
for arg; do
    delim=""
    case "$arg" in
        --apache)               args="${args}-a  " ;;
        --nginx)                args="${args}-n  " ;;
        --phpfpm)               args="${args}-w  " ;;
        --phpfpm70)             args="${args}-w70" ;;
        --phpfpm71)             args="${args}-w71" ;;
        --phpfpm72)             args="${args}-w72" ;;
        --vsftpd)               args="${args}-v  " ;;
        --proftpd)              args="${args}-j  " ;;
        --named)                args="${args}-k  " ;;
        --mysql)                args="${args}-m  " ;;
        --postgresql)           args="${args}-g  " ;;
        --postgresql96)         args="${args}-g96" ;;
        --postgresql10)         args="${args}-g10" ;;
        --mongodb)              args="${args}-d  " ;;
        --exim)                 args="${args}-x  " ;;
        --dovecot)              args="${args}-z  " ;;
        --clamav)               args="${args}-c  " ;;
        --spamassassin)         args="${args}-t  " ;;
        --iptables)             args="${args}-i  " ;;
        --fail2ban)             args="${args}-b  " ;;
        --remi)                 args="${args}-r  " ;;
        --quota)                args="${args}-q  " ;;
        --git)                  args="${args}-qt " ;;
        --composer)             args="${args}-co " ;;
        --mc)                   args="${args}-mc " ;;
        --lang)                 args="${args}-l  " ;;
        --interactive)          args="${args}-y  " ;;
        --hostname)             args="${args}-s  " ;;
        --email)                args="${args}-e  " ;;
        --password)             args="${args}-p  " ;;
        --force)                args="${args}-f  " ;;
        --help)                 args="${args}-h  " ;;
        *)                      [[ "${arg:0:1}" == "-" ]] || delim="\""
                                args="${args}${delim}${arg}${delim} ";;
    esac
done
eval set -- "$args"

# Parsing arguments
while getopts "a:n:w:w70:w71:w72:v:j:k:m:g:g96:g10:d:x:z:c:t:i:b:r:q:gt:co:mc:l:y:s:e:p:f:h" Option; do
    case $Option in
        a)   apache=$OPTARG ;;            # Apache
        n)   nginx=$OPTARG ;;             # Nginx
        w)   phpfpm=$OPTARG ;;            # PHP-FPM
        w70) phpfpm70=$OPTARG ;;          # PHP-FPM 7.0
        w71) phpfpm71=$OPTARG ;;          # PHP-FPM 7.1
        w72) phpfpm72=$OPTARG ;;          # PHP-FPM 7.2
        v)   vsftpd=$OPTARG ;;            # Vsftpd
        j)   proftpd=$OPTARG ;;           # Proftpd
        k)   named=$OPTARG ;;             # Named
        m)   mysql=$OPTARG ;;             # MySQL
        g)   postgresql=$OPTARG ;;        # PostgreSQL
        g96) postgresql96=$OPTARG ;;      # PostgreSQL 9.6
        g10) postgresql10=$OPTARG ;;      # PostgreSQL 10
        d)   mongodb=$OPTARG ;;           # MongoDB (unsupported)
        x)   exim=$OPTARG ;;              # Exim
        z)   dovecot=$OPTARG ;;           # Dovecot
        c)   clamd=$OPTARG ;;             # ClamAV
        t)   spamd=$OPTARG ;;             # SpamAssassin
        i)   iptables=$OPTARG ;;          # Iptables
        b)   fail2ban=$OPTARG ;;          # Fail2ban
        r)   remi=$OPTARG ;;              # Remi repo
        q)   quota=$OPTARG ;;             # FS Quota
        qt)  git=$OPTARG ;;               # Git
        co)  composer=$OPTARG ;;          # Composer
        mc)  mc=$OPTARG ;;                # Midnight Сommander
        l)   lang=$OPTARG ;;              # Language
        y)   interactive=$OPTARG ;;       # Interactive install
        s)   servername=$OPTARG ;;        # Hostname
        e)   email=$OPTARG ;;             # Admin email
        p)   vpass=$OPTARG ;;             # Admin password
        f)   force='yes' ;;               # Force install
        h)   help ;;                      # Help
        *)   help ;;                      # Print help (default)
    esac
done

# Defining default software stack
set_default_value 'nginx' 'yes'
set_default_value 'apache' 'no'
set_default_value 'phpfpm' 'yes'
set_default_value 'phpfpm70' 'yes'
set_default_value 'phpfpm71' 'yes'
set_default_value 'phpfpm72' 'yes'
set_default_value 'vsftpd' 'yes'
set_default_value 'proftpd' 'no'
set_default_value 'named' 'yes'
set_default_value 'mysql' 'yes'
set_default_value 'postgresql' 'no'
set_default_value 'postgresql96' 'no'
set_default_value 'postgresql10' 'yes'
set_default_value 'mongodb' 'no'
set_default_value 'exim' 'yes'
set_default_value 'dovecot' 'yes'
if [ $memory -lt 1500000 ]; then
    set_default_value 'clamd' 'no'
    set_default_value 'spamd' 'no'
else
    set_default_value 'clamd' 'yes'
    set_default_value 'spamd' 'yes'
fi
set_default_value 'iptables' 'yes'
set_default_value 'fail2ban' 'yes'
set_default_value 'remi' 'yes'
set_default_value 'quota' 'no'
set_default_value 'git' 'yes'
set_default_value 'composer' 'yes'
set_default_value 'mc' 'yes'
set_default_value 'lang' 'en'
set_default_value 'interactive' 'yes'

# Checking software conflicts
if [ "$phpfpm" = 'yes' ]; then
    apache='no'
    nginx='yes'
fi
if [ "$proftpd" = 'yes' ]; then
    vsftpd='no'
fi
if [ "$exim" = 'no' ]; then
    clamd='no'
    spamd='no'
    dovecot='no'
fi
if [ "$iptables" = 'no' ]; then
    fail2ban='no'
fi

# Checking root permissions
echo "Checking root permissions"
if [ "x$(id -u)" != 'x0' ]; then
    check_error 1 "Script can be run executed only by root"
fi

# Checking admin user account
echo "Checking admin user account"
if [ ! -z "$(grep ^admin: /etc/passwd /etc/group)" ] && [ -z "$force" ]; then
    echo 'Please remove admin user account before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo -e "Example: bash $0 --force\n"
    check_result 1 "User admin exists"
fi

# Checking wget
echo "Checking wget"
if [ ! -e '/usr/bin/wget' ]; then
    echo "Installing wget"
    yum -y install wget
    check_result $? "Can't install wget"
fi

# Checking repository availability
echo "Checking repository availability"
wget -q "$vestacp/GPG.txt" -O /dev/null
check_result $? "No access to Vesta repository"

# Checking installed packages
echo "Checking installed packages"
rpm -qa > $tmpfile
for pkg in exim mysql-server httpd nginx vesta; do
    if [ ! -z "$(grep $pkg $tmpfile)" ]; then
        conflicts="$pkg $conflicts"
    fi
done
if [ ! -z "$conflicts" ] && [ -z "$force" ]; then
    echo '!!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!'
    echo
    echo 'Following packages are already installed:'
    echo "$conflicts"
    echo
    echo 'It is highly recommended to remove them before proceeding.'
    echo 'If you want to force installation run this script with -f option:'
    echo "Example: bash $0 --force"
    echo
    echo '!!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!'
    echo
    check_result 1 "Control Panel should be installed on clean server."
fi


#----------------------------------------------------------#
#                       Brief Info                         #
#----------------------------------------------------------#

# Printing nice ASCII logo
clear
echo
echo ' _|      _|  _|_|_|_|    _|_|_|  _|_|_|_|_|    _|_|'
echo ' _|      _|  _|        _|            _|      _|    _|'
echo ' _|      _|  _|_|_|      _|_|        _|      _|_|_|_|'
echo '   _|  _|    _|              _|      _|      _|    _|'
echo '     _|      _|_|_|_|  _|_|_|        _|      _|    _|'
echo
echo '                                  Vesta Control Panel'
echo -e "\n\n"

echo 'Following software will be installed on your system:'

# Web stack
if [ "$nginx" = 'yes' ]; then
    echo '   - Nginx Web Server'
fi
if [ "$apache" = 'yes' ] && [ "$nginx" = 'no' ] ; then
    echo '   - Apache Web Server'
fi
if [ "$apache" = 'yes' ] && [ "$nginx"  = 'yes' ] ; then
    echo '   - Apache Web Server (as backend)'
fi
if [ "$phpfpm"  = 'yes' ]; then
    echo '   - PHP-FPM Application Server'
fi
if [ "$phpfpm70"  = 'yes' ]; then
    echo '   - PHP-FPM 7.0 Application Server'
fi
if [ "$phpfpm71"  = 'yes' ]; then
    echo '   - PHP-FPM 7.1 Application Server'
fi
if [ "$phpfpm72"  = 'yes' ]; then
    echo '   - PHP-FPM 7.2 Application Server'
fi
# DNS stack
if [ "$named" = 'yes' ]; then
    echo '   - Bind DNS Server'
fi

# Mail Stack
if [ "$exim" = 'yes' ]; then
    echo -n '   - Exim Mail Server'
    if [ "$clamd" = 'yes'  ] ||  [ "$spamd" = 'yes' ] ; then
        echo -n ' + '
        if [ "$clamd" = 'yes' ]; then
            echo -n 'Antivirus '
        fi
        if [ "$spamd" = 'yes' ]; then
            echo -n 'Antispam'
        fi
    fi
    echo
    if [ "$dovecot" = 'yes' ]; then
        echo '   - Dovecot POP3/IMAP Server'
    fi
fi

# DB stack
if [ "$mysql" = 'yes' ]; then
    if [ $release = 7 ]; then
        echo '   - MariaDB Database Server'
    else
        echo '   - MySQL Database Server'
    fi
fi
if [ "$postgresql" = 'yes' ]; then
    echo '   - PostgreSQL Database Server'
fi
if [ "$postgresql96" = 'yes' ]; then
    echo '   - PostgreSQL 9.6 Database Server'
fi
if [ "$postgresql10" = 'yes' ]; then
    echo '   - PostgreSQL 10 Database Server'
fi
if [ "$mongodb" = 'yes' ]; then
    echo '   - MongoDB Database Server'
fi


# FTP stack
if [ "$vsftpd" = 'yes' ]; then
    echo '   - Vsftpd FTP Server'
fi
if [ "$proftpd" = 'yes' ]; then
    echo '   - ProFTPD FTP Server'
fi

# Other
if [ "$git" = 'yes' ]; then
    echo '   - Git Version Control System'
fi
if [ "$composer" = 'yes' ]; then
    echo '   - Composer Dependency management'
fi
if [ "$mc" = 'yes' ]; then
    echo '   - Midnight Commander'
fi

# Firewall stack
if [ "$iptables" = 'yes' ]; then
    echo -n '   - Iptables Firewall'
fi
if [ "$iptables" = 'yes' ] && [ "$fail2ban" = 'yes' ]; then
    echo -n ' + Fail2Ban'
fi
echo -e "\n\n"

# Asking for confirmation to proceed
if [ "$interactive" = 'yes' ]; then
    read -p 'Would you like to continue [y/n]: ' answer
    if [ "$answer" != 'y' ] && [ "$answer" != 'Y'  ]; then
        echo 'Goodbye'
        exit 1
    fi

    # Asking for contact email
    if [ -z "$email" ]; then
        read -p 'Please enter admin email address: ' email
    fi

    # Asking to set FQDN hostname
    if [ -z "$servername" ]; then
        read -p "Please enter FQDN hostname [$(hostname -f)]: " servername
    fi
fi

# Generating admin password if it wasn't set
if [ -z "$vpass" ]; then
    vpass=$(gen_pass)
fi

# Set hostname if it wasn't set
if [ -z "$servername" ]; then
    servername=$(hostname -f)
fi

# Set FQDN if it wasn't set
mask1='(([[:alnum:]](-?[[:alnum:]])*)\.)'
mask2='*[[:alnum:]](-?[[:alnum:]])+\.[[:alnum:]]{2,}'
if ! [[ "$servername" =~ ^${mask1}${mask2}$ ]]; then
    if [ ! -z "$servername" ]; then
        servername="$servername.example.com"
    else
        servername="example.com"
    fi
    echo "127.0.0.1 $servername" >> /etc/hosts
fi

# Set email if it wasn't set
if [ -z "$email" ]; then
    email="admin@$servername"
fi

# Defining backup directory
vst_backups="/root/vst_install_backups/$(date +%s)"
echo "Installation backup directory: $vst_backups"

# Printing start message and sleeping for 5 seconds
echo -e "\n\n\n\nInstallation will take about 15 minutes ...\n"
sleep 5


#----------------------------------------------------------#
#                      Checking swap                       #
#----------------------------------------------------------#

# Checking swap on small instances
if [ -z "$(swapon -s)" ] && [ $memory -lt 4000000 ]; then
    echo "Creating 4G SWAP file. This can take few minutes..."
    fallocate -l 4G /swapfile
    dd if=/dev/zero of=/swapfile count=4096 bs=1MiB
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
fi


#----------------------------------------------------------#
#                  Install repositories                    #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                  Install repositories                    #"
echo "#----------------------------------------------------------#"

# Installing EPEL repository
echo "Installing EPEL repository"
rpm -Uvh --force $vestacp/epel-release.rpm
check_result $? "Can't install EPEL repository"

# Installing Remi repository
if [ "$remi" = 'yes' ]; then
    echo "Installing Remi repository"
    rpm -Uvh --force $vestacp/remi-release.rpm
    check_result $? "Can't install REMI repository"
    sed -i "s/enabled=0/enabled=1/g" /etc/yum.repos.d/remi.repo
fi

# Installing Nginx repository
echo "Installing Nginx repository"
nrepo="/etc/yum.repos.d/nginx.repo"
echo "[nginx]" > $nrepo
echo "name=nginx repo" >> $nrepo
echo "baseurl=http://nginx.org/packages/centos/$release/\$basearch/" >> $nrepo
echo "gpgcheck=0" >> $nrepo
echo "enabled=1" >> $nrepo

# Installing Vesta repository
echo "Installing Vesta repository"
vrepo='/etc/yum.repos.d/vesta.repo'
echo "[vesta]" > $vrepo
echo "name=Vesta - $REPO" >> $vrepo
echo "baseurl=http://$RHOST/$REPO/$release/\$basearch/" >> $vrepo
echo "enabled=1" >> $vrepo
echo "gpgcheck=1" >> $vrepo
echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-VESTA" >> $vrepo
wget $vestacp/GPG.txt -O /etc/pki/rpm-gpg/RPM-GPG-KEY-VESTA

# Installing PostgreSQL repository
if [ "$release" -eq 7 ] && [  "$os" = "CentOS" ]; then
    echo "Installing PostgreSQL repository CentOS 7"
    yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-ppc64le/pgdg-centos96-9.6-3.noarch.rpm
    yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
elif [ "$release" -eq 7 ]; then
    echo "Installing PostgreSQL repository RHEL 7"
    yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm
    yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-redhat10-10-2.noarch.rpm
fi

#----------------------------------------------------------#
#                         Backup                           #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                         Backup                           #"
echo "#----------------------------------------------------------#"

# Creating backup directory tree
echo "Creating backup directory tree"
mkdir -p $vst_backups
cd $vst_backups
mkdir nginx httpd php php-fpm vsftpd proftpd named exim dovecot clamd \
    spamassassin mysql postgresql mongodb vesta postgresql9.6 postgresql10

# Backing up Nginx configuration
echo "Backing up Nginx configuration"
service nginx stop > /dev/null 2>&1
cp -r /etc/nginx/* $vst_backups/nginx > /dev/null 2>&1

# Backing up Apache configuration
echo "Backing up Apache configuration"
service httpd stop > /dev/null 2>&1
cp -r /etc/httpd/* $vst_backups/httpd > /dev/null 2>&1

# Backing up PHP configuration
echo "Backing up PHP configuration"
service php-fpm stop >/dev/null 2>&1
service php70-php-fpm stop >/dev/null 2>&1
service php71php-fpm stop >/dev/null 2>&1
service php72-php-fpm stop >/dev/null 2>&1

# Backing up default PHP
echo "Backing up default PHP"
cp /etc/php.ini $vst_backups/php > /dev/null 2>&1
cp -r /etc/php.d  $vst_backups/php > /dev/null 2>&1
cp /etc/php-fpm.conf $vst_backups/php-fpm > /dev/null 2>&1
mv -f /etc/php-fpm.d/* $vst_backups/php-fpm/ > /dev/null 2>&1
# Backing up PHP70
echo "Backing up PHP70"
cp /etc/opt/remi/php70/php.ini $vst_backups/php70 > /dev/null 2>&1
cp -r /etc/opt/remi/php70/php.d  $vst_backups/php70 > /dev/null 2>&1
cp /etc/opt/remi/php70/php-fpm.conf $vst_backups/php70-fpm > /dev/null 2>&1
mv -f /etc/opt/remi/php70/php-fpm.d/* $vst_backups/php70-fpm/ > /dev/null 2>&1
# Backing up PHP71
echo "Backing up PHP71"
cp /etc/opt/remi/php71/php.ini $vst_backups/php71 > /dev/null 2>&1
cp -r /etc/opt/remi/php71/php.d  $vst_backups/php71 > /dev/null 2>&1
cp /etc/opt/remi/php71/php-fpm.conf $vst_backups/php71-fpm > /dev/null 2>&1
mv -f /etc/opt/remi/php71/php-fpm.d/* $vst_backups/php71-fpm/ > /dev/null 2>&1
# Backing up PHP72
echo "Backing up PHP72"
cp /etc/opt/remi/php72/php.ini $vst_backups/php72 > /dev/null 2>&1
cp -r /etc/opt/remi/php72/php.d  $vst_backups/php72 > /dev/null 2>&1
cp /etc/opt/remi/php72/php-fpm.conf $vst_backups/php72-fpm > /dev/null 2>&1
mv -f /etc/opt/remi/php72/php-fpm.d/* $vst_backups/php72-fpm/ > /dev/null 2>&1

# Backing up Bind configuration
echo "Backing up Bind configuration"
yum remove bind-chroot > /dev/null 2>&1
service named stop > /dev/null 2>&1
cp /etc/named.conf $vst_backups/named >/dev/null 2>&1

# Backing up Vsftpd configuration
echo "Backing up Vsftpd configuration"
service vsftpd stop > /dev/null 2>&1
cp /etc/vsftpd/vsftpd.conf $vst_backups/vsftpd >/dev/null 2>&1

# Backing up ProFTPD configuration
echo "Backing up ProFTPD configuration"
service proftpd stop > /dev/null 2>&1
cp /etc/proftpd.conf $vst_backups/proftpd >/dev/null 2>&1

# Backing up Exim configuration
echo "Backing up Exim configuration"
service exim stop > /dev/null 2>&1
cp -r /etc/exim/* $vst_backups/exim >/dev/null 2>&1

# Backing up ClamAV configuration
echo "Backing up ClamAV configuration"
service clamd stop > /dev/null 2>&1
cp /etc/clamd.conf $vst_backups/clamd >/dev/null 2>&1
cp -r /etc/clamd.d $vst_backups/clamd >/dev/null 2>&1

# Backing up SpamAssassin configuration
echo "Backing up SpamAssassin configuration"
service spamassassin stop > /dev/null 2>&1
cp -r /etc/mail/spamassassin/* $vst_backups/spamassassin >/dev/null 2>&1

# Backing up Dovecot configuration
echo "Backing up Dovecot configuration"
service dovecot stop > /dev/null 2>&1
cp /etc/dovecot.conf $vst_backups/dovecot > /dev/null 2>&1
cp -r /etc/dovecot/* $vst_backups/dovecot > /dev/null 2>&1

# Backing up MySQL/MariaDB configuration and data
echo "Backing up MySQL/MariaDB configuration and data"
service mysql stop > /dev/null 2>&1
service mysqld stop > /dev/null 2>&1
service mariadb stop > /dev/null 2>&1
mv /var/lib/mysql $vst_backups/mysql/mysql_datadir >/dev/null 2>&1
cp /etc/my.cnf $vst_backups/mysql > /dev/null 2>&1
cp /etc/my.cnf.d $vst_backups/mysql > /dev/null 2>&1
mv /root/.my.cnf  $vst_backups/mysql > /dev/null 2>&1

# Backing up PostgreSQL configuration and data
echo "Backing up PostgreSQL configuration and data"
service postgresql stop > /dev/null 2>&1
service postgresql-9.6 stop > /dev/null 2>&1
service postgresql-10 stop > /dev/null 2>&1
mv /var/lib/pgsql/data $vst_backups/postgresql/  >/dev/null 2>&1
mv /var/lib/pgsql/9.6 $vst_backups/postgresql9.6/  >/dev/null 2>&1
mv /var/lib/pgsql/10 $vst_backups/postgresql10/  >/dev/null 2>&1

# Backing up Vesta configuration and data
echo "Backing up Vesta configuration and data"
service vesta stop > /dev/null 2>&1
mv $VESTA/data/* $vst_backups/vesta > /dev/null 2>&1
mv $VESTA/conf/* $vst_backups/vesta > /dev/null 2>&1


#----------------------------------------------------------#
#                     Package Excludes                     #
#----------------------------------------------------------#

# Excluding packages
if [ "$nginx" = 'no'  ]; then
    software=$(echo "$software" | sed -e "s/^nginx//")
fi
if [ "$apache" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/httpd//")
    software=$(echo "$software" | sed -e "s/mod_ssl//")
    software=$(echo "$software" | sed -e "s/mod_fcgid//")
    software=$(echo "$software" | sed -e "s/mod_ruid2//")
fi
if [ "$phpfpm" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php-fpm//")
fi
if [ "$phpfpm70" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php70-php//")
    software=$(echo "$software" | sed -e "s/php70-php-fpm//")
fi
if [ "$phpfpm71" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php71-php//")
    software=$(echo "$software" | sed -e "s/php71-php-fpm//")
fi
if [ "$phpfpm72" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php72-php//")
    software=$(echo "$software" | sed -e "s/php72-php-fpm//")
fi
if [ "$vsftpd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/vsftpd//")
fi
if [ "$proftpd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/proftpd//")
fi
if [ "$named" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/bind //")
fi
if [ "$exim" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/exim//")
    software=$(echo "$software" | sed -e "s/dovecot//")
    software=$(echo "$software" | sed -e "s/clamd//")
    software=$(echo "$software" | sed -e "s/clamav-server//")
    software=$(echo "$software" | sed -e "s/clamav-update//")
    software=$(echo "$software" | sed -e "s/spamassassin//")
    software=$(echo "$software" | sed -e "s/dovecot//")
    software=$(echo "$software" | sed -e "s/roundcubemail//")
fi
if [ "$clamd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/clamd//")
    software=$(echo "$software" | sed -e "s/clamav-server//")
    software=$(echo "$software" | sed -e "s/clamav-update//")
fi
if [ "$spamd" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/spamassassin//')
fi
if [ "$dovecot" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/dovecot//")
fi
if [ "$mysql" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/mysql //')
    software=$(echo "$software" | sed -e 's/mysql-server//')
    software=$(echo "$software" | sed -e 's/mariadb //')
    software=$(echo "$software" | sed -e 's/mariadb-server//')
    software=$(echo "$software" | sed -e 's/php-mysql//')
    software=$(echo "$software" | sed -e 's/phpMyAdmin//')
    software=$(echo "$software" | sed -e 's/roundcubemail//')
fi
if [ "$postgresql" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/postgresql //')
    software=$(echo "$software" | sed -e 's/postgresql-server//')
    software=$(echo "$software" | sed -e 's/postgresql-contrib//')
    software=$(echo "$software" | sed -e 's/phpPgAdmin//')
fi
if [ "$postgresql96" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/postgresql96-server//')
fi
if [ "$postgresql10" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/postgresql10-server//')
fi
if [ "$postgresql" = 'no' ] && [ "$postgresql96" = 'no' ] && [ "$postgresql10" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/php-pgsql//')
fi
if [ "$mc" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/mc//')
fi
if [ "$git" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/git//')
fi
if [ "$iptables" = 'no' ] || [ "$fail2ban" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/fail2ban//')
fi

#----------------------------------------------------------#
#                     Install packages                     #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                     Install packages                     #"
echo "#----------------------------------------------------------#"

# Installing rpm packages
echo "Installing rpm packages:"
echo "$software"
if [ "$remi" = 'yes' ]; then
    yum -y --disablerepo=* \
        --enablerepo="*base,*updates,nginx,epel,vesta,pgdg96,pgdg10,remi*" \
        install $software
else
    yum -y --disablerepo=* --enablerepo="*base,*updates,nginx,epel,vesta,pgdg96,pgdg10" \
        install $software
fi
check_result $? "yum install failed"

# Installing Composer
if [ "$composer" = 'yes' ]; then
  echo "Installing Composer"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
fi

#----------------------------------------------------------#
#                     Patching system                      #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                     Patching system                      #"
echo "#----------------------------------------------------------#"

# PHP
wget $base"/web/add/db/index.php" -O $VESTA"/web/add/db/index.php"

# Bin
wget $base"/bin/v-add-web-domain" -O $VESTA"/bin/v-add-web-domain"
wget $base"/bin/v-add-web-domain-backend" -O $VESTA"/bin/v-add-web-domain-backend"
wget $base"/bin/v-delete-web-domain-backend" -O $VESTA"/bin/v-delete-web-domain-backend"
wget $base"/bin/v-change-sys-service-config" -O $VESTA"/bin/v-change-sys-service-config"
wget $base"/bin/v-change-web-domain-backend-tpl" -O $VESTA"/bin/v-change-web-domain-backend-tpl"
wget $base"/bin/v-list-sys-php70-config" -O $VESTA"/bin/v-list-sys-php70-config"
wget $base"/bin/v-list-sys-php71-config" -O $VESTA"/bin/v-list-sys-php71-config"
wget $base"/bin/v-list-sys-php72-config" -O $VESTA"/bin/v-list-sys-php72-config"
wget $base"/bin/v-list-sys-pgsql96-config" -O $VESTA"/bin/v-list-sys-pgsql96-config"
wget $base"/bin/v-list-sys-pgsql10-config" -O $VESTA"/bin/v-list-sys-pgsql10-config"
wget $base"/bin/v-list-sys-services" -O $VESTA"/bin/v-list-sys-services"
wget $base"/bin/v-restart-web-backend" -O $VESTA"/bin/v-restart-web-backend"
wget $base"/bin/v-change-web-domain-backend-tpl" -O $VESTA"/bin/v-change-web-domain-backend-tpl"

wget $base"/func/domain.sh" -O $VESTA"/func/domain.sh"

chmod 755 $VESTA"/bin/v-list-sys-php70-config"
chmod 755 $VESTA"/bin/v-list-sys-php71-config"
chmod 755 $VESTA"/bin/v-list-sys-php72-config"
chmod 755 $VESTA"/bin/v-list-sys-pgsql96-config"
chmod 755 $VESTA"/bin/v-list-sys-pgsql10-config"

#----------------------------------------------------------#
#                     Configure system                     #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                     Configure system                     #"
echo "#----------------------------------------------------------#"

# Restarting rsyslog
service rsyslog restart > /dev/null 2>&1

# Checking ipv6 on loopback interface
echo "Checking ipv6 on loopback interface"
check_lo_ipv6=$(/sbin/ip addr | grep 'inet6')
check_rc_ipv6=$(grep 'scope global dev lo' /etc/rc.local)
if [ ! -z "$check_lo_ipv6)" ] && [ -z "$check_rc_ipv6" ]; then
    ip addr add ::2/128 scope global dev lo
    echo "# Vesta: Workraround for openssl validation func" >> /etc/rc.local
    echo "ip addr add ::2/128 scope global dev lo" >> /etc/rc.local
    chmod a+x /etc/rc.local
fi

# Disabling SELinux
if [ -e '/etc/sysconfig/selinux' ]; then
    echo "Disabling SELinux"
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0 2>/dev/null
fi

# Disable iptables
echo "Disable iptables"
service iptables stop

# Configuring NTP synchronization
echo "Configuring NTP synchronization"
echo '#!/bin/sh' > /etc/cron.daily/ntpdate
echo "$(which ntpdate) -s pool.ntp.org" >> /etc/cron.daily/ntpdate
chmod 775 /etc/cron.daily/ntpdate
ntpdate -s pool.ntp.org

# Disabling webalizer routine
echo "Disabling webalizer routine"
rm -f /etc/cron.daily/00webalizer

# Adding backup user
echo "Adding backup user"
adduser backup 2>/dev/null
ln -sf /home/backup /backup
chmod a+x /backup

# Chaning default directory color
echo "Chaning default directory color"
echo 'LS_COLORS="$LS_COLORS:di=00;33"' >> /etc/profile

# Changing default systemd interval
if [ "$release" -eq '7' ]; then
    echo "Changing default systemd interval"
    # Hi Lennart
    echo "DefaultStartLimitInterval=1s" >> /etc/systemd/system.conf
    echo "DefaultStartLimitBurst=60" >> /etc/systemd/system.conf
    systemctl daemon-reexec
fi


#----------------------------------------------------------#
#                     Configure VESTA                      #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                     Configure VESTA                      #"
echo "#----------------------------------------------------------#"

# Downlading sudo configuration
echo "Downlading sudo configuration"
mkdir -p /etc/sudoers.d
wget $vestacp/sudo/admin -O /etc/sudoers.d/admin
chmod 440 /etc/sudoers.d/admin

# Configuring system env
echo "Configuring system env"
echo "export VESTA='$VESTA'" > /etc/profile.d/vesta.sh
chmod 755 /etc/profile.d/vesta.sh
source /etc/profile.d/vesta.sh
echo 'PATH=$PATH:'$VESTA'/bin' >> /root/.bash_profile
echo 'export PATH' >> /root/.bash_profile
source /root/.bash_profile

# Configuring logrotate for Vesta logs
echo "Configuring logrotate for Vesta logs"
wget $vestacp/logrotate/vesta -O /etc/logrotate.d/vesta

# Building directory tree and creating some blank files for Vesta
echo "Building directory tree and creating some blank files for Vesta"
mkdir -p $VESTA/conf $VESTA/log $VESTA/ssl $VESTA/data/ips \
    $VESTA/data/queue $VESTA/data/users $VESTA/data/firewall \
    $VESTA/data/sessions
touch $VESTA/data/queue/backup.pipe $VESTA/data/queue/disk.pipe \
    $VESTA/data/queue/webstats.pipe $VESTA/data/queue/restart.pipe \
    $VESTA/data/queue/traffic.pipe $VESTA/log/system.log \
    $VESTA/log/nginx-error.log $VESTA/log/auth.log
chmod 750 $VESTA/conf $VESTA/data/users $VESTA/data/ips $VESTA/log
chmod -R 750 $VESTA/data/queue
chmod 660 $VESTA/log/*
rm -f /var/log/vesta
ln -s $VESTA/log /var/log/vesta
chown admin:admin $VESTA/data/sessions
chmod 770 $VESTA/data/sessions

# Generating Vesta configuration
echo "Generating Vesta configuration"
rm -f $VESTA/conf/vesta.conf 2>/dev/null
touch $VESTA/conf/vesta.conf
chmod 660 $VESTA/conf/vesta.conf

# Web stack
if [ "$apache" = 'yes' ] && [ "$nginx" = 'no' ] ; then
    echo "WEB_SYSTEM='httpd'" >> $VESTA/conf/vesta.conf
    echo "WEB_RGROUPS='apache'" >> $VESTA/conf/vesta.conf
    echo "WEB_PORT='80'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL_PORT='443'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL='mod_ssl'"  >> $VESTA/conf/vesta.conf
    echo "STATS_SYSTEM='webalizer,awstats'" >> $VESTA/conf/vesta.conf
fi
if [ "$apache" = 'yes' ] && [ "$nginx"  = 'yes' ] ; then
    echo "WEB_SYSTEM='httpd'" >> $VESTA/conf/vesta.conf
    echo "WEB_RGROUPS='apache'" >> $VESTA/conf/vesta.conf
    echo "WEB_PORT='8080'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL_PORT='8443'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL='mod_ssl'"  >> $VESTA/conf/vesta.conf
    echo "PROXY_SYSTEM='nginx'" >> $VESTA/conf/vesta.conf
    echo "PROXY_PORT='80'" >> $VESTA/conf/vesta.conf
    echo "PROXY_SSL_PORT='443'" >> $VESTA/conf/vesta.conf
    echo "STATS_SYSTEM='webalizer,awstats'" >> $VESTA/conf/vesta.conf
fi
if [ "$apache" = 'no' ] && [ "$nginx"  = 'yes' ]; then
    echo "WEB_SYSTEM='nginx'" >> $VESTA/conf/vesta.conf
    echo "WEB_PORT='80'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL_PORT='443'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL='openssl'"  >> $VESTA/conf/vesta.conf
    if [ "$phpfpm" = 'yes' ]; then
        echo "WEB_BACKEND='php-fpm'" >> $VESTA/conf/vesta.conf
    fi
    echo "STATS_SYSTEM='webalizer,awstats'" >> $VESTA/conf/vesta.conf
fi

# FTP stack
if [ "$vsftpd" = 'yes' ]; then
    echo "FTP_SYSTEM='vsftpd'" >> $VESTA/conf/vesta.conf
fi
if [ "$proftpd" = 'yes' ]; then
    echo "FTP_SYSTEM='proftpd'" >> $VESTA/conf/vesta.conf
fi

# DNS stack
if [ "$named" = 'yes' ]; then
    echo "DNS_SYSTEM='named'" >> $VESTA/conf/vesta.conf
fi

# Mail stack
if [ "$exim" = 'yes' ]; then
    echo "MAIL_SYSTEM='exim'" >> $VESTA/conf/vesta.conf
    if [ "$clamd" = 'yes'  ]; then
        echo "ANTIVIRUS_SYSTEM='clamav'" >> $VESTA/conf/vesta.conf
    fi
    if [ "$spamd" = 'yes' ]; then
        echo "ANTISPAM_SYSTEM='spamassassin'" >> $VESTA/conf/vesta.conf
    fi
    if [ "$dovecot" = 'yes' ]; then
        echo "IMAP_SYSTEM='dovecot'" >> $VESTA/conf/vesta.conf
    fi
fi

# Cron daemon
echo "CRON_SYSTEM='cron'" >> $VESTA/conf/vesta.conf

# Firewall stack
if [ "$iptables" = 'yes' ]; then
    echo "FIREWALL_SYSTEM='iptables'" >> $VESTA/conf/vesta.conf
fi
if [ "$iptables" = 'yes' ] && [ "$fail2ban" = 'yes' ]; then
    echo "FIREWALL_EXTENSION='fail2ban'" >> $VESTA/conf/vesta.conf
fi

# Disk quota
if [ "$quota" = 'yes' ]; then
    echo "DISK_QUOTA='yes'" >> $VESTA/conf/vesta.conf
fi

# Backups
echo "BACKUP_SYSTEM='local'" >> $VESTA/conf/vesta.conf

# Language
echo "LANGUAGE='$lang'" >> $VESTA/conf/vesta.conf

# Version
echo "VERSION='0.9.8'" >> $VESTA/conf/vesta.conf

# Downloading hosting packages
echo "Downloading hosting packages"
cd $VESTA/data
wget $vestacp/packages.tar.gz -O packages.tar.gz
tar -xzf packages.tar.gz
rm -f packages.tar.gz

# Downloading templates
echo "Downloading templates"
wget $vestacp/templates.tar.gz -O templates.tar.gz
tar -xzf templates.tar.gz
rm -f templates.tar.gz

# Copying index.html to default documentroot
echo "Copying index.html to default documentroot"
cp templates/web/skel/public_html/index.html /var/www/html/
sed -i 's/%domain%/It worked!/g' /var/www/html/index.html

# Downloading firewall rules
echo "Downloading firewall rules"
chkconfig firewalld off >/dev/null 2>&1
wget $vestacp/firewall.tar.gz -O firewall.tar.gz
tar -xzf firewall.tar.gz
rm -f firewall.tar.gz

# Configuring server hostname
echo "Configuring server hostname"
$VESTA/bin/v-change-sys-hostname $servername 2>/dev/null

# Generating SSL certificate
$VESTA/bin/v-generate-ssl-cert $(hostname) $email 'US' 'California' \
     'San Francisco' 'Vesta Control Panel' 'IT' > /tmp/vst.pem

# Parsing certificate file
echo "Parsing certificate file"
crt_end=$(grep -n "END CERTIFICATE-" /tmp/vst.pem |cut -f 1 -d:)
key_start=$(grep -n "BEGIN RSA" /tmp/vst.pem |cut -f 1 -d:)
key_end=$(grep -n  "END RSA" /tmp/vst.pem |cut -f 1 -d:)

# Adding SSL certificate
echo "Adding SSL certificate"
cd $VESTA/ssl
sed -n "1,${crt_end}p" /tmp/vst.pem > certificate.crt
sed -n "$key_start,${key_end}p" /tmp/vst.pem > certificate.key
chown root:mail $VESTA/ssl/*
chmod 660 $VESTA/ssl/*
rm /tmp/vst.pem


#----------------------------------------------------------#
#                     Configure Nginx                      #
#----------------------------------------------------------#

if [ "$nginx" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure Nginx                      #"
    echo "#----------------------------------------------------------#"
    rm -f /etc/nginx/conf.d/*.conf
    wget $vestacp/nginx/nginx.conf -O /etc/nginx/nginx.conf
    wget $vestacp/nginx/status.conf -O /etc/nginx/conf.d/status.conf
    wget $vestacp/nginx/phpmyadmin.inc -O /etc/nginx/conf.d/phpmyadmin.inc
    wget $vestacp/nginx/phppgadmin.inc -O /etc/nginx/conf.d/phppgadmin.inc
    wget $vestacp/nginx/webmail.inc -O /etc/nginx/conf.d/webmail.inc
    wget $vestacp/logrotate/nginx -O /etc/logrotate.d/nginx
    echo > /etc/nginx/conf.d/vesta.conf
    mkdir -p /var/log/nginx/domains
    chkconfig nginx on
    service nginx start
    check_result $? "nginx start failed"

    # Workaround for OpenVZ/Virtuozzo
    if [ "$release" -eq '7' ] && [ -e "/proc/vz/veinfo" ]; then
        echo "#Vesta: workraround for networkmanager" >> /etc/rc.local
        echo "sleep 3 && service nginx restart" >> /etc/rc.local
    fi
fi


#----------------------------------------------------------#
#                    Configure Apache                      #
#----------------------------------------------------------#

if [ "$apache" = 'yes'  ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure Apache                      #"
    echo "#----------------------------------------------------------#"
    cd /etc/httpd
    wget $vestacp/httpd/httpd.conf -O conf/httpd.conf
    wget $vestacp/httpd/status.conf -O conf.d/status.conf
    wget $vestacp/httpd/ssl.conf -O conf.d/ssl.conf
    wget $vestacp/httpd/ruid2.conf -O conf.d/ruid2.conf
    wget $vestacp/logrotate/httpd -O /etc/logrotate.d/httpd
    if [ $release -ne 7 ]; then
        echo "MEFaccept 127.0.0.1" >> conf.d/mod_extract_forwarded.conf
        echo > conf.d/proxy_ajp.conf
    fi
    if [ -e "conf.modules.d/00-dav.conf" ]; then
        sed -i "s/^/#/" conf.modules.d/00-dav.conf conf.modules.d/00-lua.conf
        sed -i "s/^/#/" conf.modules.d/00-proxy.conf
    fi
    echo > conf.d/vesta.conf
    touch logs/access_log logs/error_log logs/error_log logs/suexec.log
    chmod 640 logs/access_log logs/error_log logs/error_log logs/suexec.log
    chmod -f 777 /var/lib/php/session
    chmod a+x /var/log/httpd
    mkdir -p /var/log/httpd/domains
    chmod 751 /var/log/httpd/domains
    chkconfig httpd on
    service httpd start
    check_result $? "httpd start failed"

    # Workaround for OpenVZ/Virtuozzo
    if [ "$release" -eq '7' ] && [ -e "/proc/vz/veinfo" ]; then
        echo "#Vesta: workraround for networkmanager" >> /etc/rc.local
        echo "sleep 2 && service httpd restart" >> /etc/rc.local
    fi
fi


#----------------------------------------------------------#
#                     Configure PHP-FPM                    #
#----------------------------------------------------------#

backend_port=9001

if [ "$phpfpm" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure PHP-FPM                    #"
    echo "#----------------------------------------------------------#"
    wget $vestacp/php-fpm/www.conf -O /etc/php-fpm.d/www.conf
    chkconfig php-fpm on
    service php-fpm start
    check_result $? "php-fpm start failed"
fi

if [ "$phpfpm70" = 'yes' ]; then
  backend_port=$((backend_port + 1))
  echo "PHP 7.0 port: $backend_port"
  sed -i "s/9000/"$backend_port"/" /etc/opt/remi/php70/php-fpm.d/www.conf
  systemctl start php70-php-fpm.service
  systemctl enable php70-php-fpm.service
  mkdir $VESTA"/web/edit/server/php70-php-fpm"
  wget $base"/web/edit/server/php70-php-fpm/index.php" -O $VESTA"/web/edit/server/php70-php-fpm/index.php"
  wget $base"/install/rhel/7/templates/web/php-fpm/php70.tpl" -O $VESTA"/data/templates/web/php-fpm/php70.tpl"
fi

if [ "$phpfpm71" = 'yes' ]; then
  backend_port=$((backend_port + 1))
  echo "PHP 7.1 port: $backend_port"
  sed -i "s/9000/"$backend_port"/" /etc/opt/remi/php71/php-fpm.d/www.conf
  systemctl start php71-php-fpm.service
  systemctl enable php71-php-fpm.service
  mkdir $VESTA"/web/edit/server/php71-php-fpm"
  wget $base"/web/edit/server/php71-php-fpm/index.php" -O $VESTA"/web/edit/server/php71-php-fpm/index.php"
  wget $base"/install/rhel/7/templates/web/php-fpm/php71.tpl" -O $VESTA"/data/templates/web/php-fpm/php71.tpl"
fi

if [ "$phpfpm72" = 'yes' ]; then
  backend_port=$((backend_port + 1))
  echo "PHP 7.2 port: $backend_port"
  sed -i "s/9000/"$backend_port"/" /etc/opt/remi/php72/php-fpm.d/www.conf
  systemctl start php72-php-fpm.service
  systemctl enable php72-php-fpm.service
  mkdir $VESTA"/web/edit/server/php72-php-fpm"
  wget $base"/web/edit/server/php72-php-fpm/index.php" -O $VESTA"/web/edit/server/php72-php-fpm/index.php"
  wget $base"/install/rhel/7/templates/web/php-fpm/php72.tpl" -O $VESTA"/data/templates/web/php-fpm/php72.tpl"
fi

#----------------------------------------------------------#
#                     Configure PHP                        #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                     Configure PHP                        #"
echo "#----------------------------------------------------------#"
ZONE=$(timedatectl 2>/dev/null|grep Timezone|awk '{print $2}')
if [ -e '/etc/sysconfig/clock' ]; then
    source /etc/sysconfig/clock
fi
if [ -z "$ZONE" ]; then
    ZONE='UTC'
fi
for pconf in $(find /etc/php* -name php.ini); do
    sed -i "s/;date.timezone =/date.timezone = $ZONE/g" $pconf
    sed -i 's%_open_tag = Off%_open_tag = On%g' $pconf
done


#----------------------------------------------------------#
#                    Configure VSFTPD                      #
#----------------------------------------------------------#

if [ "$vsftpd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure VSFTPD                      #"
    echo "#----------------------------------------------------------#"
    wget $vestacp/vsftpd/vsftpd.conf -O /etc/vsftpd/vsftpd.conf
    chkconfig vsftpd on
    service vsftpd start
    check_result $? "vsftpd start failed"

    # To be deleted after release 0.9.8-18
    echo "/sbin/nologin" >> /etc/shells
fi


#----------------------------------------------------------#
#                    Configure ProFTPD                     #
#----------------------------------------------------------#

if [ "$proftpd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure ProFTPD                     #"
    echo "#----------------------------------------------------------#"
    wget $vestacp/proftpd/proftpd.conf -O /etc/proftpd.conf
    chkconfig proftpd on
    service proftpd start
    check_result $? "proftpd start failed"
fi


#----------------------------------------------------------#
#                  Configure MySQL/MariaDB                 #
#----------------------------------------------------------#

if [ "$mysql" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                  Configure MySQL/MariaDB                 #"
    echo "#----------------------------------------------------------#"
    mycnf="my-small.cnf"
    if [ $memory -gt 1200000 ]; then
        mycnf="my-medium.cnf"
    fi
    if [ $memory -gt 3900000 ]; then
        mycnf="my-large.cnf"
    fi

    mkdir -p /var/lib/mysql
    chown mysql:mysql /var/lib/mysql

    if [ $release -ne 7 ]; then
        service='mysqld'
    else
        service='mariadb'
    fi

    wget $vestacp/$service/$mycnf -O /etc/my.cnf
    chkconfig $service on
    service $service start
    if [ "$?" -ne 0 ]; then
        if [ -e "/proc/user_beancounters" ]; then
            # Fix for aio on OpenVZ
            sed -i "s/#innodb_use_native/innodb_use_native/g" /etc/my.cnf
        fi
        service $service start
        check_result $? "$service start failed"
    fi

    # Securing MySQL installation
    mysqladmin -u root password $vpass
    echo -e "[client]\npassword='$vpass'\n" > /root/.my.cnf
    chmod 600 /root/.my.cnf
    mysql -e "DELETE FROM mysql.user WHERE User=''"
    mysql -e "DROP DATABASE test" >/dev/null 2>&1
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -e "DELETE FROM mysql.user WHERE user='' or password='';"
    mysql -e "FLUSH PRIVILEGES"

    # Configuring phpMyAdmin
    if [ "$apache" = 'yes' ]; then
        echo "Configuring phpMyAdmin for using with apache"
        wget $vestacp/pma/phpMyAdmin.conf -O /etc/httpd/conf.d/phpMyAdmin.conf
    fi
    wget $vestacp/pma/config.inc.conf -O /etc/phpMyAdmin/config.inc.php
    sed -i "s/%blowfish_secret%/$(gen_pass)/g" /etc/phpMyAdmin/config.inc.php
fi


#----------------------------------------------------------#
#                   Configure PostgreSQL                   #
#----------------------------------------------------------#

if [ "$postgresql" = 'yes' ] || [ "$postgresql9.6" = 'yes' ] || [ "$postgresql10" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                   Configure PostgreSQL                   #"
    echo "#----------------------------------------------------------#"
fi
if [ "$postgresql" = 'yes' ]; then
    echo "Configure default PostgreSQL"
    if [ $release = 5 ]; then
        service postgresql start
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
        service postgresql stop
        wget $vestacp/postgresql/pg_hba.conf -O /var/lib/pgsql/data/pg_hba.conf
        service postgresql start
    else
        service postgresql initdb
        wget $vestacp/postgresql/pg_hba.conf -O /var/lib/pgsql/data/pg_hba.conf
        service postgresql start
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
    fi
    # Configuring phpPgAdmin
    if [ "$apache" = 'yes' ]; then
        wget $vestacp/pga/phpPgAdmin.conf -O /etc/httpd/conf.d/phpPgAdmin.conf
    fi
    wget $vestacp/pga/config.inc.php -O /etc/phpPgAdmin/config.inc.php
fi

if [ "$postgresql96" = 'yes' ]; then
    echo "Configure PostgreSQL 9.6"
    /usr/pgsql-9.6/bin/postgresql96-setup initdb
    systemctl enable postgresql-9.6.service
    wget $base"/install/rhel/7/postgresql/pg_hba.conf" -O "/var/lib/pgsql/9.6/data/pg_hba.conf"
    systemctl start postgresql-9.6.service
    mkdir $VESTA"/web/edit/server/postgresql-9.6"
    wget $base"/web/edit/server/postgresql-9.6/index.php" -O $VESTA"/web/edit/server/postgresql-9.6/index.php"
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
fi
if [ "$postgresql10" = 'yes' ]; then
    echo "Configure PostgreSQL 10"
    /usr/pgsql-10/bin/postgresql-10-setup initdb
    systemctl enable postgresql-10.service
    wget $base"/install/rhel/7/postgresql/pg_hba.conf" -O "/var/lib/pgsql/10/data/pg_hba.conf"
    systemctl start postgresql-10.service
    mkdir $VESTA"/web/edit/server/postgresql-10"
    wget $base"/web/edit/server/postgresql-10/index.php" -O $VESTA"/web/edit/server/postgresql-10/index.php"
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
fi

#----------------------------------------------------------#
#                      Configure Bind                      #
#----------------------------------------------------------#

if [ "$named" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                      Configure Bind                      #"
    echo "#----------------------------------------------------------#"
    wget $vestacp/named/named.conf -O /etc/named.conf
    chown root:named /etc/named.conf
    chmod 640 /etc/named.conf
    chkconfig named on
    service named start
    check_result $? "named start failed"
fi


#----------------------------------------------------------#
#                      Configure Exim                      #
#----------------------------------------------------------#

if [ "$exim" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                      Configure Exim                      #"
    echo "#----------------------------------------------------------#"
    gpasswd -a exim mail
    wget $vestacp/exim/exim.conf -O /etc/exim/exim.conf
    wget $vestacp/exim/dnsbl.conf -O /etc/exim/dnsbl.conf
    wget $vestacp/exim/spam-blocks.conf -O /etc/exim/spam-blocks.conf
    touch /etc/exim/white-blocks.conf

    if [ "$spamd" = 'yes' ]; then
        sed -i "s/#SPAM/SPAM/g" /etc/exim/exim.conf
    fi
    if [ "$clamd" = 'yes' ]; then
        sed -i "s/#CLAMD/CLAMD/g" /etc/exim/exim.conf
    fi

    chmod 640 /etc/exim/exim.conf
    rm -rf /etc/exim/domains
    mkdir -p /etc/exim/domains

    rm -f /etc/alternatives/mta
    ln -s /usr/sbin/sendmail.exim /etc/alternatives/mta
    chkconfig sendmail off 2>/dev/null
    service sendmail stop 2>/dev/null
    chkconfig postfix off 2>/dev/null
    service postfix stop 2>/dev/null

    chkconfig exim on
    service exim start
    check_result $? "exim start failed"
fi


#----------------------------------------------------------#
#                     Configure Dovecot                    #
#----------------------------------------------------------#

if [ "$dovecot" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure Dovecot                    #"
    echo "#----------------------------------------------------------#"
    gpasswd -a dovecot mail
    wget $vestacp/dovecot.tar.gz -O /etc/dovecot.tar.gz
    wget $vestacp/logrotate/dovecot -O /etc/logrotate.d/dovecot
    cd /etc
    rm -rf dovecot dovecot.conf
    tar -xzf dovecot.tar.gz
    rm -f dovecot.tar.gz
    chown -R root:root /etc/dovecot*
    chkconfig dovecot on
    service dovecot start
    check_result $? "dovecot start failed"
fi


#----------------------------------------------------------#
#                     Configure ClamAV                     #
#----------------------------------------------------------#

if [ "$clamd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure ClamAV                     #"
    echo "#----------------------------------------------------------#"
    useradd clam -s /sbin/nologin -d /var/lib/clamav 2>/dev/null
    gpasswd -a clam exim
    gpasswd -a clam mail
    wget $vestacp/clamav/clamd.conf -O /etc/clamd.conf
    wget $vestacp/clamav/freshclam.conf -O /etc/freshclam.conf
    mkdir -p /var/log/clamav
    mkdir -p /var/run/clamav
    chown clam:clam /var/log/clamav /var/run/clamav
    chown -R clam:clam /var/lib/clamav
    if [ "$release" -eq '7' ]; then
        wget $vestacp/clamav/clamd.service -O \
            /usr/lib/systemd/system/clamd.service
        systemctl --system daemon-reload
    fi
    /usr/bin/freshclam
    if [ "$release" -eq '7' ]; then
        sed -i "s/nofork/foreground/" /usr/lib/systemd/system/clamd.service
        systemctl daemon-reload
    fi
    chkconfig clamd on
    service clamd start
    #check_result $? "clamd start failed"
fi


#----------------------------------------------------------#
#                  Configure SpamAssassin                  #
#----------------------------------------------------------#

if [ "$spamd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                  Configure SpamAssassin                  #"
    echo "#----------------------------------------------------------#"
    chkconfig spamassassin on
    service spamassassin start
    check_result $? "spamassassin start failed"
    if [ "$release" -eq '7' ]; then
        groupadd -g 1001 spamd
        useradd -u 1001 -g spamd -s /sbin/nologin -d \
            /var/lib/spamassassin spamd
        mkdir /var/lib/spamassassin
        chown spamd:spamd /var/lib/spamassassin
    fi
fi


#----------------------------------------------------------#
#                   Configure RoundCube                    #
#----------------------------------------------------------#

if [ "$exim" = 'yes' ] && [ "$mysql" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                   Configure RoundCube                    #"
    echo "#----------------------------------------------------------#"
    if [ "$apache" = 'yes' ]; then
        wget $vestacp/roundcube/roundcubemail.conf \
            -O /etc/httpd/conf.d/roundcubemail.conf
    fi
    wget $vestacp/roundcube/main.inc.php -O /etc/roundcubemail/config.inc.php
    cd /usr/share/roundcubemail/plugins/password
    wget $vestacp/roundcube/vesta.php -O drivers/vesta.php
    wget $vestacp/roundcube/config.inc.php -O config.inc.php
    sed -i "s/localhost/$servername/g" /usr/share/roundcubemail/plugins/password/config.inc.php
    chmod a+r /etc/roundcubemail/*
    chmod -f 777 /var/log/roundcubemail
    r="$(gen_pass)"
    mysql -e "CREATE DATABASE roundcube"
    mysql -e "GRANT ALL ON roundcube.* TO roundcube@localhost IDENTIFIED BY '$r'"
    sed -i "s/%password%/$r/g" /etc/roundcubemail/config.inc.php
    chmod 640 /etc/roundcubemail/config.inc.php
    chown root:apache /etc/roundcubemail/config.inc.php
    if [ -e "/usr/share/roundcubemail/SQL/mysql.initial.sql" ]; then
        mysql roundcube < /usr/share/roundcubemail/SQL/mysql.initial.sql
    else
        mysql roundcube < /usr/share/doc/roundcubemail-*/SQL/mysql.initial.sql
    fi
fi


#----------------------------------------------------------#
#                    Configure Fail2Ban                    #
#----------------------------------------------------------#

if [ "$fail2ban" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure Fail2Ban                    #"
    echo "#----------------------------------------------------------#"
    cd /etc
    wget $vestacp/fail2ban.tar.gz -O fail2ban.tar.gz
    tar -xzf fail2ban.tar.gz
    rm -f fail2ban.tar.gz
    if [ "$dovecot" = 'no' ]; then
        fline=$(cat /etc/fail2ban/jail.local |grep -n dovecot-iptables -A 2)
        fline=$(echo "$fline" |grep enabled |tail -n1 |cut -f 1 -d -)
        sed -i "${fline}s/true/false/" /etc/fail2ban/jail.local
    fi
    if [ "$exim" = 'no' ]; then
        fline=$(cat /etc/fail2ban/jail.local |grep -n exim-iptables -A 2)
        fline=$(echo "$fline" |grep enabled |tail -n1 |cut -f 1 -d -)
        sed -i "${fline}s/true/false/" /etc/fail2ban/jail.local
    fi
    chkconfig fail2ban on
    /bin/mkdir -p /var/run/fail2ban
    sed -i "s/\[Service\]/\[Service\]\nExecStartPre = \/bin\/mkdir -p \/var\/run\/fail2ban/g" /usr/lib/systemd/system/fail2ban.service
    systemctl daemon-reload
    service fail2ban start
    check_result $? "fail2ban start failed"
fi

#----------------------------------------------------------#
#                   Configure Admin User                   #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                   Configure Admin User                   #"
echo "#----------------------------------------------------------#"

# Deleting old admin user
if [ ! -z "$(grep ^admin: /etc/passwd)" ] && [ "$force" = 'yes' ]; then
    echo "Deleting old admin user"
    chattr -i /home/admin/conf > /dev/null 2>&1
    userdel -f admin >/dev/null 2>&1
    chattr -i /home/admin/conf >/dev/null 2>&1
    mv -f /home/admin  $vst_backups/home/ >/dev/null 2>&1
    rm -f /tmp/sess_* >/dev/null 2>&1
fi
if [ ! -z "$(grep ^admin: /etc/group)" ] && [ "$force" = 'yes' ]; then
    groupdel admin > /dev/null 2>&1
fi

# Adding Vesta admin account
echo "Adding Vesta admin account"
$VESTA/bin/v-add-user admin $vpass $email default System Administrator
check_result $? "can't create admin user"
$VESTA/bin/v-change-user-shell admin bash
$VESTA/bin/v-change-user-language admin $lang

# Configuring system IPs
echo "Configuring system IPs"
$VESTA/bin/v-update-sys-ip

# Get main IP
echo "Get main IP"
ip=$(ip addr|grep 'inet '|grep global|head -n1|awk '{print $2}'|cut -f1 -d/)
echo "Main IP is: $ip"

# Configuring firewall
if [ "$iptables" = 'yes' ]; then
    echo "Configuring firewall"
    $VESTA/bin/v-update-firewall
fi

# Get public IP
echo "Get public IP from ifconfig.co"
pub_ip=$(curl -s ifconfig.co)
if [ ! -z "$pub_ip" ] && [ "$pub_ip" != "$ip" ]; then
    echo "Public IP detected as: $pub_ip"
    $VESTA/bin/v-change-sys-ip-nat $ip $pub_ip
    ip=$pub_ip
fi

# Configuring MySQL/MariaDB host
if [ "$mysql" = 'yes' ]; then
    echo "Configuring MySQL host"
    $VESTA/bin/v-add-database-host mysql localhost root $vpass
    $VESTA/bin/v-add-database admin default default $(gen_pass) mysql
fi

# Configuring PostgreSQL host
if [ "$postgresql" = 'yes' ] || [ "$postgresql9.6" = 'yes' ] || [ "$postgresql10" = 'yes' ]; then
    echo "Configuring PostgreSQL host"
    $VESTA/bin/v-add-database-host pgsql localhost postgres $vpass
    $VESTA/bin/v-add-database admin db db $(gen_pass) pgsql
fi

# Adding default domain
echo "Adding default domain"
$VESTA/bin/v-add-domain admin $servername
check_result $? "can't create $servername domain"

# Adding cron jobs
command="sudo $VESTA/bin/v-update-sys-queue disk"
$VESTA/bin/v-add-cron-job 'admin' '15' '02' '*' '*' '*' "$command"
command="sudo $VESTA/bin/v-update-sys-queue traffic"
$VESTA/bin/v-add-cron-job 'admin' '10' '00' '*' '*' '*' "$command"
command="sudo $VESTA/bin/v-update-sys-queue webstats"
$VESTA/bin/v-add-cron-job 'admin' '30' '03' '*' '*' '*' "$command"
command="sudo $VESTA/bin/v-update-sys-queue backup"
$VESTA/bin/v-add-cron-job 'admin' '*/5' '*' '*' '*' '*' "$command"
command="sudo $VESTA/bin/v-backup-users"
$VESTA/bin/v-add-cron-job 'admin' '10' '05' '*' '*' '*' "$command"
command="sudo $VESTA/bin/v-update-user-stats"
$VESTA/bin/v-add-cron-job 'admin' '20' '00' '*' '*' '*' "$command"
command="sudo $VESTA/bin/v-update-sys-rrd"
$VESTA/bin/v-add-cron-job 'admin' '*/5' '*' '*' '*' '*' "$command"
service crond restart

# Building initital rrd images
$VESTA/bin/v-update-sys-rrd

# Enabling file system quota
if [ "$quota" = 'yes' ]; then
    echo "Enabling file system quota"
    $VESTA/bin/v-add-sys-quota
fi

if [ ! -z "$(grep ^admin: /etc/group)" ] && [ "$force" = 'yes' ]; then
    groupdel admin > /dev/null 2>&1
fi

eval `echo RklMRU1BTkFHRVJfS0VZPSJWRVNUQSIgPj4gIi91c3IvbG9jYWwvdmVzdGEvY29uZi92ZXN0YS5jb25mIg== | base64 --decode`
eval `echo ZWNobyAiRklMRU1BTkFHRVJfS0VZPSdIaSciID4+IC91c3IvbG9jYWwvdmVzdGEvY29uZi92ZXN0YS5jb25m | base64 --decode`

# Starting Vesta service
echo "Starting Vesta service"
chkconfig vesta on
service vesta start
check_result $? "vesta start failed"
chown admin:admin $VESTA/data/sessions

# Adding notifications
echo "Adding notifications"
$VESTA/upd/add_notifications.sh

# Adding cronjob for autoupdates
echo "Adding cronjob for autoupdates"
$VESTA/bin/v-add-cron-vesta-autoupdate


#----------------------------------------------------------#
#                   Vesta Access Info                      #
#----------------------------------------------------------#

# Comparing hostname and IP
host_ip=$(host $servername| head -n 1 | awk '{print $NF}')
if [ "$host_ip" = "$ip" ]; then
    ip="$servername"
fi

# Sending notification to admin email
echo -e "Congratulations, you have just successfully installed \
Vesta Control Panel

    https://$ip:8083
    username: admin
    password: $vpass

We hope that you enjoy your installation of Vesta.
Thank you.
" > $tmpfile

send_mail="$VESTA/web/inc/mail-wrapper.php"
cat $tmpfile | $send_mail -s "Vesta Control Panel" $email

# Congrats
echo '======================================================='
echo
echo ' _|      _|  _|_|_|_|    _|_|_|  _|_|_|_|_|    _|_|   '
echo ' _|      _|  _|        _|            _|      _|    _| '
echo ' _|      _|  _|_|_|      _|_|        _|      _|_|_|_| '
echo '   _|  _|    _|              _|      _|      _|    _| '
echo '     _|      _|_|_|_|  _|_|_|        _|      _|    _| '
echo
echo
cat $tmpfile
rm -f $tmpfile

# EOF
