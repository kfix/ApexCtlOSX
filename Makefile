#!/bin/make -f

all: clean apexctl

apexctl:
	gcc -Wall $@.m -o $@ -lobjc -framework Cocoa -framework IOKit

install: apexctl
	install apexctl /usr/local/bin
	install com.kidfixit.apexctl.plist ~/Library/LaunchAgents/
	launchctl load ~/Library/LaunchAgents/com.kidfixit.apexctl.plist
	launchctl start com.kidfixit.apexctl

clean:
	rm apexctl

.PHONY: all clean install
