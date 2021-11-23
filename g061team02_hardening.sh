#! /bin/bash

printf "\nInicio de Hardening.sh\n"  $SHELL >> /var/log/hardening.log
TIMENOW=$(date +"The local time is %r")
printf "$TIMENOW"  $SHELL >> /var/log/hardening.log
count=0

flag=$(cat /etc/systemd/system/local-fs.target.wants/tmp.mount | grep "[Mount] 
What=tmpfs 
Where=/tmp 
Type=tmpfs 
Options=mode=1777,strictatime,noexec,nodev,nosuid")
if [ -z "$flag" ];
then 
	printf "[Mount] \nWhat=tmpfs \nWhere=/tmp \nType=tmpfs \nOptions=mode=1777,strictatime,noexec,nodev,nosuid" $SHELL >> /etc/systemd/system/local-fs.target.wants/tmp.mount
	count= count + 1
	printf "\nse ha modificado el archivo /etc/systemd/system/local-fs.target.wants/tmp.mount \n"  $SHELL >> /var/log/hardening.log
fi
systemctl unmask tmp.mount 
systemctl start tmp.mount

printf "\nse ha iniciado la partición tmp\n"  $SHELL >> /var/log/hardening.log


#=========================================================
#nodev
flag=$(cat /etc/systemd/system/local-fs.target.wants/tmp.mount | grep noexec)
if [ -z "$flag" ];
then
	printf ",noexec" $SHELL >> /etc/systemd/system/local-fs.target.wants/tmp.mount
	printf "\nse ha agregado la propiedad noexec a tmp\n"  $SHELL >> /var/log/hardening.log
fi

mount -o remount,noexec /tmp
printf "\nremount tmp\n"  $SHELL >> /var/log/hardening.log
#=========================================================
#nodev
flag=$(cat /etc/systemd/system/local-fs.target.wants/tmp.mount | grep nodev)
if [ -z "$flag" ];
then
	printf ",nodev" $SHELL >> /etc/systemd/system/local-fs.target.wants/tmp.mount
	printf "\nse ha agregado la propiedad nodev a tmp\n"  $SHELL >> /var/log/hardening.log
fi

mount -o remount,nodev /tmp
printf "\nremount tmp\n"  $SHELL >> /var/log/hardening.log
#=========================================================
#nosuid
flag=$(cat /etc/systemd/system/local-fs.target.wants/tmp.mount | grep nosuid)
if [ -z "$flag" ];
then
	printf ",nosuid" $SHELL >> /etc/systemd/system/local-fs.target.wants/tmp.mount
	printf "\nse ha agregado la propiedad nosuid a tmp\n"  $SHELL >> /var/log/hardening.log
fi

mount -o remount,nosuid /tmp
printf "\nremount tmp\n"  $SHELL >> /var/log/hardening.log

#=========================================================
#separate partition for tmp

flag=$(mount | grep /tmp) 
if [ ! -z "$flag" ];
then
	sysctl -w fs.suid_dumpable=0
	printf "\nsuid_dumpable=0\n"  $SHELL >> /var/log/hardening.log
fi

#=========================================================
#Core dumps
flag=$(sysctl fs.suid_dumpable | grep 0) 
if [ -z "$flag" ];
then
	flag1=$(cat /etc/security/limits.conf | grep "hard core 0")
	if [ -z "$flag1" ];
	then
		printf "\n* hard core 0" $SHELL >> /etc/security/limits.conf
		printf "\nse ha agregado la linea hard core 0 a /etc/security/limits.conf\n"  $SHELL >> /var/log/hardening.log
	fi
	flag1=$(cat /etc/sysctl.conf | grep "fs.suid_dumpable = 0")
	if [ -z "$flag1" ];
	then
		printf "\nfs.suid_dumpable = 0" $SHELL >> /etc/sysctl.conf
		printf "\nse ha agregado la linea fs.suid_dumpable = 0 a /etc/sysctl.conf\n"  $SHELL >> /var/log/hardening.log
	fi
	sysctl -w fs.suid_dumpable=0

fi

#==================================================
# desactivando ipv6
echo "detectando ipv6"
flag=$(ifconfig -a | grep inet6)
if [ ! -z "$flag" ];
then
	printf "\nipv6 se encuentra activado en el sistema\n"

	printf "\n desactivando ipv6"

	printf "\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1" $SHELL >> /etc/sysctl.conf
	sysctl -p
	printf "\nse ha desactivado ipv6\n"  $SHELL >> /var/log/hardening.log

else

	printf "\nipv6 no estaba activado en su equipo\n"

fi
#==============================================================
# Ensure IP forwarding is disabled
printf "\nModulo IP Forwarding \n"
flag=$(sysctl net.ipv4.ip_forward | grep 1)

if [ ! -z "$flag" ];
then
	printf "\n ip forwarding is disable \n"

else
	printf "\n ip forwarding está activado en su equipo \n"
	printf "\n desactivando\n"
	sysctl -w net.ipv4.ip_forward=0 
	sysctl -w net.ipv4.route.flush=1
	printf "\n ip forwarding se ha desactivado\n"
	printf "\nse han modificado los siguientes valores \nnet.ipv4.ip_forward=0 \nnet.ipv4.route.flush=1\n"  $SHELL >> /var/log/hardening.log

fi  

#===============================================================
#ICMP redirects are not accepted
printf "\nModulo ICMP redirects"
flag=$(sysctl net.ipv4.conf.all.accept_redirects | grep 0)
if [ -z "$flag" ];
then
	sysctl -w net.ipv4.conf.all.accept_redirects=0 
	printf "\nse han modificado los siguientes valores \n net.ipv4.conf.all.accept_redirects=0 \n"  $SHELL >> /var/log/hardening.log
fi

flag=$(sysctl net.ipv4.conf.default.accept_redirects | grep 0)
if [ -z "$flag" ];
then
	sysctl -w net.ipv4.conf.default.accept_redirects=0
	printf "\nse han modificado los siguientes valores \n net.ipv4.conf.default.accept_redirects=0 \n"  $SHELL >> /var/log/hardening.log
fi

sysctl -w net.ipv4.route.flush=1
printf "\nse han modificado los siguientes valores \n net.ipv4.route.flush=1 \n"  $SHELL >> /var/log/hardening.log
#===============================================================
# icmp request are ignored
printf "\nModulo ICMP request"

flag=$(sysctl net.ipv4.icmp_echo_ignore_broadcasts | grep 0)
if [ -z "$flag" ];
then
	sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1 
	sysctl -w net.ipv4.route.flush=1
	printf "\nse han modificado los siguientes valores \n net.ipv4.icmp_echo_ignore_broadcasts=1\nnet.ipv4.route.flush=1  \n"  $SHELL >> /var/log/hardening.log
fi
#===============================================================
# icmp responses are ignored
printf "\nModulo ICMP responses"
flag=$(sysctl net.ipv4.icmp_ignore_bogus_error_responses | grep 1)
if [ -z "$flag" ];
then
	sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1 
	sysctl -w net.ipv4.route.flush=1
	printf "\nse han modificado los siguientes valores \n net.ipv4.icmp_ignore_bogus_error_responses=1 \nnet.ipv4.route.flush=1  \n"  $SHELL >> /var/log/hardening.log
fi
#===============================================================
# TCP SYN Cookies is enabled
printf "\nModulo TCP SYN Cookies\n"
flag=$(sysctl net.ipv4.tcp_syncookies | grep 1)
if [ -z "$flag" ];
then
	sysctl -w net.ipv4.tcp_syncookies=1
	sysctl -w net.ipv4.route.flush=1
	printf "\nse han modificado los siguientes valores \n net.ipv4.tcp_syncookies=1 \nnet.ipv4.route.flush=1  \n"  $SHELL >> /var/log/hardening.log
fi
printf "\n fin de ejecución \n"  $SHELL >> /var/log/hardening.log
#===============================================================