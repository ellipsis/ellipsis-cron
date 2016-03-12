#!/usr/bin/env bash
##############################################################################

cron_warning="# Ellipsis-Cron managed file. Edit with care!"

##############################################################################
pkg.install() {

    # Add crontab warning if not present
    current_crontab="$(crontab -l 2> /dev/null)"
    if ! grep "$cron_warning" <<< "$current_crontab" > /dev/null; then
        crontab <<< \
"$cron_warning
$current_crontab"
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
    # Remove crontab warning if present
    local current_crontab="$(crontab -l 2> /dev/null)"
    if grep "$cron_warning" <<< "$current_crontab" > /dev/null; then
        crontab -l | grep -v "$cron_warning" | crontab
    fi
}

##############################################################################
