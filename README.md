# Easymysql #
**Helper Bash script for MySQL current operations**

# Purpose #
 This tools is a simple Bash script that help you to
 ** clone and manage several MySQL server instances ** on the same server. 
 It supports 6 main features:

- clone
-  destroy
-  start
-  stop
-  restart    
-  status
      
# Prerequirements #
1. Use a standard Linux and Bash shell
    - [http://www.linux.com/directory/Distributions](http://www.linux.com/directory/Distributions "Linux Distibution")
    - [http://www.gnu.org/software/bash/](http://www.gnu.org/software/bash/ "Bash Shell")
2. Download mysqlutilities
	-  [http://dev.mysql.com/downloads/utilities/](http://dev.mysql.com/downloads/utilities/ "MySQL Utilities")
3. A classic MySQL or MariaDb server
	- [http://dev.mysql.com/downloads/mysql/](http://dev.mysql.com/downloads/mysql/ "MySQL Server")
	- [https://downloads.mariadb.org/](https://downloads.mariadb.org/ "MariaDB Server")

# Installation #

## Installation from Git ##
    # git clone https://github.com/jmrenouard/easymysql

## Download Source from GitHub ##
    # curl https://github.com/jmrenouard/easymysql/archive/master.zip
    # unzip master.zip


## Setup ##
    # source mysql_functions.sh

# Specific configurations #

This parameters are set at the begin of mysql_functions.sh script.
## Root Directory for all instances
    ROOT_DIR=/var/lib

## Type of servers ##
    TYPE=mysql

## General options for all instances ##
    GENERAL_OPTIONS="--log-bin=mysql-bin --pid-file=clone.pid --explicit_defaults_for_timestamp --plugin-dir=/usr/lib64/mysql/plugin"

## User used for running mysqld process ##
    MUSER=mysql

## Password used for root user in all instances ##
    RPASSWORD=admin

## Main MySQL configuration file ##
    MAIN_CFG_FILE=/etc/my.cnf

## Include Configuration Directory ##
    ETC_DIR=/etc/my.cnf.d/

# Examples #
## Cloning a instance standard 3306 instance ##
    # source mysql_functions.sh
    # mclone 1

## Cloning MySQL instance 1 port 3307 ##
    # source mysql_functions.sh
    # mclone 2 1

## Destroying MySQL instance 2 ##
    # source mysql_functions.sh
    # mdestroy 2

## Getting the status of all MySQL instances ##
    # source mysql_functions.sh
    # mstatus
	ID      DIRECTORY       PORT    STATUS  PID
	PRI     /var/lib/mysql  3306    ON      2144
	1       /var/lib/mysql1 3307    ON      3029
	2       /var/lib/mysql2 3308    ON      3048

## Stopping MySQL instance 2 ##
	# source mysql_functions.sh
    # mstop 2
    # mstatus
	ID      DIRECTORY       PORT    STATUS  PID
	PRI     /var/lib/mysql  3306    ON      2144
	1       /var/lib/mysql1 3307    ON      3029
	2       /var/lib/mysql2 3308    OFF
	
## Starting MySQL instance 2 ##
	# source mysql_functions.sh
    # mstart 2
    # mstatus
	ID      DIRECTORY       PORT    STATUS  PID
	PRI     /var/lib/mysql  3306    ON      2144
	1       /var/lib/mysql1 3307    ON      3029
	2       /var/lib/mysql2 3308    ON      3049

## Restarting MySQL instances 1 2 ##
	# source mysql_functions.sh
    # mrestart 1 2
    # mstatus
	ID      DIRECTORY       PORT    STATUS  PID
	PRI     /var/lib/mysql  3306    ON      2144
	1       /var/lib/mysql1 3307    ON      3029
	2       /var/lib/mysql2 3308    ON      3049

## Creating  10 MySQL instances at once ##
	# source mysql_functions.sh
    # for i in `seq 1 10`; do mclone $i; done
    # mstatus
	ID      DIRECTORY       PORT    STATUS  PID
	PRI     /var/lib/mysql  3306    ON      2144
	1       /var/lib/mysql1 3307    ON      3029
	10      /var/lib/mysql10        3316    ON      4018
	2       /var/lib/mysql2 3308    ON      3048
	3       /var/lib/mysql3 3309    ON      3562
	4       /var/lib/mysql4 3310    ON      3627
	5       /var/lib/mysql5 3311    ON      3692
	6       /var/lib/mysql6 3312    ON      3757
	7       /var/lib/mysql7 3313    ON      3822
	8       /var/lib/mysql8 3314    ON      3887
	9       /var/lib/mysql9 3315    ON      3952

## Stopping 10 first MySQL instances ##
	# source mysql_functions.sh
    # mstart `seq 1 10`

## Destroying 10 MySQL instances ##
	# source mysql_functions.sh
    # mdestroy `seq 1 10`
    