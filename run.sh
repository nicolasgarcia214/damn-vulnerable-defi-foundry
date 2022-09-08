#!/usr/bin/env bash

# This script can be used to simplify the execution of tests. 
# You can use the level folder name, the challenge number, or
# the first four letters of the name.


case $1 in

  unstoppable | 1 | unst)
    forge test --match-contract Unstoppable
    ;;

  naive-receiver | 2 | naiv)
    forge test --match-contract NaiveReceiver
    ;;

  truster | 3 | trus)
    forge test --match-contract Truster
    ;;

  side-entrance | 4 | side)
    forge test --match-contract SideEntrance
    ;;

  the-rewarder | 5 | rewa)
    forge test --match-contract TheRewarder
    ;;

  selfie | 6 | self)
    forge test --match-contract Selfie
    ;;

  compromised | 7 | comp)
    forge test --match-contract Compromised
    ;;

  puppet | 8 | pupp)
    forge test --match-contract Puppet --no-match-contract PuppetV2
    ;;

  puppet-v2 | 9 | pupp2)
    forge test --match-contract PuppetV2
    ;;

  free-rider | 10 | free)
    forge test --match-contract FreeRider
    ;;

  backdoor | 11 | back)
    forge test --match-contract Backdoor
    ;;

  climber | 12 | clim)
    forge test --match-contract Climber
    ;;

  safe-miners | 13 | safe)
    forge test --match-contract SafeMiners
    ;;

  *)
    echo "Invalid input use either the challenge number, the name of the contract folder, or the first 4 letter of the name (lowercase)"
    ;;
esac

