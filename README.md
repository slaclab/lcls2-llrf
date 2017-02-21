# lcls2-llrf
LCLS-II HPS LLRF firmware. 

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) Email Ben Reese (https://github.com/bengineerd) your github username and request to be added to the "lcls-hps" github group
> https://github.com/orgs/slaclab/teams/lcls-hps/repositories

3) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

4) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

5) Setup for large filesystems on github
> $ git lfs install

# Clone the GIT repository
> $ git clone --recursive git@github.com:slaclab/lcls2-llrf

# How to build the firmware

1) Setup Xilinx licensing
> In C-Shell: $ source lcls2-llrf/firmware/setup_env_slac.csh

> In Bash:    $ source lcls2-llrf/firmware/setup_env_slac.sh

2) If not done yet, make a symbolic link to the firmware/
> $ ln -s /u1/$USER/build lcls2-llrf/firmware/build

3) Go to the target directory and make the firmware:
> $ cd lcls2-llrf/firmware/targets/AmcCarrierLlrf/
> $ make

4) Optional: Review the results in GUI mode
> $ make gui
