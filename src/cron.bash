# cron.bash
#
# Main functions for ellipsis-cron
#
##############################################################################

load msg
load log

##############################################################################

cron.add() {
    :
}

##############################################################################

cron.remove() {
    :
}

##############################################################################

cron.enable() {
    :
}

##############################################################################

cron.disable() {
    :
}

##############################################################################

cron.run() {
    local name="$1"
    local opt="$2"

    # Buffer crontab content
    local crontab="$(crontab -l 2> /dev/null)"

    # Build search string to get job
    local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

    # Get the job
    local job="$(awk "$awk_string" <<< "$crontab")"

    # Remove leading #'s
    if [ "${job:0:1}" = "#" ]; then
        job="${job:1}"
    fi

    # Extract time and command
    if [ "${job:0:1}" = "@" ]; then
        local time="$(cut -d ' ' -f1 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1 <<< "$job")"
    else
        local time="$(cut -d ' ' -f1-5 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1-5 <<< "$job")"
    fi

    if [ "$opt" = "debug" ]; then
        (set -x; eval "$cmd")
    else
        (eval "$cmd")
    fi
}

##############################################################################

cron.list() {
    # Buffer crontab content
    local crontab="$(crontab -l 2> /dev/null)"

    # Get all (Ellipsis-Cron) job names from the crontab file
    local job_names="$(awk '/^# Ellipsis-Cron : / { print $NF }' <<< "$crontab")"

    # Print all jobs
    for name in $job_names; do
        # Build search string to get job
        local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

        # Get the job
        local job="$(awk "$awk_string" <<< "$crontab")"

        local color1="\033[32m"
        local color2="\033[0m"

        # Remove leading #'s and mark disabled
        if [ "${job:0:1}" = "#" ]; then
            job="${job:1}"
            color1="\033[33m"
            color2="\033[0m"
        fi

        # Extract time and command
        if [ "${job:0:1}" = "@" ]; then
            local time="$(cut -d ' ' -f1 <<< "$job")"
            local cmd="$(cut -d ' ' --complement -f1 <<< "$job")"
        else
            local time="$(cut -d ' ' -f1-5 <<< "$job")"
            local cmd="$(cut -d ' ' --complement -f1-5 <<< "$job")"
        fi

        msg.print "$color1$name$color2"
        msg.print "  $time"
        msg.print "  $cmd"
    done
}

##############################################################################

cron.edit() {
    if ! crontab -e; then
        log.fail "Could not edit crontab"
        exit 1
    fi
}

##############################################################################
