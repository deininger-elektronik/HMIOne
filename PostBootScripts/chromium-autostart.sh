#!/bin/dash
#/var/lib/dietpi/dietpi-software/installed/chromium-autostart.sh

# Autostart script for kiosk mode, based on @AYapejian: https://github.com/MichaIng/DietPi/issues/1737#issue-318697621
# Resolution to use for kiosk mode, should ideally match current system resolution
RES_X=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_X=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)
RES_Y=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_Y=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)

# Command line switches: https://peter.sh/experiments/chromium-command-line-switches/
# - Review and add custom flags in: /etc/chromium.d
CHROMIUM_OPTS="--kiosk --window-size=${RES_X:-1280},${RES_Y:-720} --window-position=0,0 \
--disable-pinch \
--overscroll-history-navigation=0 \
--disable-pull-to-refresh-effect \
--disable-infobars \
--noerrdialogs \
--incognito \
--disable-touch-adjustment \
--disable-session-crashed-bubble \
--disable-restore-session-state \
--disable-features=AutofillAddressSurvey,AutofillCreditCardSurvey,InterestFeedContentSuggestions,DesktopInProductHelp,TabletMode,TabletUI,TouchpadOverscrollHistoryNavigation,OverscrollHistoryNavigation,TouchscreenGestureNavigation \
--disable-sync-preferences \
--disable-component-update \
--disable-background-networking \
--disable-sync \
--disable-translate \
--disable-crash-reporter \
--no-first-run \
--disable-restore-session-state \
--hide-scrollbars"

# If you want tablet mode, uncomment the next line.
#CHROMIUM_OPTS="$CHROMIUM_OPTS --force-tablet-mode --tablet-ui"

# Home page
URL=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_AUTOSTART_URL=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)

# RPi or Debian Chromium package
FP_CHROMIUM=$(command -v chromium-browser)
[ "$FP_CHROMIUM" ] || FP_CHROMIUM=$(command -v chromium)

# Use "startx" as non-root user to get required permissions via systemd-logind
STARTX='xinit'
[ "$USER" = 'root' ] || STARTX='startx'

exec "$STARTX" "$FP_CHROMIUM" $CHROMIUM_OPTS "${URL:-https://dietpi.com/}" > /dev/null 2>&1