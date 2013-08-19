#!/usr/bin/env python

import sys, os, ConfigParser, pwd, signal, time

svc_name = os.path.basename(sys.argv[0])
solr_instance_name = svc_name.partition("-")[2]

def getuid(user):
    if type(user) is int: return user
    return pwd.getpwnam(user).pw_uid

def close_fds():
    for fd in os.listdir("/proc/self/fd"):
        if os.path.exists("/proc/self/fd/%s" % fd): # listdir will cause an fd to open for /proc/self/fd
            os.close(int(fd))

def get_command(conf):
    command = conf['command']
    if not (type(command) is list or type(command) is tuple):
        command = command.split()
    return command

def daemonize(conf):
    pid = os.fork()
    if pid == 0:
        os.setsid()
        pid = os.fork()
        if pid == 0:
            write_pidfile(conf['pidfile'], os.getpid())
            if "user" in conf:
                uid = getuid(conf["user"])
                os.setreuid(uid, uid)
            os.chdir(conf.get('chdir', '/'))
            os.umask(0)
            close_fds()
            os.open("/dev/null", os.O_RDONLY) # stderr
            os.open("/dev/null", os.O_WRONLY) # stdout
            os.dup2(1, 2)
            env = conf.get('environment', {})
            command_args = get_command(conf)
            command_exec = command_args[0]
            os.execvpe(command_exec, command_args, env)
        else: # parent
            sys.exit(0)
    else: # parent
        return pid

def write_pidfile(pidfile, pid):
    assert type(pid) is int
    with open(pidfile, 'w') as f:
        f.write(str(pid))

def read_pidfile(pidfile):
    with open(pidfile, 'r') as f:
        pid = f.read()
    if not pid.isdigit():
        return False
    return pid

def looks_like_prog(cmd, pid):
    if pid is int: pid = str(int)
    if pid in os.listdir("/proc"):
        cmdline = open("/proc/%s/cmdline" % pid)
        if os.path.basename(cmdline.split("\000")[0]) == os.path.basename(get_command(conf)[0]):
            return True
    return False

def status(conf):
    pid = read_pidfile(conf['pidfile'])
    if not pid: # no pid in pidfile, not sure if service is running or not
        print >> sys.stderr,  "No pid in pidfile"
        return False
    if looks_like_prog(get_command(conf), pid):
        return True
    return False

def start(conf):
    print "Starting %s" % svc_name
    daemonize(conf)

def stop(conf):
    if not status(conf):
        print "%s is already down." % svc_name
        return True
    pid = int(read_pidfile(conf['pidfile']))
    print "Stopping %s" % svc_name
    os.kill(pid, signal.SIGTERM)
    for _ in range(5):
        if not status(conf): break
        sys.stdout.write(".")
        sys.stdout.flush()
        time.sleep(1)
    else:
        print "Failed to stop %s, check if pid %d is still running" % (svc_name, pid)
        return False
    print "done"
    return True

def restart(conf):
    if status(conf): stop(conf)
    start(conf)

def usage():
    print "%s [start|stop|restart|status]" % sys.argv[0]

if __name__ == '__main__':
    config = ConfigParser.SafeConfigParser()
    config.read("/etc/solr/%s/init.conf" % solr_instance_name)
    conf = dict(config.items('main'))

    command = sys.argv[1]
    if command == "start":
        start(conf)
    elif command == "status":
        status(conf)
    elif command == "stop":
        stop(conf)
    elif command == "restart":
        restart(conf)
    else:
        print >> sys.stderr, "Unknown command."
        usage()
        sys.exit(1)
