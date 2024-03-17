#!/data/data/com.termux/files/usr/bin/env bash

pkg update -y && pkg upgrade -y

red="\e[0;31m"   # Red
green="\e[0;32m" # Green
nocol="\033[0m"  # Default

_pkgs=(bc bmon calc calcurse cpufetch curl dbus desktop-file-utils elinks fastfetch \
	feh figlet fontconfig-utils fsmon geany git gtk2 gtk3 htop imagemagick jq leafpad \
	lf man micro mpc mpd mutt ncmpcpp ncurses-utils neofetch netsurf obconf openbox \
	openssl-tool polybar python ranger rofi startup-notification termux-api \
	termux-x11-nightly thunar tigervnc toilet vim wget xarchiver xbitmaps xcompmgr \
	xfce4-settings xfce4-terminal xmlstarlet xorg-font-util xorg-xrdb zsh)

setup_base() {
	echo -e ${RED}"\n[*] Installing Termux Desktop..."
	echo -e ${CYAN}"\n[*] Updating Termux Base... \n"
	{ reset_color; pkg autoclean; pkg update -y; pkg upgrade -y; }
	echo -e ${CYAN}"\n[*] Enabling Termux X11-repo... \n"
	{ reset_color; pkg install -y x11-repo; }
	echo -e ${CYAN}"\n[*] Installing required programs... \n"
	for package in "${_pkgs[@]}"; do
		{ reset_color; pkg install -y "$package"; }
		_ipkg=$(pkg list-installed $package 2>/dev/null | tail -n 1)
		_checkpkg=${_ipkg%/*}
		if [[ "$_checkpkg" == "$package" ]]; then
			echo -e ${GREEN}"\n[*] Package $package installed successfully.\n"
			continue
		else
			echo -e ${MAGENTA}"\n[!] Error installing $package, Terminating...\n"
			{ reset_color; exit 1; }
		fi
	done
	reset_color

	file="$HOME/.local/bin/startssh"
	if [[ -f "$file" ]]; then
		rm -rf "$file"
	fi
	echo -e ${RED}"\n[*] Creating OpenSSH Script... \n"
	{ reset_color; touch $file; chmod +x $file; }
	cat > $file <<- _EOF_
		#!/data/data/com.termux/files/usr/bin/bash

		# Start SSH Server
		if [[ \$(pidof sshd) ]]; then
		    echo -e "\\n[!] Server Already Running."
		    { pgrep sshd; echo; }
		    read -p "Kill SSH Server? (Y/N) : "
		    if [[ "\$REPLY" == "Y" || "\$REPLY" == "y" ]]; then
		        { killall sshd; echo; }
		    else
		        echo
		    fi
		else
		    echo -e "\\n[*] Starting SSH Server..."
		    sshd
		fi
	_EOF_
	if [[ -f "$file" ]]; then
		echo -e ${GREEN}"[*] Script ${ORANGE}$file ${GREEN}created successfully."
	fi
}

install_desktop() {
	git clone --depth=1 https://github.com/adi1090x/termux-desktop.git
	cd termux-desktop
	chmod +x setup.sh
	./setup.sh --install
	cd ..
}

configure_termux() {
	# Set motd
	echo -e "${green}Set motd banner text: ${nocol}"
	read -p "" -r motd
	echo "" # For newline
	sed -i 's/Termux/${motd}' ~/MyTermuxConfig/Termux/motd.sh
	echo -e "${green}Configuring termux ...${nocol}"
	rm -rf "${HOME}/.termux"
	cp -r Termux "${HOME}/.termux"
	chmod +x "${HOME}/.termux/fonts.sh" "${HOME}/.termux/colors.sh"
	echo -e "${green}Setting IrBlack as default color scheme ...${nocol}"
	ln -fs "${HOME}/.termux/colors/dark/IrBlack" "${HOME}/.termux/colors.properties"
	mv "${PREFIX}/etc/motd" "${PREFIX}/etc/motd.bak"
	mv "${PREFIX}/etc/motd.sh" "${PREFIX}/etc/motd.sh.bak"
	mv "${HOME}/.termux/motd.sh" "${PREFIX}/etc/motd.sh"
	ln -sf "${PREFIX}/etc/motd.sh" "${HOME}/.termux/motd.sh"
}

install_ohmyzsh() {
	echo -e "${green}Installing Oh-My-Zsh ...${nocol}"
	git clone https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
	echo -e "${green}Installing powerlevel10k theme ...${nocol}"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"/themes/powerlevel10k
	echo -e "${green}Installing custom plugins ...${nocol}"
	git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
	echo -e "${green}Configuring Oh-My-Zsh ...${nocol}"
	cp -f OhMyZsh/zshrc "${HOME}/.zshrc"
	if [[ "$(dpkg --print-architecture)" == "arm" ]]; then
		echo -e "Armv7 device detected${red}!${nocol} Gitstatus disabled${red}!${nocol}"
		# There's no binaries of gitstatus for armv7 right now so disable it
		echo -e "\n# Disable gitstatus for now (Only for armv7 devices)\nPOWERLEVEL9K_DISABLE_GITSTATUS=true\n" >> "${HOME}/.zshrc"
	fi
	chmod +rwx "${HOME}/.zshrc"
	if [[ -f "OhMyZsh/zsh_history" ]]; then
		echo -e "${green}Installing zsh history file ...${nocol}"
		cp -f OhMyZsh/zsh_history "${HOME}/.zsh_history"
		chmod +rw "${HOME}/.zsh_history"
	fi
	if [[ -f "OhMyZsh/custom_aliases.zsh" ]]; then
		echo -e "${green}Installing custom aliases ...${nocol}"
		cp -f OhMyZsh/custom_aliases.zsh "${HOME}/.oh-my-zsh/custom/custom_aliases.zsh"
	fi
	echo -e "${green}Configuring powerlevel10k theme ...${nocol}"
	cp -f OhMyZsh/p10k.zsh "${HOME}/.p10k.zsh"
	echo -e "${green}Oh-My-Zsh installed!${nocol}"
	# Create config directory if it doesn't exist
	mkdir -p "${HOME}/.config"
	# Configure lf file manager
	cp -fr lf "${HOME}/.config/lf"
	# Remove gitstatusd from cache if arm
	if [[ "$(dpkg --print-architecture)" == "arm" ]]; then
		rm -rf "${HOME}/.cache/gitstatus"
	fi
	echo -e "${green}Setting zsh as default shell ...${nocol}"
	chsh -s zsh
}

finish_install() {
	pip install -r ./modules.txt
	clear

	# Set password
	echo -e "${green}Set you're password: ${nocol}"
	passwd

	# Setup Complete
	termux-reload-settings
	echo -e "${green}Setup Completed!${nocol}"
	echo -e "${green}Please restart Termux!${nocol}"
}

# Start installation
echo -e "${green}Start installation? [Y/n]${nocol}"
read -p "" -n 1 -r yn
echo "" # For newline
case ${yn} in
	[Yy]*)
		setup_base       #desktop
		install_desktop  #desktop
		configure_termux #zsh
		install_ohmyzsh  #zsh
		finish_install   #zsh
		exit 0
		;;
	[Nn]*)
		echo -e "${red}Installation aborted!${nocol}"
		exit 1
		;;
esac

# Error msg for invalid choice
echo -e "${red}Invalid choice!${nocol}"
echo ""
cd ..

# TODO custom tools
chmod +x ./tools/