[![Gem Version](https://badge.fury.io/rb/testlab.png)](http://badge.fury.io/rb/testlab)
[![Dependency Status](https://gemnasium.com/lookout/testlab.png)](https://gemnasium.com/lookout/testlab)
[![Build Status](https://secure.travis-ci.org/lookout/testlab.png)](http://travis-ci.org/lookout/testlab)
[![Coverage Status](https://coveralls.io/repos/lookout/testlab/badge.png?branch=master)](https://coveralls.io/r/lookout/testlab)
[![Code Climate](https://codeclimate.com/github/lookout/testlab.png)](https://codeclimate.com/github/lookout/testlab)

# What is TestLab?

Simply put; a toolkit for building virtual computer labs.

TestLab lets you iterate virtual infrastructure quickly.  Using a `Labfile` you can define how you want your virtual infrastructure laid out.  You can define multiple network segments and containers (i.e. boxen).  TestLab will then build and demolish this virtual infrastructure as you have dictated in the `Labfile`.

TestLab also allows you to template objects, meaning less congestion in your `Labfile`.

TestLab can also import and export containers, making it easy to share them.  TestLab supports the latest LXC versions, allowing for ephemeral cloning operations, furthering your ability to iterate quickly.  TestLab can be used for many other applications, including infrastructure unit and integration testing, allowing for vastly more complex configurations and more effective resource sharing than traditional VM solutions.

TestLab can be run via the command-line or can be interfaced with directly via Ruby code.

# Troubleshooting

To get debug level output run TestLab with a `-v` flag like this:

    tl -v container build -n chef-client

or you can control this by setting the environment variable `VERBOSE` to `1`:

    VERBOSE=1 tl container build -n chef-client

Alternately you can silence the output with the `-q` flag or by setting the environment variable `QUIET` to `1`.

# Reporting Issues and Bugs

If you are having issues, please generate a bug report and reference in an issue on GitHub.

To generate a bug report run the following command:

    $ tl -q bugreport
    Your bug report is located at "/tmp/testlab-bug-report.1391307431".

# Getting Help and General Usage

You can get help a few ways:

* Use the help command to get details on sets of commands or specific commands.
* On Freenode IRC, in #jovelabs

TestLab uses the GLI RubyGem, which gives us a command line pattern similar to that of Git.  Help for commands is not far away, for example:

    tl help
    tl help node recycle
    tl help network build
    tl help container import
    tl help container demolish

You can also shorten commands; for example `tl container recycle` can also be written as `tl con rec`.

When supplying container names you actually have three options.  When you do not supply a container name, it is inferred that you want to run the action against all containers.  Alternately you can supply a single container name or a comma delimited list of container names.  For example:

    tl container build                             # build all containers
    tl container build -n chef-client              # only build the chef-client container
    tl container build -n chef-server,chef-client  # build the chef-server and chef-client container (NOTE: list order dictates execution order)
    tl container build -n \!chef-server            # build all containers, except the chef-server container

# Installation

* Install the latest version of VirtualBox: https://www.virtualbox.org/wiki/Downloads
* Install the latest version of Vagrant: http://www.vagrantup.com/downloads.html
* Install the latest version of RVM: https://rvm.io/rvm/install

# Updating

* Install the latest version of VirtualBox: https://www.virtualbox.org/wiki/Downloads
* Install the latest version of Vagrant: http://www.vagrantup.com/downloads.html

# Lab

## Labfile

The `Labfile` defines your virtual computer lab.  It defines where you want to run your computer lab (i.e. VirtualBox/OpenStack/Bare Metal), what the network topology of that computer lab is and what servers are connect to those networks.

You can override the default `Labfile` by setting the path to your alternate `Labfile` via the environment variable `LABFILE` or via a command line argument (see `tl help` for more details) directly to TestLab.

## Building your Lab

You should build your TestLab node (i.e. VirtualBox VM) and TestLab networks first.  This is the foundation which the containers run on.  You should attempt to keep your TestLab node intact and only cycle your containers.

**The follow commands assume you have functioning VirtualBox, Vagrant and RVM installations.**

    tl build

## Demolishing your Lab

You should demolish your TestLab node gracefully if possible.  This can be easily accomplished.

**The follow commands assume you have functioning VirtualBox, Vagrant and RVM installations.**

    tl demolish

## Importing Labs

Importing entire labs with an embedded `Labfile` is coming soon.


## Containers

### Building Containers

You should import containers because it saves a lot of time.  Building containers from scratch is a time consuming process.  Using shipping container images and ultimately lab images greatly accelerates the speed at which you can move.

**The follow commands assume you have a functioning TestLab node.**

    tl container build --force                 # Force all defined containers to build even if some can be imported
    tl container build                         # Attempts to import all defined containers, building those which can not be imported
    tl container build -n chef-client --force  # Force the 'chef-client' container to build from scratch even if it can be imported
    tl container build -n \!chef-server        # Build all containers, except the 'chef-server' container

### Importing Containers

You should import containers because it saves a lot of time.  Building containers from scratch is a time consuming process.  Using shipping container images and ultimately lab images greatly accelerates the speed at which you can move.

**The follow commands assume you have a functioning TestLab node.**

    tl container import                             # Import all defined containers
    tl container import -n chef-client              # Import the 'chef-client' container
    tl container import -n chef-server,chef-client  # Import the 'chef-server' and 'chef-client' container
    tl container import -n \!chef-server            # Import all containers, except the 'chef-server' container

### Demolishing Containers

You can easily remove all the containers your have defined in your `Labfile` as well as single containers.  You should generally demolish your containers instead of destroying them because the demolish action involves decommissioning.

**The follow commands assume you have a functioning TestLab node with running containers.**

    tl container demolish                             # Demolish all defined containers
    tl container demolish -n chef-client              # Only demolish the 'chef-client' container
    tl container demolish -n chef-client,chef-server  # Only demolish the 'chef-client' and 'chef-server' containers
    tl container demolish -n \!chef-server            # Demolish all containers, except the 'chef-server' container

### Connecting to Containers

**The follow commands assume you have a functioning TestLab node with running containers.**

#### Console

You can easily open an LXC console to a container.  This would be similar to what you get when using IPMI to get a console.

    tl container console -n chef-client

#### SSH

You can easily open an SSH console to a container.  Simply use the SSH command and supply the name of the container you wish to connect to, in this example we are SSH'ing to the chef-client container.

    tl container ssh -n chef-client

#### TCP/UDP/ICMP

You can easily use any type of IP based network communication to talk to your containers.  Your container names will resolve for all containers and for your local machine.  For example if you had a web server running on a container called www-app you could direct your web browser at 'http://www-app' to connect to it.

If you have a container named chef-client and you want to ping it, simply run ping against the host; for example:

    $ ping -c 5 chef-client
    PING chef-client (100.64.13.253) 56(84) bytes of data.
    64 bytes from chef-client (100.64.13.253): icmp_req=1 ttl=63 time=0.463 ms
    64 bytes from chef-client (100.64.13.253): icmp_req=2 ttl=63 time=0.472 ms
    64 bytes from chef-client (100.64.13.253): icmp_req=3 ttl=63 time=0.483 ms
    64 bytes from chef-client (100.64.13.253): icmp_req=4 ttl=63 time=0.493 ms
    64 bytes from chef-client (100.64.13.253): icmp_req=5 ttl=63 time=0.492 ms
    --- chef-client ping statistics ---
    5 packets transmitted, 5 received, 0% packet loss, time 3999ms
    rtt min/avg/max/mdev = 0.463/0.480/0.493/0.026 ms

If you have a container named chef-server and you want to NMAP scan it, simply run nmap against the host; for example:

    $ nmap -sT -vv chef-server
    Starting Nmap 5.21 ( http://nmap.org ) at 2014-01-30 17:18 PST
    Initiating Ping Scan at 17:18
    Scanning chef-server (100.64.13.1) [2 ports]
    Completed Ping Scan at 17:18, 0.00s elapsed (1 total hosts)
    Initiating Connect Scan at 17:18
    Scanning chef-server (100.64.13.1) [1000 ports]
    Discovered open port 80/tcp on 100.64.13.1
    Discovered open port 22/tcp on 100.64.13.1
    Discovered open port 443/tcp on 100.64.13.1
    Discovered open port 444/tcp on 100.64.13.1
    Discovered open port 4000/tcp on 100.64.13.1
    Completed Connect Scan at 17:18, 0.06s elapsed (1000 total ports)
    Nmap scan report for chef-server (100.64.13.1)
    Host is up (0.0029s latency).
    Scanned at 2014-01-30 17:18:14 PST for 0s
    Not shown: 995 closed ports
    PORT     STATE SERVICE
    22/tcp   open  ssh
    80/tcp   open  http
    443/tcp  open  https
    444/tcp  open  snpp
    4000/tcp open  remoteanything
    Read data files from: /usr/share/nmap
    Nmap done: 1 IP address (1 host up) scanned in 0.10 seconds

### Ephemeral Container Cloning

As it stands attempting to iterate infrastructure with Vagrant is a slow and painful process.  Enter LXC and ephemeral cloning.  The idea here is that you have a container that is provisioned to a "pristine" state according to the `Labfile`.  You then clone this container and run actions against the container.  After running your actions against the container you want to maybe tweak your Chef cookbook, for example, and re-run it against the container.  Running an ever changing cookbook in development against the same system over and over again causes drift and problems.  With the cloning you can instantly reinstate the container as it was when you first cloned it.

In order to use the ephemeral cloning in LXC, we first need to put our container or containers into an ephemeral mode.  This allows TestLab to do certain operations on the backend to prepare the container for ephemeral cloning.  Then when you are finished, you can easily return the container to a persistent mode.

For example, to put the container into the ephemeral mode:

    $ tl container ephemeral -n chef-client
    [TL] TestLab v1.1.0 Loaded
    [TL] container chef-client ephemeral                         # Completed in 17.3453 seconds!
    [TL] TestLab v1.1.0 Finished (17.8546 seconds)

Now with our container in the ephemeral mode, we can run all of the normal container tasks against it with one simple caveat.  When you offline the container and bring it back online, it will be reverted to the original state it was in before you put it into the ephemeral mode.  The short of all this is, you can do what you will to the container, but the moment you bounce it (offline then online it) it reverts.  This, as you can imagine, is extremely useful for developing applications and infrastructure as code.

You can quickly revert that chef node back to it's previous state in the event the cookbook you are developing has wrecked the node.  For web developers, imagine having a mysql server running in an ephemeral container; you can quickly roll back all database operations just by bouncing the container.

This is effectively transactions for infrastructure.

To put the container back into the default, persistent mode:

    $ tl container persistent -n chef-client
    [TL] TestLab v1.1.0 Loaded
    [TL] container chef-client persistent                        # Completed in 17.3692 seconds!
    [TL] TestLab v1.1.0 Finished (17.8692 seconds)

## Network Routes

TestLab will add network routes for any networks defined in the `Labfile` witch have the `TestLab::Provisioner::Route` provisioner class specified for them.  This will allow you to directly interact with containers over the network.  Here is an example of the routes added with the multi-network `Labfile`.

    $ tl network route show
    [TL] TestLab v1.1.0 Loaded
    TestLab routes:
    172.16.0.0      192.168.33.2    255.255.255.0   UG        0 0          0 vboxnet0
    [TL] TestLab v1.1.0 Finished (0.5063 seconds)

These routes can be manually manipulated as well (regardless of if you have specified the `TestLab::Provisioner::Route` provisioner class for the networks via the `Labfile`):

    $ tl help network route
    NAME
        route - Manage routes

    SYNOPSIS
        tl [global options] network route  add
        tl [global options] network route  del
        tl [global options] network route  show

    COMMANDS
        add  - Add routes to lab networks
        del  - Delete routes to lab networks
        show - Show routes to lab networks

# Reference

## APT-Cacher NG

If you are prompted for login credentials while using the APT-Cacher NG web UI you should use username admin, password admin .

If you start seeing APT errors in your containers, it is likely because you have some corruption or some other issue with APT-Cacher NG's cache.  Access the URL below if you need to have APT-Cacher NG repair itself.

    http://100.64.13.254:3142/acng-report.html

## Chef-Server Web UI

You can access the Chef server's web UI using the following URL.

    https://chef-server:444

## Chef-Server API

You can access the Chef server's API using the following URL.

    https://chef-server

## Linux Containers (LXC)

### Service Startup Delay

LXC takes around 1-2 minutes before it will switch the runlevel in your container and start executing daemons which are set to start on boot. Because of this if you import a container from an image or clone a container, upon starting that container you will experience this delay before services are automatically started up. There is one exception to this and that is the SSH daemon is started immediately by LXC. This means you can manually SSH in, or use some other method such as capistrano, to start your required services; but it is advisable that you wait and allow the system to start the services as this would indicate that it would properly startup in production.  With some containers such as the chef-server; we use it's provisioner to start the services we want when TestLab brings the container online.

# Using TestLab Programmatically

Accessing TestLab via code is meant to be fairly easy and straightforward.  To get an instance of TestLab you only need about four lines of code:

    log_file = File.join(Dir.pwd, "testlab.log")
    @logger = ZTK::Logger.new(log_file)
    @ui = ZTK::UI.new(:logger => @logger)
    @testlab = TestLab.new(:ui => @ui)

Calling `TestLab.new` without a `:labfile` option will, by default, attempt to read `Labfile` from the current directory.  This behavior can be changed by passing the `:labfile` key with a path to your desired "Labfile" as the value to your `TestLab.new`.

There are several easy accessors available to grab the first container and execute the command `uptime` on it via and SSH connection:

    container = @testlab.containers.first
    container.exec(%(uptime))

We can also execute this command via `lxc-attach`:

    container.lxc.attach(%(-- uptime))

You can access all the nodes for example:

    @testlab.nodes

For more information see the TestLab Documentation, `testlab-repo`, command-line binary and it never hurts to look at the TestLab source itself.

You can also check out the `tl-knife` command-line binary for another example of using TestLab in a programmatic fashion:

* https://github.com/zpatten/testlab/blob/master/bin/tl-knife

# REQUIREMENTS

* Latest VirtualBox Package
* Latest Vagrant Package (non-gem version)
* Ubuntu 13.04 Base Box Recommended

* Ubuntu 13.04 Server 64-bit (Raring) Base Box - https://github.com/zpatten/raring64

# EXAMPLE USE

* See the `testlab-repo` - https://github.com/lookout/testlab-repo

# RUBIES TESTED AGAINST

* Ruby 1.8.7 (REE)
* Ruby 1.8.7 (MBARI)
* Ruby 1.9.2
* Ruby 1.9.3
* Ruby 2.0.0

# RESOURCES

IRC:

* #jovelabs on irc.freenode.net

Documentation:

* http://lookout.github.io/testlab/

Source:

* https://github.com/lookout/testlab

Issues:

* https://github.com/lookout/testlab/issues

# LICENSE

TestLab - A framework for building lightweight virtual laboratories using LXC

* Author: Zachary Patten <zachary AT jovelabs DOT com> [![endorse](http://api.coderwall.com/zpatten/endorsecount.png)](http://coderwall.com/zpatten)
* Copyright: Copyright (c) Zachary Patten
* License: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
