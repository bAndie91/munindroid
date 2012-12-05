#!/system/bin/sh
# MuninDroid munin-node daemon
##############################

bash=/system/xbin/bash
busybox=/data/data/berserker.android.apps.sshdroid/dropbear/busybox

if [ ".$1" = .--node ]; then
	echo "# munin node at $(getprop net.hostname)"
	while read munin_cmd; do
		export munin_cmd
		command $bash /data/system/munin/server.sh 2>/dev/null || break
	done
else
	while true; do
		echo "Listening on 4949..." >&2
		command $busybox nc -l -p 4949 -e "$0" --node
		echo "netcat ended." >&2
	done
fi

