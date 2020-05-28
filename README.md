# lcls2-llrf
LCLS-II HPS LLRF MPS/BSA Receiver firmware. 

<!--- ########################################################################################### -->

# Documentation

* [HPS Common Platform: Documentation Homepage](https://confluence.slac.stanford.edu/display/ppareg/LCLS-II+HPS+Common+Platform%3A+Documentation)
* [Presentation on concept](https://docs.google.com/presentation/d/1OO4wDKnGrOmJdl8fZVZN3Vd6vPXTcOh2kO_sZSfTc9E/edit?usp=sharing)
* [MPS/BSA Data Format and Encoding](https://docs.google.com/spreadsheets/d/1yAnKjZJzbtwTWP5RI_DyvOzQI-og5RyX4Gxj4QaJGGg/edit?usp=sharing)

<!--- ########################################################################################### -->

# AMC Carrier Hardware Configuration

* Carrier: 
    * [PC-379-396-01-C06](https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_01_C06) (or newer) 
    * BOM Configuration A00
    * Installed in ATCA slot# 3
* AMC.BAY[0]: 
    * [PC-379-396-09-C02](https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_09_C02): (or newer)
    * SFP[0] = LLRF Fiber[0]    
    * SFP[1] = LLRF Fiber[1]    
    * SFP[7:2] = Empty     
* AMC.BAY[1]: 
    * Unused 
    * Install AMC filler card
* RTM: 
    * Unsued
    * Install RTM filler card
    
 ```   
                                  View from the TOP
             |---------------------------||-------------|
             |-------------|             ||             | 
             |             |             ||   RTM       |
             |    BAY[1]   |             ||-----|       |
             |             |             |      |       |
             |-------------| AMC Carrier |      |       |
fiber[1]    |-------------|             |      |       |
------------|SFP[1]       |             |      |       |
fiber[0]    |    BAY[0]   |             |      |       |
------------|SFP[0]       |             |      |       |
             |-------------|             |      |       |
             |---------------------------|      |-------|
```
Note: 1 fiber per RF station (12 BSA values per RF station)

<!--- ########################################################################################### -->

# Programming the carrier in the LLRF teststand

* shelf manager: shm-b15-rf02
* cpu: cpu-b15-rf02 (tunneled from lcls-dev3)

```bash
# SSH into  lcls-dev3 
$ ssh lcls-dev3 -Y

# Go to the programming directory
$ cd /afs/slac/g/lcls/package/cpsw/utils/ProgramFPGA/current

# Execute the programming script
$ ./ProgramFPGA.bash \
   --shelfmanager shm-b15-rf02 \
   --slot 3 \
   --cpu cpu-b15-rf02 \
   --user laci \
   --mcs /afs/slac.stanford.edu/u/re/ruckman/projects/lcls/lcls2-llrf/firmware/targets/AmcCarrierLlrfBsaMpsMsgRx/images/AmcCarrierLlrfBsaMpsMsgRx-0x00000009-20200312184224-ruckman-22bcb2b.mcs
   
# Check new FW loaded
$ source /afs/slac/g/reseng/IPMC/env.sh
$ amcc_dump_bsi --all shm-b15-rf02/3
================================================================================
| BSI: shm-b15-rf02/3/CEN (shm-b15-rf02/3/4)                                   |
BSI Ld  State:  3          (READY)
BSI Ld Status: 0x00000000  (SUCCESS)
  BSI Version: 0x0103 = 1.3
        MAC 0: 08:00:56:00:4e:65
        MAC 1: 08:00:56:00:4e:66
        MAC 2: 08:00:56:00:4e:67
        MAC 3: 08:00:56:00:4e:68
   DDR status: 0x0003: MemErr: F, MemRdy: T, Eth Link: Up
  Enet uptime:         14 seconds
  FPGA uptime:         15 seconds
 FPGA version: 0x00000009
 BL start adx: 0x04000000
     Crate ID: 0x0001
    ATCA slot: 3
   AMC 0 info: Aux: 01 Ser: 4200000118f89170 Type: 05 Ver: C02 BOM: 00 Tag: 28
     GIT hash: 22bcb2b0566c2e11625d305703a4a9cce19fa439
FW bld string: 'AmcCarrierLlrfBsaMpsMsgRx: Vivado v2019.2, rdsrv307 (x86_64), Built Thu 12 Mar 2020 06:42:24 PM PDT by ruckman'
--------------------------------------------------------------------------------
```

<!--- ########################################################################################### -->

# How to run CPSW with YAML + QT GUI

Instructions based on [this confluence page](https://confluence.slac.stanford.edu/x/_b-PD)

```bash
# In the first SSH terminal, start the server using the start_control_server.sh script
$ ssh lcls-dev3 -Y
$ ssh laci@cpu-b15-rf02 -Y
$ cd /afs/slac/g/lcls/package/cpsw/controlGUI/current
$ ./start_control_server.sh \
   -a 10.0.1.103 \
   -t /afs/slac.stanford.edu/u/re/ruckman/projects/lcls/lcls2-llrf/firmware/targets/AmcCarrierLlrfBsaMpsMsgRx/images/AmcCarrierLlrfBsaMpsMsgRx-0x00000009-20200317081729-ruckman-458c85a.cpsw.tar.gz
   
         CONNECTED to 10.0.1.103:8193
         CONNECTED to 10.0.1.103:8193
         Starting up 'UDP RX Handler (UDP protocol module)'
         Starting up 'RSSI Thread'
         C SYN received, good checksum (state CLNT_WAIT_SYN_ACK)
         Starting up ''Depacketizer' protocol module'
         Starting up 'TDEST VC Demux'
         Starting up 'SRP VC Demux'
         CONNECTED to 10.0.1.103:8194
         CONNECTED to 10.0.1.103:8194
         CONNECTED to 10.0.1.103:8194
         Starting up 'UDP RX Handler (UDP protocol module)'
         Starting up 'UDP RX Handler (UDP protocol module)'
         Starting up 'RSSI Thread'
         C SYN received, good checksum (state CLNT_WAIT_SYN_ACK)
         Starting up ''Depacketizer' protocol module'
         Starting up 'TDEST VC Demux'
         Starting up 'Stream0'
         Starting up 'Stream1'
         Starting up 'Stream2'
         Starting up 'Stream3'
         Starting up 'Stream4'
         Starting up 'Stream5'
         Starting up 'Stream6'
         Starting up 'Stream7'
         Control id = 1
         Starting server at port 8090
```

Note that the server mapped to port 8090`

```bash
# In the Second SSH terminal, start the server using the start_control_server.sh script
$ ssh lcls-dev3 -Y   
$ cd /afs/slac/g/lcls/package/cpsw/controlGUI/current
$ ./start_gui.sh cpu-b15-rf02 8090
```

<!--- ########################################################################################### -->

# Example Screenshots

* [Default Configuration](https://github.com/slaclab/lcls2-llrf/blob/master/screenshots/DefaultConfig.png)
* [Standalone Testing Configuration](https://github.com/slaclab/lcls2-llrf/blob/master/screenshots/StandAloneLoopbackModeConfig.png)
   * Emulates the LLRF MPS/BSA link
   * Useful for FW/SW development without LLRF links connected
* [Standalone Status Registers Example](https://github.com/slaclab/lcls2-llrf/blob/master/screenshots/StandAloneLoopbackMode.png)



<!--- ########################################################################################### -->

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

4) Setup for large filesystems on github

```bash
$ git lfs install
```

5) Verify that you have git version 2.13.0 (or later) installed 

```bash
$ git version
git version 2.13.0
```

6) Verify that you have git-lfs version 2.1.1 (or later) installed 

```bash
$ git-lfs version
git-lfs/2.1.1
```

<!--- ########################################################################################### -->

# Clone the GIT repository

```bash
$ git clone --recursive git@github.com:slaclab/lcls2-llrf
```

<!--- ########################################################################################### -->

# How to build the AMC carrier firmware

1) Setup Xilinx licensing

> If you are on the SLAC network, here's how to setup the Xilinx licensing

```bash
$ source atlas-rd53-fmc-dev/firmware/setup_env_slac.sh
```

2) Go to the target directory and make the firmware:
```bash
$ cd lcls2-llrf/firmware/targets/AmcCarrierLlrfBsaMpsMsgRx
$ make
```

3) Optional: Review the results in GUI mode
```bash
$ make gui
```

<!--- ########################################################################################### -->
