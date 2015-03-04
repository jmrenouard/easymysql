# Easymysql #
**Helper Bash script for MySQL current operations**

# Purpose #
 This tools is a simple Bash script that help you to
 clone MySQL server. 
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

