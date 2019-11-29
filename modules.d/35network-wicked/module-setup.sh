#!/bin/bash

# called by dracut
check() {
    local _program

    require_binaries wicked || return 1

    # do not add this module by default
    return 255
}

# called by dracut
depends() {
    echo systemd dbus
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    inst_hook cmdline 99 "$moddir/wicked-config.sh"
    inst_hook initqueue/settled 99 "$moddir/wicked-run.sh"

    inst wicked wickedd wickedd-nanny
    inst_multiple /etc/dbus-1/system.d/org.opensuse.Network*
    inst_dir /etc/wicked/extensions
    inst_dir /usr/lib/wicked
    inst_dir /usr/share/wicked
    inst_dir /var/lib/wicked
    inst_multiple /var/lib/wicked/*.xml

    wicked_units="
        $systemdsystemunitdir/wickedd.service \
        $systemdsystemunitdir/wickedd-auto4.service \
        $systemdsystemunitdir/wickedd-dhcp4.service \
        $systemdsystemunitdir/wickedd-dhcp6.service \
        $systemdsystemunitdir/wickedd-nanny.service"

    inst_multiple $wicked_units

    for unit in $wicked_units; do
        sed -i 's/^After=.*/After=dbus.service/g' $initdir/$unit
        sed -i 's/^Wants=\(.*\)/Wants=\1 dbus.service/g' $initdir/$unit
    done

    systemctl --root "$initdir" enable wickedd.service
}
