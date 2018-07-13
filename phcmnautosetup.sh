#!/bin/bash
# Profit Hunters Coin masternode autosetup script
# for Ubuntu Linux
#
# by unclear#0122
#
# If you want this script to be customized for another coin, please contact author in Discord

VER="1.00"
LOGFILENAME="phcmnsetup.log"

U16WALLETLINK="http://node4.unclear.space:8080/script/phc/ubuntu16.04/phcd_1.0.0.6_ubuntu16.tar.gz"		#for xenial version (16.04), leave it emty if not supported
U17WALLETLINK="http://node4.unclear.space:8080/script/phc/ubuntu17.10/phcd_1.0.0.6_ubuntu17.tar.gz"     #for artful version (17.10), leave it emty if not supported
U18WALLETLINK="http://node4.unclear.space:8080/script/phc/ubuntu17.10/phcd_1.0.0.6_ubuntu17.tar.gz"     #for bionic version (18.04), leave it emty if not supported
BLOCKDUMPLINK="http://node4.unclear.space:8080/script/phc/phc_datadir.tar.gz"
WALLETDIR="phc"                                                                                       	#wallet instalation directory name
DATADIRNAME=".PHC"                                                                                 		#datadir name
CONFFILENAME="phc.conf"                                                                               	#conf file name
DAEMONFILE="phcd"                                                                                    	#daemon file name
CLIFILE="phcd"                                                                                    		#cli file name
P2PPORT="20060"                                                                                         #P2P port number
RPCPORT="20061"                                                                                         #RPC port number
COLLAMOUNT="10000"                                                                                      #collateral amount
TICKER="PHC"                                                                                          	#crypto ticker
BLKCOUNTLINK="curl -s http://54.37.233.45/bc_api.php?request=getblockcount"								#link to explorer API to ger current network height

function print_welcome() {
	echo ""
	echo "##############################################################################"
	echo "###                                                                        ###"
	echo "###               Welcome to PHC masternode autosetup script               ###"
	echo "###                                                                        ###"
	echo "###               Version: $VER              by unclear#0122               ###"
	echo "###                                                                        ###"
	echo "##############################################################################"
	echo

}

function run_questionnaire() {
	if ! [ "$USER" = "root" ]; then
		echo -en " Checking sudo permissions \r"
		sudo lsb_release -a &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		echo -en " Checking sudo permissions \r"
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo permissions check [Successful]" >>${LOGFILE} || echo "#    sudo permissions check [FAILED]" >>${LOGFILE}

		if [ $ec -gt 0 ]; then
			echo -en " ${RED}Failed to get sudo permissions, installation script aborted ${NC}\n"
			exit
		fi
	fi

	echo
	echo "###      SYSTEM PREPARATION PART     ###"
	## System update
	echo
	read -n1 -p 'Update system packages? [Y/n]: ' sysupdtxt
	echo "#    Update system packages? [Y/n]: ${sysupdtxt}" >>${LOGFILE}
	echo
	if [ "$sysupdtxt" = "" ] || [ "$sysupdtxt" = "y" ] || [ "$sysupdtxt" = "Y" ]; then
		sysupdate=1
	elif [ "$sysupdtxt" = "n" ] || [ "$sysupdtxt" = "N" ]; then
		sysupdate=0
	else
		echo "Incorrect answer, system will not be updated"
	fi
	echo

	## SWAP file question
	# detecting current swap size
	curswapmb=$(free -m | grep Swap | grep -oE 'Swap: +[0-9]+ ' | grep -oE '[0-9]+')
	#swapgigs=$(python -c "print ${curswapmb}/1024.0")
	#swapgigs=$(awk '$1 == ($1+0) {$1 = sprintf("%0.1f", $1)} 1' <<<${swapgigs})
	#echo $swapgigs
	if [ $curswapmb -gt 0 ]; then
		swapfilename=$(sudo more /etc/fstab | grep -v '#' | grep swap | grep -oE '^.+ +none' | grep -oE '^.+ ')
        echo "#    Existing SWAP detected: size=${curswapmb}MB; filename=${swapfilename} Swap creation skipped." >>${LOGFILE} 
        echo "Current swap size is ${curswapmb}MB. Script will not create additional swap."    
		#echo $swapfilename
		createswap=0
	else
		read -n1 -p 'Create system SWAP file? [y/N]: ' createswaptxt
		echo "#    Create system SWAP file? [y/N]: ${createswaptxt}" >>${LOGFILE}
		echo
		if [ "$createswaptxt" = "y" ] || [ "$createswaptxt" = "Y" ]; then
			read -p ' Enter SWAP file size in gigabytes ['${swapsizegigs}']: ' swapsizetxt
			echo "#    Enter SWAP file size in gigabytes ['${swapsizegigs}']: ${swapsizetxt}" >>${LOGFILE}
			if [[ $swapsizetxt =~ ^[0-9]+([.][0-9]+)?$ ]]; then
				swapsizegigs=$swapsizetxt
				echo " SWAP file size will be set to ${swapsizegigs}GB"
			elif [ "$createswaptxt" = "" ]; then
				echo " SWAP file size will be set to ${swapsizegigs}GB"
				#swapsizegigs="2"

			else
				echo " SWAP file size will be set to ${swapsizegigs}GB"
				#swapsizegigs="2"

			fi
			createswap=1
		elif [ "$createswaptxt" = "" ] || [ "$createswaptxt" = "n" ] || [ "$createswaptxt" = "N" ]; then
			createswap=0
		else
			echo "Incorrect answer, SWAP file will not be created"
			createswap=0
		fi
	fi
	echo

	## Fail2Ban installation
	read -n1 -p 'Install Fail2Ban intrusion protection? [Y/n]: ' setupf2btxt
	echo "#    Install Fail2Ban intrusion protection? [Y/N]: ${setupf2btxt}" >>${LOGFILE}
	echo
	if [ "$setupf2btxt" = "y" ] || [ "$setupf2btxt" = "Y" ] || [ "$setupf2btxt" = "" ] || [ "$setupf2btxt" = " " ]; then
		setupfail2ban=1
	else
		echo " Fail2Ban will not be installed."
		setupfail2ban=0
	fi
	echo

	## ufw activation
	ufwstatus=$(sudo ufw status | grep -oE '(active|inactive)')
	if [ "$ufwstatus" = "active" ]; then
		echo "Ubuntu firewall 'ufw' already activated"
		echo "#    Ubuntu firewall 'ufw' already activated" >>${LOGFILE}
		p2pufw=$(sudo ufw status | grep -oE ^${P2PPORT}/tcp)
		[ "$p2pufw" = "" ] && p2pufwadd=1 || p2pufwadd=0
		[ $p2pufwadd -eq 1 ] && echo " P2P tcp port '${P2PPORT}' will be added to the list of allowed" || echo " P2P tcp port '${P2PPORT}' already in the list of allowed"
		[ $p2pufwadd -eq 1 ] && echo "#    P2P tcp port '${P2PPORT}' will be added to the list of allowed" >>${LOGFILE} || echo "#    P2P tcp port '${P2PPORT}' already in the list of allowed" >>${LOGFILE}

		rpcufw=$(sudo ufw status | grep -oE ^${RPCPORT}/tcp)
		if [ "$rpcufw" = "" ]; then
			read -n1 -p ' Do you want to add RPC port to list of allowed? [y/N]: ' rpcufwaddtxt
			echo "#    Do you want to add RPC port to list of allowed? [y/N]: ${rpcufwaddtxt}" >>${LOGFILE}
			echo
			if [ "$rpcufwaddtxt" = "y" ] || [ "$rpcufwaddtxt" = "Y" ]; then rpcufwadd=1; else rpcufwadd=0; fi
		else
			echo " RPC tcp port '${RPCPORT}' already in the list of allowed"
			echo "#    RPC tcp port '${RPCPORT}' already in the list of allowed" >>${LOGFILE}
			rpcufwadd=0
		fi
		if [ $rpcufwadd -eq 1 ] || [ $p2pufwadd -eq 1 ]; then setupufw=2; else setupufw=0; fi
	else
		read -n1 -p 'Setup Ubuntu firewall (ufw)? [Y/n]: ' setupufwtxt
		echo "#    Setup Ubuntu firewall (ufw)? [Y/n]: ${setupufwtxt}" >>${LOGFILE}
		echo
		if [ "$setupufwtxt" = "y" ] || [ "$setupufwtxt" = "Y" ] || [ "$setupufwtxt" = "" ] || [ "$setupufwtxt" = " " ]; then setupufw=1; else setupufw=0; fi

		if [ $setupufw -eq 1 ]; then
			echo " P2P tcp port '${P2PPORT}' will be added to the list of allowed"
			p2pufwadd=1
			read -n1 -p ' Do you want to add RPC port to list of allowed? [y/N]: ' rpcufwaddtxt
			echo "#    Do you want to add RPC port to list of allowed? [y/N]: ${rpcufwaddtxt}" >>${LOGFILE}
			echo
			if [ "$rpcufwaddtxt" = "y" ] || [ "$rpcufwaddtxt" = "Y" ]; then rpcufwadd=1; else rpcufwadd=0; fi

			#show list of listening ports
			tcp4ports=$(netstat -ln | grep 'LISTEN ' | grep 'tcp ' | grep -oE '0.0.0.0:[0-9]+' | grep -oE ':[0-9]+' | grep -oE '[0-9]+')
			if ! [ "$tcp4ports" = "" ]; then
				echo
				echo " Following tcp ports currently LISTENING and will be added to list of allowed:"
				while read -r tcp4port; do
					echo -en "  ${PURPLE}+ $tcp4port ${NC}\n"
					portlist+=($tcp4port)
				done <<<$tcp4ports
			fi

			read -n1 -p ' Confirm configuring ufw with above ports? [Y/n]: ' ufwaddcfmtxt
			echo "#   Confirm configuring ufw with above ports? [Y/n]: ${lsnufwaddtxt}" >>${LOGFILE}
			echo
			if [ "$ufwaddcfmtxt" = "y" ] || [ "$ufwaddcfmtxt" = "Y" ] || [ "$ufwaddcfmtxt" = "" ] || [ "$ufwaddcfmtxt" = " " ]; then
				setupufw=1
			else
				echo " Port list not confirmed, canceling ufw setup"
				echo "#    Port list not confirmed, canceling ufw setup" >>${LOGFILE}
				setupufw=0
			fi
		fi
	fi
	echo

	## New user creation
	read -n1 -p 'Create new account? [y/N]: ' createacctxt && echo
	echo "#    Create new account? [y/N]: ${createacctxt}" >>${LOGFILE}
	if [ "$createacctxt" = "y" ] || [ "$createacctxt" = "Y" ]; then
		createuser=1
		# read -n1 -p ' Assign new user with sudo permissions? [Y/n]: ' createsudotxt && echo
		# echo "#     Assign new user with sudo permissions? [Y/n]: ${createsudotxt}" >> ${LOGFILE}
		# if [ "$createsudotxt" = "" ] || [ "$createsudotxt" = "y" ] || [ "$createsudotxt" = "Y" ]; then
		newsudouser=1
		if [ "$USER" = "root" ]; then
			read -n1 -p ' Allow new user sudo without password? [Y/n]: ' sudowopasstxt && echo
			echo "#     Allow new user sudo without password? [Y/n]: ${sudowopasstxt}" >>${LOGFILE}
			if [ "$sudowopasstxt" = "" ] || [ "$sudowopasstxt" = "y" ] || [ "$sudowopasstxt" = "Y" ]; then sudowopass=1; else sudowopass=0; fi
		fi
		# else newsudouser=0;
		# fi

		read -n1 -p ' Install masternode under new user account? [Y/n]: ' newusermntxt && echo
		echo "#     Install masternode under new user account? [Y/n]: ${newusermntxt}" >>${LOGFILE}
		if [ "$newusermntxt" = " " ] || [ "$newusermntxt" = "" ] || [ "$newusermntxt" = "y" ] || [ "$newusermntxt" = "Y" ]; then newusermn=1; else newusermn=0; fi
		echo

		read -p '  Enter username: ' newuser && echo
		echo "#      New username: ${newuser}" >>${LOGFILE}
		if [ $newuser = "" ]; then
			echo -en "${RED}  WARNING: Username cannot be empty, new user will not be created !! ${NC}\n"
			echo "#    WARNING: Username cannot be empty, new user will not be created !!" >>${LOGFILE}
			createuser=0
		else
			echo -en "${PURPLE}  NOTE: There will be no character substitution entering password, just type it!${NC}\n" && echo
			read -sp '  Enter password: ' pwd1 && echo
			read -sp '  Confirm password: ' pwd2 && echo

			if [ "$pwd1" = "$pwd2" ] && ! [ "$pwd1" = "" ]; then
				ePass=$(perl -e "print crypt('${pwd1}', '${newuser}')")
				pwd1=""
				pwd2=""
				echo " Password accepted, password hash: "$ePass
				echo "#   Password accepted, password hash: "$ePass >>${LOGFILE}
			else
				echo
				echo -en "${RED}  WARNING: Passwords not equal or empty, please try one more time. ${NC}\n"
				echo
				echo "#    WARNING: Passwords not equal or empty, please try one more time. " >>${LOGFILE}
				read -sp '  Enter password: ' pwd1 && echo
				read -sp '  Confirm password: ' pwd2 && echo
				if [ "$pwd1" = "$pwd2" ] && ! [ "$pwd1" = "" ]; then
					ePass=$(perl -e "print crypt('${pwd1}', '${newuser}')")
					pwd1=""
					pwd2=""
					echo " Password accepted, password hash: "$ePass
					echo "#   Password accepted, password hash: "$ePass >>${LOGFILE}
				else
					echo -en "${RED} WARNING: Something wrong with passwords, skipping user creation.${NC}\n"
					echo "#    WARNING: Something wrong with passwords, skipping user creation." >>${LOGFILE}
					createuser=0
				fi
			fi
		fi

	else
		createuser=0
	fi
	echo
	echo

	echo "###    MASTERNODE PREPARATION PART   ###"
	## Wallet installation
	echo
	read -n1 -p 'Download and setup wallet? [Y/n]: ' setupwaltxt && echo
	echo "#    Download and setup wallet? [Y/n]: ${setupwaltxt}" >>${LOGFILE}

	if [ "$setupwaltxt" = "" ] || [ "$setupwaltxt" = "y" ] || [ "$setupwaltxt" = "Y" ] || [ "$setupwaltxt" = " " ]; then
		setupwallet=1
		read -n1 -p ' Configure daemon to start after system reboots? [Y/n]: ' crontxt && echo
		echo "#    Configure daemon to start after system reboots? [Y/n]: ${crontxt}" >>${LOGFILE}
		if [ "$crontxt" = "" ] || [ "$crontxt" = "y" ] || [ "$crontxt" = "Y" ] || [ "$crontxt" = " " ]; then
			loadonboot=1
		else
			loadonboot=0
		fi
	elif [ "$setupwaltxt" = "n" ] || [ "$setupwaltxt" = "N" ]; then
		setupwallet=0
	else
		echo -en "${RED}   Incorrect answer, wallet will be downloaded and installed${NC} \n"
	fi

	echo
	## Masternode setup
	read -n1 -p 'Configure masternode? [Y/n]: ' setupmntxt && echo
	echo "#    Configure masternode? [Y/n]: ${setupmntxt}" >>${LOGFILE}

	if [ "$setupmntxt" = "" ] || [ "$setupmntxt" = "y" ] || [ "$setupmntxt" = "Y" ]; then
		read -n1 -p ' Have you already done collateral transaction and have txhash, txoutput and genkey? [Y/n]: ' coldone && echo
		echo "#   Have you already done collateral transaction and have txhash, txoutput and genkey? [Y/n]: ${coldone}" >>${LOGFILE}
		if [ "$coldone" = "" ] || [ "$coldone" = "y" ] || [ "$coldone" = "Y" ] || [ "$coldone" = " " ]; then
			echo "#   Proceeding to MN questionnaire " >>${LOGFILE}
		else
			echo
			echo " Please perform collateral transaction to desired payee address:"
			echo
			echo -en "1. Transfer exactly ${PURPLE}$COLLAMOUNT $TICKER ${NC} to payee address.\n"
			echo -en "2. Request txhash and txoutput via wallet Debug Console: \n"
			echo -en "    Navigate to ${PURPLE}Help -> Debug window -> Console tab${NC} and enter command \n"
			echo
			echo -en "       ${PURPLE}masternode outputs ${NC}\n"
			echo
			echo "3. Generate masternode private key using Debug Console, enter command "
			echo
			echo -en "       ${PURPLE}masternode genkey ${NC}\n"
			echo

			read -n1 -p ' Press any key when ready to continue or Ctrl+C to abort setup ' coldone
		fi

		setupmn=1

		vpsip=$(dig +short myip.opendns.com @resolver1.opendns.com)

		if ! [[ $vpsip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then vpsip="a.b.c.d"; fi
		echo "#    Detected ip address: ${vpsip}" >>${LOGFILE}
		echo
		read -p " Please provide VPS external IP address or accept detected with ENTER [${vpsip}]: " vpsiptxt && echo
		echo "#    Entered ip address: ${vpsiptxt}" >>${LOGFILE}
		if [[ $vpsiptxt =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			vpsip=$vpsiptxt

		elif ! [[ $vpsip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && ! [[ $vpsiptxt =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			vpsip=""
			setupmn=0
			echo -en "${RED}   ERROR: Invalid ip address provided, masternode setup will be aborted.${NC}\n"
		fi

		read -p " Please provide RPC user name (can be any of you like): " rpcuser
		echo "#    Entered rpcuser: ${rpcuser}" >>${LOGFILE}

		read -p " Please provide RPC password (letters and numbers): " rpcpassword
		echo
		echo "#    Entered rpcpassword: ****" >>${LOGFILE} #not recording for security reasons

		read -p " Please provide masternode private key (genkey): " mnprivkey
		echo "#    Entered mnprivkey: ${mnprivkey}" >>${LOGFILE}

		read -p " Please provide collateral tx hash (txhash): " txhash
		echo "#    Entered txhash: ${txhash}" >>${LOGFILE}

		read -p " Please provide collateral tx output (txoutput): " txoutput
		echo "#    Entered txoutput: ${txoutput}" >>${LOGFILE}
		echo

	elif

		[ "$setupmntxt" = "n" ] || [ "$setupmntxt" = "N" ]
	then
		setupmn=0
	else
		echo -en "${RED}   ERROR: Incorrect answer, masternode will not be configured${NC}\n"
	fi

	echo
	echo
	echo "     PLEASE REVIEW ANSWERS ABOVE   "
	read -n1 -p "     Press any key to start installation or Ctrl+C to exit   "

}

function create_swap() {
	# create swap file [0.20]
	ec=0
	echo "CREATING SWAP FILE"
	echo >>${LOGFILE}
	echo "###  SWAP creation started  ###" >>${LOGFILE}
	free -h &>>${LOGFILE}
	echo -en " Creating /swapfile of ${swapsizegigs}GB size \r"
	sudo fallocate -l ${swapsizegigs}G /swapfile &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    fallocate -l ${swapsizegigs}G /swapfile [Successful]" >>${LOGFILE} || echo "#    fallocate -l ${swapsizegigs}G /swapfile [FAILED]" >>${LOGFILE}

	if [ $ec -eq 0 ]; then
		echo -en " Changing permissions of /swapfile \r"
		sudo chmod 600 /swapfile &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    chmod 600 /swapfile [Successful]" >>${LOGFILE} || echo "#    chmod 600 /swapfile [FAILED]" >>${LOGFILE}
	fi
	if [ $ec -eq 0 ]; then
		echo -en " Setting /swapfile type to swap \r"
		sudo mkswap /swapfile &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    mkswap /swapfile [Successful]" >>${LOGFILE} || echo "#    mkswap /swapfile [FAILED]" >>${LOGFILE}
	fi
	if [ $ec -eq 0 ]; then
		echo -en " Switching on /swapfile swap \r"
		sudo swapon /swapfile &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    swapon /swapfile [Successful]" >>${LOGFILE} || echo "#    swapon /swapfile [FAILED]" >>${LOGFILE}
	fi
	if [ $ec -eq 0 ]; then
		echo -en " Updating /etc/sysctl.conf \r"
		sudo sh -c "echo  >> /etc/sysctl.conf" &>>${LOGFILE}
		sudo sh -c "echo 'vm.swappiness=10' >> /etc/sysctl.conf" &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Updating /etc/sysctl.conf [Successful]" >>${LOGFILE} || echo "#    Updating /etc/sysctl.conf [FAILED]" >>${LOGFILE}
	fi
	if [ $ec -eq 0 ]; then
		echo -en " Updating /etc/fstab \r"
		sudo sh -c "echo >> /etc/fstab" &>>${LOGFILE}
		sudo sh -c "echo '/swapfile   none    swap    sw    0   0' >> /etc/fstab" &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Updating /etc/fstab [Successful]" >>${LOGFILE} || echo "#    Updating /etc/fstab [FAILED]" >>${LOGFILE}
	fi

	free -h &>>${LOGFILE}
	echo "###  SWAP creation complete  ###" >>${LOGFILE}
	echo
}

function detect_osversion() {
	osver=$(lsb_release -c | grep -oE '[^[:space:]]+$')
}

function setup_fail2ban() {
	# setup fail2ban [0.20]
	echo "INSTALLING FAIL2BAN INTRUSION PROTECTION"
	echo >>${LOGFILE}
	echo "###  Fail2Ban installation started  ###" >>${LOGFILE}
	ec=0

	echo -en " Downloading and instaling Fail2ban application \r"
	sudo apt-get -y install fail2ban &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Installation of fail2ban [Successful]" >>${LOGFILE} || echo "#    Installation of fail2ban [FAILED]" >>${LOGFILE}

	if [ $ec -eq 0 ]; then
		echo -en " Enabling Fail2ban service autostart \r"
		sudo systemctl enable fail2ban &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Enabling Fail2ban service autostart [Successful]" >>${LOGFILE} || echo "#    Enabling Fail2ban service autostart [FAILED]" >>${LOGFILE}
	fi
	if [ $ec -eq 0 ]; then
		echo -en " Starting Fail2ban service \r"
		sudo systemctl start fail2ban &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Starting Fail2ban service [Successful]" >>${LOGFILE} || echo "#    Starting Fail2ban service [FAILED]" >>${LOGFILE}
	fi
	echo "###  Fail2Ban installation complete  ###" >>${LOGFILE}
	echo

}

function setup_ufw() {
	echo "CONFIGURING UFW FIREWALL"
	echo >>${LOGFILE}
	echo "###  Setup of ufw started  ###" >>${LOGFILE}
	ec=0
	if [ $setupufw -eq 1 ]; then
		#newly activate ufw

		# disallow everything except ssh and masternode inbound ports
		echo -en " Adding 'default deny' rule \r"
		sudo ufw default deny &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo ufw default deny [Successful]" >>${LOGFILE} || echo "#    sudo ufw default deny [FAILED]" >>${LOGFILE}

		echo -en " Switching ufw logging on \r"
		sudo ufw logging on &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo ufw logging on [Successful]" >>${LOGFILE} || echo "#    sudo ufw logging on [FAILED]" >>${LOGFILE}

		#add listening ports
		if [ ${#portlist[@]} -gt 0 ]; then
			for port in "${portlist[@]}"; do
				echo -en " Adding port ${port} to allowed list \r"
				sudo ufw allow $port/tcp &>>${LOGFILE}
				[ $? -eq 0 ] && ec=0 || ec=1
				[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
				[ $ec -eq 0 ] && echo "#    sudo ufw allow ${port}/tcp [Successful]" >>${LOGFILE} || echo "#    sudo ufw allow ${port}/tcp [FAILED]" >>${LOGFILE}
			done
		fi

		#add p2p port
		echo -en " Adding P2P port ${P2PPORT} to allowed list \r"
		sudo ufw allow $P2PPORT/tcp &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo ufw allow ${P2PPORT}/tcp [Successful]" >>${LOGFILE} || echo "#    sudo ufw allow ${P2PPORT}/tcp [FAILED]" >>${LOGFILE}

		#add rpc port
		if [ $rpcufwadd -eq 1 ]; then
			echo -en " Adding RPC port ${RPCPORT} to allowed list \r"
			sudo ufw allow $RPCPORT/tcp &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    sudo ufw allow ${RPCPORT}/tcp [Successful]" >>${LOGFILE} || echo "#    sudo ufw allow ${RPCPORT}/tcp [FAILED]" >>${LOGFILE}
		fi

		# This will only allow 6 connections every 30 seconds from the same IP address.
		echo -en " Adding limits for SSH \r"
		sudo ufw limit OpenSSH &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo ufw limit OpenSSH [Successful]" >>${LOGFILE} || echo "#    sudo ufw limit OpenSSH [FAILED]" >>${LOGFILE}

		#enabling ufw
		echo -en " Enabling ufw \r"
		sudo ufw --force enable &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo ufw --force enable [Successful]" >>${LOGFILE} || echo "#    sudo ufw --force enable [FAILED]" >>${LOGFILE}

	elif [ $setupufw -eq 2 ]; then
		#add ports to active ufw
		if [ $p2pufwadd -eq 1 ]; then
			echo -en " Adding P2P port ${P2PPORT} to allowed list \r"
			sudo ufw allow $P2PPORT/tcp &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    sudo ufw allow ${P2PPORT}/tcp [Successful]" >>${LOGFILE} || echo "#    sudo ufw allow ${P2PPORT}/tcp [FAILED]" >>${LOGFILE}
		fi
		if [ $rpcufwadd -eq 1 ]; then
			echo -en " Adding RPC port ${RPCPORT} to allowed list \r"
			sudo ufw allow $RPCPORT/tcp &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    sudo ufw allow ${RPCPORT}/tcp [Successful]" >>${LOGFILE} || echo "#    sudo ufw allow ${RPCPORT}/tcp [FAILED]" >>${LOGFILE}
		fi

	fi
	echo
}

function system_update() {
	#system update [0.20]
	echo "UPDATING SYSTEM PACKAGES"
	echo >>${LOGFILE}
	echo "###   Update of system package started  ###" >>${LOGFILE}
	ec=0

	echo -en " Updating repositories \r"
	sudo apt-get update -y &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

	echo -en " Updating packages, please wait \r"
	sudo apt-get upgrade -y &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	echo -en " Updating packages              \r"
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Update of system package complete successfully" >>${LOGFILE} || echo "#    Update of system package complete with ERRORS" >>${LOGFILE}
	echo "###  Update of system package complete  ###" >>${LOGFILE}
	echo
}

function setup_wallet() {
	#install pre-requisites
	install_prerequisites
	download_wallet

}

function install_prerequisites() {
	#wallet pre-requisites [0.20]
	echo "INSTALLING PRE-REQUISITE PACKAGES"
	echo >>${LOGFILE}
	echo "###    Pre-requisite installation started    ###" >>${LOGFILE}
	ec=0
	if [ $osver = "xenial" ]; then
		#install Ubuntu 16.04 pre-requisites
		echo -en " Adding new repository \r"
		sudo add-apt-repository -y ppa:bitcoin/bitcoin >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 2
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
        sudo apt-get update -y >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl build-essential libssl-dev libboost-all-dev libqrencode-dev libgmp3-dev miniupnpc libminiupnpc-dev libcurl4-openssl-dev dh-autoreconf libtool libtool-bin libgmp-dev libdb4.8-dev libdb4.8++-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "artful" ]; then
		#install Ubuntu 17.10 pre-requisites
		# LIST TO BE CHECKED
		echo -en " Adding new repository \r"
		sudo add-apt-repository -yu ppa:bitcoin/bitcoin &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
        sudo apt-get update -y >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl libevent-pthreads-2.1-6 libboost1.62-dev libboost1.62-tools-dev libboost-mpi-python1.62 libboost-mpi-python1.62-dev libboost1.62-all-dev libzmq3-dev libminiupnpc-dev libdb4.8-dev libdb4.8++-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "bionic" ]; then
		#install Ubuntu 18.04 pre-requisites
		# LIST TO BE CHECKED
		echo -en " Adding new repository \r"
		sudo add-apt-repository -yu ppa:bitcoin/bitcoin &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
        sudo apt-get update -y >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl libevent-pthreads-2.1-6 libboost1.62-dev libboost1.62-tools-dev libboost-mpi-python1.62 libboost-mpi-python1.62-dev libboost1.62-all-dev software-properties-common libzmq3-dev libminiupnpc-dev libdb4.8-dev libdb4.8++-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	fi
	echo "###    Pre-requisite installation complete    ###" >>${LOGFILE}
	echo
}

function download_wallet() {
	#wallet download [0.30]
	echo "DOWNLOADING AND INSTALLING WALLET"
	echo >>${LOGFILE}
	echo "###    Downloading wallet started    ###" >>${LOGFILE}
	ec=0
	cd ${HOME}
	if [ ! -d "${HOME}/${WALLETDIR}" ]; then
		echo -en " Creating ${WALLETDIR} directory \r"
		[ $newusermn -eq 1 ] && sudo --user=$newuser mkdir ${HOME}/${WALLETDIR} >>${LOGFILE} 2>&1 || mkdir ${HOME}/${WALLETDIR} >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	fi

	if [ $osver = "xenial" ]; then
		#download Ubuntu 16.04 wallet
		filename="${U16WALLETLINK##*/}"
		filepath=$HOME'/'$filename
		echo -en " Loading wallet ${filename} \r"
		[ $newusermn -eq 1 ] && sudo --user=$newuser wget ${U16WALLETLINK} &>>${LOGFILE} || wget ${U16WALLETLINK} &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

	elif [ $osver = "artful" ]; then
		#download Ubuntu 17.10 wallet
		filename="${U17WALLETLINK##*/}"
		filepath=$HOME'/'$filename
		echo -en " Loading wallet ${filename} \r"
		[ $newusermn -eq 1 ] && sudo --user=$newuser wget ${U17WALLETLINK} &>>${LOGFILE} || wget ${U17WALLETLINK} &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

	elif [ $osver = "bionic" ]; then
		#download Ubuntu 18.04 wallet
		filename="${U18WALLETLINK##*/}"
		filepath=$HOME'/'$filename
		echo -en " Loading wallet ${filename} \r"
		[ $newusermn -eq 1 ] && sudo --user=$newuser wget ${U18WALLETLINK} &>>${LOGFILE} || wget ${U18WALLETLINK} &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	fi

	echo "###  Downloading wallet complete  ###" >>${LOGFILE}

	if [ -f $filepath ]; then
		folder="${filename%.*.*}"
		echo -ne " Extracting ${filename} \r"
		[ $newusermn -eq 1 ] && sudo --user=$newuser tar -xvf ${HOME}/${filename} -C ${HOME}/${WALLETDIR}/ &>>${LOGFILE} || tar -xvf ${HOME}/${filename} -C ${HOME}/${WALLETDIR}/ &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

		#echo -ne " Renaming directory to ${WALLETDIR} \r"
		#[ $newusermn -eq 1 ] && sudo --user=$newuser mv ${folder} ${WALLETDIR} &>>${LOGFILE} || mv ${folder} ${WALLETDIR} &>>${LOGFILE}
		#mv ${folder} ${WALLETDIR}
		#[ $? -eq 0 ] && ec=0 || ec=1
		#[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

		echo -ne " Removing archive ${filename} \r"
		[ $newusermn -eq 1 ] && sudo rm -f ${HOME}/${filename} &>>${LOGFILE} || rm -f ${HOME}/${filename} &>>${LOGFILE}
		#rm $filename
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

	fi

	if [ $loadonboot -eq 1 ]; then
		if [ -f $HOME/$WALLETDIR/$DAEMONFILE ]; then
			start_on_reboot
		else
			echo "#    Daemon file doesn't exist, skipping crontab update." >>${LOGFILE}

		fi
	fi
	echo
}

function configure_masternode() {
	#mn configuration    [0.30]
	echo "CONFIGURING MASTERNODE"
	echo >>${LOGFILE}
	echo "###    Masternode configuration started    ###" >>${LOGFILE}
	ec=0
	datadir=$HOME'/'$DATADIRNAME
	coinconf=$datadir'/'$CONFFILENAME
	walletpath=$HOME'/'$WALLETDIR
	cd ${HOME}
	if [ ! -d "$datadir" ]; then
		echo "#      Creating datadirectory" >>${LOGFILE}
		echo -ne " Creating datadirectory \r"
		if [ $newusermn -eq 1 ]; then
			sudo --user=$newuser mkdir ${datadir} 2>>${LOGFILE}
		else
			mkdir $datadir 2>>${LOGFILE}
		fi

		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Creating datadirectory: Successful" >>${LOGFILE} || echo "#      Creating datadirectory: FAILED" >>${LOGFILE}
	fi

	if [ -f $coinconf ]; then
		bakfile=$coinconf".backup_$(date +%y-%m-%d-%s)"
		echo -ne " Creating ${CONFFILENAME} backup \r"
		if [ $newusermn -eq 1 ]; then
			sudo --user=$newuser cp ${coinconf} ${bakfile} 2>>${LOGFILE}
		else
			cp $coinconf $bakfile &>>${LOGFILE}
		fi
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Backup of ${CONFFILENAME}: Successful" >>${LOGFILE} || echo "#      Backup of ${CONFFILENAME}: FAILED" >>${LOGFILE}
	fi
	if [ -f $datadir"/wallet.dat" ]; then
		bakfile=$datadir"/wallet.dat.backup_$(date +%y-%m-%d-%s)"
		echo -ne " Creating wallet.dat backup \r"
		if [ $newusermn -eq 1 ]; then
			sudo --user=$newuser cp ${datadir}/wallet.dat ${bakfile} 2>>${LOGFILE}
		else
			cp $coinconf $bakfile &>>${LOGFILE}
		fi
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Backup of wallet.dat: Successful" >>${LOGFILE} || echo "#      Backup of wallet.dat: FAILED" >>${LOGFILE}

	fi

	#create conf file
	echo -ne " Creating ${CONFFILENAME} \r"
	echo "#      Creating ${CONFFILENAME}      " >>${LOGFILE}
	ec=0
	if [ $newusermn -eq 1 ]; then
		echo > ${datadir}/debug.log >>${LOGFILE} 2>&1 && sudo chmod 400 ${datadir}/debug.log >>${LOGFILE} 2>&1 
		sudo --user=$newuser echo >${coinconf} 2>>${LOGFILE}
		
	else
		echo > ${datadir}/debug.log >>${LOGFILE} 2>&1 && sudo chmod 400 ${datadir}/debug.log >>${LOGFILE} 2>&1
		echo >${coinconf} 2>>${LOGFILE}
	fi

	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#      Creating of ${coinconf}: Successful" >>${LOGFILE} || echo "#       Creating of ${coinconf}: FAILED" >>${LOGFILE}

	echo -ne " Configuring ${CONFFILENAME} \r"
	echo "# RPC configuration part " >>${coinconf}
	echo "server=1" >>${coinconf}
	echo "rpcuser=${rpcuser}" >>${coinconf}
	echo "rpcpassword=${rpcpassword}" >>${coinconf}
	echo "rpcconnect=127.0.0.1" >>${coinconf}
	echo "rpcport=${RPCPORT}" >>${coinconf}
	echo "rpcthreads=8" >>${coinconf}
	echo "rpcallowip=127.0.0.1" >>${coinconf}
	echo >>${coinconf}
	echo "# P2P configuration part" >>${coinconf}
	echo "daemon=1" >>${coinconf}
	echo "listen=1" >>${coinconf}
	echo "externalip=${vpsip}" >>${coinconf}
	echo "port=${P2PPORT}" >>${coinconf}
	echo "maxconnections=256" >>${coinconf}
	echo >>${coinconf}
	echo "# Masternode configuration part" >>${coinconf}
	echo "masternode=1" >>${coinconf}
	echo "masternodeaddr=${vpsip}:${P2PPORT}"   >> ${coinconf}
	echo "masternodeprivkey=${mnprivkey}" >>${coinconf}
	echo >>${coinconf}
	#echo "# Addnode section" >>${coinconf}
	#echo "addnode=aaa.bbb.ccc.ddd:port" >>${coinconf}
	#echo "nodebuglog=1" >>${coinconf}


	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#      Configuring of ${coinconf}: Successful" >>${LOGFILE} || echo "#       Configuring of ${coinconf}: FAILED" >>${LOGFILE}
	chown $USER:$USER ${coinconf} >>${LOGFILE} 2>&1

	#check the daemon not running
	if [ -f ${datadir}/${DAEMONFILE}.pid ]; then
		echo -en " Force stopping daemon \r"
		sudo pkill -9 -f ${DAEMONFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Force stopping daemon: Successful" >>${LOGFILE} || echo "#       Force stopping daemon: FAILED" >>${LOGFILE}
	fi

	#loading blockchain cache
	if  [ ! "$BLOCKDUMPLINK" = "" ]; then
		if [ -f "${datadir}/blk0001.dat" ]; then
			echo -en " Removing blockchain cache \r"
			sudo rm ${datadir}/mncache.dat ${datadir}/mnpayments.dat ${datadir}/peers.dat ${datadir}/blk0001.dat >>${LOGFILE} 2>&1
			sudo rm -R ${datadir}/database/ ${datadir}/txleveldb/ >>${LOGFILE} 2>&1
			echo -en $STATUS0
		fi
		echo -en " Downloading blockchain cache, please wait \r"
		filename="${BLOCKDUMPLINK##*/}"
		[ $newusermn -eq 1 ] && sudo --user=$newuser wget ${BLOCKDUMPLINK} &>>${LOGFILE} || wget ${BLOCKDUMPLINK} &>>${LOGFILE}
		echo -en " Downloading blockchain cache               \r"
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Downloading blockchain cache: Successful" >>${LOGFILE} || echo "#       Downloading blockchain cache: FAILED" >>${LOGFILE}

		echo -en " Extracting blockchain cache \r"
		[ $newusermn -eq 1 ] && sudo --user=$newuser tar -xvf ${HOME}/${filename} -C ${datadir}/ &>>${LOGFILE} || tar -xvf ${HOME}/${filename} -C ${datadir}/ &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Extracting blockchain cache: Successful" >>${LOGFILE} || echo "#       Extracting blockchain cache: FAILED" >>${LOGFILE}

		echo -en " Removing blockchain cache archive \r"
		sudo rm ${HOME}/${filename} &>>${LOGFILE} 
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Extracting blockchain cache deletion: Successful" >>${LOGFILE} || echo "#       Extracting blockchain cache deletion: FAILED" >>${LOGFILE}
	fi

	#starting daemon
	echo "#      Starting daemon      " >>${LOGFILE}
	echo -en " Starting daemon  \r"
	echo "#      Executing "${walletpath}/${DAEMONFILE}" -daemon" >>${LOGFILE}
	if [ $newusermn -eq 1 ]; then
		sudo --user=$newuser ${walletpath}/${DAEMONFILE} -daemon >>${LOGFILE} 2>&1
	else
		${walletpath}/${DAEMONFILE} -daemon >>${LOGFILE} 2>&1
	fi

	[ $? -eq 0 ] && ec=0 || ec=1
	sleep 5
	#echo -en " Starting daemon  \r"
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#      Daemon start: Successful" >>${LOGFILE} || echo "#       Daemon start: FAILED" >>${LOGFILE}

	echo -en " Waiting a bit...  \r"
	sleep 5
	echo -en " Checking pid file \r"
	if [ -f ${datadir}/${DAEMONFILE}.pid ]; then
		pid=$(more ${datadir}/${DAEMONFILE}.pid)
		[ $? -eq 0 ] && ec=0 || ec=1
		echo -en " Checking pid file: pid=${pid} \r"
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Process pid (${pid}): Successful" >>${LOGFILE} || echo "#       Reading pid file: FAILED" >>${LOGFILE}
	else
		pid=0
		echo -en " ${RED}ERROR: Failed to start daemon, further steps aborted ${NC}\n"
		echo
		exit
	fi

	if [ $pid -gt 0 ]; then
		echo -en " Synchronizing with blockchain \r"
		echo "#      Synchronizing with blockchain  " >>${LOGFILE}
		sleep 5
		synched="false"
		netheight=$(curl -s ${BLKCOUNTLINK})
		currentblk=$(${walletpath}/${CLIFILE} getblockcount | grep -oE '[0-9]*' 2>>${LOGFILE})
		while
			[ $currentblk -lt $netheight ]
		do
			currentblk=$(${walletpath}/${CLIFILE} getblockcount | grep -oE '[0-9]*' 2>>${LOGFILE})
			pcent=$(python -c "print ${currentblk}*100.00/${netheight}")
			pcent=$(awk '$1 == ($1+0) {$1 = sprintf("%0.2f", $1)} 1' <<<${pcent})
			echo -en " Synchronizing with blockchain: block ${currentblk} / ${netheight}   [ ${RED}${pcent}%${NC} ]\r"
			echo "#      Loaded blocks: ${currentblk}" >>${LOGFILE}
			sleep 3
			netheight=$(curl -s ${BLKCOUNTLINK})
		done
		synced="true"
		echo -en " Synchronizing with blockchain: block ${currentblk}    [ ${GREEN}100.00%${NC} ]                      \r"
		[ "$synced" = "true" ] && echo -en $STATUS0 || echo -en $STATUS1
		echo "#      Synchronizing with blockchain ...    [ Done ]" >>${LOGFILE}

		#local p2p port check
		echo "#        Checking p2p port reachability to tcp/"$P2PPORT &>>${LOGFILE}
		echo -en " Checking local p2p port reachability to tcp/${P2PPORT} \r"
		portstatus=$((echo > /dev/tcp/$vpsip/$P2PPORT) >/dev/null 2>&1     && echo "Successful" || echo "FAILED")
		[ "$portstatus" = "Successful" ] && echo -en $STATUS0 || echo -en $STATUS1
		[ "$portstatus" = "Successful" ] && echo "#      Local port check: Successful" >>${LOGFILE} || echo "#       Local port check: FAILED" >>${LOGFILE}

		#remote p2p port check
		echo -en " Checking remote p2p port reachability to tcp/${P2PPORT} \r"
		remote_portcheck
		[ "$remportcheck" = "Successful" ] && echo -en $STATUS0 || echo -en $STATUS1
		[ "$remportcheck" = "Successful" ] && echo "#      Remote port check: Successful" >>${LOGFILE} || echo "#       Remote port check: FAILED" >>${LOGFILE}

		#check mnsync status
		echo -en " Synchronizing masternode \r"
		echo "#      Synchronizing masternode ...    " >>${LOGFILE}
		mncount=$(${walletpath}/${CLIFILE} masternode count | grep -oE '[0-9]*' 2>>${LOGFILE})
		synced="false"
		while
			[ $mncount -eq 0 ]
		do
			mncount=$(${walletpath}/${CLIFILE} masternode count | grep -oE '[0-9]*' 2>>${LOGFILE})
			echo -ne " Waiting for masternode synchronization \r"
			sleep 5
		done
		echo -ne " Masternode synchronization                \r"
		synced="true"
		[ "$synced" = "true" ] && echo -en $STATUS0 || echo -en $STATUS1
		[ "$synced" = "true" ] && echo "#      Masternode synchronization: Successful" >>${LOGFILE} || echo "#       Masternode synchronization: FAILED" >>${LOGFILE}

		echo "###  Masternode configuration complete  ###" >>${LOGFILE}
		echo "MASTERNODE CONFIGURATION FINISHED"
		sleep 5
		#check masternode status
		mnstatus=$(${walletpath}/${CLIFILE} masternode debug)
		currentblk=$(${walletpath}/${CLIFILE} getblockcount | grep -oE '[0-9]*' 2>>${LOGFILE})

		echo
		echo "===================================================================="
		echo "                  MASTERNODE CONFIGURATION FINISHED                 "
		echo "===================================================================="
		echo
		echo -en "Node IP endpoint: ${PURPLE}"$vpsip:$P2PPORT"${NC}\n"
		echo -en "Masternode private key: ${PURPLE}"$mnprivkey"${NC}\n"
		echo -en "Collateral tx hash: ${PURPLE}"$txhash"${NC}\n"
		echo -en "Collateral tx output: ${PURPLE}"$txoutput"${NC}\n"
		echo
		echo -en "Local p2p port connection test: "
		[ "$portstatus" = "Successful" ] && echo -en "${GREEN}${portstatus}${NC}\n" || echo -en "${RED}${portstatus}${NC}\n"
		echo -en "Remote p2p port connection test: "
		[ "$remportcheck" = "Successful" ] && echo -en "${GREEN}${remportcheck}${NC}\n" || echo -en "${RED}${remportcheck}${NC}\n"
		echo
		echo -en "Current daemon block: ${PURPLE}${currentblk}${NC}\n"
		echo -en "VPS MN status: "
		[ "$mnstatus" = "Masternode successfully started" ] && echo -en "${GREEN}${mnstatus}${NC}\n" || echo -en "${RED}${mnstatus}${NC}\n"
		echo
		echo -en "Wallet installation path: ${PURPLE}"$walletpath"${NC}\n"
		echo -en "Data directory path: ${PURPLE}"$datadir"${NC}\n"
		echo
		echo "===================================================================="
		echo
		if [ "$portstatus" = "FAILED" ] || [ "$remportcheck" = "FAILED" ]; then
			echo -en "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
			echo
			echo " ATTENTION: P2P port connection test failed!"
			echo
			echo " Please check firewall settings to insure tcp port ${P2PPORT} is"
			echo " reachable from Internet."
			echo
			echo -en "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}\n"
			echo
			echo
		fi
		
		read -n1 -p " Press any key to continue..." ll
		echo
		echo
		#show instruction to start masternode in local wallet
		echo "  PLEASE FOLLOW INSTRUCTIONS BELOW TO START YOUR MASTERNODE  "
		echo
		sleep 3
		echo "1. Open your local wallet."
		echo
		echo -en "2. Navigate to ${PURPLE}Masternodes tab -> My Master Nodes tab${NC}\n"
		echo
		echo "3. Click 'Create...' button and enter following information in the form:"
		echo -en "   Alias:   any alpha-numeric identifier\n"
		echo -en "   Address: ${PURPLE}${vpsip}:${P2PPORT}${NC}\n"
		echo -en "   PrivKey: ${PURPLE}${mnprivkey}${NC}\n"
		echo -en "   TxHash:  ${PURPLE}${txhash}${NC}\n"
		echo -en "   Output Index: ${PURPLE}${txoutput}${NC}\n"
		echo     "   Reward Address and Reward % fields are optional"
		echo
		echo "   Click 'OK' button and then 'Update' button to refresh the list"
		echo
		echo "4. Restart your local wallet and wait for full synchronization"
		echo
		echo -en "5. Navigate to ${PURPLE}Help -> Debug window -> Console tab${NC}\n"
		echo
		echo "6. Start masternode using command (replace 'mnalias' with one entered at step 3):"
		echo
		echo -en "    ${PURPLE}masternode start-alias \"mnalias\" ${NC}\n"
		echo
		echo "======================================================================"
		echo
		read -n1 -p " After successful masternode start in local wallet press any key..." ll
		echo
		echo
		mnstatus=$(${walletpath}/${CLIFILE} masternode debug 2>>${LOGFILE})
		mnstate=$(${walletpath}/${CLIFILE} masternode list status $txhash | grep -oE '(PRE_ENABLED|ENABLED|EXPIRED|WATCHDOG_EXPIRED|NEW_START_REQUIRED|UPDATE_REQUIRED|POSE_BAN|OUTPOINT_SPENT|VIN_SPENT|REMOVE|POS_ERROR)' 2>>${LOGFILE})
		#mnstate=$(${walletpath}/${CLIFILE} listmasternodes $txhash | grep status | grep -oE '(PRE_ENABLED|ENABLED|EXPIRED|WATCHDOG_EXPIRED|NEW_START_REQUIRED|UPDATE_REQUIRED|POSE_BAN|OUTPOINT_SPENT|VIN_SPENT|REMOVE|POS_ERROR)' 2>>${LOGFILE})
		logstate=$mnstate
		if [ "$mnstate" = "" ]; then
			logstate="NOT IN LIST"
			mnstate="${RED}NOT IN LIST${NC}"
		elif [ "$mnstate" = "PRE_ENABLED" ] || [ "$mnstate" = "ENABLED" ]; then
			mnstate="${GREEN}${mnstate}${NC}"
		else
			mnstate="${RED}${mnstate}${NC}"
		fi
		echo "####   POST START CHECKS ####" >>${LOGFILE}
		echo "#   Post-start Mastrnode status: "$mnstatus >>${LOGFILE}
		echo "#   Masternode state: "$logstate >>${LOGFILE}
		echo -en " Post-start Masternode status: "
		[ "$mnstatus" = "masternode started remotely" ] && echo -en "${GREEN}${mnstatus}${NC}\n" || echo -en "${RED}${mnstatus}${NC}\n"
		echo -en " Masternode list state: "$mnstate"\n"
		echo
		echo " Please use command below to check masternode status from command line:"
		echo
		echo -en "${PURPLE}  ${walletpath}/${CLIFILE} masternode list status ${txhash}${NC}\n"
		echo

		if [ $newusermn -eq 1 ]; then
			echo -en "  WARNING: Installation was done under ${PURPLE}${newuser}${NC} account\n"
			echo -en "           To run commands correcly, relogin as ${PURPLE}${newuser}${NC} or switch user with command below: \n"
			echo
			echo -en "               ${PURPLE}cd ${HOME} && su ${newuser}${NC}\n"
			echo

		fi
		echo

	else
		echo -en "${RED} DAEMON FAILED TO START, MASTERNODE SETUP ABORTED ${NC}\n"
		echo "#      Daemon failed to start, masternode setup aborted." >>${LOGFILE}
	fi
}

function remote_portcheck() {
	result=$(curl -sH 'Accept: application/json' https://check-host.net/check-tcp\?host=$vpsip:$P2PPORT\&max_nodes=1)
	echo "#    Remote port check result:" >>${LOGFILE}
	echo $result >>$LOGFILE
	rid=$(echo $result | cut -d',' -f 8)
	link=$(echo ${rid//\\/} | cut -d'"' -f 4)
	sleep 2
	result=$(curl -s $link | grep check_displayer.display | grep -oE 'time|error')
	if [ "$result" = "time" ]; then remportcheck="Successful"; else remportcheck="FAILED"; fi
	if [ "$remportcheck" = "FAILED" ]; then
		# let's check once more
		result=$(curl -sH 'Accept: application/json' https://check-host.net/check-tcp\?host=$vpsip:$P2PPORT\&max_nodes=1)
		echo "#    Remote port check result:" >>${LOGFILE}
		echo $result >>$LOGFILE
		rid=$(echo $result | cut -d',' -f 8)
		link=$(echo ${rid//\\/} | cut -d'"' -f 4)
		sleep 2
		result=$(curl -s $link | grep check_displayer.display | grep -oE 'time|error')
		if [ "$result" = "time" ]; then remportcheck="Successful"; else remportcheck="FAILED"; fi
	fi

}

function create_user() {
	#create non-root user [0.20]
	echo "CREATING NEW USER"
	if [ $newsudouser -eq 1 ]; then
		echo -en " Creating new sudo user (${newuser})\r"
		echo "#    Creating new sudo user (${newuser})" >>${LOGFILE}
		echo "$    sudo useradd -d /home/$newuser -m -G sudo -s /bin/bash -p $ePass $newuser" >>${LOGFILE}
		sudo useradd -d /home/$newuser -m -G sudo -s /bin/bash -p $ePass $newuser &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Creating new sudo user (${newuser}) successful" >>${LOGFILE} || echo "#    Creating new sudo user (${newuser}) FAILED" >>${LOGFILE}
		if [ $sudowopass -eq 1 ]; then
			echo -en " Assigning sudo permissions without password \r"
			echo "#    Assigning sudo permissions without password" >>${LOGFILE}
			sudo echo "${newuser} ALL=(ALL:ALL) NOPASSWD: ALL" >/etc/sudoers.d/$newuser
			sudo chmod 440 /etc/sudoers.d/$newuser &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    Assigning sudo permissions without password successful" >>${LOGFILE} || echo "#    Assigning sudo permissions without password FAILED" >>${LOGFILE}
		fi
	else
		echo -en " Creating new non-sudo user (${newuser})\r"
		echo "#    Creating new non-sudo user (${newuser})" >>${LOGFILE}
		echo "$    sudo useradd -d /home/$newuser -m -s /bin/bash -p $ePass $newuser" >>${LOGFILE}
		sudo useradd -d /home/$newuser -m -s /bin/bash -p $ePass $newuser &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Creating new non-sudo user (${newuser}) successful" >>${LOGFILE} || echo "#    Creating new non-sudo user (${newuser}) FAILED" >>${LOGFILE}
	fi

	if [ $newusermn -eq 1 ]; then
		echo "#    Preparing installation to user ${newuser} profile" >>${LOGFILE}

		if ! [ "$USER" = "root" ]; then
			scriptname="${SCRIPTPATH##*/}"
			echo -en " Copying script to ${newuser} home \r"
			sudo cp $SCRIPTPATH /home/$newuser
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

			echo -en " Changing script owner to ${newuser} \r"
			sudo chown $newuser:$newuset /home/$newuser/*.sh
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

			echo -en "\n${RED} WARNING:${NC} To continue masternode installation please switch to '"${newuser}"' account and launch the script again.\n"
			echo -en " Use below commands to run script under '"${newuser}"' account \n\n"
			echo -en "   ${PURPLE} cd /home/${newuser} && su ${newuser} \n"
			echo -en "   ./${scriptname} ${NC}\n\n"
			echo " SCRIPT TERMINATED "
			exit

		fi
		HOME=$(su -c 'cd ~ && pwd' ${newuser}) #update home directory
		USER=$newuser                          #update current user
		echo " Installation will continue using user profile: "$USER
		echo
	else
		echo
	fi

}

function start_on_reboot() {
	#update crontab to tart daemon on reboot
	if [ $loadonboot -eq 1 ]; then
		if [ $newusermn -eq 1 ]; then
			crontab -u ${newuser} -l 2>>${LOGFILE} 1>/tmp/tempcron
		else
			crontab -l 2>>${LOGFILE} 1>/tmp/tempcron
		fi
		crn=$(more /tmp/tempcron | grep $HOME'/'$WALLETDIR'/'$DAEMONFILE)
		if [ "$crn" = "" ]; then
			echo -en " Updating crontab \r"
			echo "#    Updating crontab " >>${LOGFILE}

			echo "@reboot ${HOME}/${WALLETDIR}/${DAEMONFILE} -daemon" 1>>/tmp/tempcron 2>>${LOGFILE}

			if [ $newusermn -eq 1 ]; then
				crontab -u ${newuser} /tmp/tempcron >>${LOGFILE}
			else
				crontab /tmp/tempcron >>${LOGFILE}
			fi
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

			if [ $newusermn -eq 1 ]; then
				crontab -u ${newuser} -l >>${LOGFILE}
			else
				crontab -l >>${LOGFILE}
			fi

			[ $ec -eq 0 ] && echo "#    crontab update: Successful" >>${LOGFILE} || echo "#    crontab update: FAILED" >>${LOGFILE}
		fi
		rm /tmp/tempcron
	fi

}

function check_os_support() {
	if [ "${osver}" = "xenial" ]; then
		if [ "$U16WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	elif [ "${osver}" = "artful" ]; then
		if [ "$U17WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	elif [ "${osver}" = "bionic" ]; then
		if [ "$U18WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	else
		echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
		exit
	fi
}

function print_devsupport() {
	echo
	echo " Thank you for using this script. If you found it helpful, you can support developer donating to the address below."
	echo
	echo " ${TICKER}: PU22AgPFdj1PDqWESgEZQot9jj4KjRgzVH"
	echo

}

#switches
sysupdate=0
createswap=0
setupufw=0
setupfail2ban=0
createuser=0
setupwallet=0
setupmn=0

#defaults
swapsizegigs="2.0"
newsudouser=0
sudowopass=0
newusermn=0
loadonboot=0
newuser=""
ePass=""
osver=""
vpsip=""
rpcuser=""
rpcpassword=""
mnprivkey=""
txhash=""
txoutput=""
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
portlist=()

# main procedure
SCRIPTPATH=$(readlink -f $0)

cols=$(tput cols)
if [ $cols -ge 100 ]; then cols=100; fi
mv=$(expr $cols - 11)
STATUS1="\033[${mv}C [${RED} FAILED ${NC}]\n"   #[ FAILED ]
STATUS0="\033[${mv}C [ ${GREEN} DONE ${NC} ]\n" #[  DONE  ]

cd ~
USER=$(whoami)               #current user
HOME=$(pwd)                  #home directory
LOGFILE=$HOME"/"$LOGFILENAME #create log full path
detect_osversion             #run OS version detection
echo >${LOGFILE}             #clear log file
echo "Script version: ${VER}" >>${LOGFILE}
echo "OS detected: ${osver}" >>${LOGFILE}
check_os_support
#clear
print_welcome                                #print welcome frame
echo "OS $(lsb_release -d) (${osver})"       #print OS version

echo "Running script using account: ${USER}" #print user account
echo "Current user home directory: ${HOME}"  #print user home dir
echo "Installation log file: "$LOGFILE       #path to log
echo

run_questionnaire #run user questionnaire

echo
echo "###############################"
echo "#     STARTING NODE SETUP     #"
echo "###############################"
echo
if [ $createswap -eq 1 ]; then create_swap; fi
if [ $sysupdate -eq 1 ]; then system_update; fi
if [ $setupfail2ban -eq 1 ]; then setup_fail2ban; fi
if [ $setupufw -ge 1 ]; then setup_ufw; fi
if [ $createuser -eq 1 ]; then create_user; fi
if [ $setupwallet -eq 1 ]; then setup_wallet; fi
if [ $setupmn -eq 1 ]; then configure_masternode; fi
echo
echo "###############################"
echo "#      NODE SETUP FINISHED    #"
echo "###############################"
echo
print_devsupport
