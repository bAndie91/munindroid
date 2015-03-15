A set of scripts using unix toolbox serve Android system stats for <a href='http://munin-monitoring.org/'>Munin monitoring</a>.
You will need busybox (or other software providing standard unix commands) installed.

Example graphs:

<img src='http://i.imgur.com/JHLUK.png' height='150' />
<img src='http://i.imgur.com/NmK7o.png' height='150' />

Dependancies:

  * sh
  * bash (>=4.0)
  * busybox
    * nc (netcat)
    * awk
    * sed
    * sort
    * uniq
    * sleep
    * df
    * cat
    * expr
    * grep