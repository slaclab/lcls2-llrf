# lcls2-llrf
LCLS-II HPS LLRF MPS/BSA Receiver firmware. 


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
    * Empty with AMC filler installed
* RTM: 
    * Empty with RTM filler installed
    
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
