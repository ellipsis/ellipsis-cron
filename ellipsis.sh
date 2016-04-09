#!/usr/bin/env bash
##############################################################################

cron_warning="# Ellipsis-Cron managed file. Edit with care!"

##############################################################################
pkg.install() {
    local CRONTAB="$(crontab -l 2> /dev/null)"

    # Add crontab warning if not present
    if ! grep "$cron_warning" <<< "$CRONTAB" > /dev/null; then
        # Only add newline if crontab is not empty
        if [ -n "$CRONTAB" ]; then
            crontab <<< "$cron_warning"$'\n'"$CRONTAB"
        else
            crontab <<< "$cron_warning"
        fi
    fi
}

##############################################################################

pkg.link() {
    fs.link_file "$PKG_PATH/bin/ellipsis-cron" "$ELLIPSIS_PATH/bin/ellipsis-cron"
}

##############################################################################

pkg.unlink() {
    rm "$ELLIPSIS_PATH/bin/ellipsis-cron"
}

##############################################################################

pkg.uninstall(){
    local CRONTAB="$(crontab -l 2> /dev/null)"

    # Remove crontab warning if present
    if grep "$cron_warning" <<< "$CRONTAB" > /dev/null; then
        cron_warning="$(sed 's/[\/&]/\\&/g' <<< "$cron_warning")"

        # Remove warning
        local sed_string="/^$cron_warning\$/d"
        CRONTAB="$(sed "$sed_string" <<< "$CRONTAB")"

        if ! crontab <<< "$CRONTAB"; then
            log.error "Could not restore crontab file"
            return 1
        fi
    fi
}

##############################################################################
