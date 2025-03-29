#   Copyright (C) 2025 John Törnblom
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING. If not see
# <http://www.gnu.org/licenses/>.


DISC_LABEL := etaHEN-BDJ-IPV6

ifndef BDJSDK_HOME
    $(error BDJSDK_HOME is undefined)
endif

#
# Host tools
#
BDSIGNER     := $(BDJSDK_HOME)/host/bin/bdsigner
MAKEFS       := $(BDJSDK_HOME)/host/bin/makefs
JAVA8_HOME   ?= $(BDJSDK_HOME)/host/jdk8
JAVA11_HOME  ?= $(BDJSDK_HOME)/host/jdk11
JAVAC        := $(JAVA11_HOME)/bin/javac
JAR          := $(JAVA11_HOME)/bin/jar

export JAVA8_HOME
export JAVA11_HOME

#
# Compilation artifacts
#
CLASSPATH := $(BDJSDK_HOME)/target/lib/enhanced-stubs.zip:$(BDJSDK_HOME)/target/lib/sony-stubs.jar
SOURCES   := $(wildcard src/org/homebrew/*.java)
JFLAGS    := -Xlint:-options

ITEMZFLOW_URL := https://pkg-zone.com/download/ps5/ITEM00001/latest
PS5_EXPLORER_URL := https://pkg-zone.com/download/ps5/LAPY20011/latest
PS5_TEMP_URL := https://pkg-zone.com/download/ps5/LAPY20012/latest
AVATAR_CHANGER_URL := https://pkg-zone.com/download/ps5/LAPY20016/latest
PS5_SPOOFER := https://github.com/MagicStuffCL/ps5Spoofer/releases/download/Ps5Spoofer2.xx-7.xx/ps5spoofer.zip
ELFLDR_URL := https://github.com/ps5-payload-dev/elfldr/releases/latest/download/Payload.zip
ETAHEN_URL :=  https://github.com/etaHEN/etaHEN/releases/download/2.0b/etaHEN-2.0b.bin

#
# Disc files
#
TMPL_DIRS  := $(shell find $(BDJSDK_HOME)/resources/AVCHD/ -type d)
TMPL_FILES := $(shell find $(BDJSDK_HOME)/resources/AVCHD/ -type f)

DISC_DIRS  := $(patsubst $(BDJSDK_HOME)/resources/AVCHD%,discdir%,$(TMPL_DIRS)) \
              discdir/BDMV/JAR
DISC_FILES := $(patsubst $(BDJSDK_HOME)/resources/AVCHD%,discdir%,$(TMPL_FILES)) \
              discdir/BDMV/JAR/00000.jar discdir/elfldr.elf discdir/etaHEN.elf discdir/spoofer.elf discdir/PS5_ITEM00001_LATEST.pkg discdir/PS5_LAPY20011_LATEST.pkg discdir/PS5_LAPY20012_LATEST.pkg discdir/PS5_LAPY20016_LATEST.pkg

all: $(DISC_LABEL).iso

discdir:
	mkdir -p $(DISC_DIRS)

discdir/PS5_LAPY20011_LATEST.pkg:
	mkdir -p discdir
	wget -qO discdir/PS5_LAPY20011_LATEST.pkg $(PS5_EXPLORER_URL)

discdir/PS5_LAPY20012_LATEST.pkg:
	mkdir -p discdir
	wget -qO discdir/PS5_LAPY20012_LATEST.pkg $(PS5_TEMP_URL)

discdir/PS5_LAPY20016_LATEST.pkg:
	mkdir -p discdir
	wget -qO discdir/PS5_LAPY20016_LATEST.pkg $(AVATAR_CHANGER_URL)

discdir/PS5_ITEM00001_LATEST.pkg:
	mkdir -p discdir
	wget -qO discdir/PS5_ITEM00001_LATEST.pkg $(ITEMZFLOW_URL)

discdir/spoofer.elf:
	wget -qO- $(PS5_SPOOFER) | gunzip -c - > $@

discdir/elfldr.elf:
	wget -qO- $(ELFLDR_URL) | gunzip -c - > $@

discdir/etaHEN.elf:
	mkdir -p discdir
	wget -qO discdir/etaHEN.elf $(ETAHEN_URL)

discdir/BDMV/JAR/00000.jar: discdir $(SOURCES)
	$(JAVAC) $(JFLAGS) -cp $(CLASSPATH) $(SOURCES)
	$(JAR) cf $@ -C src/ .
	$(BDSIGNER) -keystore $(BDJSDK_HOME)/resources/sig.ks $@

discdir/%: discdir
	cp $(BDJSDK_HOME)/resources/AVCHD/$* $@

$(DISC_LABEL).iso: $(DISC_FILES)
	$(MAKEFS) -m 128m -t udf -o T=bdre,v=2.50,L=$(DISC_LABEL) $@ discdir

clean:
	rm -rf META-INF $(DISC_LABEL).iso discdir src/org/homebrew/*.class

