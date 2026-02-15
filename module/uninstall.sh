#!/bin/sh

rm -rf /data/bypass_chg
need_gone="bypass bypass_chg_profiler bypass_chg_utility"
manager_paths="/data/adb/ap/bin /data/adb/ksu/bin"

for dir in $manager_paths; do
	[ -d $dir ] && {
		for bin in $need_gone; do
			rm "$dir/$bin"
		done
	}
done
