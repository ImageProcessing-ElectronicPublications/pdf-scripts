#!/bin/sh

check_and_set () {
    if [ -e $1 ]; then
        echo $2 > $1;
    fi
}

echo 'Disable NMI watchdog'
echo 0 > /proc/sys/kernel/nmi_watchdog

echo 'VM writeback timeout'
echo 1500 > /proc/sys/vm/dirty_writeback_centisecs

# echo 5 > /proc/sys/vm/laptop_mode
# rmmod uhci_hcd
# rmmod ohci_hcd
# amixer set Mic mute nocap

echo 'Enable powersave for PCIe ASPM'
echo powersave > /sys/module/pcie_aspm/parameters/policy

echo 'Autosuspend for USB devices'
for i in /sys/bus/usb/devices/*/power/control; do
    echo auto > $i
done

echo 'Autosuspend for PCI Devices'
for i in /sys/bus/pci/devices/*/power/control; do
    echo auto > $i
done

echo 'Enable SATA link power Management'
for i in /sys/class/scsi_host/*/link_power_management_policy; do
    echo min_power > $i
done

echo 'Autosuspend for AC97 audio devices'
check_and_set /sys/module/snd_ac97_codec/parameters/power_save 1

echo 'Autosuspend for HDA audio devices'
check_and_set /sys/module/snd_hda_intel/parameters/power_save_controller Y
check_and_set /sys/module/snd_hda_intel/parameters/power_save 1

echo 'Tune the scheduler for saving power on hyperthreading systems'
check_and_set /sys/devices/system/cpu/sched_mc_power_savings 2
check_and_set /sys/devices/system/cpu/sched_smt_power_savings 2

# -B 1 spins down and up all the time
echo 'Set APM level to low'
hdparm -B 128 /dev/sda > /dev/null 2>/dev/null || echo 'Could not set APM level'

echo 'Set acoustic level to quiet'
hdparm -M 128 /dev/sda > /dev/null 2>/dev/null || echo 'Could not set acoustic level'

echo 'Disable wake-on lan'
ethtool -s eth0 wol d 2>/dev/null || echo 'Could not disable wake-on-lan'

echo 'For intel wireless stuff, to save power'
iwpriv wlan0 set_power 7 2>/dev/null || echo 'Failed to enable powersaving for wifi'
iwconfig wlan0 power timeout 500ms 2>/dev/null || echo 'Failed to enable powersaving for wifi'

echo 'Enable ondemand cpufreq governor'
/sbin/modprobe cpufreq_ondemand > /dev/null 2>&1
for i in /sys/devices/system/cpu/*/cpufreq/scaling_governor; do
    check_and_set $i ondemand 2>/dev/null
done

echo 'Enable aggressive power savings for ondemand governor'
check_and_set /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias 1
check_and_set /sys/devices/system/cpu/cpufreq/ondemand/ignore_nice_load 0
