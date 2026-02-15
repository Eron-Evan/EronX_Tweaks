# shellcheck disable=SC2034
SKIPUNZIP=1
SOC=0

abort_unsupported_arch() {
	ui_print "*********************************************************"
	ui_print "! Unsupported ARCH: $ARCH"
	ui_print "! EronX | Bypass Charging does not support your CPU architecture"
	ui_print "! If you think this is wrong, please report to maintainer"
	abort "*********************************************************"
}

abort_corrupted() {
	ui_print "*********************************************************"
	ui_print "! Unable to extract verify.sh!"
	ui_print "! This zip may be corrupted, please try downloading again"
	abort "*********************************************************"
}

soc_recognition_extra() {
	[ -d /sys/class/kgsl/kgsl-3d0/devfreq ] && {
		SOC=2
		ui_print "- Implementing tweaks for Snapdragon"
		return 0
	}

	[ -d /sys/devices/platform/kgsl-2d0.0/kgsl ] && {
		SOC=2
		ui_print "- Implementing tweaks for Snapdragon"
		return 0
	}

	[ -d /sys/kernel/ged/hal ] && {
		SOC=1
		ui_print "- Implementing tweaks for MediaTek"
		return 0
	}

	[ -d /sys/kernel/tegra_gpu ] && {
		SOC=7
		ui_print "- Implementing tweaks for Nvidia Tegra"
		return 0
	}

	return 1
}

recognize_soc() {
	case "$1" in
	*mt* | *MT*) SOC=1 ;;
	*sm* | *qcom* | *SM* | *QCOM* | *Qualcomm*) SOC=2 ;;
	*exynos* | *Exynos* | *EXYNOS* | *universal* | *samsung* | *erd* | *s5e*) SOC=3 ;;
	*Unisoc* | *unisoc* | *ums*) SOC=4 ;;
	*gs*) SOC=5 ;;
	*Intel* | *intel*) SOC=6 ;;
	esac

	case "$SOC" in
	1) ui_print "- Implementing tweaks for MediaTek" ;;
	2) ui_print "- Implementing tweaks for Snapdragon" ;;
	3) ui_print "- Implementing tweaks for Exynos" ;;
	4) ui_print "- Implementing tweaks for Unisoc" ;;
	5) ui_print "- Implementing tweaks for Google Tensor" ;;
	6) ui_print "- Implementing tweaks for Intel" ;;
	0) return 1 ;;
	esac
}

# Flashable integrity checkup
ui_print "- Extracting verify.sh"
unzip -o "$ZIPFILE" 'verify.sh' -d "$TMPDIR" >&2
[ ! -f "$TMPDIR/verify.sh" ] && abort_corrupted
source "$TMPDIR/verify.sh"

# Extract module files
ui_print "- Extracting module files"
extract "$ZIPFILE" 'module.prop' $MODPATH
extract "$ZIPFILE" 'service.sh' $MODPATH
extract "$ZIPFILE" 'uninstall.sh' $MODPATH
extract "$ZIPFILE" 'action.sh' $MODPATH
extract "$ZIPFILE" 'system/bin/bypass_chg_profiler' $MODPATH
extract "$ZIPFILE" 'system/bin/bypass_chg_utility' $MODPATH

# Extract executables
case $ARCH in
"arm64") ARCH_TMP="arm64-v8a" ;;
"arm") ARCH_TMP="armeabi-v7a" ;;
"x64") ARCH_TMP="x86_64" ;;
"x86") ARCH_TMP="x86" ;;
"riscv64") ARCH_TMP="riscv64" ;;
*) abort_unsupported_arch ;;
esac

extract "$ZIPFILE" "libs/$ARCH_TMP/bypass" "$TMPDIR"
cp $TMPDIR/libs/$ARCH_TMP/* "$MODPATH/system/bin"
rm -rf "$TMPDIR/libs"

if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
	# remove action on APatch / KernelSU
	rm "$MODPATH/action.sh"
	# skip mount on APatch / KernelSU
	touch "$MODPATH/skip_mount"
	ui_print "- KSU/AP Detected, skipping module mount (skip_mount)"
	# symlink ourselves on $PATH
	manager_paths="/data/adb/ap/bin /data/adb/ksu/bin"
	BIN_PATH="/data/adb/modules/bypass_chg/system/bin"
	for dir in $manager_paths; do
		[ -d "$dir" ] && {
			ui_print "- Creating symlink in $dir"
			ln -sf "$BIN_PATH/bypass" "$dir/bypass"
			ln -sf "$BIN_PATH/bypass_chg_profiler" "$dir/bypass_chg_profiler"
			ln -sf "$BIN_PATH/bypass_chg_utility" "$dir/bypass_chg_utility"
		}
	done
fi

# Extract webroot
ui_print "- Extracting webroot"
unzip -o "$ZIPFILE" "webroot/*" -d "$MODPATH" >&2

# Set configs
ui_print "- EronX | Bypass Charging configuration setup"
[ ! -d /data/bypass_chg ] && mkdir /data/bypass_chg
[ ! -f /data/bypass_chg/kill_logd ] && echo 0 >/data/bypass_chg/kill_logd
[ ! -f /data/bypass_chg/bypass_charging ] && echo 0 >/data/bypass_chg/bypass_charging
[ ! -f /data/bypass_chg/dnd_gameplay ] && echo 0 >/data/bypass_chg/dnd_gameplay
[ ! -f /data/bypass_chg/gamelist.txt ] && extract "$ZIPFILE" 'gamelist.txt' "/data/bypass_chg"
extract "$ZIPFILE" 'bypass_chg_logo.png' "/data/local/tmp"
touch /data/bypass_chg/_files_on_this_directory_is_critical_for_bypass_chg_module__please_DO_NOT_REMOVE_OR_MODIFY

# Install Bellavita Toast
if ! grep -q "bellavita.toast" /data/system/packages.list; then
	ui_print "- Installing bellavita Toast"
	extract "$ZIPFILE" 'toast.apk' $TMPDIR
	pm install $TMPDIR/toast.apk >&2
	rm -f $TMPDIR/toast.apk
fi

if ! grep -q "bellavita.toast" /data/system/packages.list; then
	ui_print "! Unable to install Bellavita Toast"
	ui_print "! Please install the app manually after installation."
fi

# Permission settings
ui_print "- Permission setup"
set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755

# SOC CODE:
# 1 = MediaTek
# 2 = Qualcomm Snapdragon
# 3 = Exynos
# 4 = Unisoc
# 5 = Google Tensor
# 6 = Intel
# 7 = Nvidia Tegra

# Recognize Chipset
soc_recognition_extra
[ $SOC -eq 0 ] && recognize_soc "$(grep -E "Hardware|Processor" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')" # Try normal way
[ $SOC -eq 0 ] && recognize_soc "$(grep "model\sname" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')"           # Try Intel (or X86) way
[ $SOC -eq 0 ] && recognize_soc "$(getprop ro.board.platform) $(getprop ro.hardware) $(getprop ro.hardware.chipname)"        # Try Android way
[ $SOC -eq 0 ] && {
	ui_print "! Unknown SoC, skipping some tweaks"
	ui_print "! If you think this is wrong, please report to maintainer"
}

echo $SOC >/data/bypass_chg/soc_recognition

# Easter Egg
case "$((RANDOM % 8 + 1))" in
1) ui_print "- Wooly's Fairy Tale" ;;
2) ui_print "- Sheep-counting Lullaby" ;;
3) ui_print "- Fog? The Black Shores!" ;;
4) ui_print "- Adventure? Let's go!" ;;
5) ui_print "- Hero Takes the Stage!" ;;
6) ui_print "- Woolies Save the World!" ;;
7) ui_print "- How much people will let you live for Encore?" ;;
8) ui_print "- Wen Donate?" ;;
esac
