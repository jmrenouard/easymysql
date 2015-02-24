#!/bin/sh
#The Artistic License 2.0
#
#           Copyright (c) 2015 Jean-Marie Renouard
#
#     Everyone is permitted to copy and distribute verbatim copies
#      of this license document, but changing it is not allowed.
#
ROOT_DIR=/var/lib
TYPE=mysql
GENERAL_OPTIONS="--log-bin=mysql-bin --explicit_defaults_for_timestamp --plugin-dir=/usr/lib64/mysql/plugin"
MUSER=mysql

CLONE_SQL='GRANT ALL PRIVILEGES ON *.* TO "clone"@"localhost" IDENTIFIED BY "clone";FLUSH PRIVILEGES;'
msetup()
{
	mysql -h$(myip) $@ -e "$CLONE_SQL" 2>/dev/null
}

mclone()
{
	ID=${1:-"1"}
	DATADIR=$ROOT_DIR/${TYPE}${ID}
	PORT=$((3306+ID))

	CLONE_ID=${2}
	[ -z "$2" ] && CLONE_PORT=3306
	[ -z "$2" ] || CLONE_PORT=$((3306+CLONE_ID))
	
	mkdir -p $DATADIR; 
	chown -R ${USER}. $DATADIR
	su - $MUSER -c "mysqlserverclone --server=clone:clone@localhost:$CLONE_PORT --new-data=$DATADIR --new-id=$ID --new-port=$PORT --root-password=admin --verbose --mysqld='$GENERAL_OPTIONS'"
	msetup -P$PORT -uroot -padmin
}

mdestroy()
{
	ID=${1:-"1"}
	DATADIR=$ROOT_DIR/${TYPE}${ID}
	mstop $ID
	rm -rf $DATADIR
}

mstart() 
{
	set -x
	ID=${1:-"1"}
	DATADIR=$ROOT_DIR/${TYPE}${ID}
	PORT=$((3306+ID))
	su - $MUSER -c "nohup /usr/sbin/mysqld --no-defaults --datadir=$DATADIR --tmpdir=$DATADIR --pid-file=$DATADIR/clone.pid --port=$PORT --server-id=$ID --basedir=/usr --socket=$DATADIR/mysql.sock $GENERAL_OPTIONS --log-error=$DATADIR/mysqld.log" &
	set +x
}

mstop()
{
	set -x
	ID=${1:-"1"}
	DATADIR=$ROOT_DIR/${TYPE}${ID}
	PORT=$((3306+ID))
	PS_PID=$(ps -edf | grep mysqld | grep "\-\-server\-id=$ID \-" | awk '{ print $2 }')
	FILE_PID=$(cat $DATADIR/clone.pid 2>/dev/null)

	if [ "$PS_PID" = "$FILE_PID" ]; then
		mysqladmin -uclone -pclone -P$PORT shutdown 	
	fi
	kill -9 $PS_PID 2>/dev/null
	rm -f $DATADIR/{clone.pid,mysqld.log,mysql.sock}
set +x
}

mstatus() 
{
	ID=${1:-'*'}
	#(
	echo -e "ID\tDIRECTORY\tPORT\tSTATUS"
	for rep in $ROOT_DIR/$TYPE$ID; do
		ID=$(echo "$rep"| sed -e "s#$ROOT_DIR/$TYPE##g")

		PROCESS=$(ps -edf | grep mysqld | grep "$rep "| grep -v "su \-"| grep -v "nohup")
		PORT=$(echo $PROCESS|xargs -n1| grep "port=" | cut -f2 -d=)
		PORT=${PORT:-"$((ID+3306))"}
		STATUS="OFF"
		[ $(netstat -ltn | grep -c ":$PORT") -eq 1 ] && STATUS="ON"
		echo -ne "${ID:-"PRI"}\t$rep\t$PORT\t$STATUS"
		

		echo
	done
	#)|column -t 

}

mclient()
{
	set -x
	ID=${1:-"1"}
	PORT=$((3306+ID))
	shift
	DATADIR=/var/lib/mysql${ID}
	mysql -uclone -pclone -P$PORT -h $(myip) $@
set +x
}

myip()
{
	ifconfig | grep inet | awk '{ print $2}' | head -n1
}