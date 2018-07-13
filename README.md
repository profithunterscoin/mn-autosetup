# mn-autosetup
PHC Masternode autosetup script

Login to your VPS and execute:
```
wget https://raw.githubusercontent.com/profithunterscoin/mn-autosetup/master/phcmnautosetup.sh && chmod +x phcmnautosetup.sh
```
Now to run the script:
```
./phcmnautosetup.sh
```

Troubleshooting & Notes:

So all steps console and error messages will be recorded to logfile. You can follow it online during script execution in second ssh session using
```
tail -f ~/phcmnsetup.log
```

After script execution you can find the main status of spets execution if you filter logfile for rows containing '# '
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
