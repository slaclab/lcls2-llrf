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
    * INstall AMC filler card
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


<!--- ########################################################################################### -->

# Programming the carrier in the LLRF teststand

* shelf manager: shm-b15-rf02
* cpu: cpu-b15-rf02 (tunneled from lcls-dev3)

```
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
   --mcs /afs/slac.stanford.edu/u/re/ruckman/projects/lcls/lcls2-llrf/firmware/targets/AmcCarrierLlrfBsaMpsMsgRx/images/AmcCarrierLlrfBsaMpsMsgRx-0x00000001-20200130143821-ruckman-343b730.mcs


/afs/slac/g/lcls/package/cpsw/utils/ProgramFPGA/current/ProgramFPGA.bash --shelfmanager shm-b084-sp07 --slot 4 --addr 3 --mcs ~ruckman/projects/lcls/cryo-det/firmware/targets/CryoRtmEth/images/CryoRtmEth-0x00000013-20170720163850-ruckman-3fc2f4b.mcs




<!--- ########################################################################################### -->

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

4) Setup for large filesystems on github

```
$ git lfs install
```

5) Verify that you have git version 2.13.0 (or later) installed 

```
$ git version
git version 2.13.0
```

6) Verify that you have git-lfs version 2.1.1 (or later) installed 

```
$ git-lfs version
git-lfs/2.1.1
```

<!--- ########################################################################################### -->

# Clone the GIT repository

```
$ git clone --recursive git@github.com:slaclab/lcls2-llrf
```

<!--- ########################################################################################### -->

# How to build the AMC carrier firmware

1) Setup Xilinx licensing

> If you are on the SLAC network, here's how to setup the Xilinx licensing

```
$ source atlas-rd53-fmc-dev/firmware/setup_env_slac.sh
```

2) Go to the target directory and make the firmware:
```
$ cd lcls2-llrf/firmware/targets/AmcCarrierLlrfBsaMpsMsgRx
$ make
```

3) Optional: Review the results in GUI mode
```
$ make gui
```

<!--- ########################################################################################### -->
