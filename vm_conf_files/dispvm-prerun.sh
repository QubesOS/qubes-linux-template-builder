#!/bin/sh

apps="evince okular openoffice gwenview firefox"

for app in $apps ; do
    echo "Launching: $app..."
    $app >/tmp/dispvm_prerun_errors.log 2>&1 &
done

echo "Sleeping..."
sleep 120

ps ax > /tmp/dispvm-prerun-proclist.log

cat /etc/dispvm-dotfiles.tbz | tar -xjf- --overwrite -C /home/user --owner user 2>&1 >/tmp/dispvm-dotfiles-errors.log

echo done.

