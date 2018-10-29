#!/bin/bash
#
# Masternode Autosetup Script
# for Debian/Ubuntu/CentOS/Fedora Linux
#
# by unclear#0122
#
# If you want this script to be customized for another coin, please contact author in Discord
#
#     Official Discord server: https://discord.gg/dF6JvJf
#
# This code or parts of this code can be used only under agreement with author.
# Please contact author in official Discord in order to arrange such agreement.
#
# Unauthorized forking is strictly forbidden.
#

VERSION="2.00"
LOGFILENAME="phcmnsetup.log"

# WALLET(DAEMON) LINKS
U14WALLETLINK=""           	 	#for trusty version (14.04), leave it empty if not supported
U16WALLETLINK="http://node4.unclear.space/script/phc/ubuntu16.04/phcd_1.0.0.6_ubuntu16.tar.gz" 		#for xenial version (16.04), leave it empty if not supported
U17WALLETLINK="http://node4.unclear.space/script/phc/ubuntu17.10/phcd_1.0.0.6_ubuntu17.tar.gz" 		#for artful version (17.10), leave it empty if not supported
U18WALLETLINK="http://node4.unclear.space/script/phc/ubuntu17.10/phcd_1.0.0.6_ubuntu17.tar.gz" 		#for bionic version (18.04), leave it empty if not supported
DE8WALLETLINK="http://node4.unclear.space/script/phc/phc-debian8-daemon-1.0.0.6.tar.gz"             #for jessie version (Debian 8), leave it empty if not supported
DE9WALLETLINK="http://node4.unclear.space/script/phc/phc-debian9-daemon-1.0.0.6.tar.gz"             #for stretch version (Debian 9), leave it empty if not supported
CO7WALLETLINK="http://node4.unclear.space/script/phc/phc-centos7-daemon-1.0.0.6.tar.gz"             #for Core version (CentOS 7), leave it empty if not supported
F27WALLETLINK="http://node4.unclear.space/script/phc/phc-fedora27-daemon-1.0.0.6.tar.gz"			#for Fedora 27, leave it empty if not supported
F28WALLETLINK="http://node4.unclear.space/script/phc/phc-fedora28-daemon-1.0.0.6.tar.gz"			#for Fedora 28, leave it empty if not supported
#
BLOCKDUMPLINK="http://node4.unclear.space/script/phc/phc_datadir.tar.gz" 				 			#link blockchain cache/bootstrap
BOOTSTRAP="false"																				 	#selector (bootstrap=true/block cache=false)
BLKCOUNTLINK="http://54.37.233.45/bc_api.php?request=getblockcount"									#link to explorer API to ger current network height
#
WALLETDIR="phc"                                                             	#wallet instalation directory name
DATADIRNAME=".PHC"                                                              #datadir name
CONFFILENAME="phc.conf"                                                         #conf file name
DAEMONFILE="phcd"                                                               #daemon file name
CLIFILE="phcd"                                                                 	#cli file name
P2PPORT="20060"                                                                 #P2P port number
RPCPORT="20061"                                                                 #RPC port number
IPV6SUPPORTED="false"															#IPv6 support by coin wallet (true -  supported; false - not supported)
COLLAMOUNT="10000"                                                              #collateral amount
TICKER="PHC"                                                                    #coin ticker / symbol
#
EASYNODELINK=""             			   										#link to easyNode Manager script

function print_welcome() {
	echo ""
	echo "╔══════════════════════════════════════════════════════════════════════════════╗"
	echo "║                                                                              ║"
	echo "║                  Welcome to PHC masternode autosetup script                  ║"
	echo "║                                                                              ║"
	echo -en "║                  Version: ${VERSION}\r"
	echo -en "\033[46C${ITA}by unclear#0122${NC}                  ║\n"
	echo "║                  Script support: https://discord.gg/dF6JvJf                  ║"
	echo "║                                                                              ║"
	echo "╚══════════════════════════════════════════════════════════════════════════════╝"
	echo

}

function run_pre_checks() {
	#[2.00]
	echo "EXECUTING PRE-CHECKS"
	#check sudo installed
	echo -en " Checking 'sudo' package installed \r"
	if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
		sudopkg=$(dpkg-query --show | grep -E '^sudo' 2>>${LOGFILE})
		[ "$sudopkg" = "" ] && sp=1 || sp=0
	elif [[ "$osfam" =~ ^(centos|fedora)$ ]]; then
		sudopkg=$(yum list installed 2>>${LOGFILE}| grep sudo)
		[ "$sudopkg" = "" ] && sp=1 || sp=0
	fi
	[ $sp -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $sp -eq 0 ] && echo "#    sudo package check [Successful]" >>${LOGFILE} || echo "#    sudo package check [FAILED]" >>${LOGFILE}
	#check curl installed
	echo -en " Checking 'curl' package installed \r"
	if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
		curlpkg=$(dpkg-query --show | grep -E '^curl' 2>>${LOGFILE})
		[ "$curlpkg" = "" ] && curlp=1 || curlp=0
	elif [[ "$osfam" =~ ^(centos|fedora)$ ]]; then
		curlpkg=$(yum list installed 2>>${LOGFILE}| grep curl)
		[ "$curlpkg" = "" ] && curlp=1 || curlp=0
	fi
	[ $curlp -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $curlp -eq 0 ] && echo "#    curl package check [Successful]" >>${LOGFILE} || echo "#    curl package check [FAILED]" >>${LOGFILE}

	if [ $sp -eq 1 ]; then
		echo
		echo " WARNING: 'sudo' package required for installation, but it's missing in the system."
		if [ "$USER" = "root" ]; then
			read -n1 -p ' Do you want to install it now? [Y/n]: ' sudotxt
			echo
			if [ "$sudotxt" = "" ] || [ "$sudotxt" = "y" ] || [ "$sudotxt" = "Y" ]; then
				echo -en " Installing 'sudo' package \r"
				if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
					apt-get update -y >>${LOGFILE} 2>&1
					apt-get install -y sudo >>${LOGFILE} 2>&1
				elif [[ "$osfam" =~ ^(centos|fedora)$ ]]; then
					yum install -y sudo >>${LOGFILE} 2>&1
				fi
				[ $? -eq 0 ] && ec=0 || ec=1
				[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
				[ $ec -eq 0 ] && echo "#    sudo installation check [Successful]" >>${LOGFILE} || echo "#    sudo installation check [FAILED]" >>${LOGFILE}
			else
				echo " 'sudo' package installation canceled."
				echo " Installation cannot be continued, please install missing packages and re-start script."
				exit 0
			fi
		fi
	fi

	if [ $curlp -eq 1 ]; then
		echo
		echo " WARNING: 'curl' package required for installation, but it's missing in the system."
		if [ "$USER" = "root" ]; then
			read -n1 -p " Do you want to install 'curl' package now? [Y/n]: " sudotxt
			echo
			if [ "$sudotxt" = "" ] || [ "$sudotxt" = "y" ] || [ "$sudotxt" = "Y" ]; then
				echo -en " Installing 'curl' package \r"
				if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
					apt-get update -y >>${LOGFILE} 2>&1
					apt-get install -y curl >>${LOGFILE} 2>&1
				elif [[ "$osfam" =~ ^(centos|fedora)$ ]]; then
					yum install -y curl >>${LOGFILE} 2>&1
				fi
				[ $? -eq 0 ] && ec=0 || ec=1
				[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
				[ $ec -eq 0 ] && echo "#    curl installation check [Successful]" >>${LOGFILE} || echo "#    curl installation check [FAILED]" >>${LOGFILE}
			else
				echo " 'curl' package installation canceled."
				echo " Installation cannot be continued, please install missing packages and re-start script."
				exit 0
			fi
		fi
	fi

	if ! [ "$USER" = "root" ]; then
		if [ $sp -eq 1 ] || [ $curlp -eq 1 ];  then
			plist=""
			if [ $sp -eq 1 ]; then plist="sudo "; fi
			if [ $curlp -eq 1 ]; then plist=$plist"curl "; fi
			echo
			echo " Installation cannot be continued, please install missing packages and re-start script."
			if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
				echo -en ' Try using command '${PURPLE}'su -l -c "apt-get install -y '${plist}'"'${NC}' to install missing packages.\n'
			elif [[ "$osfam" =~ ^(centos|fedora)$ ]]; then
				echo -en ' Try using command '${PURPLE}'su -l -c "yum install -y '${plist}'"'${NC}' to install missing packages.\n'
			fi
			echo
			echo -en " ${RED}Installation script aborted ${NC}\n"
			exit
		fi
		echo -en " Checking sudo permissions \r"
		sudo echo "sudo check" >/dev/null 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		echo -en " Checking sudo permissions \r"
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo permissions check [Successful]" >>${LOGFILE} || echo "#    sudo permissions check [FAILED]" >>${LOGFILE}

		if [ $ec -gt 0 ]; then
			echo -en " ${RED}Failed to get sudo permissions, installation script aborted ${NC}\n"
			exit
		fi
	fi

}

function run_questionnaire() {
	#[2.00]
	echo
	echo "###      SYSTEM PREPARATION PART     ###"
	## System update
		echo
		read -n1 -p '1. Update system packages? [Y/n]: ' sysupdtxt
		echo "#    Update system packages? [Y/n]: ${sysupdtxt}" >>${LOGFILE}
		echo
		if [ "$sysupdtxt" = "" ] || [ "$sysupdtxt" = "y" ] || [ "$sysupdtxt" = "Y" ]; then
			sysupdate=1
		elif [ "$sysupdtxt" = "n" ] || [ "$sysupdtxt" = "N" ]; then
			sysupdate=0
		else
			echo " Incorrect answer, system will not be updated"
			echo
		fi
		#echo

	## SWAP file question
		curswapmb=$(free -m | grep Swap | grep -oE 'Swap: +[0-9]+ ' | grep -oE '[0-9]+')
		if [ $curswapmb -gt $minswapmb ]; then
			swapfilename=$(sudo more /etc/fstab | grep -v '#' | grep swap | grep -oE '^.+ +none' | grep -oE '^.+ ')
			echo "#    Existing SWAP detected: size=${curswapmb}MB; filename=${swapfilename} Swap creation skipped." >>${LOGFILE}
			echo "2. Current swap size is ${curswapmb}MB. Script will not create additional swap."
			createswap=0
		else
			read -n1 -p '2. Create system SWAP file? [Y/n]: ' createswaptxt
			echo "#    Create system SWAP file? [Y/n]: ${createswaptxt}" >>${LOGFILE}
			echo
			if [ "$createswaptxt" = "" ] || [ "$createswaptxt" = "y" ] || [ "$createswaptxt" = "Y" ]; then
				read -p '   Enter SWAP file size in gigabytes ['${swapsizegigs}']: ' swapsizetxt
				echo "#    Enter SWAP file size in gigabytes ['${swapsizegigs}']: ${swapsizetxt}" >>${LOGFILE}
				if [[ $swapsizetxt =~ ^[0-9]+([.][0-9]+)?$ ]]; then
					swapsizegigs=$swapsizetxt
					echo "   SWAP file size will be set to ${swapsizegigs}GB"
				elif [ "$createswaptxt" = "" ]; then
					echo "   SWAP file size will be set to ${swapsizegigs}GB"
				else
					echo "   SWAP file size will be set to ${swapsizegigs}GB"
				fi
				createswap=1
			elif [ "$createswaptxt" = "n" ] || [ "$createswaptxt" = "N" ]; then
				createswap=0
			else
				echo "   Incorrect answer, SWAP file will not be created"
				createswap=0
				echo
			fi
		fi

	## Fail2Ban installation
		read -n1 -p '3. Install Fail2Ban intrusion protection? [Y/n]: ' setupf2btxt
		echo "#    Install Fail2Ban intrusion protection? [Y/N]: ${setupf2btxt}" >>${LOGFILE}
		echo
		if [[ "$setupf2btxt" =~ ^[yY]+$ ]] || [ "$setupf2btxt" = "" ]; then
			setupfail2ban=1
		elif [[ "$setupf2btxt" =~ ^[nN]+$ ]]; then
			setupfail2ban=0
		else
			echo "   Fail2Ban will not be installed."
			setupfail2ban=0
		fi

	## Firewall activation
		check_fw_status
		if [ "$fwstatus" = "active" ]; then
			echo "4. Firewall '"$firewall"' already activated"
			echo "#    Firewall '"$firewall"' already activated" >>${LOGFILE}
			if [ "$firewall" = "UFW" ]; then
				p2pufw=$(sudo ufw status | grep -oE ^${P2PPORT}/tcp)
			elif [ "$firewall" = "FirewallD" ]; then
				p2pufw=$(sudo firewall-cmd --zone=${fwdzone} --list-ports | grep -oE "(^${P2PPORT}/tcp| ${P2PPORT}/tcp)")
			fi
			[ "$p2pufw" = "" ] && p2pufwadd=1 || p2pufwadd=0
			[ $p2pufwadd -eq 1 ] && echo "    P2P tcp port '${P2PPORT}' will be added to the list of allowed" || echo "    P2P tcp port '${P2PPORT}' already in the list of allowed"
			[ $p2pufwadd -eq 1 ] && echo "#    P2P tcp port '${P2PPORT}' will be added to the list of allowed" >>${LOGFILE} || echo "#    P2P tcp port '${P2PPORT}' already in the list of allowed" >>${LOGFILE}

			if [ "$firewall" = "UFW" ]; then
				rpcufw=$(sudo ufw status | grep -oE ^${RPCPORT}/tcp)
			elif [ "$firewall" = "FirewallD" ]; then
				rpcufw=$(sudo firewall-cmd --zone=${fwdzone} --list-ports | grep -oE "(^${RPCPORT}/tcp| ${RPCPORT}/tcp)")
			fi

			if [ "$rpcufw" = "" ]; then
				read -n1 -p '    Do you want to add RPC port to list of allowed? [y/N]: ' rpcufwaddtxt && echo
				echo "#    Do you want to add RPC port to list of allowed? [y/N]: ${rpcufwaddtxt}" >>${LOGFILE}
				if [ "$rpcufwaddtxt" = "y" ] || [ "$rpcufwaddtxt" = "Y" ]; then rpcufwadd=1; else rpcufwadd=0; fi
			else
				echo "   RPC tcp port '${RPCPORT}' already in the list of allowed"
				echo "#    RPC tcp port '${RPCPORT}' already in the list of allowed" >>${LOGFILE}
				rpcufwadd=0
			fi
			if [ $rpcufwadd -eq 1 ] || [ $p2pufwadd -eq 1 ]; then setupufw=2; else setupufw=0; fi
		else
			read -n1 -p '4. Setup firewall ('${firewall}')? [Y/n]: ' setupufwtxt
			echo "#    Setup firewall ('${firewall}')? [Y/n]: ${setupufwtxt}" >>${LOGFILE}
			echo
			if [ "$setupufwtxt" = "y" ] || [ "$setupufwtxt" = "Y" ] || [ "$setupufwtxt" = "" ] || [ "$setupufwtxt" = " " ]; then setupufw=1; else setupufw=0; fi

			if [ $setupufw -eq 1 ]; then
				echo "   P2P tcp port '${P2PPORT}' will be added to the list of allowed"
				p2pufwadd=1
				read -n1 -p '   Do you want to add RPC port to list of allowed? [y/N]: ' rpcufwaddtxt
				echo "#    Do you want to add RPC port to list of allowed? [y/N]: ${rpcufwaddtxt}" >>${LOGFILE}
				echo
				if [ "$rpcufwaddtxt" = "y" ] || [ "$rpcufwaddtxt" = "Y" ]; then rpcufwadd=1; else rpcufwadd=0; fi

				#show list of listening ports [2.00]
				tcpports=$(ss -ln | grep 'LISTEN ' | grep 'tcp' | grep -oE ':[0-9]+ ' | grep -oE '[0-9]+' | sort -u -n)
				read -a tcp4ports <<< $tcpports
				if ! [ "$tcp4ports" = "" ]; then
					echo "   Following tcp ports currently LISTENING and will be added to list of allowed:"
					while read -r tcp4port; do
						if ! [[ "$tcp4port" =~ "'('"${P2PPORT}"'|'"${RPCPORT}"')'" ]] ; then 
							echo -en "    ${PURPLE}+$tcp4port ${NC}\n"
							portlist+=($tcp4port); 
						fi
					done <<<$tcp4ports
				fi

				read -n1 -p '   Confirm configuring '${firewall}' with above ports? [Y/n]: ' ufwaddcfmtxt && echo
				echo "#   Confirm configuring '${firewall}' with above ports? [Y/n]: ${lsnufwaddtxt}" >>${LOGFILE}
				
				if [ "$ufwaddcfmtxt" = "y" ] || [ "$ufwaddcfmtxt" = "Y" ] || [ "$ufwaddcfmtxt" = "" ] || [ "$ufwaddcfmtxt" = " " ]; then
					setupufw=1
				else
					echo "   Port list not confirmed, ${firewall} setup canceled"
					echo "#    Port list not confirmed, ${firewall} setup canceled" >>${LOGFILE}
					setupufw=0
					echo
				fi
			fi
		fi

	## New user creation
		read -n1 -p '5. Create new account? [y/N]: ' createacctxt && echo
		echo "#    Create new account? [y/N]: ${createacctxt}" >>${LOGFILE}
		if [ "$createacctxt" = "y" ] || [ "$createacctxt" = "Y" ]; then
			createuser=1
			newsudouser=1

			read -n1 -p '   Allow new user sudo without password? [y/N]: ' sudowopasstxt && echo
			echo "#     Allow new user sudo without password? [y/N]: ${sudowopasstxt}" >>${LOGFILE}
			if [[ "$sudowopasstxt" =~ ^[yY]+$ ]]; then sudowopass=1; else sudowopass=0; fi

			read -n1 -p '   Install masternode under new user account? [Y/n]: ' newusermntxt && echo
			echo "#     Install masternode under new user account? [Y/n]: ${newusermntxt}" >>${LOGFILE}
			if [ "$newusermntxt" = " " ] || [ "$newusermntxt" = "" ] || [ "$newusermntxt" = "y" ] || [ "$newusermntxt" = "Y" ]; then newusermn=1; else newusermn=0; fi
			echo

			read -p '    Enter username: ' newuser && echo
			echo "#      New username: ${newuser}" >>${LOGFILE}
			if [ $newuser = "" ]; then
				echo -en "${RED}  WARNING: Username cannot be empty, new user will not be created !! ${NC}\n"
				echo "#    WARNING: Username cannot be empty, new user will not be created !!" >>${LOGFILE}
				createuser=0
			else
				echo -en "${PURPLE}    NOTE: There will be no character substitution entering password.\n          Just type it!${NC}\n" 
				read -sp '    Enter password: ' pwd1 && echo
				read -sp '    Confirm password: ' pwd2 && echo

				if [ "$pwd1" = "$pwd2" ] && ! [ "$pwd2" = "" ]; then
					encrypt_password
					pwd1=""
					pwd2=""
					echo "   Password accepted, password hash: "${ePass:0:7}"*******"
					echo "#   Password accepted, password hash: "${ePass:0:15}"*******" >>${LOGFILE}
				else
					echo
					echo -en "${RED}    WARNING: Passwords not equal or empty, please try one more time. ${NC}\n"
					echo
					echo "#    WARNING: Passwords not equal or empty, please try one more time. " >>${LOGFILE}
					read -sp '    Enter password: ' pwd1 && echo
					read -sp '    Confirm password: ' pwd2 && echo
					if [ "$pwd1" = "$pwd2" ] && ! [ "$pwd2" = "" ]; then
						encrypt_password
						pwd1=""
						pwd2=""
						echo "   Password accepted, password hash: "${ePass:0:7}"*******"
						echo "#   Password accepted, password hash: "${ePass:0:15}"*******" >>${LOGFILE}
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

	echo "###    MASTERNODE PREPARATION PART   ###"
	## Wallet installation
		echo
		read -n1 -p '6. Download and setup masternode daemon? [Y/n]: ' setupwaltxt && echo
		echo "#    Download and masternode daemon? [Y/n]: ${setupwaltxt}" >>${LOGFILE}

		if [ "$setupwaltxt" = "" ] || [ "$setupwaltxt" = "y" ] || [ "$setupwaltxt" = "Y" ] || [ "$setupwaltxt" = " " ]; then
			setupwallet=1
			if ! [ "$osver" = "trusty" ]; then
				read -n1 -p '   Configure daemon as systemd service? [Y/n]: ' sysctltxt && echo
				echo "#    Configure daemon as systemd service? [Y/n]: ${sysctltxt}" >>${LOGFILE}
				if [[ "$sysctltxt" =~ ^[nN]+$ ]]; then
					sysctl=0
					read -n1 -p '   Configure daemon to start after system reboots? [Y/n]: ' crontxt && echo
					echo "#    Configure daemon to start after system reboots? [Y/n]: ${crontxt}" >>${LOGFILE}
					if [ "$crontxt" = "" ] || [ "$crontxt" = "y" ] || [ "$crontxt" = "Y" ] || [ "$crontxt" = " " ]; then
						loadonboot=1
					else
						loadonboot=0
					fi
				else
					sysctl=1
					loadonboot=0
				fi
			else
				sysctl=0
				read -n1 -p '   Configure daemon to start after system reboots? [Y/n]: ' crontxt && echo
				echo "#    Configure daemon to start after system reboots? [Y/n]: ${crontxt}" >>${LOGFILE}
				if [ "$crontxt" = "" ] || [ "$crontxt" = "y" ] || [ "$crontxt" = "Y" ] || [ "$crontxt" = " " ]; then
					loadonboot=1
				else
					loadonboot=0
				fi
			fi
		elif [[ "$setupwaltxt" =~ ^[nN]+$ ]]; then
			setupwallet=0
			sysctl=0
		else
			setupwallet=1
			echo -en "${RED}   Incorrect answer, by default wallet will be downloaded and installed${NC} \n"
			echo
		fi

	## easyNode Manager setup
		if ! [ "$EASYNODELINK" = "" ]; then
			read -n1 -p '7. Install easyNode script? [Y/n]: ' setupentxt && echo
			echo "#    Install easyNode script? [Y/n]: ${setupentxt}" >>${LOGFILE}
			if [[ "$setupentxt" =~ ^[yY]+$ ]] || [ "$setupentxt" = "" ]; then
				easynode=1
			elif [[ "$setupentxt" =~ ^[nN]+$ ]]; then
				easynode=0
			else
				echo "   easyNode will not be installed."
				easynode=0
			fi
		else
			echo "7. easyNode installation not available"
		fi

	## Masternode setup
		read -n1 -p '8. Configure masternode? [Y/n]: ' setupmntxt && echo
		echo "#    Configure masternode? [Y/n]: ${setupmntxt}" >>${LOGFILE}

		if [ "$setupmntxt" = "" ] || [ "$setupmntxt" = "y" ] || [ "$setupmntxt" = "Y" ]; then
			# collateral tx instructions
				read -n1 -p '   Have you already made collateral transaction and have txhash, txindex and genkey? [Y/n]: ' coldone && echo
				echo "#   Have you already made collateral transaction and have txhash, txindex and genkey? [Y/n]: ${coldone}" >>${LOGFILE}
				if [ "$coldone" = "" ] || [ "$coldone" = "y" ] || [ "$coldone" = "Y" ] || [ "$coldone" = " " ]; then
					echo "#   Proceeding to MN questionnaire " >>${LOGFILE}
				else
					echo
					echo "   Please perform collateral transaction to desired payee address:"
					echo
					echo -en "   1. Transfer exactly ${PURPLE}$COLLAMOUNT $TICKER ${NC} to payee address.\n"
					echo -en "   2. Request txhash and txoutput via wallet Debug Console: \n"
					echo -en "      Navigate to ${PURPLE}Menu -> Help -> Debug Console${NC} and enter command \n"
					echo
					echo -en "         ${PURPLE}masternode outputs ${NC}\n"
					echo
					echo "   3. Generate masternode private key using Debug Console, enter command "
					echo
					echo -en "         ${PURPLE}masternode genkey ${NC}\n"
					echo

					read -n1 -p '   Press any key when ready to continue or Ctrl+C to abort setup ' coldone
					echo        "                                                                 "
				fi

			setupmn=1

			# IP DETECTION / DEFINITION
				echo -en "   Detecting external IP address\r"
				detect_ip_address
				if ! [ "${vpsip}" = "" ]; then
					echo -en "   Detected external IP address is [${PURPLE}${vpsip}${NC}]\n"	

					#check for port usage of detected ip
						ipaddr=$vpsip
						ipv=$ipver
						nstat=$(ss -ln | grep 'LISTEN ' | grep 'tcp')
						check_ip_port_in_use
						if ! [ "$pcres" = "" ]; then pcres="USED"; else pcres="FREE"; fi
						if ! [ "$rcres" = "" ]; then rcres="USED"; else rcres="FREE"; fi
						if [ "$pcres" = "USED" ] || [ "$rcres" = "USED" ]; then
							echo -en " ${RED}WARNING:\n P2P and/or RPC port already in use, this will prevent daemon to start.\n We recommend to use another IP address if available.${NC}\n"
							echo -en " P2P port status: ${pcres}; RPC port status: ${rcres}\n"	
							defanswer="[y/N]"
						else
							defanswer="[Y/n]"
						fi
						ipaddr=""; ipv=""; pcres=""; rcres=""; nstat="";

					if  [ "$IPV6SUPPORTED" = "true" ] || [ $ipver -eq 4 ]; then 
						read -n1 -p "   Do you confirm using detected ip? ${defanswer}: " usedet && echo
						if ! [[ "$usedet" =~ ^[yY]+$ ]] && ! [ "$usedet" = "" ]; then
							if [ "$natip" = "true" ]; then
								ip_questionnaire
							else
								select_ip
							fi
						fi
					else
						if [ "$natip" = "true" ]; then
							ip_questionnaire
						else
							select_ip
						fi
					fi
					if [ "$natip" = "true" ]; then 
						echo -en "${PURPLE}   NAT was detected, daemon will listen on all local ip addresses.${NC}\n"
					fi
				else
					echo -en "   External IP address detection ${RED}failed${NC}\n"
					ip_questionnaire
				fi
			# MASTERNODE QUESTIONNAIRE
				mn_questionnaire

		elif [ "$setupmntxt" = "n" ] || [ "$setupmntxt" = "N" ]; then
			setupmn=0
		else
			echo -en "${RED}   ERROR: Incorrect answer, masternode will not be configured${NC}\n"
		fi

	echo
	echo "     PLEASE REVIEW YOUR ANSWERS ABOVE   "
	read -n1 -p "     Press any key to start installation or press Ctrl+C to exit   "

}

function ip_questionnaire() {
	if  [ "$IPV6SUPPORTED" = "false" ]; then limit="${PURPLE}IPv4${NC} "; else limit=""; fi
	echo -en "   Please provide external ${limit}ip address\n"
	read -p $'   >> \e[35m ' vpsiptxt
	echo -en "\e[0m\r"
	echo "#    Entered ip address: ${vpsiptxt}" >>${LOGFILE}
	if [ "$IPV6SUPPORTED" = "false" ]; then
		#only ipv4
		if [[ $vpsiptxt =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then 
			vpsip=$vpsiptxt
			ipver=4
			detect_nat
		else 
			echo -en "${RED}   ERROR: Incorrect ipaddress format, please try again.${NC}\n"
			ip_questionnaire
		fi
	else 
		#ipv4 or ipv6
		if [[ $vpsiptxt =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then 
			vpsip=$vpsiptxt
			ipver=4
			detect_nat
		elif [[ $vpsiptxt =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]; then
			vpsip=$vpsiptxt
			ipver=6
			detect_nat
		else 
			echo -en "${RED}   ERROR: Incorrect ipaddress format, please try again.${NC}\n"
			ip_questionnaire
		fi
	fi
	echo
}

function mn_questionnaire() {
	echo 
	echo "  MASTERNODE QUESIONNAIRE"
	echo "   RPC user name and password will be generated automatically" && echo
	#generating random user (24chars) and password (48chars)
	rpcuser=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-24};echo;)
	rpcpassword=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-48};echo;)
	echo "#    Generated rpcuser: ${rpcuser}" >>${LOGFILE}
	echo "#    Generated rpcpassword: ****" >>${LOGFILE} #not recording for security reasons

	echo "   Enter masternode private key (genkey): "
	read -p $'   >> \e[35m ' mnprivkey
	echo -en "\e[0m\r"
	echo
	echo "#    Entered mnprivkey: ${mnprivkey}" >>${LOGFILE}

	echo "   Enter collateral txhash (outputs hex string): " 
	read -p $'   >> \e[35m ' txhash
	echo -en "\e[0m\r"
	echo
	echo "#    Entered txhash: ${txhash}" >>${LOGFILE}

	echo "   Enter collateral txindex (outputs integer): " 
	read -p $'   >> \e[35m ' txoutput
	echo -en "\e[0m\r"
	echo "#    Entered txoutput: ${txoutput}" >>${LOGFILE}
	echo

}

function set_default_answers() {
	echo && echo "DEFAULT INSTALLATION OPTIONS"
	echo "#    DEFAULT INSTALLATION OPTIONS" >>${LOGFILE}
	#Update system packages?
		sysupdate=1
		echo -en " Update system packages:\r"
		[ $sysupdate -eq 0 ] && echo -en "\033[40C${NC}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $sysupdate -eq 0 ] && echo "#    Update system packages: NO"  >>${LOGFILE} || echo "#    Update system packages: YES" >>${LOGFILE}

	#Create system SWAP file?
		curswapmb=$(free -m | grep Swap | grep -oE 'Swap: +[0-9]+ ' | grep -oE '[0-9]+')
		if [ $curswapmb -gt $minswapmb ]; then
			createswap=0
			echo -en " Create SWAP file:\r"
			echo -en "\033[40C${NC}NO${NC}\n"
		else
			createswap=1
			echo -en " Create SWAP file (${swapsizegigs}GB):\r"
			echo -en "\033[40C${GREEN}YES${NC}\n"
		fi
		[ $createswap -eq 0 ] && echo "#    Create SWAP file: NO"  >>${LOGFILE} || echo "#    Create SWAP file: YES (${swapsizegigs}GB)"  >>${LOGFILE}

	#Install Fail2Ban intrusion protection?
		setupfail2ban=1
		echo -en " Install Fail2Ban:\r"
		[ $setupfail2ban -eq 0 ] && echo -en "\033[40C${NC}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $setupfail2ban -eq 0 ] && echo "#    Install Fail2Ban: NO"  >>${LOGFILE} || echo "#    Install Fail2Ban: YES " >>${LOGFILE}

	#Setup firewall ('${firewall}')? [Y/n]
		check_fw_status
		if [ "$fwstatus" = "active" ]; then
			if [ "$firewall" = "UFW" ]; then
				p2pufw=$(sudo ufw status | grep -oE ^${P2PPORT}/tcp)
			elif [ "$firewall" = "FirewallD" ]; then
				p2pufw=$(sudo firewall-cmd --zone=${fwdzone} --list-ports | grep -oE "(^${P2PPORT}/tcp| ${P2PPORT}/tcp)")
			fi
			[ "$p2pufw" = "" ] && p2pufwadd=1 || p2pufwadd=0
			rpcufwadd=0
			if [ $rpcufwadd -eq 1 ] || [ $p2pufwadd -eq 1 ]; then 
				setupufw=2
				echo -en " Add P2P port to ${firewall}:\r"
				echo -en "\033[40C${GREEN}YES${NC}\n"
			else 
				echo -en " Change ${firewall} configuration:\r" 
				echo -en "\033[40C${NC}NO${NC}\n"
			fi
		else
			setupufw=0 
			p2pufwadd=0
			echo -en " Install and setup ${firewall}:\r" 
			echo -en "\033[40C${NC}NO${NC}\n"
		fi
		echo "#    FW change mode: ${setupufw} [0 - not install; 1 - install and setup; 2 - add port]"  >>${LOGFILE}
	#Create new account?
		createuser=0
		echo -en " Create new user:\r"
		[ $createuser -eq 0 ] && echo -en "\033[40C${NC}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $createuser -eq 0 ] && echo "#    Create new user: NO"  >>${LOGFILE} || echo "#    Create new user: YES " >>${LOGFILE}
	#Download and setup masternode daemon?
		setupwallet=1
		if [ "$osver" = "trusty" ]; then
			sysctl=0
			loadonboot=1
		else
			sysctl=1
			loadonboot=0
		fi
		echo -en " Download and install daemon:\r"
		[ $setupwallet -eq 0 ] && echo -en "\033[40C${RED}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $setupwallet -eq 0 ] && echo "#    Download and install daemon: NO"  >>${LOGFILE} || echo "#    Download and install daemon: YES" >>${LOGFILE}
		echo -en " Install daemon as systemd service:\r"
		[ $sysctl -eq 0 ] && echo -en "\033[40C${NC}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $sysctl -eq 0 ] && echo "#    Install daemon as systemd service: NO"  >>${LOGFILE} || echo "#    Install daemon as systemd services: YES" >>${LOGFILE}
		echo -en " Update crontab with @reboot:\r"
		[ $loadonboot -eq 0 ] && echo -en "\033[40C${NC}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $loadonboot -eq 0 ] && echo "#    Start daemon after reboot: NO"  >>${LOGFILE} || echo "#    Start daemon after reboot: YES" >>${LOGFILE}
	#Download and setup easyNode script?
		if ! [ "$EASYNODELINK" = "" ]; then
			easynode=1
		else
			easynode=0
		fi
		echo -en " Install easyNode script:\r"
		[ $easynode -eq 0 ] && echo -en "\033[40C${NC}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $easynode -eq 0 ] && echo "#    Install easyNode script: NO"  >>${LOGFILE} || echo "#    Install easyNode script: YES" >>${LOGFILE}
	#Configure masternode?
		setupmn=1
		echo -en " Configure masternode:\r"
		[ $setupmn -eq 0 ] && echo -en "\033[40C${NC}NO${NC}\n" || echo -en "\033[40C${GREEN}YES${NC}\n"
		[ $setupmn -eq 0 ] && echo "#   Configure masternode: NO"  >>${LOGFILE} || echo "#    Configure masternode: YES" >>${LOGFILE}
	#Detect IP / NAT
		detect_ip_address
		echo -en " External IP address:\r"
		if [ "$IPV6SUPPORTED" = "true" ] || [ $ipver -eq 4 ]; then
			echo -en "\033[40C${vpsip}\n"
		else
			echo -en "\033[40C${RED}${vpsip}${NC}\n"
			iperr=1
		fi
		echo "#   External IP address: ${vpsip}"  >>${LOGFILE}

		echo -en " IP binding mode:\r"
		if [ "$natip" = "true" ]; then 
			echo -en "\033[40C${NC}LISTEN (NAT detected)${NC}\n"
		else
			echo -en "\033[40C${GREEN}BIND${NC}\n"
		fi
		echo "#   NAT detected: ${natip}"  >>${LOGFILE}

		if [ "$iperr" = "1" ]; then
			echo
			echo -en "${RED} ERROR: This coin doesn't support usage of IPv6 addresses.\n"
			echo -en " Script detected IPv6 address and cannot continue setup in default mode.${NC}\n" 
			echo "#   Script detected IPv6 address and cannot continue setup in default mode."  >>${LOGFILE}
			defaultconf="n"
		else 
			defaultconf=''
		fi
	#check for port usage of detected ip
		ipaddr=$vpsip
		ipv=$ipver
		nstat=$(ss -ln | grep 'LISTEN ' | grep 'tcp')
		check_ip_port_in_use
		if ! [ "$pcres" = "" ]; then pcres="USED"; else pcres="FREE"; fi
		if ! [ "$rcres" = "" ]; then rcres="USED"; else rcres="FREE"; fi
		if [ "$pcres" = "USED" ] || [ "$rcres" = "USED" ]; then
			echo -en " ${RED}WARNING:\n P2P and/or RPC port already in use, this will prevent daemon to start.\n We recommend to continue installation using FULL questionnaire with IP address selection.${NC}\n"
			echo -en " P2P port status: ${pcres}; RPC port status: ${rcres}\n"	
			pu=1
		else
			pu=0
		fi
		ipaddr=""; ipv=""; pcres=""; rcres=""; nstat="";
	#Confirm above configuration or run full questionnaire
		if [ $pu -eq 0 ]; then cprop="[Y/n]"; else cprop="[y/N]"; fi
		if [ "$defaultconf" = "" ]; then
			echo && echo " Please confirm DEFAULT setup (Y) or run FULL questionnaire (N)"
			echo -en "\033[s"
		fi
		while ! [[ "$defaultconf" =~ ^[yYnN]+$ ]]; do 
			echo -en "\033[u"
			read -n1 -p "Do you confirm installation with DEFAULT options? ${cprop}: " defaultconf
		done
		echo && echo
		if [[ "$defaultconf" =~ ^[yY]+$ ]]; then
			echo "#    Installation with DEFAULTS confirmed." >>${LOGFILE}
			# show mn_questionnaire
			mn_questionnaire
			echo
			echo " PLEASE REVIEW YOUR ANSWERS ABOVE   "
			read -n1 -p " Press any key to start installation or press Ctrl+C to exit   "
		else
			# show run_questionnaire
			echo "#    Installation with DEFAULTS not confirmed, proceeding with FULL questionnaire." >>${LOGFILE}
			echo "Installation with defaults canceled, running through the FULL questionnaire."
			echo
			run_questionnaire
		fi
}

function create_handover_file() {
	if [ -f $SCRIPTPATH.ho ]; then sudo rm $SCRIPTPATH.ho &>>${LOGFILE}; fi
	echo -en "# THIS IS PARAMETER HANDOVER FILE, PLEASE DON'T DELETE IT UNTIL SETUP IS FINISHED #\n"\
	"setupwallet='"${setupwallet}"'\n"\
	"sysctl='"${sysctl}"'\n"\
	"loadonboot='"${loadonboot}"'\n"\
	"easynode='"${easynode}"'\n"\
	"setupmn='"${setupmn}"'\n"\
	"vpsip='"${vpsip}"'\n"\
	"ipver='"${ipver}"'\n"\
	"natip='"${natip}"'\n"\
	"rpcuser='"${rpcuser}"'\n"\
	"rpcpassword='"${rpcpassword}"'\n"\
	"mnprivkey='"${mnprivkey}"'\n"\
	"txhash='"${txhash}"'\n"\
	"txoutput='"${txoutput}"'\n"\
	"p2pufwadd='"${p2pufwadd}"'\n"\
	"fwdzone='"${fwdzone}"'" > $SCRIPTPATH.ho 
}

function check_fw_status() {
		if [ "$firewall" = "UFW" ]; then
		fwpkg=$(dpkg-query --show --showformat='${db:Status-Status}\n' 'ufw' 2>>${LOGFILE})
		if [ "$fwpkg" = "installed" ]; then
			fwstatus=$(sudo ufw status 2>>${LOGFILE} | grep -oE '(active|inactive)')
		else
			fwstatus="inactive"
		fi
	elif [ "$firewall" = "FirewallD" ]; then
		fwpkg=$(sudo yum list installed 2>>${LOGFILE} | grep '^firewalld.')
		[ "$fwpkg" = "" ] && fwpkg="missing" || fwpkg="installed"
		if [ "$fwpkg" = "installed" ]; then
			fwstatus=$(sudo firewall-cmd --state 2>>${LOGFILE} | grep -oE '(running|not running)')
			if [ "$fwstatus" = "running" ]; then
				fwstatus="active"
				fwdzone=$(sudo firewall-cmd --get-default-zone 2>>${LOGFILE})
			else
				fwstatus="inactive"
			fi
		else
			fwstatus="inactive"
		fi
	fi
}

function create_swap() {
	# create swap file [2.00]
	ec=0
	echo "CREATING SWAP FILE"
	echo >>${LOGFILE}
	echo "###  SWAP creation started  ###" >>${LOGFILE}
	free -h &>>${LOGFILE}
	echo -en " Creating /swapfile of ${swapsizegigs}GB size \r"
	mbytes=$(awk -vg=1024 -vq=${swapsizegigs} 'BEGIN{printf "%.0f" ,g * q}' 2>>${LOGFILE})
	sudo dd if=/dev/zero of=/swapfile count=${mbytes} bs=1M &>>${LOGFILE}
	# sudo fallocate -l ${bytessize}M /swapfile &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    fallocate -l ${mbytes} /swapfile [Successful]" >>${LOGFILE} || echo "#    fallocate -l ${mbytes} /swapfile [FAILED]" >>${LOGFILE}

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
	#[2.00]
	#check /etc/os-release for ID
	idline=$(more /etc/os-release | grep '^ID=')
	id=${idline##*=}
	osfam=$(echo $id | grep -oE '[a-zA-Z0-9]*')

	OSNAME=$(more /etc/os-release | grep '^NAME=')
	OSNAME=${OSNAME##*=}
	OSNAME=$(echo ${OSNAME} | grep -oE '[a-zA-Z0-9.,/ ]*')
	OSVERSION=$(more /etc/os-release | grep '^VERSION=')
	OSVERSION=${OSVERSION##*=}
	OSVERSION=$(echo ${OSVERSION} | grep -oE '[a-zA-Z0-9.,/\(\) ]*')

	if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
		osver=$(lsb_release -c | grep -oE '[^[:space:]]+$')
		installer="apt-get"
		firewall="UFW"
	elif [ "$osfam" = "centos" ]; then
		osver=${OSVERSION##*(}
		osver=$(echo ${osver} | grep -oE '[a-zA-Z0-9]*')
		installer="yum"
		firewall="FirewallD"
	elif [ "$osfam" = "fedora" ]; then
		VID=$(more /etc/os-release | grep '^VERSION_ID=')
		VID=${VID##*=}
		osver=$osfam$VID
		installer="yum"
		firewall="FirewallD"
	else
		osver="not_detected"
	fi
}

function setup_fail2ban() {
	# setup fail2ban [2.00]
	echo "INSTALLING FAIL2BAN INTRUSION PROTECTION"
	echo >>${LOGFILE}
	echo "###  Fail2Ban installation started  ###" >>${LOGFILE}
	ec=0

	echo -en " Downloading and instaling Fail2ban application \r"
	if [[ "$osfam" =~ ^(centos)$ ]]; then
		sudo yum install -y epel-release >>${LOGFILE} 2>&1
	fi
	sudo ${installer} install -y fail2ban &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Installation of fail2ban [Successful]" >>${LOGFILE} || echo "#    Installation of fail2ban [FAILED]" >>${LOGFILE}

	if [ $osver = "trusty" ]; then
		if [ $ec -eq 0 ]; then
			echo -en " Starting Fail2ban service \r"
			sudo service fail2ban restart &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    Starting Fail2ban service [Successful]" >>${LOGFILE} || echo "#    Starting Fail2ban service [FAILED]" >>${LOGFILE}
		fi
	else
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
	fi
	echo "###  Fail2Ban installation complete  ###" >>${LOGFILE}
	echo

}

function setup_fw() {
	if [ "$firewall" = "UFW" ]; then
		setup_ufw
	elif [ "$firewall" = "FirewallD" ]; then
		setup_firewalld
	fi
}

function setup_ufw() {
	#[2.00] for CentOS use setup_firewalld
	echo "CONFIGURING UFW FIREWALL"
	echo >>${LOGFILE}
	echo "###  Setup of ufw started  ###" >>${LOGFILE}
	ec=0
	if [ $setupufw -eq 1 ]; then
		#newly activate ufw
		#checking ufw installed
		sshprofile="OpenSSH"
		ufwpkg=$(dpkg-query --show --showformat='${db:Status-Status}\n' 'ufw' 2>/dev/null)
		if ! [ "$ufwpkg" = "installed" ]; then
			echo -en " Installing 'ufw' package  \r"
			sudo ${installer} install -y ufw >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    ufw installation [Successful]" >>${LOGFILE} || echo "#    ufw installation [FAILED]" >>${LOGFILE}
		fi

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
		sudo ufw limit ${sshprofile} &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo ufw limit ${sshprofile} [Successful]" >>${LOGFILE} || echo "#    sudo ufw limit ${sshprofile} [FAILED]" >>${LOGFILE}

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

function setup_firewalld() {
	#[2.00] for CentOS use firewall-cmd
	echo "CONFIGURING FIREWALLD"
	echo >>${LOGFILE}
	echo "###  Setup of ${firewall} started  ###" >>${LOGFILE}
	ec=0
	if [ $setupufw -eq 1 ]; then
		#newly activate firewalld
		#checking firewalld installed
		fwpkg=$(sudo yum list installed | grep firewalld.)
		[ "$fwpkg" = "" ] && fwpkg="missing" || fwpkg="installed"
		sshprofile="ssh"
		if ! [ "$fwpkg" = "installed" ]; then
			echo -en " Installing ${firewall} package  \r"
			sudo ${installer} install -y firewalld >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    ${firewall} installation [Successful]" >>${LOGFILE} || echo "#    ${firewall} installation [FAILED]" >>${LOGFILE}
		fi

		#starting firewall
		echo -en " Starting ${firewall} service \r"
		sudo systemctl start firewalld.service &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo systemctl start firewalld.service [Successful]" >>${LOGFILE} || echo "#    sudo systemctl start firewalld.service [FAILED]" >>${LOGFILE}

		#detecting default zone
		echo -en " Detecting default-zone \r"
		fwdzone=$(sudo firewall-cmd --get-default-zone 2>>${LOGFILE})
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --get-default-zone [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --get-default-zone [FAILED]" >>${LOGFILE}

		echo -en " Adding SSH service to allowed list \r"
		sudo firewall-cmd --zone=${fwdzone} --add-service=$sshprofile --permanent &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --zone=${fwdzone} --add-service=$sshprofile --permanent [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --zone=${fwdzone} --add-service=$sshprofile --permanent [FAILED]" >>${LOGFILE}

		#add listening ports
		if [ ${#portlist[@]} -gt 0 ]; then
			for port in "${portlist[@]}"; do
				echo -en " Adding port ${port} to allowed list \r"
				sudo firewall-cmd --zone=${fwdzone} --add-port=$port/tcp --permanent &>>${LOGFILE}
				[ $? -eq 0 ] && ec=0 || ec=1
				[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
				[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$port/tcp --permanent [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$port/tcp --permanent [FAILED]" >>${LOGFILE}
			done
		fi

		#add p2p port
		echo -en " Adding P2P port ${P2PPORT} to allowed list \r"
		sudo firewall-cmd --zone=${fwdzone} --add-port=$P2PPORT/tcp --permanent &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$P2PPORT/tcp --permanent [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$P2PPORT/tcp --permanent [FAILED]" >>${LOGFILE}

		#add rpc port
		if [ $rpcufwadd -eq 1 ]; then
			echo -en " Adding RPC port ${RPCPORT} to allowed list \r"
			sudo firewall-cmd --zone=${fwdzone} --add-port=$RPCPORT/tcp --permanent &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$RPCPORT/tcp --permanent [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$RPCPORT/tcp --permanent [FAILED]" >>${LOGFILE}
		fi

		echo -en " Applying ${firewall} configuration \r"
		sudo firewall-cmd --reload &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --reload [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --reload ${sshprofile} [FAILED]" >>${LOGFILE}

		#enabling ufw
		echo -en " Enabling ${firewall} service \r"
		sudo systemctl enable firewalld.service &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo systemctl enable firewalld.service [Successful]" >>${LOGFILE} || echo "#    sudo systemctl enable firewalld.service [FAILED]" >>${LOGFILE}

	elif [ $setupufw -eq 2 ]; then
		#add ports to active ufw
		if [ $p2pufwadd -eq 1 ]; then
			echo -en " Adding P2P port ${P2PPORT} to allowed list \r"
			sudo firewall-cmd --zone=${fwdzone} --add-port=$P2PPORT/tcp --permanent &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$P2PPORT/tcp --permanent [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$P2PPORT/tcp --permanent [FAILED]" >>${LOGFILE}
		fi
		if [ $rpcufwadd -eq 1 ]; then
			echo -en " Adding RPC port ${RPCPORT} to allowed list \r"
			sudo firewall-cmd --zone=${fwdzone} --add-port=$RPCPORT/tcp --permanent &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$RPCPORT/tcp --permanent [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --zone=${fwdzone} --add-port=$RPCPORT/tcp --permanent [FAILED]" >>${LOGFILE}
		fi
		echo -en " Applying ${firewall} configuration \r"
		sudo firewall-cmd --reload &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    sudo firewall-cmd --reload [Successful]" >>${LOGFILE} || echo "#    sudo firewall-cmd --reload ${sshprofile} [FAILED]" >>${LOGFILE}
	fi
	echo
}

function system_update() {
	#system update [2.00]
	echo "UPDATING SYSTEM PACKAGES"
	echo >>${LOGFILE}
	echo "###   Update of system package started  ###" >>${LOGFILE}
	ec=0
	if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
		echo -en " Updating repositories \r"
		sudo apt-get update -y &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		
		# holding grub-pc (requires user interaction)
		sudo apt-mark hold grub-pc openssh-server >>${LOGFILE} 2&>1
	fi
	if [[ "$osfam" =~ ^(centos)$ ]]; then
		# install epel-release
		sudo yum install -y epel-release >>${LOGFILE} 2>&1
	fi
	echo -en " Updating packages, please wait \r"
	sudo ${installer} upgrade -y &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	echo -en " Updating packages              \r"
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Update of system package complete successfully" >>${LOGFILE} || echo "#    Update of system package complete with ERRORS" >>${LOGFILE}

	if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
		# unholding grub-pc (requires user interaction)
		sudo apt-mark unhold grub-pc openssh-server >>${LOGFILE} 2&>1
	fi
	
	echo "###  Update of system package complete  ###" >>${LOGFILE}
	echo
}

function setup_wallet() {
	install_prerequisites
	download_wallet
}

function install_prerequisites() {
	#wallet pre-requisites [2.00]
	echo "INSTALLING PRE-REQUISITE PACKAGES"
	echo >>${LOGFILE}
	echo "###    Pre-requisite installation started    ###" >>${LOGFILE}
	ec=0
	if [ $osver = "trusty" ]; then
		#install Ubuntu 14.04 pre-requisites
		echo -en " Adding new repository \r"
		sudo apt-get install software-properties-common -y >>${LOGFILE} 2>&1 #required for openVZ compatibility
		sudo add-apt-repository -y ppa:bitcoin/bitcoin >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
		sudo apt-get update >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl build-essential libtool autotools-dev libssl-dev libevent-dev bsdmainutils libboost-all-dev libdb4.8-dev libdb4.8++-dev libminiupnpc-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "xenial" ]; then
		#install Ubuntu 16.04 pre-requisites
		echo -en " Adding new repository \r"
		sudo apt-get install software-properties-common -y >>${LOGFILE} 2>&1 #required for openVZ compatibility
		sudo add-apt-repository -y ppa:bitcoin/bitcoin >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
		sudo apt-get update >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl build-essential libtool autotools-dev libssl-dev libevent-dev bsdmainutils libboost-all-dev libdb4.8-dev libdb4.8++-dev libminiupnpc-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "artful" ]; then
		#install Ubuntu 17.10 pre-requisites
		echo -en " Adding new repository \r"
		sudo apt-get install software-properties-common -y >>${LOGFILE} 2>&1 #required for openVZ compatibility
		sudo add-apt-repository -y ppa:bitcoin/bitcoin &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
		sudo apt-get update >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl libboost1.62-dev libboost1.62-tools-dev libboost-mpi-python1.62 libboost-mpi-python1.62-dev libboost1.62-all-dev software-properties-common libdb4.8-dev libdb4.8++-dev libminiupnpc-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "bionic" ]; then
		#install Ubuntu 18.04 pre-requisites
		echo -en " Adding new repository \r"
		sudo apt-get install software-properties-common -y >>${LOGFILE} 2>&1 #required for openVZ compatibility
		sudo add-apt-repository -y ppa:bitcoin/bitcoin &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
		sudo apt-get update >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl libboost1.62-dev libboost1.62-tools-dev libboost-mpi-python1.62 libboost-mpi-python1.62-dev libboost1.62-all-dev software-properties-common libdb4.8-dev libdb4.8++-dev libminiupnpc-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "jessie" ]; then
		#install Debian 8 pre-requisites
		echo -en " Adding new repository \r"
		sudo apt-get install software-properties-common dirmngr -y >>${LOGFILE} 2>&1 #required for openVZ compatibility
		sudo add-apt-repository -y ppa:bitcoin/bitcoin &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
		sudo apt-get update >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl libssl-dev libminiupnpc-dev libevent-dev libboost-all-dev libdb5.3-dev libdb5.3++-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "stretch" ]; then
		#install Debian 9 pre-requisites
		echo -en " Adding new repository \r"
		sudo apt-get install software-properties-common dirmngr -y >>${LOGFILE} 2>&1 #required for openVZ compatibility
		sudo add-apt-repository -y ppa:bitcoin/bitcoin &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		sleep 1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		echo -en " Installing required packages \r"
		sudo apt-get update >>${LOGFILE} 2>&1
		sudo apt-get install unzip curl libssl1.0-dev libminiupnpc-dev libevent-pthreads-2.0 libevent-2.0 libboost1.62-dev libboost1.62-tools-dev libboost-mpi-python1.62 libboost-mpi-python1.62-dev libboost1.62-all-dev software-properties-common libdb5.3-dev libdb5.3++-dev -y >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "Core" ]; then
		echo -en " Installing required packages \r"
		sudo yum install -y epel-release >>${LOGFILE} 2>&1
		sudo yum install -y unzip curl libtool openssl-devel libevent-devel boost-devel libdb-devel libdb-cxx-devel python3 miniupnpc-devel gmp-devel >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "fedora27" ]; then
		echo -en " Installing required packages \r"
		#sudo yum update -y >>${LOGFILE} 2>&1
		sudo yum install -y unzip curl libtool openssl-devel libevent-devel boost-devel libdb-devel libdb-cxx-devel python3 miniupnpc-devel gmp-devel >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	elif [ $osver = "fedora28" ]; then
		echo -en " Installing required packages, please wait... \r"
		#sudo yum update -y >>${LOGFILE} 2>&1
		sudo yum install -y unzip curl libtool compat-openssl10-devel libevent-devel boost-devel libdb-devel libdb-cxx-devel python3 miniupnpc-devel gmp-devel --allowerasing >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		echo -en " Installing required packages,                \r"
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

		# creating sym-links
			echo -en " Creating symbolic links \r"
			echo "#   Creating symbolic links " >>${LOGFILE} 
			ec=0
			if ! [ -f /usr/lib64/libboost_system.so.1.64.0 ]; then
				sudo ln -s /usr/lib64/libboost_system.so.1.66.0  /usr/lib64/libboost_system.so.1.64.0 >>${LOGFILE} 2>&1
				if ! [ $? -eq 0 ]; then ((ec+=1)); fi
			fi
			if ! [ -f /usr/lib64/libboost_thread.so.1.64.0 ]; then
				sudo ln -s /usr/lib64/libboost_thread.so.1.66.0 /usr/lib64/libboost_thread.so.1.64.0 >>${LOGFILE} 2>&1
				if ! [ $? -eq 0 ]; then ((ec+=1)); fi
			fi
			if ! [ -f /usr/lib64/libboost_program_options.so.1.64.0 ]; then
				sudo ln -s /usr/lib64/libboost_program_options.so.1.66.0 /usr/lib64/libboost_program_options.so.1.64.0 >>${LOGFILE} 2>&1
				if ! [ $? -eq 0 ]; then ((ec+=1)); fi
			fi
			if ! [ -f /usr/lib64/libboost_filesystem.so.1.64.0 ]; then
				sudo ln -s /usr/lib64/libboost_filesystem.so.1.66.0 /usr/lib64/libboost_filesystem.so.1.64.0 >>${LOGFILE} 2>&1
				if ! [ $? -eq 0 ]; then ((ec+=1)); fi
			fi
			if ! [ -f /usr/lib64/libboost_chrono.so.1.64.0 ]; then
				sudo ln -s /usr/lib64/libboost_chrono.so.1.66.0 /usr/lib64/libboost_chrono.so.1.64.0 >>${LOGFILE} 2>&1
				if ! [ $? -eq 0 ]; then ((ec+=1)); fi
			fi
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	fi
	echo "###    Pre-requisite installation complete    ###" >>${LOGFILE}
	echo
}

function download_wallet() {
	#wallet download [1.40]
	echo "DOWNLOADING AND INSTALLING DAEMON"
	echo >>${LOGFILE}
	echo "###    Downloading daemon started    ###" >>${LOGFILE}
	ec=0
	# OS specififc variables
		if [ $osver = "trusty" ]; then
			#download Ubuntu 14.04 wallet
			filename="${U14WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${U14WALLETLINK}
		elif [ $osver = "xenial" ]; then
			#download Ubuntu 16.04 wallet
			filename="${U16WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${U16WALLETLINK}
		elif [ $osver = "artful" ]; then
			#download Ubuntu 17.10 wallet
			filename="${U17WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${U17WALLETLINK}
		elif [ $osver = "bionic" ]; then
			#download Ubuntu 18.04 wallet
			filename="${U18WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${U18WALLETLINK}
		elif [ $osver = "jessie" ]; then
			#download Debian 8 wallet
			filename="${DE8WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${DE8WALLETLINK}
		elif [ $osver = "stretch" ]; then
			#download Debian 9 wallet
			filename="${DE9WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${DE9WALLETLINK}
		elif [ $osver = "Core" ]; then
			#download CentOS 7 wallet
			filename="${CO7WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${CO7WALLETLINK}
		elif [ $osver = "fedora27" ]; then
			#download Fedora 27 wallet
			filename="${F27WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${F27WALLETLINK}
		elif [ $osver = "fedora28" ]; then
			#download Fedora 28 wallet
			filename="${F28WALLETLINK##*/}"
			filepath=$HOME'/'$filename
			walletlink=${F28WALLETLINK}
		fi

	echo -en " Loading wallet ${filename} \r"
	[ $newusermn -eq 1 ] && sudo --user=$newuser wget ${walletlink} &>>${LOGFILE} || cd ~ && wget ${walletlink} &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

	echo "###  Downloading daemon complete  ###" >>${LOGFILE}
	if [ -f $filepath ]; then
		folder="${filename%.*}"
		echo -ne " Extracting ${filename} \r"
		if [ -d /tmp/$folder ]; then sudo rm -Rf /tmp/$folder &>>${LOGFILE}; fi
		[ $newusermn -eq 1 ] && sudo mkdir -p /tmp/$folder &>>${LOGFILE} ||sudo  mkdir -p /tmp/$folder &>>${LOGFILE}
		sudo chown --reference=${HOME} /tmp/$folder &>>${LOGFILE}
		[ $newusermn -eq 1 ] && sudo --user=$newuser tar -xvf ${filename} -C /tmp/${folder}/ &>>${LOGFILE} || tar -xvf ${filename} -C /tmp/${folder}/ &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

		echo -ne " Preparing ${WALLETPATH} directory \r"
		ec=0
		if ! [ -d ${WALLETPATH} ]; then
			[ $newusermn -eq 1 ] && sudo mkdir -p ${WALLETPATH} &>>${LOGFILE} ||sudo  mkdir -p ${WALLETPATH} &>>${LOGFILE}
		else
			[ $newusermn -eq 1 ] && sudo rm ${WALLETPATH}/* &>>${LOGFILE} || sudo rm ${WALLETPATH}/* &>>${LOGFILE}
		fi
		if ! [ $? -eq 0 ]; then ((ec+=1)); fi
		sudo chown --reference=${HOME} ${WALLETPATH} &>>${LOGFILE} 
		if ! [ $? -eq 0 ]; then ((ec+=1)); fi
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

		echo -ne " Moving files to ${WALLETPATH} \r"
		[ $newusermn -eq 1 ] && sudo --user=$newuser cp /tmp/${folder}/* ${WALLETPATH}/ &>>${LOGFILE} || cp /tmp/${folder}/* ${WALLETPATH}/ &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

		echo -ne " Removing installation files \r"
		sudo rm -Rf /tmp/${folder} &>>${LOGFILE}
		sudo rm -f ${filename} &>>${LOGFILE} 
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	fi
	#create symlinks in $HOME
		echo -ne " Creating stmbolic links to daemon and cli \r"
		if [ -d $HOME/$WALLETDIR"-sym" ]; then sudo rm -Rf $HOME/$WALLETDIR"-sym"; fi
		[ $newusermn -eq 1 ] && sudo --user=$newuser mkdir $HOME/$WALLETDIR"-sym" &>>${LOGFILE} || mkdir $HOME/$WALLETDIR"-sym" &>>${LOGFILE}
		#[ $newusermn -eq 1 ] && sudo --user=$newuser ln -s ${WALLETPATH}/${DAEMONFILE} $HOME/$WALLETDIR"-sym"/${DAEMONFILE} &>>${LOGFILE} || ln -s ${WALLETPATH}/${DAEMONFILE} $HOME/$WALLETDIR"-sym"/${DAEMONFILE} &>>${LOGFILE}
		[ $newusermn -eq 1 ] && sudo --user=$newuser ln -s ${WALLETPATH}/${CLIFILE} $HOME/$WALLETDIR"-sym"/${CLIFILE} &>>${LOGFILE} || ln -s ${WALLETPATH}/${CLIFILE} $HOME/$WALLETDIR"-sym"/${CLIFILE} &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

	if [ $sysctl -eq 1 ]; then
		if [ -f $WALLETPATH/$DAEMONFILE ]; then
			setup_systemd_service
		else
			echo -en "${RED} Daemon file doesn't exist, skipping systemd service setup.${NC}\n"
			echo "#    Daemon file doesn't exist, skipping systemd service setup." >>${LOGFILE}
		fi
	fi

	if [ $loadonboot -eq 1 ]; then
		if [ -f $WALLETPATH/$DAEMONFILE ]; then
			start_on_reboot
		else
			echo -en "${RED} Daemon file doesn't exist, skipping crontab update.${NC}\n"
			echo "#    Daemon file doesn't exist, skipping crontab update." >>${LOGFILE}
		fi
	fi
	echo
}

function configure_masternode() {
	#mn configuration    [2.00]
	echo "CONFIGURING MASTERNODE"
	echo >>${LOGFILE}
	echo "###    Masternode configuration started    ###" >>${LOGFILE}
	extip=$vpsip
	if [ $ipver -eq 6 ]; then rpcip=$vpsip; vpsip='['$vpsip']'; else rpcip=$vpsip; fi
	ec=0
	datadir=$HOME'/'$DATADIRNAME
	coinconf=$datadir'/'$CONFFILENAME

	if ! [ -d "$datadir" ]; then
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
			cp ${datadir}/wallet.dat $bakfile &>>${LOGFILE}
		fi
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#      Backup of wallet.dat: Successful" >>${LOGFILE} || echo "#      Backup of wallet.dat: FAILED" >>${LOGFILE}

	fi

	#check the daemon not running
	if [ -f ${datadir}/${DAEMONFILE}.pid ]; then

		if [ -f /etc/systemd/system/$SERVICENAME ]; then
			svcstate=$(sudo systemctl status ${SERVICENAME} | grep -oE 'Active: .*\)' | grep -oE '(running|dead)') 2>>${LOGFILE}
			if [ "$svcstate" = "running" ]; then
				echo -en " Stopping ${SERVICENAME} service\r"
				sudo systemctl stop ${SERVICENAME} >>${LOGFILE} 2>&1
				[ $? -eq 0 ] && ec=0 || ec=1
				[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
				[ $ec -eq 0 ] && echo "#      Stopping ${SERVICENAME} service: Successful" >>${LOGFILE} || echo "#       Stopping ${SERVICENAME} service: FAILED" >>${LOGFILE}
			fi
		else
			echo -en " Force stopping daemon \r"
			sudo pkill -9 -f ${DAEMONFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#      Force stopping daemon: Successful" >>${LOGFILE} || echo "#       Force stopping daemon: FAILED" >>${LOGFILE}
		fi
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
	[ $ec -eq 0 ] && echo "#      Clearing of ${coinconf}: Successful" >>${LOGFILE} || echo "#       Clearing of ${coinconf}: FAILED" >>${LOGFILE}

	echo -ne " Configuring ${CONFFILENAME} \r"
	echo "# RPC configuration part " >>${coinconf}
	echo "server=1" >>${coinconf}
	echo "rpcuser=${rpcuser}" >>${coinconf}
	echo "rpcpassword=${rpcpassword}" >>${coinconf}
	if [ "$natip" = "true" ]; then echo "rpcconnect=127.0.0.1" >>${coinconf}; else echo "rpcconnect=${rpcip}" >>${coinconf}; echo "rpcbind=${vpsip}:${RPCPORT}" >>${coinconf}; fi
	echo "rpcport=${RPCPORT}" >>${coinconf}
	echo "rpcthreads=8" >>${coinconf}
	echo "rpcallowip=127.0.0.1" >>${coinconf}
	if [ $ipver -eq 6 ]; then echo "rpcallowip=::1" >>${coinconf}; fi
	if [ "$natip" = "false" ]; then echo "rpcallowip=${rpcip}" >>${coinconf}; fi
	echo >>${coinconf}
	echo "# P2P configuration part" >>${coinconf}
	echo "daemon=1" >>${coinconf}
	if [ "$natip" = "true" ]; then echo "listen=1" >>${coinconf}; else echo "bind=${vpsip}" >>${coinconf}; fi
	echo "externalip=${vpsip}" >>${coinconf}
	echo "port=${P2PPORT}" >>${coinconf}
	echo "maxconnections=256" >>${coinconf}
	echo >>${coinconf}
	echo "# Masternode configuration part" >>${coinconf}
	echo "masternode=1" >>${coinconf}
	echo "masternodeaddr=${vpsip}:${P2PPORT}" >>${coinconf}
	echo "masternodeprivkey=${mnprivkey}" >>${coinconf}
	#echo "# Addnode section" >>${coinconf}
	#echo "addnode=1.1.1.1:65535" >>${coinconf}


	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#      Configuring of ${coinconf}: Successful" >>${LOGFILE} || echo "#       Configuring of ${coinconf}: FAILED" >>${LOGFILE}
	chown $USER:$USER ${coinconf} >>${LOGFILE} 2>&1

	#loading blockchain cache
	if ! [ "$BLOCKDUMPLINK" = "" ]; then
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

	#creating de-provisioning script
		create_deprovisioning_script

	#starting daemon
	if [ $sysctl -eq 1 ]; then
			echo "#      Starting ${SERVICENAME} service      " >>${LOGFILE}
			echo -en " Starting ${SERVICENAME} service\r"

			if [ "$BOOTSTRAP" = "true" ] && [ ! "$BLOCKDUMPLINK" = "" ]; then
				sudo systemctl set-environment "${DAEMONFILE}${USER}opt=-loadblock=${WALLETPATH}/bootstrap.dat" >>${LOGFILE} 2>&1;
			else
				sudo systemctl unset-environment ${DAEMONFILE}${USER}'opt' >>${LOGFILE} 2>&1
			fi
		
			sudo systemctl start ${SERVICENAME} >>${LOGFILE} 2>&1
			sudo systemctl unset-environment ${DAEMONFILE}${USER}'opt' >>${LOGFILE} 2>&1; 
			[ $? -eq 0 ] && ec=0 || ec=1
			sleep 5
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#      Starting ${SERVICENAME} service: Successful" >>${LOGFILE} || echo "#       Starting ${SERVICENAME} service: FAILED" >>${LOGFILE}
			
	else
			echo "#      Starting daemon      " >>${LOGFILE}
			echo -en " Starting daemon  \r"
			if [ "$BOOTSTRAP" = "true" ] && [ ! "$BLOCKDUMPLINK" = "" ]; then
				optstring="-loadblock=${HOME}/${DATADIRNAME}/bootstrap.dat"
			else
				optstring=""
			fi

			echo "#      Executing "${WALLETPATH}/${DAEMONFILE}" -daemon ${optstring}" >>${LOGFILE}
			if [ $newusermn -eq 1 ]; then
				sudo --user=$newuser ${WALLETPATH}/${DAEMONFILE} -daemon ${optstring} >>${LOGFILE} 2>&1
			else
				${WALLETPATH}/${DAEMONFILE} -daemon ${optstring} >>${LOGFILE} 2>&1
			fi

			[ $? -eq 0 ] && ec=0 || ec=1
			sleep 5
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#      Daemon start: Successful" >>${LOGFILE} || echo "#       Daemon start: FAILED" >>${LOGFILE}
	fi
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
		currentblk=$(${WALLETPATH}/${CLIFILE} getblockcount  2>>${LOGFILE} | grep -oE '[0-9]*')
		while
			[ $currentblk -lt $netheight ]
		do
			currentblk=$(${WALLETPATH}/${CLIFILE} getblockcount 2>>${LOGFILE} | grep -oE '[0-9]*')
			if [ "$currentblk" = "" ]; then currentblk=0; fi
			pcent=$(python -c "print ${currentblk}*100.0/${netheight}"  2>>${LOGFILE})
			format_pcent
			echo -en " Synchronizing blockchain: block ${currentblk} / ${netheight}   \r" && echo -en "${STATUSX}[ ${RED}${pcent}%${NC} ]\r"
			echo "#      Loaded blocks: ${currentblk}" >>${LOGFILE}
			sleep 3
			netheight=$(curl -s ${BLKCOUNTLINK}  2>>${LOGFILE})
		done
		synced="true"
		echo -en " Synchronizing blockchain: block ${currentblk}    [ ${GREEN}100.0%${NC} ]                      \r"
		[ "$synced" = "true" ] && echo -en $STATUS0 || echo -en $STATUS1
		echo "#      Synchronizing blockchain ...    [ Done ]" >>${LOGFILE}


		#local p2p port check
		echo "#        Checking p2p port reachability to tcp/"$P2PPORT &>>${LOGFILE}
		echo -en " Checking local p2p port reachability to tcp/${P2PPORT} \r"
		portstatus=$(echo >/dev/tcp/$extip/$P2PPORT >/dev/null 2>&1 && echo "Successful" || echo "FAILED")
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
		mncount=$(${WALLETPATH}/${CLIFILE} masternode count 2>>${LOGFILE} | grep -oE '[0-9]*' )
		synced="false"
		while
			[ $mncount -eq 0 ]
		do
			mncount=$(${WALLETPATH}/${CLIFILE} masternode count 2>>${LOGFILE} | grep -oE '[0-9]*')
			echo -ne " Waiting for masternode synchronization \r"
			sleep 5
		done
		echo -ne " Masternode synchronization                \r"
		synced="true"
		[ "$synced" = "true" ] && echo -en $STATUS0 || echo -en $STATUS1
		[ "$synced" = "Successful" ] && echo "#      Masternode synchronization: Successful" >>${LOGFILE} || echo "#       Masternode synchronization: FAILED" >>${LOGFILE}

		echo "###  Masternode configuration complete  ###" >>${LOGFILE}
		echo "MASTERNODE CONFIGURATION FINISHED"
		sleep 5
		#check masternode status
		mnstatus=$(${WALLETPATH}/${CLIFILE} masternode debug 2>>${LOGFILE})
		currentblk=$(${WALLETPATH}/${CLIFILE} getblockcount | grep -oE '[0-9]*' 2>>${LOGFILE})

	else

		echo -en "${RED} DAEMON FAILED TO START, MASTERNODE SETUP ABORTED ${NC}\n"
		echo "#      Daemon failed to start, masternode setup aborted." >>${LOGFILE}
		setupmn=0
	fi
}

function remote_portcheck() {
	# returns
	 # result  :  port open status (open=port is open / closed=port is closed / restricted_query=port is not in the list of allowed)
	result=$(curl -sH 'Accept: text/plain' https://unclear.space/services/port-chk.php?host=$extip\&port=$P2PPORT)
	echo "#    Remote port check result: ${result}" >>${LOGFILE}
	result=$(echo $result | grep -oE 'open|closed|resticted_query')
	if [ "$result" = "open" ]; then remportcheck="Successful"; else remportcheck="FAILED"; fi
}

function detect_ip_address() {
	# returns
	 #   vpsip     :  detected external ip address
	 #   ipver     :  detected ip address version (4=IPv4 / 6=IPv6)
	vpsip=$(curl -sH 'Accept: text/plain' http://unclear.space/services/detect-ip.php)
	echo "#    IP address detected: ${vpsip}" >>${LOGFILE}
	if [[ $vpsip = *":"* ]]; then ipver=6; else ipver=4; fi
	if [ $ipver -eq 6 ] && ! [ "$IPV6SUPPORTED" = "true" ]; then 
		vpsip4=$(curl -4 -sH 'Accept: text/plain' http://unclear.space/services/detect-ip.php)
		echo "#    IPv4 address detected: ${vpsip4}" >>${LOGFILE}
		if ! [ "$vpsip4" = "" ]; then vpsip=$vpsip4; ipver=4; fi
	fi
	detect_nat
}

function check_ip_port_in_use() {
	if [ $ipv -eq 4 ]; then bcast='0.0.0.0'; else bcast='::'; fi
	if [[ $nstat = *"${ipaddr}:${P2PPORT}"* ]]; then
		pcres="${ipaddr}:${P2PPORT}"
	elif [[ $nstat = *"[${ipaddr}]:${P2PPORT}"* ]]; then
		pcres="[${ipaddr}]:${P2PPORT}"
	elif [[ $nstat = *"${bcast}:${P2PPORT}"* ]]; then
		pcres="${bcast}:${P2PPORT}"
	elif [[ $nstat = *"[${bcast}]:${P2PPORT}"* ]]; then
		pcres="[${bcast}]:${P2PPORT}"
	elif [[ $nstat = *"*:"${P2PPORT}* ]]; then
		pcres="*:${P2PPORT}"
	else
		pcres=""
	fi
	if [[ $nstat = *"${ipaddr}:${RPCPORT}"* ]]; then
		rcres="${ipaddr}:${RPCPORT}"
	elif [[ $nstat = *"[${ipaddr}]:${RPCPORT}"* ]]; then
		rcres="[${ipaddr}]:${RPCPORT}"
	elif [[ $nstat = *"${bcast}:${RPCPORT}"* ]]; then
		rcres="${bcast}:${RPCPORT}"
	elif [[ $nstat = *"[${bcast}]:${RPCPORT}"* ]]; then
		rcres="[${bcast}]:${RPCPORT}"
	elif [[ $nstat = *"*:${RPCPORT}"* ]]; then
		rcres="*:${RPCPORT}"
	else 
		rcres=""
	fi
}

function detect_nat() {
	# returns
	#   natlip :  check detected ip is assidned to local interface ( true=NAT detected / false=no NAT detected )
	natip=$(ip -o addr | grep global | awk '!/^[0-9]*: ?lo|tun|link\/ether/ {gsub("/", " "); print $2" "$4}' | grep -oE ${vpsip} 2>>${LOGFILE})
	if [ "$natip" = "" ]; then natip="true"; else natip="false"; fi
	if [ "$natip" = "true" ]; then echo "#    IP address ${vpsip} is NOT IN LIST OF LOCAL IPs" >>${LOGFILE};  else echo "#    IP address ${vpsip} is local" >>${LOGFILE}; fi
}

function select_ip () {
	sleep 1
	echo -en "\n   IP ADDRESS SELECTION\n"
    ipv4list=$(ip -f inet -o addr | grep global | awk '!/^[0-9]*: ?lo|tun|link\/ether/ {gsub("/", " "); print $2" "$4}')
	#echo "$ipv4list"   # DEBUG
    i=0
    nstat=$(ss -ln | grep 'LISTEN ' | grep 'tcp')
    if ! [ "$ipv4list" = "" ]; then
        ipv=4
        while read -r ipline; do
            ((i+=1))
            ifname=$(echo $ipline | grep -oE '^[a-zA-Z0-9-]*')
            INTERFACES[$i]=$ifname
            ipaddr=$(echo $ipline | grep -oE '[0-9.]*$')
            IPADDRESSES[$i]=$ipaddr
			#echo "i=$i; ipaddr=$ipaddr; IPADDRESSES[$i]=${IPADDRESSES[$i]}; ipline=$ipline"  # DEBUG
            check_ip_port_in_use
            if ! [ "$pcres" = "" ]; then P2PPU[$i]="USED"; else P2PPU[$i]="FREE"; fi
            if ! [ "$rcres" = "" ]; then RPCPU[$i]="USED"; else RPCPU[$i]="FREE"; fi
        done <<< "$ipv4list"
    fi

    if [ "$IPV6SUPPORTED" = "true" ]; then
        ipv6list=$(ip -f inet6 -o addr | grep global | awk '!/^[0-9]*: ?lo|tun|link\/ether/ {gsub("/", " "); print $2" "$4}')
        if ! [ "$ipv6list" = "" ]; then
            ipv=6
            while read -r ipline; do
                ((i+=1))
                ifname=$(echo $ipline | grep -oE '^[a-zA-Z0-9-]*')
                INTERFACES[$i]=$ifname
                ipaddr=$(echo $ipline | grep -oE '[a-fA-F0-9:]*$')
                IPADDRESSES[$i]=$ipaddr
				#echo "i=$i; ipaddr=$ipaddr; IPADDRESSES[$i]=${IPADDRESSES[$i]}; ipline=$ipline"  # DEBUG
                check_ip_port_in_use
                if ! [ "$pcres" = "" ]; then P2PPU[$i]="USED"; else P2PPU[$i]="FREE"; fi
                if ! [ "$rcres" = "" ]; then RPCPU[$i]="USED"; else RPCPU[$i]="FREE"; fi
            done <<< "$ipv6list"
        fi
    fi
	if [ ${#IPADDRESSES[@]} -gt 0 ]; then
		# header                                       '
			echo -en "   Nb\r"
			echo -en "\033[5C │"
			echo -en " PR\r"
			echo -en "\033[10C │"
			echo -en " Interface\r"
			echo -en "\033[22C │"
			echo -en " IP Address\n"
			echo "  ────┼────┼───────────┼───────────────────────────────────────────────────────"

		for (( j=1; j<=${i}; j++ )); do
			if [ "${P2PPU[$j]}" = "FREE" ]; then pi="${GREEN}+${NC}"; else pi="${RED}!${NC}"; fi
			if [ "${RPCPU[$j]}" = "FREE" ]; then ri="${GREEN}+${NC}"; else ri="${RED}!${NC}"; fi

			#echo "j=$j; i=$i; IPADDRESSES[$j]=${IPADDRESSES[$j]}" # DEBUG
			echo -en "   ${j}\r"
			echo -en "\033[5C │"  
			echo -en " ${pi}${ri}\r"
			echo -en "\033[10C │" 
			echo -en " ${INTERFACES[$j]}\r"
			echo -en "\033[22C │"
			echo -en " ${IPADDRESSES[$j]}\n"
		done

		echo "   0    Exit selection and enter IP manually"
		echo -en "        ( PR: P - P2P port; R - RPC port )\n"
		echo -en "        ( ${GREEN}+${NC} port is free; ${RED}!${NC} port already in use )\n"
		echo 
		read -p "   Please select IP address Nb to bind masternode: " ipidx
		if ! [[ "$ipidx" =~ ^[0-9]+$ ]]; then ipidx=-1; fi
		while [ $ipidx -gt $i ] || [ $ipidx -lt 0 ]; do
			echo -en "   ${RED}Incorrect index selected, please try again.${NC}\n"
			read -p "   Please select Nb of IP address to bind masternode: " ipidx
			if ! [[ "$ipidx" =~ ^[0-9]+$ ]]; then ipidx=-1; fi
		done	
		if [ $ipidx -eq 0 ]; then
        	ip_questionnaire
    	else
			vpsip=${IPADDRESSES[$ipidx]}
			if [[ $vpsip = *":"* ]]; then ipver=6; else ipver=4; fi
			echo -en "   Selected ip address: ${PURPLE}${vpsip}${NC} \n"
			echo "#    Selected ip address: ${vpsip}" >>${LOGFILE}
		fi
	else
		ip_questionnaire
	fi
}

function format_pcent(){
	pcent=$(awk '$1 == ($1+0) {$1 = sprintf("%0.1f", $1)} 1' <<<${pcent})
	if [ ${#pcent} -eq 3 ]; then
		pcent='  '$pcent
	elif [ ${#pcent} -eq 4 ]; then
		pcent=' '$pcent
	fi
}

function create_user() {
	#create non-root user [2.00]
	echo "CREATING NEW USER"
	if [[ "$osfam" =~ ^(ubuntu|debian|linuxmint)$ ]]; then
		sudogrp="sudo"
	elif [[ "$osfam" =~ ^(centos|fedora)$ ]]; then
		sudogrp="wheel"
	fi
	if [ $newsudouser -eq 1 ]; then
		echo -en " Creating new sudo user (${newuser})\r"
		echo "#    Creating new sudo user (${newuser})" >>${LOGFILE}
		echo "$    sudo useradd -d /home/$newuser -m -G $sudogrp -s /bin/bash -p >${ePass:0:15}*******< $newuser" >>${LOGFILE}
		sudo useradd -d /home/$newuser -m -G $sudogrp -s /bin/bash -p $ePass $newuser &>>${LOGFILE}
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Creating new sudo user (${newuser}) successful" >>${LOGFILE} || echo "#    Creating new sudo user (${newuser}) FAILED" >>${LOGFILE}
		if [ $sudowopass -eq 1 ]; then
			echo -en " Assigning sudo permissions without password \r"
			echo "#    Assigning sudo permissions without password" >>${LOGFILE}
			sudo echo "${newuser} ALL=(ALL:ALL) NOPASSWD: ALL" >/tmp/$newuser 2>>${LOGFILE}
			sudo mv /tmp/$newuser /etc/sudoers.d/ &>>${LOGFILE}
			sudo chown --reference=/etc/sudoers.d/ /etc/sudoers.d/$newuser &>>${LOGFILE}
			sudo chmod 440 /etc/sudoers.d/$newuser &>>${LOGFILE}
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    Assigning sudo permissions without password successful" >>${LOGFILE} || echo "#    Assigning sudo permissions without password FAILED" >>${LOGFILE}
		fi
	else
		echo -en " Creating new non-sudo user (${newuser})\r"
		echo "#    Creating new non-sudo user (${newuser})" >>${LOGFILE}
		echo "$    sudo useradd -d /home/$newuser -m -s /bin/bash -p >${ePass:0:15}*******< $newuser" >>${LOGFILE}
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
			sudo cp $SCRIPTPATH /home/$newuser >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

			echo -en " Changing script owner to ${newuser} \r"
			sudo chown --reference=/home/$newuser/ /home/$newuser/$scriptname >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

			echo -en " Creating parameters handover file \r"
			create_handover_file
			sudo mv $SCRIPTPATH.ho /home/$newuser >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1

			echo -en " Changing file owner to ${newuser} \r"
			sudo chown --reference=/home/$newuser/ /home/$newuser/$scriptname.ho >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1


			echo -en "\n${RED} WARNING:${NC} To continue masternode installation please switch to '"${newuser}"' account and launch the script again.\n"
			echo -en " Use below commands to run script under '"${newuser}"' account \n\n"
			echo -en "   ${PURPLE} su ${newuser} \n"
			echo -en "    cd /home/${newuser} \n"
			echo -en "    ./${scriptname} ${NC}\n\n"
			echo " SCRIPT TERMINATED "
			exit

		fi
		HOME=$(su -c 'cd ~ && pwd' ${newuser})
		USER=$newuser
		# defining wallet path (under /usr/local/bin)
		WALLETPATH=/usr/local/bin/${WALLETDIR}-${USER}
		echo " Installation will continue using user profile: "$USER
		echo
	else
		echo
	fi

}

function encrypt_password() {
	ePass=$(python -c "import random,string,crypt; randomsalt = ''.join(random.sample(string.ascii_letters,8)); print crypt.crypt('${pwd1}', '\$6\$%s\$' % randomsalt)" 2>>${LOGFILE}) 
	if [ "$ePass" = "" ]; then
		ePass=$(perl -e "print crypt("$pwd1", '\$6\$$(</dev/urandom tr -dc 'a-zA-Z0-9' | head -c 8)\$')" 2>>${LOGFILE}) 
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
		crn=$(more /tmp/tempcron | grep $WALLETPATH'/'$DAEMONFILE)
		if [ "$crn" = "" ]; then
			echo -en " Updating crontab \r"
			echo "#    Updating crontab " >>${LOGFILE}

			echo "@reboot ${WALLETPATH}/${DAEMONFILE} -daemon" 1>>/tmp/tempcron 2>>${LOGFILE}

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

function setup_systemd_service() {
	#create systemd service [1.40]
	SERVICENAME=$DAEMONFILE'-'$USER'.service'
	echo
	echo "CREATING SYSTEMD SERVICE"
	echo "###   Systemd service creation started    ###" >>${LOGFILE}
	#check if service exist
	echo -en " Checking service doesn't exist\r"
	echo "#      Checking service doesn't exist" >>${LOGFILE}
	if [ -f "/etc/systemd/system/${SERVICENAME}" ]; then
		exist=1
		echo -en $STATUS0
		#echo -en "${RED} Failed to create systemd service, service already exist${NC}\n"
		echo "#    Service existance check done, service file alredy exist" >>${LOGFILE}
	else
		exist=0
		echo -en $STATUS0
		echo "#    Service existance check successful" >>${LOGFILE}
	fi
	#delete existing service
		if [ $exist -eq 1 ]; then
			echo -en " Removing old system instance, please wait...\r"
			echo "#      Removing old system instance" >>${LOGFILE}
			sudo systemctl stop ${SERVICENAME} >>${LOGFILE} 2>&1
			sudo systemctl disable ${SERVICENAME} >>${LOGFILE} 2>&1
			sudo systemctl daemon-reload >>${LOGFILE} 2>&1
			sudo rm -f /etc/systemd/system/${SERVICENAME} >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			echo -en " Removing old system instance,               \r"
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#    Removing old system instance: successful" >>${LOGFILE} || echo "#    Removing old system instance: FAILED" >>${LOGFILE}
			exist=0
		fi
	#create service
	if [ $exist -eq 0 ]; then
		echo "#    Creating /tmp/${SERVICENAME} file " >>${LOGFILE}
		echo -en " Creating /tmp/${SERVICENAME} file \r"

		echo -en '[Unit]'"\n"\
		'Description='$TICKER' masternode service ('$DAEMONFILE'-'$USER')'"\n"\
		'After=network.target'"\n\n"\
		'[Service]'"\n"\
		'User='$USER"\n"\
		'Type=forking'"\n"\
		'WorkingDirectory='$HOME'/'$DATADIRNAME"\n"\
		'ExecStart='$WALLETPATH'/'$DAEMONFILE' -daemon $'${DAEMONFILE}${USER}'opt'"\n"\
		'ExecStop='$WALLETPATH'/'$CLIFILE' stop'"\n"\
		'Restart=on-failure'"\n"\
		'RestartSec=15'"\n"\
		'TimeoutStopSec=60'"\n"\
		'TimeoutStartSec=15'"\n"\
		'StartLimitInterval=60'"\n"\
		'StartLimitBurst=10'"\n\n"\
		'[Install]'"\n"\
		'WantedBy=multi-user.target'"\n">/tmp/$SERVICENAME 2>>${LOGFILE}

		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Creating /tmp/${SERVICENAME} file: successful" >>${LOGFILE} || echo "#    Creating /tmp/${SERVICENAME} file: FAILED" >>${LOGFILE}

		#move file from /tmp to /etc/systemd/system
		echo "#    Moving ${SERVICENAME} file to /etc/systemd/system " >>${LOGFILE}
		echo -en " Moving ${SERVICENAME} file to /etc/systemd/system\r"
		sudo mv /tmp/${SERVICENAME} /etc/systemd/system >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Moving ${SERVICENAME} file to /etc/systemd/system: successful" >>${LOGFILE} || echo "#    Moving ${SERVICENAME} file to /etc/systemd/system: FAILED" >>${LOGFILE}

		#reload systemctl daemon
		echo "#    Reloading systemctl daemon" >>${LOGFILE}
		echo -en " Reloading systemctl daemon\r"
		sudo systemctl daemon-reload >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#    Reloading systemctl daemon: successful" >>${LOGFILE} || echo "#    Reloading systemctl daemon: FAILED" >>${LOGFILE}

		#enable service
		echo "#    Enabling ${SERVICENAME} " >>${LOGFILE}
		echo -en " Enabling ${SERVICENAME} \r"
		sudo systemctl enable ${SERVICENAME} >>${LOGFILE} 2>&1
		[ $? -eq 0 ] && ec=0 || ec=1
		[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
		[ $ec -eq 0 ] && echo "#   Enabling ${SERVICENAME}: successful" >>${LOGFILE} || echo "#    Enabling ${SERVICENAME}: FAILED" >>${LOGFILE}
	fi

}

function print_result() {
	if [ $setupmn -eq 1 ]; then
		# show MN setup report
			echo
			echo "╒══════════════════════════════════════════════════════════════════════════════╕"
			echo "│                        MASTERNODE CONFIGURATION REPORT                       │"
			echo "├──────────────────────────────────────────────────────────────────────────────┤"
			echo -en "│ Node IP endpoint: ${PURPLE}"$vpsip:$P2PPORT"${NC}\r" && echo -en "\033[79C│\n"
			echo -en "│ Masternode private key: ${PURPLE}"$mnprivkey"${NC}\r" && echo -en "\033[79C│\n"
			echo -en "│ Tx hash: ${PURPLE}"$txhash"${NC}\r" && echo -en "\033[79C│\n"
			echo -en "│ Tx output: ${PURPLE}"$txoutput"${NC}\r" && echo -en "\033[79C│\n"
			echo -en "│ Current daemon block: ${PURPLE}"$currentblk"${NC}\r" && echo -en "\033[79C│\n"
			echo "├──────────────────────────────────────────────────────────────────────────────┤"
			echo -en "│ RPC user:     ${PURPLE}${rpcuser}${NC}\r" && echo -en "\033[79C│\n"
			echo -en "│ RPC password: ${PURPLE}${rpcpassword}${NC}\r" && echo -en "\033[79C│\n"
			echo "├──────────────────────────────────────────────────────────────────────────────┤"
			echo -en "│ Local p2p port connection test:  "
			[ "$portstatus" = "Successful" ] && echo -en "${GREEN}${portstatus}${NC}\r" || echo -en "${RED}${portstatus}${NC}\r"
			echo -en "\033[79C│\n"
			echo -en "│ Remote p2p port connection test: "
			[ "$remportcheck" = "Successful" ] && echo -en "${GREEN}${remportcheck}${NC}\r" || echo -en "${RED}${remportcheck}${NC}\r"
			echo -en "\033[79C│\n"
			echo "├──────────────────────────────────────────────────────────────────────────────┤"
			echo -en "│ Installation path:   ${PURPLE}"$WALLETPATH"${NC}\r" && echo -en "\033[79C│\n"
			echo -en "│ Data directory path: ${PURPLE}"$datadir"${NC}\r" && echo -en "\033[79C│\n"
			if [ $sysctl -eq 1 ]; then
				echo "╞══════════════════════════════════════════════════════════════════════════════╡"
				echo "│                           SYSTEMD SERVICE COMMANDS                           │"
				echo "├──────────────────────────────────────────────────────────────────────────────┤"
				echo -en "│ Daemon start: ${PURPLE}sudo systemctl start ${SERVICENAME}${NC}\r" && echo -en "\033[79C│\n"
				echo -en "│ Daemon stop:  ${PURPLE}sudo systemctl stop ${SERVICENAME}${NC}\r" && echo -en "\033[79C│\n"
				echo -en "│ Check status: ${PURPLE}sudo systemctl status ${SERVICENAME}${NC}\r" && echo -en "\033[79C│\n"
				echo -en "│\r" && echo -en "\033[79C│\n"

				svcstate=$(sudo systemctl status ${SERVICENAME} | grep -oE 'Active: .*\)' | grep -oE '(active|inactive)') 2>>${LOGFILE}
				echo -en "│ SERVICE STATUS: "
				[ "$svcstate" = "active" ] && echo -en "${GREEN}${svcstate}${NC}\r" || echo -en "${RED}${svcstate}${NC}\r"
				echo -en "\033[79C│\n"
			fi
			if [ $easynode -eq 1 ]; then
				echo "╞══════════════════════════════════════════════════════════════════════════════╡"
				echo "│                       easyNode Manager script installed                      │"
				echo "├──────────────────────────────────────────────────────────────────────────────┤"
				echo -en "│ Start command: ${PURPLE}${WALLETPATH}/easynode.sh${NC}\r" && echo -en "\033[79C│\n"
				echo -en "│ Config file:  ${PURPLE}${WALLETPATH}/easynode.conf${NC}\r" && echo -en "\033[79C│\n"
			fi
			echo "╞══════════════════════════════════════════════════════════════════════════════╡"
			echo "│                           MASTERNODE STATUS ON VPS                           │"
			echo "├──────────────────────────────────────────────────────────────────────────────┤"
			[ "$mnstatus" = "Masternode successfully started" ] && msgcolor=${GREEN} ||msgcolor=${RED}
			msglines=$(echo ${mnstatus} | fold -sw 76)
			while read -r mline; do
				echo -en "│ ${msgcolor}$mline${NC}\r" && echo -en "\033[79C│\n"
			done <<< "$msglines"
			echo "╘══════════════════════════════════════════════════════════════════════════════╛"
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
		echo -en "     Press any key to continue ...\r" 
		read -n1 ll
		echo
		#show instruction to start masternode in local wallet
			echo "  PLEASE FOLLOW INSTRUCTIONS BELOW TO START YOUR MASTERNODE  "
			echo
			echo "1. Open your local wallet."
			echo -en "2. Navigate to ${PURPLE}Masternodes tab -> My Master Nodes tab${NC}\n"
			echo "3. Click 'Create...' button and enter following information in the form:"
			echo -en "   Alias:   any alpha-numeric identifier\n"
			echo -en "   Address: ${PURPLE}${vpsip}:${P2PPORT}${NC}\n"
			echo -en "   PrivKey: ${PURPLE}${mnprivkey}${NC}\n"
			echo -en "   TxHash:  ${PURPLE}${txhash}${NC}\n"
			echo -en "   Output Index: ${PURPLE}${txoutput}${NC}\n"
			echo     "   (Reward Address and Reward % fields are optional)"
			echo "   Click 'OK' button and then 'Update' button to refresh the list"
			echo "4. Restart your local wallet and wait for full synchronization"
			echo -en "5. Navigate to ${PURPLE}Help -> Debug window -> Console tab${NC}\n"
			echo "6. Start masternode using command (replace 'mnalias' with one entered at step 3):"
			echo -en "    ${PURPLE}masternode start-alias \"mnalias\" ${NC}\n"
			echo
		echo -en "    After successful masternode start in local wallet press any key...\r"
		read -n1 ll
		echo
		# post-start status report
			mnstatus=$(${WALLETPATH}/${CLIFILE} masternode debug 2>>${LOGFILE})
			mnstate=$(${WALLETPATH}/${CLIFILE} masternode list status $txhash 2>>${LOGFILE} | grep -oE '(PRE_ENABLED|ENABLED|EXPIRED|WATCHDOG_EXPIRED|NEW_START_REQUIRED|UPDATE_REQUIRED|POSE_BAN|OUTPOINT_SPENT)' 2>>${LOGFILE})
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
			echo "╒══════════════════════════════════════════════════════════════════════════════╕"
			echo "│                         MASTERNODE POST-START REPORT                         │"
			echo "├────────────┬─────────────────────────────────────────────────────────────────┤"
			echo -en "│ VPS STATUS \r"
			[ "$mnstatus" = "Masternode successfully started" ] && msgcolor=${GREEN} ||msgcolor=${RED}
			msglines=$(echo ${mnstatus} | fold -sw 62)
			while read -r mline; do
				echo -en "│ \r" 
				echo -en "\033[13C│ ${msgcolor}$mline${NC}\r"
				echo -en "\033[79C│\n"
			done <<< "$msglines"
			echo "├────────────┼─────────────────────────────────────────────────────────────────┤"
			echo -en "│ LIST STATE │ ${mnstate}\r" && echo -en "\033[79C│\n"
			echo "╘════════════╧═════════════════════════════════════════════════════════════════╛"
			echo
			echo " Please use command below to check masternode status in VPS command line:"
			echo
			echo -en "${PURPLE}  ${WALLETPATH}/${CLIFILE} masternode status${NC}\n"
			echo

			if [ $newusermn -eq 1 ]; then
				echo -en "  WARNING: Installation was done under ${PURPLE}${newuser}${NC} account\n"
				echo -en "           To run commands correcly, relogin as ${PURPLE}${newuser}${NC} or switch user with command below: \n"
				echo
				echo -en "               ${PURPLE}cd ${HOME} && su ${newuser}${NC}\n"
				echo

			fi
	fi
}

function setup_easynode() {
	echo "INSTALLING EASYNODE MANAGER SCRIPT"
	echo >>${LOGFILE}
	echo "###    easyNode installation started    ###" >>${LOGFILE}

	#create config file
	echo -en " Creating easynode.conf \r"
	if [ $newusermn -eq 1 ]; then
		sudo --user=$newuser echo >$WALLETPATH/easynode.conf 2>>${LOGFILE}
	else
		echo >$WALLETPATH/easynode.conf 2>>${LOGFILE}
	fi
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Creating easynode.conf: successful" >>${LOGFILE} || echo "#    Creating easynode.conf: FAILED" >>${LOGFILE}

	echo -en " Configuring easynode.conf \r"
	echo 'TICKER="FLM"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'DATADIR="'$HOME'/'$DATADIRNAME'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'CONFIGFILENAME="'$CONFFILENAME'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'WALLETPATH="'$WALLETPATH'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'DAEMONFILENAME="'$DAEMONFILE'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'CLIFILENAME="'$CLIFILE'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'PIDFILENAME="'$DAEMONFILE'.pid"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'SERVICENAME="'$SERVICENAME'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'TXHASH="'$txhash'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'P2PPORT="'$P2PPORT'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	echo 'RPCPORT="'$RPCPORT'"' >>$WALLETPATH/easynode.conf 2>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Configuring easynode.conf: successful" >>${LOGFILE} || echo "#    Configuring easynode.conf: FAILED" >>${LOGFILE}

	#download easyNode script
	echo -en " Downloading easyNode Manager script \r"
	[ $newusermn -eq 1 ] && sudo --user=$newuser wget ${EASYNODELINK} &>>${LOGFILE} || cd ~ && wget ${EASYNODELINK} &>>${LOGFILE}
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Downloading easyNode script: successful" >>${LOGFILE} || echo "#    Downloading easyNode script: FAILED" >>${LOGFILE}

	#update permissions
	echo -en " Updating easyNode Manager permissions \r"
	chmod +x easynode.sh >>${LOGFILE} 2>&1
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Downloading easyNode script: successful" >>${LOGFILE} || echo "#    Downloading easyNode script: FAILED" >>${LOGFILE}

	#moving file to wallet dir
	echo -en " Moving easyNode to daemon directory \r"
	mv easynode.sh $WALLETPATH
	[ $? -eq 0 ] && ec=0 || ec=1
	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
	[ $ec -eq 0 ] && echo "#    Moving easyNode to daemon directory: successful" >>${LOGFILE} || echo "#    Moving easyNode to daemon directory: FAILED" >>${LOGFILE}
	echo
}

function check_os_support() {
	if [ "${osver}" = "trusty" ]; then
		if [ "$U14WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	elif [ "${osver}" = "xenial" ]; then
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
	elif [ "${osver}" = "stretch" ]; then
		if [ "$DE9WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	elif [ "${osver}" = "jessie" ]; then
		if [ "$DE8WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	elif [ "${osver}" = "Core" ]; then
		if [ "$CO7WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	elif [ "${osver}" = "fedora27" ]; then
		if [ "$F27WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	elif [ "${osver}" = "fedora28" ]; then
		if [ "$F28WALLETLINK" = "" ]; then
			echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n"
			exit
		fi
	else
		echo -en "${RED} This operating system is not supported by the script. Please contact support.${NC}\n\n"
		exit
	fi
}

function create_deprovisioning_script() {
	echo -en " Creating de-provisioning script \r"
	if [ -d ${WALLETPATH} ]; then
		DEPFILE="${WALLETPATH}/deprovision.sh"
		echo 'BLUE="\033[0;34m"' >> ${DEPFILE}
		echo 'PURPLE="\033[0;35m"' >> ${DEPFILE}
		echo 'GREEN="\033[0;32m"' >> ${DEPFILE}
		echo 'RED="\033[0;31m"' >> ${DEPFILE}
		echo 'ITA="\033[3m"' >> ${DEPFILE}
		echo 'NC="\033[0m"' >> ${DEPFILE}
		echo 'SERVICENAME="'$SERVICENAME'"' >> ${DEPFILE}
		echo 'WALLETPATH="'$WALLETPATH'"' >> ${DEPFILE}
		echo 'DATADIRNAME="'$DATADIRNAME'"' >> ${DEPFILE}
		echo 'SCRIPT="'$SCRIPTPATH'"' >> ${DEPFILE}
		echo 'LOGFILE="'$LOGFILE'"' >> ${DEPFILE}
		echo 'DAEMONFILE="'$DAEMONFILE'"' >> ${DEPFILE}

		echo 'clear'  >> ${DEPFILE}
		echo 'cols=$(tput cols)' >> ${DEPFILE}
		echo 'if [ $cols -ge 100 ]; then cols=100; fi' >> ${DEPFILE}
		echo 'mv=$(expr $cols - 11)'  >> ${DEPFILE}
		echo 'STATUS1="\033[${mv}C [${RED} FAILED ${NC}]\n"' >> ${DEPFILE}
		echo 'STATUS0="\033[${mv}C [ ${GREEN} DONE ${NC} ]\n"' >> ${DEPFILE}

		#add warning
		echo 'echo'  >> ${DEPFILE}
		echo 'echo -en "${RED}            !!!     WARNING     !!!\n"' >> ${DEPFILE}
		echo 'echo "    RUNNING THIS SCRIPT WILL KILL MASTERNODE  "' >> ${DEPFILE}
		echo 'echo -en "          AND DELETE ALL RELATED FILES ${NC}\n\n"' >> ${DEPFILE}
		#request run confirmation
		echo 'read -p " Do you confirm de-provisioning of masternode? (type \"yes\" to confirm): " confirmtxt' >> ${DEPFILE}

		echo 'if ! [ "$confirmtxt" = "yes" ]; then'  >> ${DEPFILE}
		echo '	echo " De-provisioning was not confirmed. Exiting..."' >> ${DEPFILE}
		echo '  exit' >> ${DEPFILE}
		echo 'fi' >> ${DEPFILE}
		echo 'sudo ls >/dev/null 2>&1 '>> ${DEPFILE}
		if [ $sysctl -eq 1 ]; then
			# de-provisioning systemd service
			echo 'echo -en " Disabling ${SERVICENAME} \r"' >> ${DEPFILE}
			echo 'sudo systemctl disable ${SERVICENAME} >/dev/null 2>&1' >> ${DEPFILE}
			echo '[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}

			echo 'echo -en " Stopping ${SERVICENAME} \r"' >> ${DEPFILE}
			echo 'sudo systemctl stop ${SERVICENAME} >/dev/null 2>&1' >> ${DEPFILE}
			echo '[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}

			echo 'echo -en " Reloading systemd daemon \r"' >> ${DEPFILE}
			echo 'sudo systemctl daemon-reload >/dev/null 2>&1' >> ${DEPFILE}
			echo '[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}

			echo 'echo -en " Removing service file \r"' >> ${DEPFILE}
			echo 'sudo rm /etc/systemd/system/${SERVICENAME} >/dev/null 2>&1' >> ${DEPFILE}
			echo '[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}
		else
			# de-provision daemon and cron
			echo 'echo -en " Creating new crontab \r"' >> ${DEPFILE}
			echo 'lines=$(crontab -l)' >> ${DEPFILE}
			echo 'if ! [ "$lines" = "" ]; then' >> ${DEPFILE}
			echo '		touch /tmp/tempcron' >> ${DEPFILE}
			echo '		while read -r line; do' >> ${DEPFILE}
			echo '				if ! [[ $line = *"@reboot '${WALLETPATH}'/'${DAEMONNAME}'"* ]]; then' >> ${DEPFILE}
			echo '						printf "%s"  "$line" >>/tmp/tempcron; fi' >> ${DEPFILE}
			echo '		done <<< "$lines"' >> ${DEPFILE}
			echo 'fi' >> ${DEPFILE}
			
			echo '[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}

			echo 'echo -en " Installing new crontab \r"' >> ${DEPFILE}
			echo 'crontab /tmp/tempcron >/dev/null 2>&1' >> ${DEPFILE}
			echo '[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}
			echo 'sudo rm -f /tmp/tempcron >/dev/null 2>&1' >> ${DEPFILE}

			echo 'if [ -f ${HOME}/${DATADIRNAME}/${DAEMONFILE}.pid ]; then' >> ${DEPFILE}
			echo '	pid=$(more ${HOME}/${DATADIRNAME}/${DAEMONFILE}.pid 2>/dev/null)' >> ${DEPFILE}
			echo '	echo -en " Killing daemon process \r"' >> ${DEPFILE}
			echo '	sudo kill -s 9 ${pid} &>/dev/null' >> ${DEPFILE}
			echo '	[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '	sleep 3' >> ${DEPFILE}
			echo '	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}
			echo 'fi' >> ${DEPFILE}
		fi

		# remove daemon and data
			echo 'if [ -f ${LOGFILE} ]; then' >> ${DEPFILE}
			echo '	echo -en " Removing setup log \r"' >> ${DEPFILE}
			echo '	sudo rm ${LOGFILE} >/dev/null 2>&1' >> ${DEPFILE}
			echo '	[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}
			echo 'fi' >> ${DEPFILE}

			echo 'if [ -f ${SCRIPT} ]; then' >> ${DEPFILE}
			echo '	echo -en " Removing setup script \r"' >> ${DEPFILE}
			echo '	sudo rm ${SCRIPT} >/dev/null 2>&1' >> ${DEPFILE}
			echo '	[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}
			echo 'fi' >> ${DEPFILE}

			echo 'if [ -d ${HOME}/${DATADIRNAME} ]; then' >> ${DEPFILE}
			echo '	echo -en " Removing data directory \r"' >> ${DEPFILE}
			echo '	sudo rm -R ${HOME}/${DATADIRNAME} >/dev/null 2>&1' >> ${DEPFILE}
			echo '	[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}
			echo 'fi' >> ${DEPFILE}

			echo 'if [ -d ${WALLETPATH} ]; then' >> ${DEPFILE}
			echo '	echo -en " Removing daemon directory \r"' >> ${DEPFILE}
			echo '	sudo rm -R ${WALLETPATH} >/dev/null 2>&1' >> ${DEPFILE}
			echo '	[ $? -eq 0 ] && ec=0 || ec=1' >> ${DEPFILE}
			echo '	[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1'  >> ${DEPFILE}
			echo 'fi' >> ${DEPFILE}

			if [ $p2pufwadd -eq 1 ]; then 
				echo 'echo && echo -en "We recommend to close p2p tcp port ${PURPLE}${P2PPORT}${NC} in the firewall (if was open) if not in use by other masternode instances.\n"'  >> ${DEPFILE}
				echo 'echo "When sure, perform command below:"' >> ${DEPFILE} 
				if [ "$firewall" = "UFW" ]; then
					echo 'echo -en "${PURPLE}  sudo ufw delete allow '${P2PPORT}'/tcp${NC}\n"' >> ${DEPFILE}
				elif [ "$firewall" = "FirewallD" ]; then
					echo 'echo -en "${PURPLE}  sudo firewall-cmd --zone='${fwdzone}' --remove-port='$P2PPORT'/tcp\n"' >> ${DEPFILE}
					echo 'echo "  sudo firewall-cmd --runtime-to-permanent"' >> ${DEPFILE}
					echo 'echo -en "  sudo firewall-cmd --reload${NC}\n"' >> ${DEPFILE}
				fi
			fi
		echo 'echo && echo "MASTERNODE DE-PROVISIONING FINISHED"' >> ${DEPFILE}
		echo 'cd ${HOME}' >> ${DEPFILE}
		echo -en $STATUS0 

		[ $ec -eq 0 ] && echo "#      De-provisioning script creation: Successful" >>${LOGFILE}
		if [ $newusermn -eq 1 ]; then
			echo -en " Setting de-provisioning script owner \r"
			sudo chown --reference=${WALLETPATH} ${DEPFILE} >>${LOGFILE} 2>&1
			[ $? -eq 0 ] && ec=0 || ec=1
			[ $ec -eq 0 ] && echo -en $STATUS0 || echo -en $STATUS1
			[ $ec -eq 0 ] && echo "#      Changing de-provisioning script owner: Successful" >>${LOGFILE} || echo "#      Changing de-provisioning script owner: FAILED" >>${LOGFILE}
		fi
	else
		echo -en $STATUS1
		echo "#       De-provisioning script creation: FAILED" >>${LOGFILE}
	fi
}

function print_devsupport() {
	echo
	echo " Thank you for using this script. If you found it helpful, you can support developer donating to the address below."
	echo
	echo -en " ${PURPLE}${TICKER}: PU22AgPFdj1PDqWESgEZQot9jj4KjRgzVH${NC}\n"
	echo
	echo -en " Script support server: ${PURPLE}https://discord.gg/dF6JvJf${NC}\n"
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
	minswapmb=1024
	sshport=22
	newsudouser=0
	sudowopass=0
	newusermn=0
	loadonboot=0
	easynode=0
	sysctl=0
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
	ITA="\033[3m"
	NC="\033[0m"
	portlist=()

# main procedure
SCRIPTPATH=$(readlink -f $0)
cols=$(tput cols)
if [ $cols -ge 100 ]; then cols=100; fi
mv=$(expr $cols - 11)
STATUSX="\033[${mv}C "
STATUS1="\033[${mv}C [${RED} FAILED ${NC}]\n"   #[ FAILED ]
STATUS0="\033[${mv}C [ ${GREEN} DONE ${NC} ]\n" #[  DONE  ]
cd ~
USER=$(whoami)               					#current user
HOME=$(pwd)                  					#home directory
LOGFILE=$HOME"/"$LOGFILENAME 					#create log full path
WALLETPATH=/usr/local/bin/${WALLETDIR}-${USER}
detect_osversion             					#run OS version detection
echo >${LOGFILE}             					#clear log file
echo "Script version: ${VERSION}" >>${LOGFILE}
echo "OS detected: ${osver}" >>${LOGFILE}

print_welcome                                #print welcome frame
echo "Detected OS: ${OSNAME} ${OSVERSION}"   #print OS version
echo "Running script using account: ${USER}" #print user account
echo "Current user home directory: ${HOME}"  #print user home dir
echo "Installation log file: "$LOGFILE       #path to log
echo
check_os_support
run_pre_checks    
if ! [ -f $SCRIPTPATH.ho ]; then
	set_default_answers 
	echo
	echo "───────────────────────────────"
	echo "      STARTING NODE SETUP      "
	echo "───────────────────────────────"
	echo
	if [ $createswap -eq 1 ]; then create_swap; fi
	if [ $sysupdate -eq 1 ]; then system_update; fi
	if [ $setupfail2ban -eq 1 ]; then setup_fail2ban; fi
	if [ $setupufw -ge 1 ]; then setup_fw; fi
	if [ $createuser -eq 1 ]; then create_user; fi
else
	echo
	echo " Script detected parameter handover file."
	conttxt=""
	echo -en "\033[s"
	while ! [[ "$conttxt" =~ ^[yYnN]+$ ]]; do
	echo -en "\033[u"
		read -n1 -p "  Do you want to continue setup? [Y/n]:" conttxt
		echo -en "\r"
	done
	echo
	if [[ "$conttxt" =~ ^[yY]+$ ]]; then
		. $SCRIPTPATH.ho

		echo
		echo "───────────────────────────────"
		echo "     CONTINUING NODE SETUP     "
		echo "───────────────────────────────"
	else
		sudo rm $SCRIPTPATH.ho &>>${LOGFILE}
		echo
		echo " Parameter handover file was deleted."
		echo " Please run the script again to start new installation."
		exit 0
	fi
fi
if [ $setupwallet -eq 1 ]; then setup_wallet; fi
if [ $easynode -eq 1 ]; then setup_easynode; fi
if [ $setupmn -eq 1 ]; then configure_masternode; fi
echo
if [ -f $SCRIPTPATH.ho ]; then sudo rm $SCRIPTPATH.ho; fi
echo "───────────────────────────────"
echo "       NODE SETUP FINISHED     "
echo "───────────────────────────────"
echo
print_result
echo
print_devsupport
