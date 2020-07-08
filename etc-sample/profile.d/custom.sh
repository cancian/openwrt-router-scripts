. /etc/profile.d/colors.inc

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

setpromt
