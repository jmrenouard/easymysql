#!/bin/sh

ROOT_DIR=/var/lib
TYPE=mysql
GENERAL_OPTIONS="--log-bin=mysql-bin --explicit_defaults_for_timestamp --plugin-dir=/usr/lib64/mysql/plugin"
MUSER=mysql

CLONE_SQL='GRANT ALL PRIVILEGES ON *.* TO "clone"@"localhost" IDENTIFIED BY "clone";FLUSH PRIVILEGES;'
msetup()
{
	mysql $@ -e "$CLONE_SQL" 2>/dev/null
}

mclone()
{
	set -x
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
set +x
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
	su - $MUSER -c "nohup /usr/sbin/mysqld --no-defaults --datadir=$DATADIR --tmpdir=$DATADIR --pid-file=$DATADIR/clone.pid --port=$PORT --server-id=$ID --basedir=/usr --socket=$DATADIR/mysql.sock $GENERAL_OPTIONS --error-log=$DATADIR/mysqld.log" &
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
		PORT=${PORT:-"3306"}
		echo -ne "${ID:-"PRI"}\t$rep\t$PORT\t"
		

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
	mysql -uclone -pclone -P$PORT $@
set +x
}

