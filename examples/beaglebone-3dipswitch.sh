#!/bin/bash
#             1
#  P9-12 ___/ ____
#                 |
#             2   |
#  P9-13 ___/ ____|
#                 |
#             3   |
#  P9-27 ___/ ____|
#                 |
#                 |
# P9-GND _________|

source /usr/share/gpio-tools/boards/beaglebone.sh

# buttons
button_1="gpmc_ben1"	# P9-12
button_2="gpmc_wpn"		# P9-13
button_3="mcasp0_fsr"	# P9-27

# setup signals
setupSignal ${button_1} 37
setupSignal ${button_2} 37
setupSignal ${button_3} 37

# get gpio values
gpio_button_1=$(calculateGPIO ${button_1})
gpio_button_2=$(calculateGPIO ${button_2})
gpio_button_3=$(calculateGPIO ${button_3})

# setup gpio
setupGPIO ${gpio_button_1} in
setupGPIO ${gpio_button_2} in
setupGPIO ${gpio_button_3} in

# now keep polling forever
while [[ 1 -lt 2 ]]; do

	if [ ! -z $(pollGPIO ${gpio_button_1} 0) ]; then
		echo "click button 1"
		sleep 0.2
	fi

	if [ ! -z $(pollGPIO ${gpio_button_2} 0) ]; then
		echo "click button 2"
		sleep 0.2
	fi

	if [ ! -z $(pollGPIO ${gpio_button_3} 0) ]; then
		echo "click button 3"
		sleep 0.2
	fi

	sleep 0.1
done
