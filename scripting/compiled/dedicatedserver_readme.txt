General dedicated server changes for Left4Dead:
===============================================

* There is a new remote access feature which allows a server
  administrator (or software tool) to create a persistent connection
  to a running server, and to see its entire console output and send
  it commands. This feature is enabled by using the "-netconport"
  option when launching srcds. For instance, if a server is started
  with "-netconport 9000", someone with access to port 9000 of the
  server could type "telnet xxxx 9000" and view the console
  output. This feature is disabled by default, and should only be used
  when an appropriate firewall/tunnel is used to control access to
  this port. Multiple clients can connect to the netconport of a
  running server at the same time.

* If the netconsole is enabled, and the option "-netconpassword xxx"
  is set, the network console will not execute commands received
  through the netconport until the command "PASS xxx" is entered.

* Dedicated servers by default participate in matchmaking. Matchmaking
  system allows players to get together in a lobby and then start a game
  on a dedicated server together. To make your Left 4 Dead dedicated
  server easily accessible to your community you would create a Steam group
  and get its group id on Steam community group admin page (say "444").
  Set "sv_steamgroup 444" to make all members of your Steam group have access
  to the server from their main menu. You can also set "sv_steamgroup_exclusive 1"
  which will require that at least one player from your Steam group has to join
  the server before public people will be able to join via matchmaking.

Linux-specific dedicated server changes for Left4Dead
=====================================================

There have been many changes, enhancements, and optimizations with the
dedicated server for Linux:

* All of the code is now being compiled with gcc 4.3.0 and glibc 2.8-8
  in order to take advantage of compiler fixes and optimization
  enhancements. In order to run the l4d Linux dedicated server, you
  will need a system which can run binaries built against this version
  of glibc.

* As a performance enhancement, the dedicated server can now use the
  hardware "RDTSC" timer instead of gettimeofday() for its internal
  timing, on systems which support it ( such systems are identified by
  having the "constant_tsc" flag set in /proc/cpuinfo ). When the code
  detects that the system has this, it will execute a benchmark to
  measure the actual rate of the hardware timer, and use this for all
  timing. If this causes trouble on a system, you can set the
  environment variable "RDTSC_FREQUENCY" to "disabled".

* The Linux dedicated server is now capable of running multiple
  server instances as sub-processes off of one parent process. This
  provides a memory savings (through sharing of read-only data), a
  speedup when starting multiple servers, and also enhances server
  stability by having the servers restart as new sub-processes after
  each game is completed. This is controlled by the "-fork n" option.
  For instance, you can run "srcds_run -fork 5" to start up 5 separate
  server instances in this mode.

* When -fork mode is enabled, some options on the command line can be
  parametrized based upon the server instance, by typing '##' on the
  launching line. For instance, "-fork 10 -netconport 90##" would
  cause the first server instance to use port 9001, the second to use
  9002, etc.

* When running with -fork mode and a netconsole, the control/parent
  process will also listen on a port and accept commands. For
  instance, if you start the server with "-fork 10 -netconport 90##",
  the parent will accept netconsole connections on port 9000, the
  first child will accept netconsole connections on port 9001,
  etc. You can see a list of commands accepted by the parent process
  by connecting to it and typing "find". useful commands are:

  status		   see status of all children.
  shutdown         cleanly shutdown the server when all games have finished.
  broadcast <cmd>  execute the console command 'cmd' on all active subprocesses.

  Note that this netconsole also obeys the set -netconpassword. You
  should always set a password unless you are otherwise protecting
  access to your netconsole ports (for insatnce via a firewall/ssh
  tunnel).

* The linux dedicated server supports a watchdog timer functionality,
  which is enabled by default. The intent of this timer is to make
  anything which hangs the server, either due to unknown bugs or
  misconfiguration, cause an abort, so that the server may restart or
  be debugged. In the case of a forked server, this will cause a new
  subprocess to start to replace the crashed one. On a non-forked
  server, this can be used in conjunction with an auto-restart script
  in order to increase server availability. If you see your server
  dying with SIGALRM (signal 14), it means that this has triggered
  because of either a server frame taking longer than 5 seconds of
  wall time, or a map load taking too long. If this code causes
  trouble for you, it can be disabled via giving the "-nowatchdog"
  option on the command line.


  
