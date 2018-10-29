# mn-autosetup
PHC Masternode autosetup script

Release Notes:
Version: 2.00
- Added support of Debian 8/9, CentOS 7, Fedora 27/28
- Reduced questionnaire if installed with default options
- Daemon bind to IP address (Listen in case of NAT detected)
- P2P/RPC IP:port usage detection
- FirewallD configuration support (CentOS/Fedora)
- Added blockchain cache to reduce sync time
- Added MN de-provisioning script (created in directory of daemon)
and lot of other improvements

Login to your VPS and execute:
```
rm phcmnautosetup.sh; wget https://raw.githubusercontent.com/profithunterscoin/mn-autosetup/master/phcmnautosetup.sh && chmod +x phcmnautosetup.sh
```
Now to run the script:
```
./phcmnautosetup.sh
```
Troubleshooting & Notes:

Script has dedicated Discord server for changes follow-up and user support
- https://discord.gg/gEuT56B

Typical installation process shown in the video below
- https://youtu.be/9z7rLQYbIJA
- https://youtu.be/Vr7F9meLaBc

So all steps console and error messages will be recorded to logfile. You can follow it online during script execution in second ssh session using
```
tail -f ~/phcmnsetup.log
```

After script execution you can find the main status of steps execution if you filter logfile for rows containing '# '
```
more ~/phcmnsetup.log | grep '# '
```

If you have slow internet connection, files may be loading for a long time, which may (with low probability) lead to ssh session timeout. To avoid this, I recommend to launch script in screen session. Start new screen session:
```
screen -q
```

Launch the script. If ssh session disconnected, script will continue working. After connection restoration, you can attach the screen session with
```
screen -r -d
```
