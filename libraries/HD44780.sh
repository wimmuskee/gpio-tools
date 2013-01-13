# HD44780 function library

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


# Set all required GPIO's to output
# direction
function setupHD44780 {
	setupGPIO ${gpio_register} out
	setupGPIO ${gpio_enable} out
	setupGPIO ${gpio_data_0} out
	setupGPIO ${gpio_data_1} out
	setupGPIO ${gpio_data_2} out
	setupGPIO ${gpio_data_3} out
	setupGPIO ${gpio_data_4} out
	setupGPIO ${gpio_data_5} out
	setupGPIO ${gpio_data_6} out
	setupGPIO ${gpio_data_7} out

    powerHD44780 1
    functionHD44780
    writeCommandHD44780 clear
}

# Sets all output signals to zero
# and re-initialize.
function resetHD44780 {
    writeCommandHD44780 00000000
    writeDataHD44780 00000000
    writeGPIO ${gpio_enable} 0
    writeGPIO ${gpio_register} 0

    powerHD44780 1
    functionHD44780
    writeCommandHD44780 clear
}

# Parses a string to separate characters,
# map them to variables containing the
# binary values, and write the data.
function writeStringHD44780 {
	local string=${1}
	local binary
	IFS=$(echo -en "\n\b")

	for l in $(echo ${string} | tr '[:lower:]' '[:upper:]' | fold -w1); do
		binary=$(grep "^${l}," /usr/share/gpio-tools/mappings/HD44780.csv | cut -d ',' -f 2)

		if [ -z $binary ]; then
			# default space
			binary=00100000
		fi
	
		writeDataHD44780 $binary
	done
	unset IFS
}

# Sets the position of the cursor. For
# the HD44780, 80 positions can be selected.
# Select 40 to start on the second line.
function setCursorHD44780 {
    local pos=$1
	local binary

    if [[ $pos -lt 0 ]] || [[ $pos -gt 79 ]]; then
        error "Character position should be between 0 and 79"
    fi

    binary=$(echo "obase=2;$pos" | bc)
    zeros_to_add=$(( 7 - ${#binary}))

    local c=0
    while [ $c -lt $zeros_to_add ]; do
        binary="0"$binary
        c=$(($c + 1))
    done

    writeCommandHD44780 "1"$binary
}

# Does a power command call depending on the
# variables for this call. When one of the cursor
# arguments # isn't present, set them to 0.
function powerHD44780 {
	local power=$1			# 0=off, 1=on
	local cursor=$2			# 0=off, 1=on
	local cursorblink=$3	# 0=off, 1=on

	if [ -z $power ]; then
		error "missing parameters" $FUNCNAME
	fi

	if [ -z $cursor ] || [ -z $cursorblink ]; then
		# writing default if one of the args isn't there
		writeCommandHD44780 00001${power}00
	else
		writeCommandHD44780 00001${power}${cursor}${cursorblink}
	fi
}

# Does a function command call depending on the
# variables for this call. When one of the arguments
# isn't present, set all to 1.
function functionHD44780 {
	local bits=$1	# 0=4, 1=8
	local lines=$2	# 0=8, 1=16
	local size=$3	# 0=5x8, 1=5x10

	if [ -z $bits ] || [ -z $lines ] || [ -z $size ]; then
		# writing default if one of the args isn't there
		writeCommandHD44780 00111100
	else
		writeCommandHD44780 001${bits}${lines}${size}00
	fi
}

# Writes the selected binary with the register
# in command mode. Some predefined commands are
# also available in the mapping.
function writeCommandHD44780 {
	local value=${1}
	local binary=$(grep "^${value}," /usr/share/gpio-tools/mappings/HD44780.csv | cut -d ',' -f 2)

	if [ -z $binary ]; then
		binary=$value
	fi
    
	writeGPIO ${gpio_enable} 1
	writeGPIO ${gpio_register} 0
	setDataHD44780 ${binary}
	writeGPIO ${gpio_enable} 0
	writeGPIO ${gpio_enable} 1
	sleep 0.01
}

# Writes the selected binary with the
# register in data mode.
function writeDataHD44780 {
	local binary=${1}

	writeGPIO ${gpio_enable} 1
	writeGPIO ${gpio_register} 1
	setDataHD44780 ${binary}
	writeGPIO ${gpio_enable} 0
	writeGPIO ${gpio_enable} 1
}

# Sets the data pins with the selected
# binary value.
function setDataHD44780 {
	local binary=${1}

	if [ -z ${binary} ]; then
		error "missing parameters" $FUNCNAME
	fi

	if [[ ${#binary} -ne 8 ]]; then
		error "binary should have 8 characters"
	fi

	writeGPIO ${gpio_data_0} ${binary:7:1}
	writeGPIO ${gpio_data_1} ${binary:6:1}
	writeGPIO ${gpio_data_2} ${binary:5:1}
	writeGPIO ${gpio_data_3} ${binary:4:1}
	writeGPIO ${gpio_data_4} ${binary:3:1}
	writeGPIO ${gpio_data_5} ${binary:2:1}
	writeGPIO ${gpio_data_6} ${binary:1:1}
	writeGPIO ${gpio_data_7} ${binary:0:1}
}
