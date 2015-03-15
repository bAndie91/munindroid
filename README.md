A set of scripts using unix toolbox serve Android system stats for Munin monitoring.
You will need busybox (or other software providing standard unix commands) installed.

# Dependancies

  * sh
  * bash (>=4.0)
  * busybox
    ** nc (netcat)
    ** awk
    ** sed
    ** sort
    ** uniq
    ** sleep
    ** df
    ** cat
    ** expr
    ** grep

# INSTALL

1. Copy files to the phone and run make install on Android.
2. Append these lines to /etc/init.local.rc to register MuninDroid service:
```
# MuninDroid
service munin-node /system/bin/logwrapper /data/system/munin/munin-node.sh   
        user root
        group root
```

# Example graphs
![graph1](http://i.imgur.com/JHLUK.png)
![graph2](http://i.imgur.com/NmK7o.png)
