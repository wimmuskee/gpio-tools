# Beaglebone function library

# Copyright 2012 Wim Muskee <wimmuskee@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


source /usr/share/gpio-tools/gpio.sh
source /usr/share/gpio-tools/mappings/beaglebone

# Sets up omap_mux signal with the provided
# mux mode.
function setupSignal {
    local mode0=$1
    local muxmode=$2

    if [ -z ${mode0} ] || [ -z ${muxmode} ]; then
        error "missing parameters" $FUNCNAME
    fi

	if [ ! -f "/sys/kernel/debug/omap_mux/${mode0}" ]; then
		error "could not find signal: ${mode0}"
	fi

	echo ${muxmode} > "/sys/kernel/debug/omap_mux/${mode0}"
}

# Calculates the gpio value to export
# from the provided signal. Works only
# if the signal is configured to a
# gpio type.
function calculateGPIO {
	local mode0=$1

    if [ -z ${mode0} ]; then
        error "missing parameters" $FUNCNAME
    fi

	if [ ! -f "/sys/kernel/debug/omap_mux/${mode0}" ]; then
		error "could not find signal: ${mode0}"
	fi

	name=$(cat "/sys/kernel/debug/omap_mux/${mode0}" | grep -o $mode0\\.[a-z0-9_]*)
	rawgpio=$(echo $name | cut -d '.' -f 2)

	if [ "${rawgpio:0:4}" == "gpio" ]; then
		major=$(echo ${rawgpio:4} | cut -d '_' -f 1)
		minor=$(echo ${rawgpio:4} | cut -d '_' -f 2)

		echo $(((major*32)+minor))
	else
		error "signal is not a gpio"
	fi
}

# Creates a csv export from all listed
# signals in omap_mux. Also listing the
# pin number when it is defined in the
# mappings.
function exportSignals {
	echo -e "pin;mode;bits;mode0;mode1;mode2;mode3;mode4;mode5;mode6;mode7"

	for s in $(find /sys/kernel/debug/omap_mux -type f); do
		pin=""
		mode0=$(basename ${s})

		# pin assignment
		if [ ! -z $(eval "echo \$$mode0") ]; then
			pin=$(eval "echo \$$mode0")
		fi

		# read and parse file
	    O=$IFS
	    IFS=$(echo -en "\n\b")

		for line in $(cat ${s}); do
			linetype=$(echo ${line} | cut -d ':' -f 1)

			case "${linetype}" in
				"name")
					name=$(echo ${line} | cut -d ' ' -f 2)
					mode=$(echo ${name} | cut -d '.' -f 2)
					bits=$(echo ${line} | cut -d ' ' -f 5 | tr -d '),')
					;;
				"signals")
					mode1=$(echo ${line} | cut -d '|' -f 2 | tr -d ' ')
					mode2=$(echo ${line} | cut -d '|' -f 3 | tr -d ' ')
					mode3=$(echo ${line} | cut -d '|' -f 4 | tr -d ' ')
					mode4=$(echo ${line} | cut -d '|' -f 5 | tr -d ' ')
					mode5=$(echo ${line} | cut -d '|' -f 6 | tr -d ' ')
					mode6=$(echo ${line} | cut -d '|' -f 7 | tr -d ' ')
					mode7=$(echo ${line} | cut -d '|' -f 8 | tr -d ' ')
					;;
			esac
		done

		IFS=$O

		echo "$pin;$mode;$bits;$mode0;$mode1;$mode2;$mode3;$mode4;$mode5;$mode6;$mode7"
	done
}


# Fail if omap_mux dir is not present.
if [ ! -d "/sys/kernel/debug/omap_mux" ]; then
	error "This is not a Beaglebone, or GPIO not configured"
fi
