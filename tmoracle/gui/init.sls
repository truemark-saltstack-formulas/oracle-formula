# Due to the bug at https://github.com/saltstack/salt/issues/38841 we cannot use pkg.group_installed
# You can use the yum groupinfo

GUI:
  pkg.installed:
    - pkgs:
# yum group info "X Window System"
        - glx-utils
        - initial-setup-gui
        - mesa-dri-drivers
        - plymouth-system-theme
        - spice-vdagent
        - xorg-x11-drivers
        - xorg-x11-server-Xorg
        - xorg-x11-utils
        - xorg-x11-xauth
        - xorg-x11-xinit
        - xvattr
# yum groupinfo Xfce
        - Thunar
        - xfce4-panel
        - xfce4-session
        - xfce4-settings
        - xfconf
        - xfdesktop
        - xfwm4
        - xfce4-terminal
# VNC
        - tigervnc-server

/etc/sysconfig/desktop:
  file.managed:
    - source: salt://tmoracle/gui/files/desktop
    - user: root
    - group: root
    - mode: 644
