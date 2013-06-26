ifeq "$(profile)" "1"
CFLAGS += -fprofile-generate
endif
ifeq "$(profile)" "2"
CFLAGS += -fprofile-use
endif
ifeq "$(pdb)" "1"
DEFINES += PDB
OBJS += cpu/debug.o
 ifeq "$(pdb_net)" "1"
 DEFINES += PDB_NET
 endif
 ifeq "$(readline)" "1"
 DEFINES += HAVE_READLINE
 LDFLAGS += -lreadline
 endif
endif
ifeq "$(pprof)" "1"
DEFINES += PPROF
OBJS += platform/linux/pprof.o
endif

# asm stuff
ifeq "$(asm_render)" "1"
DEFINES += _ASM_DRAW_C
OBJS += pico/draw_arm.o pico/draw2_arm.o
endif
ifeq "$(asm_memory)" "1"
DEFINES += _ASM_MEMORY_C
OBJS += pico/memory_arm.o
endif
ifeq "$(asm_ym2612)" "1"
DEFINES += _ASM_YM2612_C
OBJS += pico/sound/ym2612_arm.o
endif
ifeq "$(asm_misc)" "1"
DEFINES += _ASM_MISC_C
OBJS += pico/misc_arm.o
OBJS += pico/cd/misc_arm.o
endif
ifeq "$(asm_cdpico)" "1"
DEFINES += _ASM_CD_PICO_C
OBJS += pico/cd/pico_arm.o
endif
ifeq "$(asm_cdmemory)" "1"
DEFINES += _ASM_CD_MEMORY_C
OBJS += pico/cd/memory_arm.o
endif
ifeq "$(asm_32xdraw)" "1"
DEFINES += _ASM_32X_DRAW
OBJS += pico/32x/draw_arm.o
endif

# === Pico core ===
# Pico
OBJS += pico/state.o pico/cart.o pico/memory.o pico/pico.o pico/sek.o pico/z80if.o \
	pico/videoport.o pico/draw2.o pico/draw.o pico/mode4.o \
	pico/misc.o pico/eeprom.o pico/patch.o pico/debug.o \
	pico/media.o
# SMS
ifneq "$(no_sms)" "1"
OBJS += pico/sms.o
else
DEFINES += NO_SMS
endif
# CD
OBJS += pico/cd/pico.o pico/cd/memory.o pico/cd/sek.o pico/cd/LC89510.o \
	pico/cd/cd_sys.o pico/cd/cd_file.o pico/cd/cue.o pico/cd/gfx_cd.o \
	pico/cd/misc.o pico/cd/pcm.o pico/cd/buffering.o
# 32X
ifneq "$(no_32x)" "1"
OBJS += pico/32x/32x.o pico/32x/memory.o pico/32x/draw.o pico/32x/pwm.o
else
DEFINES += NO_32X
endif
# Pico
OBJS += pico/pico/pico.o pico/pico/memory.o pico/pico/xpcm.o
# carthw
OBJS += pico/carthw/carthw.o
# SVP
OBJS += pico/carthw/svp/svp.o pico/carthw/svp/memory.o \
	pico/carthw/svp/ssp16.o
ifeq "$(ARCH)" "arm"
OBJS += pico/carthw/svp/stub_arm.o
OBJS += pico/carthw/svp/compiler.o
endif
# sound
OBJS += pico/sound/sound.o
OBJS += pico/sound/sn76496.o pico/sound/ym2612.o
ifeq "$(ARCH)" "arm"
OBJS += pico/sound/mix_arm.o
else
OBJS += pico/sound/mix.o
endif

# === CPU cores ===
# --- M68k ---
ifeq "$(use_musashi)" "1"
DEFINES += EMU_M68K
OBJS += cpu/musashi/m68kops.o cpu/musashi/m68kcpu.o
#OBJS += cpu/musashi/m68kdasm.o
endif
ifeq "$(use_cyclone)" "1"
DEFINES += EMU_C68K
OBJS += pico/m68kif_cyclone.o cpu/cyclone/Cyclone.o cpu/cyclone/tools/idle.o
endif
ifeq "$(use_fame)" "1"
DEFINES += EMU_F68K
OBJS += cpu/fame/famec.o
endif

# --- Z80 ---
ifeq "$(use_drz80)" "1"
DEFINES += _USE_DRZ80
OBJS += cpu/DrZ80/drz80.o
endif
#
ifeq "$(use_cz80)" "1"
DEFINES += _USE_CZ80
OBJS += cpu/cz80/cz80.o
endif

# --- SH2 ---
OBJS += cpu/drc/cmn.o
ifneq "$(no_32x)" "1"
OBJS += cpu/sh2/sh2.o
#
ifeq "$(use_sh2drc)" "1"
DEFINES += DRC_SH2
OBJS += cpu/sh2/compiler.o
ifdef drc_debug
DEFINES += DRC_DEBUG=$(drc_debug)
OBJS += cpu/sh2/mame/sh2dasm.o
OBJS += platform/linux/host_dasm.o
LDFLAGS += -lbfd -lopcodes -liberty
endif
ifeq "$(drc_debug_interp)" "1"
DEFINES += DRC_DEBUG_INTERP
use_sh2mame = 1
endif
endif # use_sh2drc
#
ifeq "$(use_sh2mame)" "1"
OBJS += cpu/sh2/mame/sh2pico.o
endif
endif # !no_32x

CFLAGS += $(addprefix -D,$(DEFINES))

# common rules
.s.o:
	@echo ">>>" $<
	$(CC) $(CFLAGS) -c $< -o $@

tools/textfilter: tools/textfilter.c
	make -C tools/ textfilter


# random deps
pico/carthw/svp/compiler.o : cpu/drc/emit_$(ARCH).c
cpu/sh2/compiler.o : cpu/drc/emit_$(ARCH).c
cpu/sh2/mame/sh2pico.o : cpu/sh2/mame/sh2.c
pico/pico.o pico/cd/pico.o : pico/pico_cmn.c pico/pico_int.h
pico/memory.o pico/cd/memory.o : pico/pico_int.h pico/memory.h

cpu/musashi/m68kops.c :
	@make -C cpu/musashi

cpu/fame/famec.o : cpu/fame/famec.c cpu/fame/famec_opcodes.h
	@echo ">>>" $<
	$(CC) $(CFLAGS) -Wno-unused -c $< -o $@

cpu/cyclone/Cyclone.s:
	@echo building Cyclone...
	@make -C cpu/cyclone CONFIG_FILE='\"../cyclone_config.h\"'

