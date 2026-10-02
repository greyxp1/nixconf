{
  environment.etc."modules-load.d/uinput.conf".text = "uinput\nuhid\n";
  environment.etc."udev/rules.d/85-sunshine-input.rules".text = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uinput"
    KERNEL=="uhid", SUBSYSTEM=="misc", MODE="0660", GROUP="input", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uhid"
  '';
}
