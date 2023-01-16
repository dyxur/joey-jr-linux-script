#!/bin/bash
## ARGS: $1: message, $2: input file, $3: path to joey, $4 seek
write_to_joey() {
    echo $1
    dd if="$2" of=/dev/$3 bs=512 seek=$4
}
## check which drive is the BENNVENN drive (Joey Jr.)
drive=$(lsblk | grep BENNVENN | cut -d ' ' -f1 | tr '\n' ' ')

## If drive string is empty return since drive is not connected or mounted
if [ -z "$drive" ]
then
    echo "Nothing found"
    exit
fi

echo "Found at /dev/$drive"

case $1 in
    "ROM") #Write ROM to the cart
        write_to_joey "Writing Rom... This may take minutes" "$2" $drive 37
        ;;
    "FLASH") #Write FLASH save to the cart
        write_to_joey "Writing Flash Save..." "$2" $drive 65573
        ;;
    "SRAM") #Write SRAM save to the cart
        write_to_joey "Writing SRAM..." "$2" $drive 65829
        ;;
    "EEPROM") #Write EEPROM save to the cart
        write_to_joey "Writing EEPROM..." "$2" $drive 66085
        ;;
    "ROMLIST") #Update the ROMLIST
        dd if=$2 of=/dev/$drive bs=512 seek=66341
        echo ROMLIST Update Complete
        ;;
    "MODE")
        echo $2 > mode.txt
        cnt=`echo $2 | wc -c`
        let cnt=cnt-1
        let cnt=512-cnt
        head -c $cnt < /dev/zero >> mode.txt
        dd if=mode.txt of=/dev/$drive bs=512 seek=66725 2>/dev/null
        echo Mode set to $2
        sleep 1

        ## Not Tested
        if [ "$2" == "UPDATE" ]
        then
            dd if=$3 of=/dev/$drive bs=512 seek=66469
            echo Update Complete
        fi
        ;;
esac

## Sleep since the devices take a second to appear busy
sleep 5

## Checks if the drive is busy
isBusy=$(lsof 2>/dev/null | grep /dev/$drive | tr '\n' ' ')

## If drive is busy check until it isn't
while [ ! -z "$(lsof 2>/dev/null | grep /dev/$drive)" ]
do
    echo "Joey is busy. Wait before pulling game out!"
    sleep 5
done

echo "Joey is done. You can remove your game now"
