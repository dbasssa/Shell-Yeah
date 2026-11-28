#!/bin/bash
/usr/lib/pam_kwallet_init &
/usr/lib/xfce-polkit/xfce-polkit >polkit-log &
openrgb -c f90091 &
qs &
