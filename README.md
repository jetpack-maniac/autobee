# AutoBee v1.0
Last Updated: 16 June 2016

## 1. Purpose

AutoBee automates Apiaries.  AutoBee was written because no programs are capable of automating bee needs in Forestry v4.  It was written with complete cross platform compatibility between OpenComputers and ComputerCraft.

## 2. Usage

AutoBee will replace princesses and drones as generations die off and empty the output of the apiary into the attached chest.  It is not capable of breeding Bees (yet!) but will maintain constant uptime on apiaries to maximize output with minimal user interaction.

AutoBee automates Forestry Apiaries.  Currently Bee Houses and Alvearies are not supported.  It will only attempt to utilize attached Apiaries.  ComputerCraft has no limit to the amount of Apiaries that can be attached.  OpenComputers connected Apiaries is limited to the CPU you are using.  There is no other difference in platforms in term of function and performance.

## 3. Relevant Mod Versions:

Written on:
- Minecraft                   1.7.10
- Forge                       10.13.4.1614-1.7.10
- Forestry                    4.2.11.59
- OpenComputers               1.5.22.46
- ComputerCraft               1.75
- OpenPeripherals All In One  7

Will it work on others?  Potentially.  If not, the code was made as modular as possible to keep version to version updates as streamlined as possible.

## 4. Configuration

```sh
chestSize = 27
 ```

This is the size of the chest type you are using.  Currently AutoBee uses a pair of reserved slots in it's output chest for the princess and drones necessary to keep the hive running.

```sh
chestDir = "up"
```

This is direction of the chest from the apiary.

```sh
Delay = 2
```

Amount of seconds the program waits before checking the apiaries again.

## 5. Considerations

The system is not completely intelligent and cannot completely manage itself.  Keep in mind these aspects and your system will continue to work.

- Does not 'smart' breed bees.

This program will only restart apiaries with first available drone it finds.  If you place a non-pure bred lineage into this it will overflow your output chest in short order.

- OpenComputers basic computer can only run 4 apiaries at a time.

With all tier 1 parts and a screen, GPU, keyboard, and HDD, you can only hook up 4 apiaries before your computer will crash.  Tier 2 and 3 can handle more.

- Physical Layout

The layout must be properly built by the individual before the system can run.  For CC users, you cannot place apiaries next to each other if you are using vanilla chests.  For OC users, you can maximize the amount of apiaries per adapter (up to 5) if you surround the adapter with them (See above for tier 1 limits).

## 6. Links

- OpenComputers Forum Page: https://oc.cil.li/index.php?/topic/913-autobee-automate-your-forestry-bees/
- ComputerCraft Forum Page: http://www.computercraft.info/forums2/index.php?/topic/26629-autobee-automate-your-forestry-bees/
- Pastebin: http://pastebin.com/32eLm50M
- Github: https://github.com/jetpack-maniac/autobee
