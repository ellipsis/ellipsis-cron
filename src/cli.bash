# cli.bash
#
# CLI functions
#
##############################################################################

load extension
load git
load log
load msg
load utils
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

    # Check if crontab is available
    if ! utils.cmd_exists crontab; then
        log.fail "Could not run crontab"
        msg.print "Please make sure crontab is installed"
        exit 1
    fi

    # Check if cron daemon is running
    if [ "$(ps -e | grep -c cron)" -eq 0 ] ; then
        log.warn "Could not detect running cron daemon!"
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
