# GPIO function library

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


# Provide an error message and exit.
function error {
    funcref=""
    [ ! -z $2 ] && funcref=" calling ${2}"
    echo "Error: ${1}${funcref}"
    exit 1
}

# Setup a specific gpio by exporting it
# and giving it a direction.
function setupGPIO {
	local gpio=$1
	local direction=$2

	if [ -z ${gpio} ] || [ -z ${direction} ]; then
		error "missing parameters" $FUNCNAME
	fi

	if [ "${direction}" != "in" ] && [ "${direction}" != "out" ]; then
		error "gpio direction should be in or out"
	fi

	# export
	[ ! -d "/sys/class/gpio/gpio${gpio}" ] && echo $gpio > /sys/class/gpio/export

	# direction
	if [ -f "/sys/class/gpio/gpio${gpio}/direction" ]; then
		echo $direction > "/sys/class/gpio/gpio${gpio}/direction"
	else
		error "problem directing gpio${gpio}"
	fi
}

# Read the value for the given gpio.
function readGPIO {
	local gpio=$1

	if [ -z ${gpio} ]; then
		error "missing parameters" $FUNCNAME
	fi

	if [ ! -f "/sys/class/gpio/gpio${gpio}/value" ]; then
		err_msg "GPIO not found: ${gpio}"
	fi

	cat "/sys/class/gpio/gpio${gpio}/value"
}

# Write a value to the given gpio.
function writeGPIO {
	local gpio=$1
	local value=$2

	if [ -z ${gpio} ] || [ -z ${value} ]; then
		err_missing_parameters $FUNCNAME
	fi

	if [ "${value}" != "0" ] && [ "${value}" != "1" ]; then
		error "gpio value should be 0 or 1"
	fi

	if [ ! -f "/sys/class/gpio/gpio${gpio}/value" ]; then
		error "GPIO not found: ${gpio}"
	fi

	echo $value > "/sys/class/gpio/gpio${gpio}/value"
}

# Poll the provided gpio and return
# true when the given value is found.
function pollGPIO {
	local gpio=${1}
	local lookfor=${2}

	signal=$(readGPIO ${gpio})

	if [ "${signal}" == "${lookfor}" ]; then
		echo "true"
	else
		echo ""
	fi
}

# Turn on and off one or more gpio's
# for a number of times (default 1) and
# with a certain speed (default 0.5).
function blinkGPIO {
	local gpios=$1
	local blinktimes=$2
	local blinkspeed=$3
	local c=0

	[ -z $blinktimes ] && blinktimes=1
	[ -z $blinkspeed ] && blinkspeed=0.5

	while [[ $c -lt $blinktimes ]]; do
		for gpio in $gpios; do
			writeGPIO ${gpio} 1
		done
		sleep $blinkspeed

		for gpio in $gpios; do
			writeGPIO ${gpio} 0
		done
		sleep $blinkspeed

		let c=c+1
	done
}
