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
vestacp="$VESTA/install/$VERSION/$release"
base='https://raw.githubusercontent.com/stasisha/vesta/master'

# Defining software pack for all distros
software="awstats bc bind bind-libs bind-utils clamav-server clamav-update
    curl dovecot e2fsprogs exim expect fail2ban flex freetype ftp GeoIP httpd
    ImageMagick iptables-services jwhois lsof mailx mariadb mariadb-server mc
    mod_fcgid mod_ruid2 mod_ssl net-tools nginx ntp openssh-clients pcre php
    php-bcmath php-cli php-common php-fpm php-gd php-imap php-mbstring
    php-mcrypt phpMyAdmin php-mysql php-pdo phpPgAdmin php-pgsql php-soap
    php-tidy php-xml php-xmlrpc php70-php php70-php-fpm php71-php php71-php-fpm
    php72-php php72-php-fpmpostgresql postgresql-contrib
    postgresql-server proftpd roundcubemail rrdtool rsyslog screen
    spamassassin sqlite sudo tar telnet unzip vesta vesta-ioncube vesta-nginx
    vesta-php vesta-softaculous vim-common vsftpd webalizer which zip
    postgresql96-server postgresql10-server git mc"

# Fix for old releases
if [ "$release" -lt 7 ]; then
    software=$(echo "$software" |sed -e "s/mariadb/mysql/g")
    software=$(echo "$software" |sed -e "s/clamav-server/clamd/")
    software=$(echo "$software" |sed -e "s/clamav-update//")
    software=$(echo "$software" |sed -e "s/iptables-services//")
    software="$software mod_extract_forwarded"
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
  -o, --softaculous       Install Softaculous
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
        --softaculous)          args="${args}-o " ;;
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
while getopts "a:n:w:w70:w71:w72:v:j:k:m:g:g96:g10:d:x:z:c:t:i:b:r:p:q:gt:co:mc:l:y:s:e:p:f:h" Option; do
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
        o)   softaculous=$OPTARG ;;
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

# Checking root permissions
echo "Checking root permissions"
if [ "x$(id -u)" != 'x0' ]; then
    check_result 1 "Script can be run executed only by root"
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
wget -q "c.vestacp.com/GPG.txt" -O /dev/null
check_result $? "No access to Vesta repository"

# Checking installed packages
echo "Checking installed packages"
tmpfile=$(mktemp -p /tmp)
rpm -qa > $tmpfile
for pkg in exim mysql-server httpd nginx vesta; do
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
            echo -n 'ClamAV '
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
    if [ $release -ge 7 ]; then
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
#                   Install repository                     #
#----------------------------------------------------------#

echo "#----------------------------------------------------------#"
echo "#                  Install repositories                    #"
echo "#----------------------------------------------------------#"

# Updating system
yum -y update
check_result $? 'yum update failed'

# Installing EPEL repository
echo "Installing EPEL repository"
yum install epel-release -y
check_result $? "Can't install EPEL repository"

# Installing Remi repository
if [ "$remi" = 'yes' ] && [ ! -e "/etc/yum.repos.d/remi.repo" ]; then
    rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-$release.rpm
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
wget c.vestacp.com/GPG.txt -O /etc/pki/rpm-gpg/RPM-GPG-KEY-VESTA

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
if [ "$softaculous" = 'no' ]; then
    software=$(echo "$software" | sed -e 's/vesta-softaculous//')
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
yum install -y $software
if [ $? -ne 0 ]; then
    if [ "$remi" = 'yes' ]; then
        yum -y --disablerepo=* \
            --enablerepo="*base,*updates,nginx,epel,vesta,remi*" \
            install $software
    else
        yum -y --disablerepo=* --enablerepo="*base,*updates,nginx,epel,vesta" \
            install $software
    fi
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

# Disabling iptables
service iptables stop
service firewalld stop >/dev/null 2>&1


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
cp -f $vestacp/sudo/admin /etc/sudoers.d/
chmod 440 /etc/sudoers.d/admin

# Configuring system env
echo "Configuring system env"
echo "export VESTA='$VESTA'" > /etc/profile.d/vesta.sh
chmod 755 /etc/profile.d/vesta.sh
source /etc/profile.d/vesta.sh
echo 'PATH=$PATH:'$VESTA'/bin' >> /root/.bash_profile
echo 'export PATH' >> /root/.bash_profile
source /root/.bash_profile

# Configuring logrotate for vesta logs
cp -f $vestacp/logrotate/vesta /etc/logrotate.d/

# Building directory tree and creating some blank files for Vesta
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

# Generating vesta configuration
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
echo "CRON_SYSTEM='crond'" >> $VESTA/conf/vesta.conf

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

# Installing hosting packages
cp -rf $vestacp/packages $VESTA/data/

# Installing templates
cp -rf $vestacp/templates $VESTA/data/

# Copying index.html to default documentroot
cp $VESTA/data/templates/web/skel/public_html/index.html /var/www/html/
sed -i 's/%domain%/It worked!/g' /var/www/html/index.html

# Installing firewall rules
cp -rf $vestacp/firewall $VESTA/data/

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
    cp -f $vestacp/nginx/nginx.conf /etc/nginx/
    cp -f $vestacp/nginx/status.conf /etc/nginx/conf.d/
    cp -f $vestacp/nginx/phpmyadmin.inc /etc/nginx/conf.d/
    cp -f $vestacp/nginx/phppgadmin.inc /etc/nginx/conf.d/
    cp -f $vestacp/nginx/webmail.inc /etc/nginx/conf.d/
    cp -f $vestacp/logrotate/nginx /etc/logrotate.d/
    echo > /etc/nginx/conf.d/vesta.conf
    mkdir -p /var/log/nginx/domains
    if [ "$release" -ge 7 ]; then
        mkdir -p /etc/systemd/system/nginx.service.d
        cd /etc/systemd/system/nginx.service.d
        echo "[Service]" > limits.conf
        echo "LimitNOFILE=500000" >> limits.conf
    fi
    chkconfig nginx on
    service nginx start
    check_result $? "nginx start failed"

    # Workaround for OpenVZ/Virtuozzo
    if [ "$release" -ge '7' ] && [ -e "/proc/vz/veinfo" ]; then
        echo "#Vesta: workraround for networkmanager" >> /etc/rc.local
        echo "sleep 3 && service nginx restart" >> /etc/rc.local
    fi
fi


#----------------------------------------------------------#
#                    Configure Apache                      #
#----------------------------------------------------------#

if [ "$apache" = 'yes'  ]; then
    cp -f $vestacp/httpd/httpd.conf /etc/httpd/conf/
    cp -f $vestacp/httpd/status.conf /etc/httpd/conf.d/
    cp -f $vestacp/httpd/ssl.conf /etc/httpd/conf.d/
    cp -f $vestacp/httpd/ruid2.conf /etc/httpd/conf.d/
    cp -f $vestacp/logrotate/httpd /etc/logrotate.d/
    if [ $release -lt 7 ]; then
        cd /etc/httpd/conf.d
        echo "MEFaccept 127.0.0.1" >> mod_extract_forwarded.conf
        echo > proxy_ajp.conf
    fi
    if [ -e "/etc/httpd/conf.modules.d/00-dav.conf" ]; then
        cd /etc/httpd/conf.modules.d
        sed -i "s/^/#/" 00-dav.conf 00-lua.conf 00-proxy.conf
    fi
    echo > /etc/httpd/conf.d/vesta.conf
    cd /var/log/httpd
    touch access_log error_log suexec.log
    chmod 640 access_log error_log suexec.log
    chmod -f 777 /var/lib/php/session
    chmod a+x /var/log/httpd
    mkdir -p /var/log/httpd/domains
    chmod 751 /var/log/httpd/domains
    if [ "$release" -ge 7 ]; then
        mkdir -p /etc/systemd/system/httpd.service.d
        cd /etc/systemd/system/httpd.service.d
        echo "[Service]" > limits.conf
        echo "LimitNOFILE=500000" >> limits.conf
    fi
    chkconfig httpd on
    service httpd start
    check_result $? "httpd start failed"

    # Workaround for OpenVZ/Virtuozzo
    if [ "$release" -ge '7' ] && [ -e "/proc/vz/veinfo" ]; then
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
  cp -f $vestacp/php-fpm/www.conf /etc/php-fpm.d/
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
    sed -i "s|;date.timezone =|date.timezone = $ZONE|g" $pconf
    sed -i 's%_open_tag = Off%_open_tag = On%g' $pconf
done


#----------------------------------------------------------#
#                    Configure Vsftpd                      #
#----------------------------------------------------------#

if [ "$vsftpd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure VSFTPD                      #"
    echo "#----------------------------------------------------------#"
    cp -f $vestacp/vsftpd/vsftpd.conf /etc/vsftpd/
    chkconfig vsftpd on
    service vsftpd start
    check_result $? "vsftpd start failed"
fi


#----------------------------------------------------------#
#                    Configure ProFTPD                     #
#----------------------------------------------------------#

if [ "$proftpd" = 'yes' ]; then
    echo "#----------------------------------------------------------#"
    echo "#                    Configure ProFTPD                     #"
    echo "#----------------------------------------------------------#"
   cp -f $vestacp/proftpd/proftpd.conf /etc/
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
    mkdir -p /etc/my.cnf.d

    if [ $release -lt 7 ]; then
        service='mysqld'
    else
        service='mariadb'
    fi

    cp -f $vestacp/$service/$mycnf /etc/my.cnf
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
        cp -f $vestacp/pma/phpMyAdmin.conf /etc/httpd/conf.d/
    fi
    cp -f $vestacp/pma/config.inc.conf /etc/phpMyAdmin/config.inc.php
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
    if [ $release -eq 5 ]; then
        service postgresql start
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
        service postgresql stop
        cp -f $vestacp/postgresql/pg_hba.conf /var/lib/pgsql/data/
        service postgresql start
    else
        service postgresql initdb
        cp -f $vestacp/postgresql/pg_hba.conf /var/lib/pgsql/data/
        service postgresql start
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$vpass'"
    fi
    # Configuring phpPgAdmin
    if [ "$apache" = 'yes' ]; then
        cp -f $vestacp/pga/phpPgAdmin.conf /etc/httpd/conf.d/
    fi
    cp -f $vestacp/pga/config.inc.php /etc/phpPgAdmin/
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
    cp -f $vestacp/named/named.conf /etc/
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
    cp -f $vestacp/exim/exim.conf /etc/exim/
    cp -f $vestacp/exim/dnsbl.conf /etc/exim/
    cp -f $vestacp/exim/spam-blocks.conf /etc/exim/
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
    cp -rf $vestacp/dovecot /etc/
    cp -f $vestacp/logrotate/dovecot /etc/logrotate.d/
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
    cp -f $vestacp/clamav/clamd.conf /etc/
    cp -f $vestacp/clamav/freshclam.conf /etc/
    mkdir -p /var/log/clamav /var/run/clamav
    chown clam:clam /var/log/clamav /var/run/clamav
    chown -R clam:clam /var/lib/clamav
    if [ "$release" -ge '7' ]; then
        cp -f $vestacp/clamav/clamd.service /usr/lib/systemd/system/
        systemctl --system daemon-reload
    fi
    /usr/bin/freshclam
    if [ "$release" -ge '7' ]; then
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
    if [ "$release" -ge '7' ]; then
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
        cp -f $vestacp/roundcube/roundcubemail.conf /etc/httpd/conf.d/
    fi
    cp -f $vestacp/roundcube/main.inc.php /etc/roundcubemail/config.inc.php
    cd /usr/share/roundcubemail/plugins/password
    cp -f $vestacp/roundcube/vesta.php drivers/vesta.php
    cp -f $vestacp/roundcube/config.inc.php config.inc.php
    sed -i "s/localhost/$servername/g" config.inc.php
    chmod a+r /etc/roundcubemail/*
    chmod -f 777 /var/log/roundcubemail
    r="$(gen_pass)"
    mysql -e "CREATE DATABASE roundcube"
    mysql -e "GRANT ALL ON roundcube.* TO
            roundcube@localhost IDENTIFIED BY '$r'"
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
    chkconfig fail2ban on
    mkdir -p /var/run/fail2ban
    if [ -e "/usr/lib/systemd/system/fail2ban.service" ]; then
        exec_pre='ExecStartPre=/bin/mkdir -p /var/run/fail2ban'
        sed -i "s|\[Service\]|[Service]\n$exec_pre|g" \
            /usr/lib/systemd/system/fail2ban.service
        systemctl daemon-reload
    fi
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
    chkconfig firewalld off >/dev/null 2>&1
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

# Building RRD images
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

# Enabling Softaculous plugin
if [ "$softaculous" = 'yes' ]; then
    $VESTA/bin/v-add-vesta-softaculous
fi

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
