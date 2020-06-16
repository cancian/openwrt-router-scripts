. /etc/profile.d/colors.inc
export EDITOR=nano
export PATH="${PATH}:/opt/bin:/opt/sbin"

if [ -f /opt/etc/profile ]; then 
  export TERMINFO=/opt/share/terminfo
  export TERM=xterm
  export TMP=/opt/tmp
  export TEMP=/opt/tmp
  unset LD_PRELOAD
  unset LD_LIBRARY_PATH

  # You may define localization
  export LANG='en_US.UTF-8'
  export LC_ALL='en_US.UTF-8'
fi

[ -f /root/bin/sysinfo ] && /root/bin/sysinfo

setpromt() {
  FancyX="\342\234\227"
  Checkmark="\342\234\223"
  Last_Command="\$(if [ \$? -eq 0 ]; then echo \"${green}[$Checkmark]\"; else echo \"${red}[$FancyX]\"; fi)${reset}"
  if [ $(id -u) = 0 ]; then
    usershell='#'
    usercolor="${red}"
  else
    usershell='$'
    usercolor="${blue}"
  fi
  #PS1=",-${Last_Command}-${yellow}[${cyan}\t${yellow}]${reset}-${yellow}[${usercolor}\u@\h${yellow}]${reset}-${green}[\w\] ${reset}${usershell}\n'-> "
}

#[ ! -f /usr/bin/dmesg ] || [ ! -f /opt/bin/dmesg ] && alias dmesg='/usr/sbin/dmesgh'

setpromt
