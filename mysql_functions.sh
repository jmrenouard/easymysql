#!/bin/sh
#				The Artistic License 2.0
#
#           Copyright (c) 2015 Jean-Marie Renouard
#
#     Everyone is permitted to copy and distribute verbatim copies
#      of this license document, but changing it is not allowed.
#
#######################################################################
set +x
ROOT_DIR=/var/lib
ETC_DIR=/etc/my.cnf.d/
TYPE=mysql
GENERAL_OPTIONS="--log-bin=mysql-bin --pid-file=clone.pid --explicit_defaults_for_timestamp --plugin-dir=/usr/lib64/mysql/plugin"
MUSER=mysql
RPASSWORD=admin
MAIN_CFG_FILE=/etc/my.cnf

mcleanup() {
	unset mhelp misrunning mcleanup mtest mexists msetup mrestart mclone mdestroy mstart mstop mclient mrmconfig mcrconfig _mcrmulticonfig
}
mcleanup
mhelp()
{
	typeset | grep -e '^m'
}
mclone()
{
	ID=${1:-"1"}
	local DATADIR=$ROOT_DIR/${TYPE}${ID}
	PORT=$((3306+ID))
	
	mexists $ID
	if [ $? -eq 0 ]; then
		echo "$TYPE SERVER (${1:-"PRI"}) ALREADY EXISTS..."
		return 1
	fi
	
	CLONE_ID=${2}
	[ -z "$2" -o "$2" = "0" ] && CLONE_PORT=3306
	[ -z "$2" ] || CLONE_PORT=$((3306+CLONE_ID))
	mexists $CLONE_ID
	if [ $? -ne 0 ]; then
		echo "$TYPE SERVER (${CLONE_ID:-"PRI"}) DOESN'T EXIST..."
		return 1
	fi
	
	
	mkdir -p $DATADIR; 
	chown -R ${MUSER}. $DATADIR
	SOCK=/var/lib/mysql${ID}/mysql.sock
	su - $MUSER -c "mysqlserverclone --server=root:$RPASSWORD@localhost:$CLONE_PORT --new-data=$DATADIR --new-id=$ID --new-port=$PORT --root-password=$RPASSWORD --mysqld='--log-error=$DATADIR/mysqld.log $GENERAL_OPTIONS'" 1>/dev/null 2>&1
	#mcrconfig $ID

	return 0
}
mrmconfig() 
{
	[ $# -ne 1 ] && return 1
	rm -f ${ETC_DIR}/${TYPE}${1}.cnf
	sed -i "/${TYPE}d${1}/d" $MAIN_CFG_FILE
}
mcrconfig()
{
	[ $# -ne 1 ] && return 1
	_mcrmulticonfig
cat > ${ETC_DIR}/${TYPE}${1}.cnf <<END
[mysqld${1}]
socket     = $ROOT_DIR/$TYPE${1}/mysql.sock
port       = $((3306+$1))
pid-file   = $ROOT_DIR/$TYPE${1}/clone.pid
datadir    = $ROOT_DIR/$TYPE${1}
log-error  = $ROOT_DIR/$TYPE${1}/mysqld.log
user       = root
END
cat >> $MAIN_CFG_FILE <<END
[mysqld${1}]
!include ${ETC_DIR}/mysqld${1}.cnf
END
}

_mcrmulticonfig() 
{
[ -f "${ETC_DIR}/multi.cnf" ] && return 0
cat > ${ETC_DIR}/multi.cnf <<END
[mysqld_multi]
mysqld     = $(which mysqld_safe)
mysqladmin = $(which mysqladmin)
user       = root
password   = $RPASSWORD
END

cat >> $MAIN_CFG_FILE <<END
[mysqld_multi]
!include ${ETC_DIR}/multi.cnf
END
}

mdestroy()
{
	if [ $# -gt 1 ]; then
		RET=0
		for arg in $@; do
			mdestroy $arg
			RET=$(($RET+$?))
		done
		return $RET
	fi
	ID=${1:-"1"}
	DATADIR=$ROOT_DIR/${TYPE}${ID}
	mexists $ID
	if [ $? -ne 0 ]; then
		echo "$TYPE SERVER (${ID:-"PRI"}) DOESN'T EXIST..."
		return 1
	fi
	mstop $ID
	rm -rf $DATADIR
	#mrmconfig $ID
}

mstart() 
{
	if [ $# -gt 1 ]; then
		RET=0
		for arg in $@; do
			mstart $arg
			RET=$(($RET+$?))
		done
		return $RET
	fi
	ID=${1:-""}
	misrunning $ID 1>/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "$TYPE SERVER (${ID:-"PRI"}) IS ALREADY RUNNING..."
		return 1
	fi
	DATADIR=$ROOT_DIR/${TYPE}${ID}
	PORT=$((3306+ID))
	su - $MUSER -c "nohup /usr/sbin/mysqld --no-defaults --datadir=$DATADIR --tmpdir=$DATADIR --pid-file=$DATADIR/clone.pid --port=$PORT --server-id=$ID --basedir=/usr --socket=$DATADIR/mysql.sock $GENERAL_OPTIONS --log-error=$DATADIR/mysqld.log" 1>/dev/null 2>&1&
}

mstop()
{
	if [ $# -gt 1 ]; then
		RET=0
		for arg in $@; do
			mstop $arg
			RET=$(($RET+$?))
		done
		return $RET
	fi
	ID=${1:-"0"}
	PORT=$((3306+ID))
	[ $ID -eq 0 ] && ID=''
	DATADIR=$ROOT_DIR/${TYPE}${ID}
	
	misrunning $ID 1>/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "$TYPE SERVER (${ID:-"PRI"}) IS NOT RUNNING..."
		return 1
	fi
	PS_PID=$(ps -edf | grep mysqld | grep "\-\-server\-id=$ID \-" | awk '{ print $2 }')
	[ -z "$PS_PID" ] && PS_PID=$(ps -edf | grep mysqld | grep "$ROOT_DIR/${TYPE} "| grep -v grep | awk '{ print $2 }')
	FILE_PID=$(cat $DATADIR/*.pid 2>/dev/null)

	if [ "$PS_PID" = "$FILE_PID" ]; then
		SOCK=/var/lib/mysql${ID}/mysql.sock
		mysqladmin -uroot -p$RPASSWORD -S$SOCK shutdown 	
	fi
	kill -9 $PS_PID 1>/dev/null 2>&1
	rm -f $DATADIR/{clone.pid,mysqld.log,mysql.sock}
	return 0
}

mrestart() 
{
	if [ $# -gt 1 ]; then
		RET=0
		for arg in $@; do
			mrestart $arg
			RET=$(($RET+$?))
		done
		return $RET
	fi
	mstop $ID
	mstart $ID
}

mexists() 
{
	if [ $# -gt 1 ]; then
		RET=0
		for arg in $@; do
			mexists $arg
			RET=$(($RET+$?))
		done
		return $RET
	fi
	local DATADIR=$ROOT_DIR/${TYPE}${1:-''}
	echo -n "CHECKING $TYPE SERVER (${1:-"PRI"}) EXISTS : "
	if [ -d "$DATADIR" ]; then
		echo "[OK]"
		return 0
	fi
	echo "[FAIL]"
	return 1
}

mstatus() 
{
	ID=${1:-'*'}
	#(
	echo -e "ID\tDIRECTORY\tPORT\tSTATUS\tPID"
	for rep in $ROOT_DIR/$TYPE$ID; do
		ID=$(echo "$rep"| sed -e "s#$ROOT_DIR/$TYPE##g")

		PROCESS=$(ps -edf | grep mysqld | grep "$rep "| grep -v "su \-"| grep -v "nohup")
		PORT=$(echo $PROCESS|xargs -n1| grep "port=" | cut -f2 -d=)
		PORT=${PORT:-"$((ID+3306))"}
		PID=$(echo $PROCESS| awk '{print $2}')
		STATUS="OFF"
		[ $(netstat -ltn | grep -c ":$PORT") -eq 1 ] && STATUS="ON"
		echo -ne "${ID:-"PRI"}\t$rep\t$PORT\t$STATUS\t$PID"
		

		echo
	done
	#)|column -t 
}

misrunning() 
{
	if [ $# -gt 1 ]; then
		RET=0
		for arg in $@; do
			misrunning $arg
			RET=$(($RET+$?))
		done
		return $RET
	fi
	ID=${1:-""}
	[ "$ID" = "0" ] && ID=''
	mexists $ID
	if [ $? -ne 0 ]; then
		echo "$TYPE SERVER (${ID:-"PRI"}) DOESN'T EXIST..."
		return 1
	fi
	rep=$ROOT_DIR/$TYPE$ID
	PROCESS=$(ps -edf | grep mysqld | grep "$rep "| grep -v "su \-"| grep -v "nohup")
	PORT=$(echo $PROCESS|xargs -n1| grep "port=" | cut -f2 -d=)
	PORT=${PORT:-"$((ID+3306))"}
	PID=$(echo $PROCESS| awk '{print $2}')
	
	if [ -z "$PID" ]; then
		echo "$TYPE SERVER (${ID:-"PRI"}) NO PROCESS FOUND..."
		return 1
	fi
	
	if [ $(netstat -ltn | grep -c ":$PORT") -eq 0 ]; then
		echo "$TYPE SERVER (${ID:-"PRI"}) NO OPENED PORT($PORT)..."
		return 1
	fi
	echo "$TYPE SERVER (${ID:-"PRI"})(PID:$PID, PORT:$PORT) RUNNING..."
	return 0
}

mclient()
{
	
	ID=${1:-"0"}
	PORT=$((3306+ID))
	[ "$ID" = "0" ] && ID=''
	mexists $ID
	if [ $? -ne 0 ]; then
		echo "$TYPE SERVER (${ID:-"PRI"}) DOESN'T EXIST..."
		return 1
	fi
	
	shift
	SOCK=$ROOT_DIR/${TYPE}${ID}/mysql.sock
	
	PARAM="$@"
	if [ -z "$PARAM" ]; then
		mysql -uroot -p$RPASSWORD -S$SOCK 
		return $?
	fi
	echo $@ | mysql -uroot -p$RPASSWORD -S$SOCK 
}

myip()
{
	ifconfig | grep inet | awk '{ print $2}' | head -n1
}

mtest() 
{
INSTANCES='1 2 3 4'

set +x
for id in $INSTANCES; do
	mdestroy $id
	mstatus
	mclone $id $(($id-1))
	mstatus
	mclient $id 'select @@port'
done
set +x
#mstop $id
#	mstatus
#	mstart $id
#	mclient $id 'select @@port'
#	mdestroy $id
#	mstatus
}



