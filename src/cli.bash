# cli.bash
#
# CLI functions
#
##############################################################################

load extension
load msg
load log
load git
load cron

##############################################################################

# prints usage
cli.usage() {
msg.print "\
Usage: ellipsis-$ELLIPSIS_XNAME_L <command>
  Options:
    -h, --help     show help
    -v, --version  show version

  Commands:
    add             Add a cron job
    remove|rm       Remove a cron job
    enable          Enable an inactive cron job
    disable         Disable an active cron job
    list|ls         List cron jobs
    run             Run a cron job manualy (in current tty)
    debug           Run a cron job manualy with debug output (bash -x)
    edit            Edit your crontab manualy"
}

##############################################################################

# prints version
cli.version() {
    local cwd="$(pwd)"
    cd "$ELLIPSIS_XPATH"

    local sha1="$(git.sha1)"
    msg.print "\033[1mv$ELLIPSIS_XVERSION\033[0m ($sha1)"

    cd "$cwd"
}

##############################################################################

cli.run() {
    # Check if Ellipsis version is sufficient
    if ! extension.is_compatible; then
        log.fail "Ellipsis-$ELLIPSIS_XNAME v$ELLIPSIS_XVERSION needs at least Ellipsis v$ELLIPSIS_VERSION_DEP"
        msg.print "Please update Ellipsis!"
        exit 1
    fi

    case "$1" in
        add)
            cron.add "${@:2}"
            ;;
        remove|rm)
            cron.remove "${@:2}"
            ;;
        list | ls)
            cron.list "${@:2}"
            ;;
        enable)
            cron.enable "${@:2}"
            ;;
        disable)
            cron.disable "${@:2}"
            ;;
        run)
            cron.run "${@:2}"
            ;;
        debug)
            cron.debug "${@:2}"
            ;;
        edit)
            cron.edit
            ;;
        help|--help|-h)
            cli.usage
            ;;
        version|--version|-v)
            cli.version
            ;;
        *)
            if [ $# -gt 0 ]; then
                msg.print "ellipsis-$ELLIPSIS_XNAME_L: invalid command -- $1"
            fi
            cli.usage
            return 1
            ;;
    esac
}

##############################################################################
