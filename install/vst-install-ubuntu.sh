#!/bin/bash

# Vesta Ubuntu installer v.05s

#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
export PATH=$PATH:/sbin
export DEBIAN_FRONTEND=noninteractive
RHOST='apt.vestacp.com'
CHOST='c.vestacp.com'
VERSION='ubuntu'
VESTA='/usr/local/vesta'
memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
arch=$(uname -i)
os='ubuntu'
release="$(lsb_release -s -r)"
codename="$(lsb_release -s -c)"
vestacp="$VESTA/install/$VERSION/$release"
base='https://raw.githubusercontent.com/stasisha/vesta/master'

# Defining software pack for all distros
software="apache2 apache2.2-common apache2-suexec-custom apache2-utils
    apparmor-utils awstats bc bind9 bsdmainutils bsdutils clamav-daemon
    cron curl dnsutils dovecot-imapd dovecot-pop3d e2fslibs e2fsprogs exim4
    exim4-daemon-heavy expect fail2ban flex ftp git idn imagemagick
    libapache2-mod-fcgid libapache2-mod-php libapache2-mod-rpaf
    libapache2-mod-ruid2 lsof mc mysql-client mysql-common mysql-server nginx
    ntpdate php-cgi php-common php-curl php-fpm phpmyadmin php-mysql
    phppgadmin php-pgsql postgresql postgresql-contrib proftpd-basic quota
    roundcube-core roundcube-mysql roundcube-plugins rrdtool rssh spamassassin
    sudo vesta vesta-ioncube vesta-nginx vesta-php vesta-softaculous
    vim-common vsftpd webalizer whois zip postgresql-9.6 postgresql-10 git mc
    libapache2-mod-php7.0 php7.0 php7.0-common php7.0-cgi
    php7.0-mysql php7.0-curl php7.0-fpm php7.0-pgsql php7.1 php7.1-common php7.1-cgi
    php7.1-mysql php7.1-curl php7.1-fpm php7.1-pgsql php7.2 php7.2-common php7.2-cgi
    php7.2-mysql php7.2-curl php7.2-fpm php7.2-pgsql"

# Fix for old releases
if [[ ${release:0:2} -lt 16 ]]; then
    software=$(echo "$software" |sed -e "s/php /php5 /g")
    software=$(echo "$software" |sed -e "s/vesta-php5 /vesta-php /g")
    software=$(echo "$software" |sed -e "s/php-/php5-/g")
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
  -o,  --softaculous       Install Softaculous   [yes|no]  default: yes
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

# Defining return code check function
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

# Defining function to set default language value
set_default_lang() {
    if [ -z "$lang" ]; then
        eval lang=$1
    fi
    lang_list="
        ar cz el fa hu ja no pt se ua
        bs da en fi id ka pl ro tr vi
        cn de es fr it nl pt-BR ru tw
        bg ko sr th ur"
    if !(echo $lang_list |grep -w $lang 1>&2>/dev/null); then
        eval lang=$1
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
        --softaculous)          args="${args}-o  " ;;
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
while getopts "a:n:w:w70:w71:w72:v:j:k:m:g:g96:g10:d:x:z:c:t:i:b:r:o:q:gt:co:mc:l:y:s:e:p:fh" Option; do
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
        o)   softaculous=$OPTARG ;;       # Softaculous plugin
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
set_default_value 'softaculous' 'yes'
set_default_value 'quota' 'no'
set_default_value 'git' 'yes'
set_default_value 'composer' 'yes'
set_default_value 'mc' 'yes'
set_default_value 'lang' 'en'
set_default_value 'interactive' 'yes'
set_default_lang 'en'

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

echo "Checking root permissions"
if [ "x$(id -u)" != 'x0' ]; then
    check_error 1 "Script can be run executed only by root"
fi

echo "Checking admin user account"
if [ ! -z "$(grep ^admin: /etc/passwd /etc/group)" ] && [ -z "$force" ]; then
    echo 'Please remove admin user account before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo -e "Example: bash $0 --force\n"
    check_result 1 "User admin exists"
fi

echo "Checking wget"
if [ ! -e '/usr/bin/wget' ]; then
    echo "Installing wget"
    apt-get -y install wget
    check_result $? "Can't install wget"
fi

echo "Checking repository availability"
wget -q "c.vestacp.com/deb_signing.key" -O /dev/null
check_result $? "No access to Vesta repository"

echo "Checking installed packages"
tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > $tmpfile
for pkg in exim4 mysql-server apache2 nginx vesta; do
    if [ ! -z "$(grep $pkg $tmpfile)" ]; then
        conflicts="$pkg $conflicts"
    fi
done
rm -f $tmpfile
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

echo 'The following software will be installed on your system:'

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

# Mail stack
if [ "$exim" = 'yes' ]; then
    echo -n '   - Exim Mail Server'
    if [ "$clamd" = 'yes'  ] ||  [ "$spamd" = 'yes' ] ; then
        echo -n ' + '
        if [ "$clamd" = 'yes' ]; then
            echo -n 'ClamAV'
        fi
        if [ "$spamd" = 'yes' ]; then
            echo -n 'SpamAssassin'
        fi
    fi
    echo
    if [ "$dovecot" = 'yes' ]; then
        echo '   - Dovecot POP3/IMAP Server'
    fi
fi

# Database stack
if [ "$mysql" = 'yes' ]; then
    echo '   - MySQL Database Server'
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

# Softaculous
if [ "$softaculous" = 'yes' ]; then
    echo '   - Softaculous Plugin'
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
echo ""
echo "Installation backup directory: $vst_backups"

# Printing start message and sleeping for 5 seconds
echo -e "\n\n\n\nInstallation will take about 15 minutes ...\n"
sleep 5


#----------------------------------------------------------#
#                      Checking swap                       #
#----------------------------------------------------------#

# Checking swap on small instances
if [ -z "$(swapon -s)" ] && [ $memory -lt 1000000 ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
fi


echo "#----------------------------------------------------------#"
echo "#                  Install repositories                    #"
echo "#----------------------------------------------------------#"

# Updating system
apt-get -y upgrade
check_result $? 'apt-get upgrade failed'

# Installing nginx repo
apt=/etc/apt/sources.list.d
echo "deb http://nginx.org/packages/mainline/ubuntu/ $codename nginx" \
    > $apt/nginx.list
wget http://nginx.org/keys/nginx_signing.key -O /tmp/nginx_signing.key
apt-key add /tmp/nginx_signing.key

# Installing vesta repo
echo "deb http://$RHOST/$codename/ $codename vesta" > $apt/vesta.list
wget $CHOST/deb_signing.key -O deb_signing.key
apt-key add deb_signing.key

# Installing postgresql9.6 repository
add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $codename-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add

# Installing php repository
add-apt-repository -y ppa:ondrej/php


echo "#----------------------------------------------------------#"
echo "#                         Backup                           #"
echo "#----------------------------------------------------------#"

echo "Creating backup directory tree"
mkdir -p $vst_backups
cd $vst_backups
mkdir nginx apache2 php vsftpd proftpd bind exim4 dovecot clamd
mkdir spamassassin mysql postgresql mongodb vesta pgsql9.6

echo "Backing up nginx configuration"
service nginx stop > /dev/null 2>&1
cp -r /etc/nginx/* $vst_backups/nginx >/dev/null 2>&1

echo "Backing up Apache configuration"
service apache2 stop > /dev/null 2>&1
cp -r /etc/apache2/* $vst_backups/apache2 > /dev/null 2>&1
rm -f /etc/apache2/conf.d/* > /dev/null 2>&1

echo "Backing up PHP configuration"
service php7.0-fpm stop > /dev/null 2>&1
service php7.1-fpm stop > /dev/null 2>&1
service php7.2-fpm stop > /dev/null 2>&1
service php5-fpm stop > /dev/null 2>&1
service php-fpm stop > /dev/null 2>&1
cp -r /etc/php7.2/* $vst_backups/php/ > /dev/null 2>&1
cp -r /etc/php7.1/* $vst_backups/php/ > /dev/null 2>&1
cp -r /etc/php7.0/* $vst_backups/php/ > /dev/null 2>&1
cp -r /etc/php5/* $vst_backups/php/ > /dev/null 2>&1
cp -r /etc/php/* $vst_backups/php/ > /dev/null 2>&1

echo "Backing up Bind configuration"
service bind9 stop > /dev/null 2>&1
cp -r /etc/bind/* $vst_backups/bind > /dev/null 2>&1

echo "Backing up Vsftpd configuration"
service vsftpd stop > /dev/null 2>&1
cp /etc/vsftpd.conf $vst_backups/vsftpd > /dev/null 2>&1

echo "Backing up ProFTPD configuration"
service proftpd stop > /dev/null 2>&1
cp /etc/proftpd.conf $vst_backups/proftpd > /dev/null 2>&1

# Backup Exim configuration
echo "Backing up Exim configuration"
service exim4 stop > /dev/null 2>&1
cp -r /etc/exim4/* $vst_backups/exim4 > /dev/null 2>&1

echo "Backing up ClamAV configuration"
service clamav-daemon stop > /dev/null 2>&1
cp -r /etc/clamav/* $vst_backups/clamav > /dev/null 2>&1

echo "Backing up SpamAssassin configuration"
service spamassassin stop > /dev/null 2>&1
cp -r /etc/spamassassin/* $vst_backups/spamassassin > /dev/null 2>&1

echo "Backing up Dovecot configuration"
service dovecot stop > /dev/null 2>&1
cp /etc/dovecot.conf $vst_backups/dovecot > /dev/null 2>&1
cp -r /etc/dovecot/* $vst_backups/dovecot > /dev/null 2>&1

echo "Backing up MySQL/MariaDB configuration and data"
service mysql stop > /dev/null 2>&1
killall -9 mysqld > /dev/null 2>&1
mv /var/lib/mysql $vst_backups/mysql/mysql_datadir > /dev/null 2>&1
cp -r /etc/mysql/* $vst_backups/mysql > /dev/null 2>&1
mv -f /root/.my.cnf $vst_backups/mysql > /dev/null 2>&1
if [ "$release" = '16.04' ] && [ -e '/etc/init.d/mysql' ]; then
    mkdir -p /var/lib/mysql > /dev/null 2>&1
    chown mysql:mysql /var/lib/mysql
    mysqld --initialize-insecure
fi

echo "Backing up PostgreSQL configuration and data"
service postgresql stop > /dev/null 2>&1
service postgresql-9.6 stop > /dev/null 2>&1
service postgresql-10 stop > /dev/null 2>&1
mv /var/lib/pgsql/data $vst_backups/postgresql/  >/dev/null 2>&1
mv /var/lib/pgsql/9.6 $vst_backups/postgresql9.6/  >/dev/null 2>&1
mv /var/lib/pgsql/10 $vst_backups/postgresql10/  >/dev/null 2>&1

echo "Backing up Vesta configuration and data"
service vesta stop > /dev/null 2>&1
cp -r $VESTA/* $vst_backups/vesta > /dev/null 2>&1
apt-get -y remove vesta vesta-nginx vesta-php > /dev/null 2>&1
apt-get -y purge vesta vesta-nginx vesta-php > /dev/null 2>&1
rm -rf $VESTA > /dev/null 2>&1


#----------------------------------------------------------#
#                     Package Excludes                     #
#----------------------------------------------------------#

# Excluding packages
if [ "$release" != "15.04" ] && [ "$release" != "15.04" ]; then
    software=$(echo "$software" | sed -e "s/apache2.2-common//")
fi

if [ "$nginx" = 'no'  ]; then
    software=$(echo "$software" | sed -e "s/^nginx//")
fi
if [ "$apache" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/apache2 //")
    software=$(echo "$software" | sed -e "s/apache2-utils//")
    software=$(echo "$software" | sed -e "s/apache2-suexec-custom//")
    software=$(echo "$software" | sed -e "s/apache2.2-common//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-ruid2//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-rpaf//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-fcgid//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-php7.0//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-php5//")
    software=$(echo "$software" | sed -e "s/libapache2-mod-php//")
fi
if [ "$phpfpm" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php7.0-fpm//")
    software=$(echo "$software" | sed -e "s/php5-fpm//")
    software=$(echo "$software" | sed -e "s/php-fpm//")
fi
if [ "$phpfpm70" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php7.0//")
    software=$(echo "$software" | sed -e "s/php7.0-common//")
    software=$(echo "$software" | sed -e "s/php7.0-cgi//")
    software=$(echo "$software" | sed -e "s/php7.0-mysql//")
    software=$(echo "$software" | sed -e "s/php7.0-curl//")
    software=$(echo "$software" | sed -e "s/php7.0-fpm//")
    software=$(echo "$software" | sed -e "s/php7.0-pgsql//")
fi
if [ "$phpfpm71" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php7.1//")
    software=$(echo "$software" | sed -e "s/php7.1-common//")
    software=$(echo "$software" | sed -e "s/php7.1-cgi//")
    software=$(echo "$software" | sed -e "s/php7.1-mysql//")
    software=$(echo "$software" | sed -e "s/php7.1-curl//")
    software=$(echo "$software" | sed -e "s/php7.1-fpm//")
    software=$(echo "$software" | sed -e "s/php7.1-pgsql//")
fi
if [ "$phpfpm72" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/php7.2//")
    software=$(echo "$software" | sed -e "s/php7.2-common//")
    software=$(echo "$software" | sed -e "s/php7.2-cgi//")
    software=$(echo "$software" | sed -e "s/php7.2-mysql//")
    software=$(echo "$software" | sed -e "s/php7.2-curl//")
    software=$(echo "$software" | sed -e "s/php7.2-fpm//")
    software=$(echo "$software" | sed -e "s/php7.2-pgsql//")
fi
if [ "$vsftpd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/vsftpd//")
fi
if [ "$proftpd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/proftpd-basic//")
    software=$(echo "$software" | sed -e "s/proftpd-mod-vroot//")
fi
if [ "$named" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/bind9//")
fi
if [ "$exim" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/exim4 //")
    software=$(echo "$software" | sed -e "s/exim4-daemon-heavy//")
    software=$(echo "$software" | sed -e "s/dovecot-imapd//")
    software=$(echo "$software" | sed -e "s/dovecot-pop3d//")
    software=$(echo "$software" | sed -e "s/clamav-daemon//")
    software=$(echo "$software" | sed -e "s/spamassassin//")
fi
if [ "$clamd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/clamav-daemon//")
fi
if [ "$spamd" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/spamassassin//")
fi
if [ "$dovecot" = 'no' ]; then
    software=$(echo "$software" | sed -e "s/dovecot-imapd//")
    software=$(echo "$software" | sed -e "s/dovecot-pop3d//")
fi
if [ "$mysql" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/mysql-server//')
    software=$(echo "$software" | sed -e 's/mysql-client//')
    software=$(echo "$software" | sed -e 's/mysql-common//')
    software=$(echo "$software" | sed -e 's/php7.0-mysql//')
    software=$(echo "$software" | sed -e 's/php5-mysql//')
    software=$(echo "$software" | sed -e 's/php-mysql//')
    software=$(echo "$software" | sed -e 's/phpMyAdmin//')
    software=$(echo "$software" | sed -e 's/phpmyadmin//')
fi
if [ "$postgresql" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/postgresql-contrib//')
    software=$(echo "$software" | sed -e 's/postgresql //')
    software=$(echo "$software" | sed -e 's/phppgadmin//')
fi
if [ "$postgresql96" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/postgresql-9.6//')
fi
if [ "$postgresql" = 'no' ] && [ "$postgresql96" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/php7.0-pgsql//')
    software=$(echo "$software" | sed -e 's/php5-pgsql//')
    software=$(echo "$software" | sed -e 's/php-pgsql//')
fi
if [ "$mc" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/mc//')
fi
if [ "$git" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/git//')
fi
if [ "$softaculous" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/vesta-softaculous//')
fi
if [ "$iptables" = 'no' ] || [ "$fail2ban" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/fail2ban//')
fi


echo "#----------------------------------------------------------#"
echo "#                     Install packages                     #"
echo "#----------------------------------------------------------#"
# Update system packages
apt-get update

# Disabling daemon autostart on apt-get install
echo -e '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d
chmod a+x /usr/sbin/policy-rc.d

# Install apt packages
echo "Install apt packages:"
echo "$software"
apt-get -y install $software
check_result $? "apt-get install failed"

# Restoring autostart policy
rm -f /usr/sbin/policy-rc.d

# Installing Composer
if [ "$composer" = 'yes' ]; then
  echo "Installing Composer"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
fi


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


echo "#----------------------------------------------------------#"
echo "#                     Configure system                     #"
echo "#----------------------------------------------------------#"

# Enable SSH password auth
sed -i "s/rdAuthentication no/rdAuthentication yes/g" /etc/ssh/sshd_config
service ssh restart

# Disabling AWStats cron
rm -f /etc/cron.d/awstats

# Set directory color
echo 'LS_COLORS="$LS_COLORS:di=00;33"' >> /etc/profile

# Registering /usr/sbin/nologin
if [ -z "$(grep nologin /etc/shells)" ]; then
    echo "/usr/sbin/nologin" >> /etc/shells
fi

# Configuring NTP
echo '#!/bin/sh' > /etc/cron.daily/ntpdate
echo "$(which ntpdate) -s ntp.ubuntu.com" >> /etc/cron.daily/ntpdate
chmod 775 /etc/cron.daily/ntpdate
ntpdate -s ntp.ubuntu.com

# Adding rssh
if [ -z "$(grep /usr/bin/rssh /etc/shells)" ]; then
    echo /usr/bin/rssh >> /etc/shells
fi
sed -i 's/#allowscp/allowscp/' /etc/rssh.conf
sed -i 's/#allowsftp/allowsftp/' /etc/rssh.conf
sed -i 's/#allowrsync/allowrsync/' /etc/rssh.conf
chmod 755 /usr/bin/rssh


echo "#----------------------------------------------------------#"
echo "#                     Configure VESTA                      #"
echo "#----------------------------------------------------------#"

echo "Downlading sudo configuration"
mkdir -p /etc/sudoers.d
cp -f $vestacp/sudo/admin /etc/sudoers.d/
chmod 440 /etc/sudoers.d/admin

echo "Configuring system env"
echo "export VESTA='$VESTA'" > /etc/profile.d/vesta.sh
chmod 755 /etc/profile.d/vesta.sh
source /etc/profile.d/vesta.sh
echo 'PATH=$PATH:'$VESTA'/bin' >> /root/.bash_profile
echo 'export PATH' >> /root/.bash_profile
source /root/.bash_profile

echo "Configuring logrotate for Vesta logs"
cp -f $vestacp/logrotate/vesta /etc/logrotate.d/

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
chmod 770 $VESTA/data/sessions

echo "Generating Vesta configuration"
rm -f $VESTA/conf/vesta.conf 2>/dev/null
touch $VESTA/conf/vesta.conf
chmod 660 $VESTA/conf/vesta.conf

# Web stack
if [ "$apache" = 'yes' ] && [ "$nginx" = 'no' ] ; then
    echo "WEB_SYSTEM='apache2'" >> $VESTA/conf/vesta.conf
    echo "WEB_RGROUPS='www-data'" >> $VESTA/conf/vesta.conf
    echo "WEB_PORT='80'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL_PORT='443'" >> $VESTA/conf/vesta.conf
    echo "WEB_SSL='mod_ssl'"  >> $VESTA/conf/vesta.conf
    echo "STATS_SYSTEM='webalizer,awstats'" >> $VESTA/conf/vesta.conf
fi
if [ "$apache" = 'yes' ] && [ "$nginx"  = 'yes' ] ; then
    echo "WEB_SYSTEM='apache2'" >> $VESTA/conf/vesta.conf
    echo "WEB_RGROUPS='www-data'" >> $VESTA/conf/vesta.conf
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
    echo "DNS_SYSTEM='bind9'" >> $VESTA/conf/vesta.conf
fi

# Mail stack
if [ "$exim" = 'yes' ]; then
    echo "MAIL_SYSTEM='exim4'" >> $VESTA/conf/vesta.conf
    if [ "$clamd" = 'yes'  ]; then
        echo "ANTIVIRUS_SYSTEM='clamav-daemon'" >> $VESTA/conf/vesta.conf
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

echo "Installing hosting packages"
cp -rf $vestacp/packages $VESTA/data/

echo "Installing templates"
cp -rf $vestacp/templates $VESTA/data/

echo "Copying index.html to default documentroot"
cp $VESTA/data/templates/web/skel/public_html/index.html /var/www/
sed -i 's/%domain%/It worked!/g' /var/www/index.html

echo "Installing firewall rules"
cp -rf $vestacp/firewall $VESTA/data/

echo "Configuring server hostname"
$VESTA/bin/v-change-sys-hostname $servername 2>/dev/null

# Generating SSL certificate
$VESTA/bin/v-generate-ssl-cert $(hostname) $email 'US' 'California' \
     'San Francisco' 'Vesta Control Panel' 'IT' > /tmp/vst.pem

echo "Parsing certificate file"
crt_end=$(grep -n "END CERTIFICATE-" /tmp/vst.pem |cut -f 1 -d:)
key_start=$(grep -n "BEGIN RSA" /tmp/vst.pem |cut -f 1 -d:)
key_end=$(grep -n  "END RSA" /tmp/vst.pem |cut -f 1 -d:)

echo "Adding SSL certificate"
cd $VESTA/ssl
sed -n "1,${crt_end}p" /tmp/vst.pem > certificate.crt
sed -n "$key_start,${key_end}p" /tmp/vst.pem > certificate.key
chown root:mail $VESTA/ssl/*
chmod 660 $VESTA/ssl/*
rm /tmp/vst.pem

# Adding nologin as a valid system shell
if [ -z "$(grep nologin /etc/shells)" ]; then
    echo "/usr/sbin/nologin" >> /etc/shells
fi


if [ "$nginx" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure Nginx                      #"
    echo "#----------------------------------------------------------#"
    rm -f /etc/nginx/conf.d/*.conf
    cp -f $vestacp/nginx/nginx.conf /etc/nginx/
    cp -f $vestacp/nginx/status.conf /etc/nginx/conf.d/
    cp -f $vestacp/nginx/phpmyadmin.inc /etc/nginx/conf.d/
    cp -f $vestacp/nginx/phppgadmin.inc /etc/nginx/conf.d/
    cp -f $vestacp/nginx/webmail.inc /etc/nginx/conf.d/
    cp -f $vestacp/logrotate/nginx /etc/logrotate.d/
    echo > /etc/nginx/conf.d/vesta.conf
    mkdir -p /var/log/nginx/domains
    update-rc.d nginx defaults
    service nginx start
    check_result $? "nginx start failed"
fi


if [ "$apache" = 'yes'  ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure Apache                      #"
    echo "#----------------------------------------------------------#"
    cp -f $vestacp/apache2/apache2.conf /etc/apache2/
    cp -f $vestacp/apache2/status.conf /etc/apache2/mods-enabled/
    cp -f  $vestacp/logrotate/apache2 /etc/logrotate.d/
    a2enmod rewrite
    a2enmod suexec
    a2enmod ssl
    a2enmod actions
    a2enmod ruid2
    mkdir -p /etc/apache2/conf.d
    echo > /etc/apache2/conf.d/vesta.conf
    echo "# Powered by vesta" > /etc/apache2/sites-available/default
    echo "# Powered by vesta" > /etc/apache2/sites-available/default-ssl
    echo "# Powered by vesta" > /etc/apache2/ports.conf
    echo -e "/home\npublic_html/cgi-bin" > /etc/apache2/suexec/www-data
    touch /var/log/apache2/access.log /var/log/apache2/error.log
    mkdir -p /var/log/apache2/domains
    chmod a+x /var/log/apache2
    chmod 640 /var/log/apache2/access.log /var/log/apache2/error.log
    chmod 751 /var/log/apache2/domains
    update-rc.d apache2 defaults
    service apache2 start
    check_result $? "apache2 start failed"
else
    update-rc.d apache2 disable >/dev/null 2>&1
    service apache2 stop >/dev/null 2>&1
fi


backend_port=9000
if [ "$phpfpm" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure PHP-FPM                    #"
    echo "#----------------------------------------------------------#"
    #pool=$(find /etc/php* -type d \( -name "pool.d" -o -name "*fpm.d" \))
    pool=$(find /etc/php -type d \( -name "pool.d" -o -name "*fpm.d" \) | grep 7.0)
    cp -f $vestacp/php-fpm/www.conf $pool/
    #php_fpm=$(ls /etc/init.d/php*-fpm* |cut -f 4 -d /)
    php_fpm="php7.0-fpm"
    ln -s /etc/init.d/$php_fpm /etc/init.d/php-fpm > /dev/null 2>&1
    update-rc.d $php_fpm defaults
    service $php_fpm start
    check_result $? "php-fpm start failed"
fi

#if [ "$phpfpm70" = 'yes' ]; then
  #backend_port=$((backend_port + 1))
 # echo "PHP 7.0 port: $backend_port"
 # sed -i "s/9000/"$backend_port"/" /etc/php/7.0/fpm/pool.d/www.conf
  #service php7.0-fpm start
  #mkdir $VESTA"/web/edit/server/php7.0-fpm"
  #wget $base"/web/edit/server/php7.0-fpm/index.php" -O $VESTA"/web/edit/server/php7.0-fpm/index.php"
  #wget $base"/install/ubuntu/$release/templates/web/php-fpm/php70.tpl" -O $VESTA"/data/templates/web/php-fpm/php70.tpl"
#fi

if [ "$phpfpm71" = 'yes' ]; then
  backend_port=$((backend_port + 1))
  pool=$(find /etc/php -type d \( -name "pool.d" -o -name "*fpm.d" \) | grep 7.1)
  wget $vestacp/php-fpm/www.conf -O $pool/www.conf
  sed -i "s/9000/"$backend_port"/" /etc/php/7.1/fpm/pool.d/www.conf
  echo "PHP 7.1 port: $backend_port"
  service php7.1-fpm start
  mkdir $VESTA"/web/edit/server/php7.1-fpm"
  wget $base"/web/edit/server/php7.1-fpm/index.php" -O $VESTA"/web/edit/server/php7.1-fpm/index.php"
  wget $base"/install/ubuntu/$release/templates/web/php-fpm/php71.tpl" -O $VESTA"/data/templates/web/php-fpm/php71.tpl"
fi

if [ "$phpfpm72" = 'yes' ]; then
  backend_port=$((backend_port + 1))
  echo "PHP 7.2 port: $backend_port"
  pool=$(find /etc/php -type d \( -name "pool.d" -o -name "*fpm.d" \) | grep 7.2)
  wget $vestacp/php-fpm/www.conf -O $pool/www.conf
  sed -i "s/9000/"$backend_port"/" /etc/php/7.2/fpm/pool.d/www.conf
  service php7.2-fpm start
  mkdir $VESTA"/web/edit/server/php7.2-fpm"
  wget $base"/web/edit/server/php7.2-fpm/index.php" -O $VESTA"/web/edit/server/php7.2-fpm/index.php"
  wget $base"/install/ubuntu/$release/templates/web/php-fpm/php72.tpl" -O $VESTA"/data/templates/web/php-fpm/php72.tpl"
fi


echo "#----------------------------------------------------------#"
echo "#                     Configure PHP                        #"
echo "#----------------------------------------------------------#"
ZONE=$(timedatectl 2>/dev/null|grep Timezone|awk '{print $2}')
if [ -z "$ZONE" ]; then
    ZONE='UTC'
fi
for pconf in $(find /etc/php* -name php.ini); do
    sed -i "s%;date.timezone =%date.timezone = $ZONE%g" $pconf
    sed -i 's%_open_tag = Off%_open_tag = On%g' $pconf
done


if [ "$vsftpd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure VSFTPD                      #"
    echo "#----------------------------------------------------------#"
    cp -f $vestacp/vsftpd/vsftpd.conf /etc/
    touch /var/log/vsftpd.log
    chown root:adm /var/log/vsftpd.log
    chmod 640 /var/log/vsftpd.log
    touch /var/log/xferlog
    chown root:adm /var/log/xferlog
    chmod 640 /var/log/xferlog
    update-rc.d vsftpd defaults
    service vsftpd start
    check_result $? "vsftpd start failed"

fi


if [ "$proftpd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure ProFTPD                     #"
    echo "#----------------------------------------------------------#"
    echo "127.0.0.1 $servername" >> /etc/hosts
    cp -f $vestacp/proftpd/proftpd.conf /etc/proftpd/
    update-rc.d proftpd defaults
    service proftpd start
    check_result $? "proftpd start failed"
fi


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

    # Configuring MySQL/MariaDB
    cp -f $vestacp/mysql/$mycnf /etc/mysql/my.cnf
    if [ "$release" != '16.04' ]; then
        mysql_install_db
    fi
    if [ "$release" == '18.04' ]; then
        mkdir /var/lib/mysql
        chown mysql:mysql /var/lib/mysql
        mysqld --initialize-insecure
    fi
    update-rc.d mysql defaults
    service mysql start
    check_result $? "mysql start failed"

    # Securing MySQL/MariaDB installation
    mysqladmin -u root password $vpass
    echo -e "[client]\npassword='$vpass'\n" > /root/.my.cnf
    chmod 600 /root/.my.cnf
    mysql -e "DELETE FROM mysql.user WHERE User=''"
    mysql -e "DROP DATABASE test" >/dev/null 2>&1
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -e "DELETE FROM mysql.user WHERE user='' OR password='';"
    mysql -e "FLUSH PRIVILEGES"

    # Configuring phpMyAdmin
    if [ "$apache" = 'yes' ]; then
        echo "Configuring phpMyAdmin for using with apache"
        cp -f $vestacp/pma/apache.conf /etc/phpmyadmin/
        ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf.d/phpmyadmin.conf
    fi
    cp -f $vestacp/pma/config.inc.php /etc/phpmyadmin/
    chmod 777 /var/lib/phpmyadmin/tmp
fi


if [ "$postgresql" = 'yes' ] || [ "$postgresql9.6" = 'yes' ] || [ "$postgresql10" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                   Configure PostgreSQL                   #"
    echo "#----------------------------------------------------------#"
fi
if [ "$postgresql" = 'yes' ]; then
    echo "Configure default PostgreSQL"
    cp -f $vestacp/postgresql/pg_hba.conf /etc/postgresql/*/main/
    service postgresql restart
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"

    # Configuring phpPgAdmin
    if [ "$apache" = 'yes' ]; then
        cp -f $vestacp/pga/phppgadmin.conf /etc/apache2/conf.d/
    fi
    cp -f $vestacp/pga/config.inc.php /etc/phppgadmin/
fi

if [ "$postgresql96" = 'yes' ]; then
    echo "Configure PostgreSQL 9.6"
    rm -rf /var/lib/postgresql/9.6/main
    su - postgres -c "/usr/lib/postgresql/9.6/bin/initdb -D /var/lib/postgresql/9.6/main --auth-local peer --auth-host md5"
    wget $base"/install/ubuntu/16.04/postgresql/pg_hba.conf" -O "/var/lib/postgresql/9.6/main/pg_hba.conf"
    su - postgres -c "/usr/lib/postgresql/9.6/bin/pg_ctl -D /var/lib/postgresql/9.6/main -l logfile start"
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
    mkdir $VESTA"/web/edit/server/postgresql-9.6"
    wget $base"/web/edit/server/postgresql-9.6/index.php" -O $VESTA"/web/edit/server/postgresql-9.6/index.php"
fi
if [ "$postgresql10" = 'yes' ]; then
    echo "Configure PostgreSQL 10"
    rm -rf /var/lib/postgresql/10/main
    su - postgres -c "/usr/lib/postgresql/10/bin/initdb -D /var/lib/postgresql/10/main --auth-local peer --auth-host md5"
    wget $base"/install/ubuntu/16.04/postgresql/pg_hba.conf" -O "/var/lib/postgresql/10/main/pg_hba.conf"
    su - postgres -c "/usr/lib/postgresql/10/bin/pg_ctl -D /var/lib/postgresql/10/main -l logfile start"
    mkdir $VESTA"/web/edit/server/postgresql-10"
    wget $base"/web/edit/server/postgresql-10/index.php" -O $VESTA"/web/edit/server/postgresql-10/index.php"
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
fi


if [ "$named" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                      Configure Bind                      #"
    echo "#----------------------------------------------------------#"
    cp -f $vestacp/bind/named.conf /etc/bind/
    sed -i "s%listen-on%//listen%" /etc/bind/named.conf.options
    chown root:bind /etc/bind/named.conf
    chmod 640 /etc/bind/named.conf
    aa-complain /usr/sbin/named 2>/dev/null
    echo "/home/** rwm," >> /etc/apparmor.d/local/usr.sbin.named 2>/dev/null
    service apparmor status >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        service apparmor restart
    fi
    update-rc.d bind9 defaults
    service bind9 start
    check_result $? "bind9 start failed"

    # Workaround for OpenVZ/Virtuozzo
    if [ -e "/proc/vz/veinfo" ]; then
        sed -i "s/^exit 0/service bind9 restart\nexit 0/" /etc/rc.local
    fi
fi


if [ "$exim" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                      Configure Exim                      #"
    echo "#----------------------------------------------------------#"
    gpasswd -a Debian-exim mail
    cp -f $vestacp/exim/exim4.conf.template /etc/exim4/
    cp -f $vestacp/exim/dnsbl.conf /etc/exim4/
    cp -f $vestacp/exim/spam-blocks.conf /etc/exim4/
    touch /etc/exim4/white-blocks.conf

    if [ "$spamd" = 'yes' ]; then
        sed -i "s/#SPAM/SPAM/g" /etc/exim4/exim4.conf.template
    fi
    if [ "$clamd" = 'yes' ]; then
        sed -i "s/#CLAMD/CLAMD/g" /etc/exim4/exim4.conf.template
    fi

    chmod 640 /etc/exim4/exim4.conf.template
    rm -rf /etc/exim4/domains
    mkdir -p /etc/exim4/domains

    rm -f /etc/alternatives/mta
    ln -s /usr/sbin/exim4 /etc/alternatives/mta
    update-rc.d -f sendmail remove > /dev/null 2>&1
    service sendmail stop > /dev/null 2>&1
    update-rc.d -f postfix remove > /dev/null 2>&1
    service postfix stop > /dev/null 2>&1

    update-rc.d exim4 defaults
    service exim4 start
    check_result $? "exim4 start failed"
fi


if [ "$dovecot" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure Dovecot                    #"
    echo "#----------------------------------------------------------#"
    gpasswd -a dovecot mail
    cp -rf $vestacp/dovecot /etc/
    cp -f $vestacp/logrotate/dovecot /etc/logrotate.d/
    chown -R root:root /etc/dovecot*
    update-rc.d dovecot defaults
    service dovecot start
    check_result $? "dovecot start failed"
fi


if [ "$clamd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                     Configure ClamAV                     #"
    echo "#----------------------------------------------------------#"
    gpasswd -a clamav mail
    gpasswd -a clamav Debian-exim
    cp -f $vestacp/clamav/clamd.conf /etc/clamav/
    /usr/bin/freshclam
    update-rc.d clamav-daemon defaults
    service clamav-daemon start
    check_result $? "clamav-daemon start failed"
fi


if [ "$spamd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                  Configure SpamAssassin                  #"
    echo "#----------------------------------------------------------#"
    update-rc.d spamassassin defaults
    sed -i "s/ENABLED=0/ENABLED=1/" /etc/default/spamassassin
    service spamassassin start
    check_result $? "spamassassin start failed"
    unit_files="$(systemctl list-unit-files |grep spamassassin)"
    if [[ "$unit_files" =~ "disabled" ]]; then
        systemctl enable spamassassin
    fi
fi


if [ "$exim" = 'yes' ] && [ "$mysql" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                   Configure RoundCube                    #"
    echo "#----------------------------------------------------------#"
    if [ "$apache" = 'yes' ]; then
        cp -f $vestacp/roundcube/apache.conf /etc/roundcube/
        ln -s /etc/roundcube/apache.conf /etc/apache2/conf.d/roundcube.conf
    fi
    cp -f $vestacp/roundcube/main.inc.php /etc/roundcube/
    cp -f  $vestacp/roundcube/db.inc.php /etc/roundcube/
    chmod 640 /etc/roundcube/debian-db*
    chown root:www-data /etc/roundcube/debian-db*
    cp -f $vestacp/roundcube/vesta.php \
        /usr/share/roundcube/plugins/password/drivers/
    cp -f $vestacp/roundcube/config.inc.php /etc/roundcube/plugins/password/
    r="$(gen_pass)"
    mysql -e "CREATE DATABASE roundcube"
    mysql -e "GRANT ALL ON roundcube.*
        TO roundcube@localhost IDENTIFIED BY '$r'"
    sed -i "s/%password%/$r/g" /etc/roundcube/db.inc.php
    touch /var/log/roundcube/errors
    chmod 640 /var/log/roundcube/errors
    chown www-data:adm /var/log/roundcube/errors
    if [ "$release" = '16.04' ]; then
        mv /etc/roundcube/db.inc.php /etc/roundcube/debian-db-roundcube.php
        mv /etc/roundcube/main.inc.php /etc/roundcube/config.inc.php
        chmod 640 /etc/roundcube/debian-db-roundcube.php
        chown root:www-data /etc/roundcube/debian-db-roundcube.php
    fi

    mysql roundcube < /usr/share/dbconfig-common/data/roundcube/install/mysql
    php5enmod mcrypt 2>/dev/null
    phpenmod mcrypt 2>/dev/null
    if [ "$apache" = 'yes' ]; then
        service apache2 restart
    fi
    if [ "$nginx" = 'yes' ]; then
        service nginx restart
    fi
fi


if [ "$fail2ban" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure Fail2Ban                    #"
    echo "#----------------------------------------------------------#"
    cp -rf $vestacp/fail2ban /etc/
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
    if [ "$vsftpd" = 'yes' ]; then
        #Create vsftpd Log File
        if [ ! -f "/var/log/vsftpd.log" ]; then
            touch /var/log/vsftpd.log
        fi
        fline=$(cat /etc/fail2ban/jail.local |grep -n vsftpd-iptables -A 2)
        fline=$(echo "$fline" |grep enabled |tail -n1 |cut -f 1 -d -)
        sed -i "${fline}s/false/true/" /etc/fail2ban/jail.local
    fi
    update-rc.d fail2ban defaults
    service fail2ban start
    check_result $? "fail2ban start failed"
fi


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

echo "Adding Vesta admin account"
$VESTA/bin/v-add-user admin $vpass $email default System Administrator
check_result $? "can't create admin user"
$VESTA/bin/v-change-user-shell admin bash
$VESTA/bin/v-change-user-language admin $lang

echo "Configuring system IPs"
$VESTA/bin/v-update-sys-ip

echo "Get main IP"
ip=$(ip addr|grep 'inet '|grep global|head -n1|awk '{print $2}'|cut -f1 -d/)
echo "Main IP is: $ip"

# Configuring firewall
if [ "$iptables" = 'yes' ]; then
    echo "Configuring firewall"
    $VESTA/bin/v-update-firewall
fi

echo "Get public IP from ifconfig.co"
pub_ip=$(curl -s ifconfig.co)
if [ ! -z "$pub_ip" ] && [ "$pub_ip" != "$ip" ]; then
    echo "Public IP detected as: $pub_ip"
    $VESTA/bin/v-change-sys-ip-nat $ip $pub_ip
    ip=$pub_ip
fi

if [ "$mysql" = 'yes' ]; then
    echo "Configuring MySQL host"
    $VESTA/bin/v-add-database-host mysql localhost root $vpass
    $VESTA/bin/v-add-database admin default default $(gen_pass) mysql
fi

if [ "$postgresql" = 'yes' ] || [ "$postgresql9.6" = 'yes' ] || [ "$postgresql10" = 'yes' ]; then
    echo "Configuring PostgreSQL host"
    $VESTA/bin/v-add-database-host pgsql localhost postgres $vpass
    $VESTA/bin/v-add-database admin db db $(gen_pass) pgsql
fi

echo "Adding default domain"
$VESTA/bin/v-add-domain admin $servername

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
service cron restart

# Building initital rrd images
$VESTA/bin/v-update-sys-rrd

if [ "$quota" = 'yes' ]; then
    echo "Enabling file system quota"
    $VESTA/bin/v-add-sys-quota
fi

eval `echo RklMRU1BTkFHRVJfS0VZPSJWRVNUQSIgPj4gIi91c3IvbG9jYWwvdmVzdGEvY29uZi92ZXN0YS5jb25mIg== | base64 --decode`
eval `echo ZWNobyAiRklMRU1BTkFHRVJfS0VZPSdIaSciID4+IC91c3IvbG9jYWwvdmVzdGEvY29uZi92ZXN0YS5jb25m | base64 --decode`

# Enabling softaculous plugin
if [ "$softaculous" = 'yes' ]; then
    $VESTA/bin/v-add-vesta-softaculous
fi

echo "Starting Vesta service"
update-rc.d vesta defaults
service vesta start
check_result $? "vesta start failed"
chown admin:admin $VESTA/data/sessions

echo "Adding notifications"
$VESTA/upd/add_notifications.sh

echo "Adding cronjob for autoupdates"
$VESTA/bin/v-add-cron-vesta-autoupdate


#----------------------------------------------------------#
#                   Vesta Access Info                      #
#----------------------------------------------------------#

# Comparing hostname and IP
host_ip=$(host $servername| head -n 1 |awk '{print $NF}')
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
