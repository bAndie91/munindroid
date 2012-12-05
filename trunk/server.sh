
export ver=0.2
disk_warn_percent=92
disk_crit_percent=98
declare -A mems

munin_node() {
	# ---------------------------
	param1=$1
	plugin=$2
	# ---------------------------
	procStatChar=(S T Z X W D R)
	# ---------------------------

	case "$param1" in
	list)
		echo load uptime df df_abs df_asec df_asec_abs processes memory cpu battery_cap battery_temp swap if_wlan0 open_files
		;;
	autoconfig)
		case "$plugin" in
		load)		test -f /proc/loadavg && echo yes || echo no;;
		uptime)		test -f /proc/uptime && echo yes || echo no;;
		df|df_*)	test -x /system/xbin/df && echo yes || echo no;;
		processes)	test -d /proc/ && echo yes || echo no;;
		memory)		test -f /proc/meminfo && echo yes || echo no;;
		cpu|swap)	test -f /proc/stat && echo yes || echo no;;
		battery_cap)	test -d /sys/class/power_supply/battery/capacity && echo yes || echo no;;
		battery_temp)	test -d /sys/class/power_supply/battery/batt_temp && echo yes || echo no;;
		if_*)		test -f /proc/net/dev && echo yes || echo no;;
		open_files)	test -f /proc/sys/fs/file-nr && echo yes || echo no;;
		*)	echo no;;
		esac
		;;
	config)
		case "$plugin" in
		load)
			echo graph_title Load average
			echo graph_args --base 1000 -l 0
			echo graph_vlabel load
			echo graph_scale no
			echo graph_category system
			echo load.label loadavg5
			echo load.info 5 minute load average
			;;
		uptime)
			echo graph_title Uptime
			echo graph_args --base 1000 -l 0 
			echo graph_scale no
			echo graph_vlabel uptime in minutes
			echo graph_category system
			echo uptime.label uptime
			echo uptime.draw AREA
			;;
		df)
			echo graph_title Filesystem usage in percent
			echo graph_args --upper-limit 100 -l 0
			echo graph_vlabel %
			echo graph_scale no
			echo graph_category disk
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" = /mnt/asec/ ] && continue
				echo $dev.label $mp
				echo $dev.warning $disk_warn_percent
				echo $dev.critical $disk_crit_percent
			done
			;;
		df_abs)
			echo graph_title Filesystem usage in bytes
			echo graph_args --base 1024 --lower-limit 0
			echo graph_vlabel bytes
			echo graph_category disk
			echo graph_total Total
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" = /mnt/asec/ ] && continue
				echo $dev.label $mp
				echo $dev.warning $(( total / 100 * disk_warn_percent ))
				echo $dev.critical $(( total / 100 * disk_crit_percent ))
			done
			;;
		df_asec)
			echo graph_title Filesystem usage in percent "(asec)"
			echo graph_args --upper-limit 100 -l 0
			echo graph_vlabel %
			echo graph_scale no
			echo graph_category disk
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" != /mnt/asec/ ] && continue
				dev=${mp//[!a-zA-Z0-9-]/_}
				echo $dev.label $mp
				echo $dev.warning $disk_warn_percent
				echo $dev.critical $disk_crit_percent
			done
			;;
		df_asec_abs)
			echo graph_title Filesystem usage in bytes "(asec)"
			echo graph_args --base 1024 --lower-limit 0
			echo graph_vlabel bytes
			echo graph_category disk
			#echo graph_total Total
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" != /mnt/asec/ ] && continue
				dev=${mp//[!a-zA-Z0-9-]/_}
				echo $dev.label $mp
				#echo $dev.warning $(( total / 100 * disk_warn_percent ))
				#echo $dev.critical $(( total / 100 * disk_crit_percent ))
			done
			;;
		processes)
			ptype=(sleeping stopped zombie dead paging uninterruptible runnable)
			colour=(0022ff cc0000 990000 ff0000 00aaaa ffa500 22ff22)
			ti=0
			ci=0
			echo graph_title Processes
			echo graph_info This graph shows the number of processes
			echo graph_category processes
			echo graph_args --base 1000 -l 0
			echo graph_vlabel Number of processes
			echo graph_order ${procStatChar[@]} total
			for c in ${procStatChar[@]}; do
				echo $c.label ${ptype[ti++]}
				echo $c.draw $( test $c = S && echo -n AREA || echo STACK )
				echo $c.colour ${colour[ci++]}
			done
			echo total.label total
			echo total.draw LINE1
			echo total.colour c0c0c0
			;;
		memory)
			load_mem_data

			    echo graph_args --base 1024 -l 0 --upper-limit ${mems[MemTotal]}
			    echo graph_vlabel Bytes
			    echo graph_title Memory usage
			    echo graph_category system
			    echo graph_info "This graph shows what the machine uses memory for."
			    echo -n graph_order
			    for mem in apps PageTables SwapCached VmallocUsed slab Cached Buffers MemFree swap; do
			    	[ -n "${mems[$mem]}" ] && echo -n " $mem"
			    done
			    echo
			    # ----------------------- #
			    echo apps.label apps
			    echo apps.draw AREA
			    echo apps.colour 00cc00
			    echo apps.info "Memory used by user-space applications."
			    echo Buffers.label buffers
			    echo Buffers.draw STACK
			    echo Buffers.colour 990099
			    echo Buffers.info "Block device (e.g. harddisk) cache. Also where \"dirty\" blocks are stored until written."
			    echo swap.label swap
			    echo swap.draw STACK
			    echo swap.colour ff0000
			    echo swap.info "Swap space used."
			    echo Cached.label cache
			    echo Cached.draw STACK
			    echo Cached.colour 330099
			    echo Cached.info "Parked file data (file content) cache."
			    echo MemFree.label unused
			    echo MemFree.draw STACK
			    echo MemFree.colour ccff00
			    echo MemFree.info "Wasted memory. Memory that is not used for anything at all."
			    if [ -n "${mems[Slab]}" ]; then
				echo Slab.label slab_cache
				echo Slab.draw STACK
				echo Slab.colour ffcc00
				echo Slab.info "Memory used by the kernel (major users are caches like inode, dentry, etc)."
			    fi
			    if [ -n "${mems[SwapCached]}" ]; then
				echo SwapCached.label swap_cache
				echo SwapCached.draw STACK
				echo SwapCached.colour ff8000
				echo SwapCached.info "A piece of memory that keeps track of pages that have been fetched from swap but not yet been modified."
			    fi
			    if [ -n "${mems[PageTables]}" ]; then
				echo PageTables.label page_tables
				echo PageTables.draw STACK
				echo PageTables.info "Memory used to map between virtual and physical memory addresses."
			    fi
			    if [ -n "${mems[VmallocUsed]}" ]; then
				echo VmallocUsed.label vmalloc_used
				echo VmallocUsed.draw LINE1
				echo VmallocUsed.colour b35a00
				echo VmallocUsed.info "'VMalloc' (kernel) memory used"
			    fi
			    if [ -n "${mems[Committed_AS]}" ]; then
				echo Committed_AS.label "committed"
				echo Committed_AS.draw LINE1
				echo Committed_AS.colour 008f00
				# Linux machines frequently overcommit - this is not a error
				# condition or even worrying.  But sometimes overcommit shows
				# memory leaks so we want to graph it.
				echo Committed_AS.warning $[ mems[SwapTotal] + mems[MemTotal] ]
				echo Committed_AS.info "The amount of memory allocated to programs. Overcommitting is normal, but may indicate memory leaks."
			    fi
			    if [ -n "${mems[01Committed_AS]}" ]; then
				echo 01Committed_AS.label "0.1 * committed"
				echo 01Committed_AS.draw LINE1
				echo 01Committed_AS.colour 008f00
				# Linux machines frequently overcommit - this is not a error
				# condition or even worrying.  But sometimes overcommit shows
				# memory leaks so we want to graph it.
				echo 01Committed_AS.warning $[ ( mems[SwapTotal] + mems[MemTotal] ) / 10 ]
			    fi
			    if [ -n "${mems[Mapped]}" ]; then
				echo Mapped.label mapped
				echo Mapped.draw LINE1
				echo Mapped.colour b38f00
				echo Mapped.info "All mmap()ed pages."
			    fi
			    if [ -n "${mems[Active]}" ]; then
				echo Active.label active
				echo Active.draw LINE1
				echo Active.colour 00487d
				echo Active.info "Memory recently used. Not reclaimed unless absolutely necessary."
			    fi
			    if [ -n "${mems[ActiveAnon]}" ]; then
				echo ActiveAnon.label active_anon
				echo ActiveAnon.draw LINE1
			    fi
			    if [ -n "${mems[ActiveCache]}" ]; then
				echo ActiveCache.label active_cache
				echo ActiveCache.draw LINE1
			    fi
			    if [ -n "${mems[Inactive]}" ]; then
				echo Inactive.label inactive
				echo Inactive.draw LINE1
				echo Inactive.info "Memory not currently used."
				echo Inactive.colour 808080
			    fi
			    if [ -n "${mems[Inact_dirty]}" ]; then
				echo Inact_dirty.label inactive_dirty
				echo Inact_dirty.draw LINE1
				echo Inact_dirty.info "Memory not currently used, but in need of being written to disk."
			    fi
			    if [ -n "${mems[Inact_laundry]}" ]; then
				echo Inact_laundry.label inactive_laundry
				echo Inact_laundry.draw LINE1
			    fi
			    if [ -n "${mems[Inact_clean]}" ]; then
				echo Inact_clean.label inactive_clean
				echo Inact_clean.draw LINE1
				echo Inact_clean.info "Memory not currently used."
			    fi
			;;
		cpu)
			plugin_cpu_init
			
			NCPU=$(grep -E '^cpu[0-9]+ ' /proc/stat | wc -l)
			if [ "$scaleto100" = "yes" ]; then
				graphlimit=100
			else
				graphlimit=$(( NCPU * 100 ))
			fi
			echo 'graph_title CPU usage'
			echo "graph_order system user nice idle" $extinfo
			echo "graph_args --base 1000 -r --lower-limit 0 --upper-limit $graphlimit"
			echo 'graph_vlabel %'
			echo 'graph_scale no'
			echo 'graph_info This graph shows how CPU time is spent.'
			echo 'graph_category system'
			echo 'graph_period second'
			echo 'system.label system'
			echo 'system.draw AREA'
			echo 'system.min 0'
			echo 'system.type DERIVE'
			echo "system.info CPU time spent by the kernel in system activities" 
			echo 'user.label user'
			echo 'user.draw STACK'
			echo 'user.min 0'
			echo 'user.type DERIVE'
			echo 'user.info CPU time spent by normal programs and daemons'
			echo 'nice.label nice'
			echo 'nice.draw STACK'
			echo 'nice.min 0'
			echo 'nice.type DERIVE'
			echo 'nice.info CPU time spent by nice(1)d programs'
			echo 'idle.label idle'
			echo 'idle.draw STACK'
			echo 'idle.min 0'
			echo 'idle.type DERIVE'
			echo 'idle.info Idle CPU time'
		
			if [ "$scaleto100" = "yes" ]; then
				echo "system.cdef system,$NCPU,/"
				echo "user.cdef user,$NCPU,/"
				echo "nice.cdef nice,$NCPU,/"
				echo "idle.cdef idle,$NCPU,/"
			fi
			if [ ! -z "$extinfo" ]; then
				echo 'iowait.label iowait'
				echo 'iowait.draw STACK'
				echo 'iowait.min 0'
				echo 'iowait.type DERIVE'
				echo 'iowait.info CPU time spent waiting for I/O operations to finish when there is nothing else to do.'
				echo 'irq.label irq'
				echo 'irq.draw STACK'
				echo 'irq.min 0'
				echo 'irq.type DERIVE'
				echo 'irq.info CPU time spent handling interrupts'
				echo 'softirq.label softirq'
				echo 'softirq.draw STACK'
				echo 'softirq.min 0'
				echo 'softirq.type DERIVE'
				echo 'softirq.info CPU time spent handling "batched" interrupts'
				if [ "$scaleto100" = "yes" ]; then
					echo "iowait.cdef iowait,$NCPU,/"
					echo "irq.cdef irq,$NCPU,/"
					echo "softirq.cdef softirq,$NCPU,/"
				fi
			fi
		        if [ ! -z "$extextinfo" ]; then
		                echo 'steal.label steal'
		                echo 'steal.draw STACK'
		                echo 'steal.min 0'
		                echo 'steal.type DERIVE'
		                echo 'steal.info The time that a virtual CPU had runnable tasks, but the virtual CPU itself was not running'
		                if [ "$scaleto100" = "yes" ]; then
		                        echo "steal.cdef steal,$NCPU,/"
				fi
			fi
			;;
		battery_cap)
			echo graph_title Battery capacity
			echo graph_vlabel %
			echo graph_category sensors
			echo graph_args -l 0 -u 100
			echo graph_scale no
			echo graph_order ac usb battery
			echo battery.label Battery
			echo battery.colour FF0000
			echo battery.draw LINE2
			echo battery.warning 15:100
			echo battery.critical 7:100
			echo usb.label USB charger present
			echo usb.colour 00FFFF
			echo usb.draw AREA
			echo ac.label AC charger present
			echo ac.colour FFFF00
			echo ac.draw AREA
			;;
		battery_temp)
			echo graph_title Battery temperature
			echo graph_vlabel grad-C
			echo graph_category sensors
			echo battery.label Battery
			echo battery.colour FF0000
			echo battery.warning 160:520
			echo battery.critical 90:650
			echo battery.cdef battery,10,/
			;;
		swap)
			echo 'graph_title Swap in/out'
			echo 'graph_args -l 0 --base 1000'
			echo 'graph_vlabel pages per ${graph_period} in (-) / out (+)'
			echo 'graph_category system'
			echo 'swap_in.label swap'
			echo 'swap_in.type DERIVE'
			echo 'swap_in.max 100000'
			echo 'swap_in.min 0'
			echo 'swap_in.graph no'
			echo 'swap_out.label swap'
			echo 'swap_out.type DERIVE'
			echo 'swap_out.max 100000'
			echo 'swap_out.min 0'
			echo 'swap_out.negative swap_in'
			;;
		if_*)
			INTERFACE=${plugin##*_}
			echo "graph_order down up" 
			echo "graph_title $INTERFACE traffic"
			echo 'graph_args --base 1000'
			echo 'graph_vlabel bits in (-) / out (+) per ${graph_period}'
			echo 'graph_category network'
			echo "graph_info This graph shows the traffic of the $INTERFACE network interface. Please note that the traffic is shown in bits per second, not bytes. IMPORTANT: On 32 bit systems the data source for this plugin uses 32bit counters, which makes the plugin unreliable and unsuitable for most 100Mb (or faster) interfaces, where traffic is expected to exceed 50Mbps over a 5 minute period.  This means that this plugin is unsuitable for most 32 bit production environments. To avoid this problem, use the ip_ plugin instead.  There should be no problems on 64 bit systems running 64 bit kernels."
			echo 'down.label received'
        		echo 'down.type COUNTER'
        		echo 'down.graph no'
        		echo 'down.cdef down,8,*'
        		echo 'up.label bps'
			echo 'up.type COUNTER'
			echo 'up.negative down'
			echo 'up.cdef up,8,*'
			;;
		open_files)
			echo 'graph_title File table usage'
			echo 'graph_args --base 1000 -l 0'
			echo 'graph_vlabel number of open files'
			echo 'graph_category system'
			echo 'graph_info This graph monitors the Linux open files table.'
			echo 'used.label open files'
			echo 'used.info The number of currently open files.'
			echo 'max.label max open files'
			echo 'max.info The maximum supported number of open files. Tune by modifying /proc/sys/fs/file-max.'
			awk '{printf "used.warning %d\nused.critical %d\n", $3 * 0.92, $3 * 0.98}' < /proc/sys/fs/file-nr
		esac
		echo .
		;;
	fetch)
		case "$plugin" in
		load)
			set $(cat /proc/loadavg)
			echo load.value $1
			;;
		uptime)
			set $(cat /proc/uptime)
			echo uptime.value $(( ${1%%.*} / 60 ))
			;;
		df)
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" = /mnt/asec/ ] && continue
				echo $dev.value $pusage
			done
			;;
		df_abs)
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" = /mnt/asec/ ] && continue
				echo $dev.value $used
			done
			;;
		df_asec)
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" != /mnt/asec/ ] && continue
				dev=${mp//[!a-zA-Z0-9-]/_}
				echo $dev.value $pusage
			done
			;;
		df_asec_abs)
			disks | while read dev total used pusage mp
			do
				[ "${mp:0:10}" != /mnt/asec/ ] && continue
				dev=${mp//[!a-zA-Z0-9-]/_}
				echo $dev.value $used
			done
			;;
		processes)
			for c in ${procStatChar[@]}; do
				let $c=0
			done
			proclist=(/proc/*/status)
			for process in ${proclist[@]}; do
				sed -ne '2{s/^[^ \t]*[ \t]*\(.\).*/\1/;p;q}' "$process" 2>/dev/null
			done | sort | uniq -c | {
			    while read num char; do
				let $char=$num
			    done
			    for c in ${procStatChar[@]}; do
				echo $c.value ${!c}
			    done
			}
			echo total.value ${#proclist[@]}
			;;
		memory)
			load_mem_data
			
			for mem in Slab SwapCached PageTables VmallocUsed apps MemFree Buffers Cached swap Committed_AS 01Committed_AS Mapped Active ActiveAnon ActiveCache Inactive Inact_dirty Inact_laundry Inact_clean
			do
				[ -n "${mems[$mem]}" ] && echo $mem.value ${mems[$mem]}
			done
			;;
		cpu)
			plugin_cpu_init
			# Note: Counters/derive need to report integer values.  Also we need
			# to avoid 10e+09 and the like %.0f should do this.
			if [ ! -z "$extextinfo" ]; then
				awk -v hz=$HZ '/^cpu / { printf "user.value %.0f\nnice.value %.0f\nsystem.value %.0f\nidle.value %.0f\niowait.value %.0f\nirq.value %.0f\nsoftirq.value %.0f\nsteal.value %.0f\n", $2*100/hz, $3*100/hz, $4*100/hz, $5*100/hz, $6*100/hz, $7*100/hz, $8*100/hz, $9*100/hz }' < /proc/stat
			elif [ ! -z "$extinfo" ]; then
				awk -v hz=$HZ '/^cpu / { printf "user.value %.0f\nnice.value %.0f\nsystem.value %.0f\nidle.value %.0f\niowait.value %.0f\nirq.value %.0f\nsoftirq.value %.0f\n", $2*100/hz, $3*100/hz, $4*100/hz, $5*100/hz, $6*100/hz, $7*100/hz, $8*100/hz }' < /proc/stat
			else
				awk -v hz=$HZ '/^cpu / { printf "user.value %.0f\nnice.value %.0f\nsystem.value %.0f\nidle.value %.0f\n", $2*100/hz, $3*100/hz, $4*100/hz, $5*100/hz }' < /proc/stat
			fi
			;;
		battery_cap)
			echo battery.value `cat /sys/class/power_supply/battery/capacity`
			for charger in usb ac; do
				echo $charger.value $(( $(cat /sys/class/power_supply/$charger/online) * 100 ))
			done
			;;
		battery_temp)
			echo battery.value `cat /sys/class/power_supply/battery/batt_temp`
			;;
		swap)
			if [ -f /proc/vmstat ]; then
				awk '/pswpin/ { print "swap_in.value " $2 } /pswpout/ { print "swap_out.value " $2 }' < /proc/vmstat 
			else
				awk '/swap/ { print "swap_in.value " $2 "\nswap_out.value " $3 }' < /proc/stat 
			fi
			;;
		if_*)
			cat /proc/net/dev | \
			while read interface rxbytes rxpackets rxerrs rxdrop rxfifo rxframe rxcompressed rxmulticast \
			                     txbytes txpackets txerrs txdrop txfifo txcolls txcarrier txcompressed; do
				if [ "$interface" = "${plugin##*_}:" ]; then
					echo down.value $rxbytes
					echo up.value $txbytes
				fi
			done
			;;
		open_files)
			cat /proc/sys/fs/file-nr | { read used n max rest
				echo used.value $(( used - n ))
				echo max.value $max
			}
			;;
		esac
		echo .
		;;
	version)
		echo munin node on $(getprop net.hostname) version: $ver
		;;
	sleep)
		sleep $2
		;;
	cap|*)
		echo "#"
		;;
	quit)
		exit 1
		;;
	esac
}

disks() {
	/system/xbin/df -P -B 1 | while read fs blocks used avail percent mp
	do
		case "$fs" in
		tmpfs|devpts|proc|sysfs)	continue;;
		esac
		if [ "$blocks" -gt 0 -o "$blocks" -le 0 ] 2>/dev/null; then true
		else continue; fi
		
		dev=${fs//[^a-zA-Z0-9-]/_}
		total=$blocks
		#pusage=${percent//[^0-9]/}
		pusage=$(( used * 100 / blocks ))
		echo $dev $total $used $pusage $mp
	done
}

load_mem_data() {
	
	IFS='
'
	for record in `cat /proc/meminfo`; do
	    IFS=' 	
'
	    set $record
	    mem=${1%:}
	    mem=${mem%\)}
	    #mem=${mem//[!a-zA-Z0-9]/_}
	    if expr "$mem" : '.*(' >/dev/null; then
	    	b=${mem##*\(}
	    	mem="$mem${b^}"
	    fi
	    mems[$mem]=$[ $2 * 1024 ]
	done
	    
	    # Only 2.6 and above has slab reported in meminfo, so read slabinfo if it isn't in meminfo
	    if [ -z "${mems[Slab]}" ]; then
		# In 2.0 there is no slabinfo file, so return if the file doesn't open
		tot_slab_pages=0
		slabinfo=$(head -n 1 /proc/slabinfo)
		if expr "$slabinfo" : "slabinfo - version: 1.1" >/dev/null; then
			IFS='
'
	    		for slabinfo in `cat /proc/slabinfo`; do
	    			IFS=' 	
'
	    			set $slabinfo
				let tot_slab_pages+=$6
			done
		fi
		if [ $tot_slab_pages -gt 0 ]; then
			mems[Slab]=$[ tot_slab_pages * 4096 ]
		fi
	    fi
	
	    # Support 2.4 Rmap VM based kernels
	    [ -z "${mems[Inactive]}" -a -n "${mems[Inact_dirty]}" -a -n "${mems[Inact_laundry]}" -a -n "${mems[Inact_clean]}" ] && \
	    	mems[Inactive]=$[ ${mems[Inact_dirty]} + ${mems[Inact_laundry]} + ${mems[Inact_clean]} ]

	mems[apps]=$[ mems[MemTotal] - mems[MemFree] - mems[Buffers] - mems[Cached] - mems[Slab] - mems[PageTables] - mems[SwapCached] ]
	mems[swap]=$[ mems[SwapTotal] - mems[SwapFree] ]

	mems[01Committed_AS]=$[ mems[Committed_AS] / 10 ]
	mems[Committed_AS]=
}

plugin_cpu_init() {
	HZ=100
	scaleto100=no
	extinfo=
	extextinfo=
	if grep -Eq '^cpu +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+' /proc/stat; then
	        extinfo="iowait irq softirq"
		if grep -Eq '^cpu +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+' /proc/stat; then
		    extextinfo="steal"
		fi
	fi
}

munin_node $munin_cmd
