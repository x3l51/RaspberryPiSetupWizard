If you, like me, setup raspberry pi's quite frequently, you most likely get tired of doing so, because of all the various things to do. I wrote a simple script to help me with most of the stuff that usually takes some time, like setting up WiFi without having a `.conf` with the login data in cleartext, adding a new `root user` and deleting the default `PI user`, setting up `screenfetch` as `MOTD` etc.

You can disable parts of the script easily by commenting out the function calls at the bottom of it.


Download the script:
```
$ sudo wget https://raw.githubusercontent.com/x3l51/RaspberryPiSetupWizard/master/setupRpiWizard.sh
--2019-03-03 10:07:36--  https://raw.githubusercontent.com/x3l51/RaspberryPiSetupWizard/master/setupRpiWizard.sh
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 151.101.12.133
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|151.101.12.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 4870 (4.8K) [text/plain]
Saving to: ‘setupRpiWizard.sh’

setupRpiWizard.sh                                    100%[=====================================================================================================================>]   4.76K  --.-KB/s    in 0s

2019-03-03 10:07:36 (14.6 MB/s) - ‘setupRpiWizard.sh’ saved [4870/4870]
```

Execute it:
```
$ sudo bash setupRpiWizard.sh
```
