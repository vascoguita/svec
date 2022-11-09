// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: LGPL-2.1-or-later
// Author: Federico Vaga <federico.vaga@cern.ch>

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <getopt.h>
#include <libgen.h>
#include <errno.h>
#include <inttypes.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <linux/svec.h>
#include <svec-core-fpga.h>


static const char git_version[] = "git version: " GIT_VERSION;
static char *name;
static bool singleline = false;
static unsigned int verbose;

static void help(void)
{
	fprintf(stderr, "%s [options]\n"
		"\tPrint the firmware version\n"
		"\t-s <VME slot>\n"
		"\t-b  print svec-base\n"
		"\t-a  print svec-application\n"
		"\t-B  print FPGA build information\n"
		"\t-1  print on a single line\n"
		"\t-V  print version\n"
		"\t-h  print help\n",
		name);
}

static void print_version(void)
{
	printf("%s version %s\n", name, git_version);
}

static void cleanup(void)
{
	if (name)
		free(name);
}

static const char *bom_to_str(uint32_t bom)
{
	if ((bom & SVEC_META_BOM_END_MASK) == SVEC_META_BOM_BE)
		return "little-endian";
	else
		return "wrong";
}

static void print_meta_id_one(struct svec_meta_id *rom)
{
	fprintf(stdout, "0x%08x,0x%08x,%u.%u.%u",
		rom->vendor,
		rom->device,
		SVEC_META_VERSION_MAJ(rom->version),
		SVEC_META_VERSION_MIN(rom->version),
		SVEC_META_VERSION_PATCH(rom->version));
	if (verbose > 0) {
		fprintf(stdout, "%08x,%08x,%08x%08x%08x%08x,%08x%08x%08x%08x",
			rom->cap, rom->bom,
			rom->src[0], rom->src[1], rom->src[2], rom->src[3],
			rom->uuid[0], rom->uuid[1], rom->uuid[2], rom->uuid[3]);
	}
	fputc('\n', stdout);
}

static void print_meta_vendor(uint32_t vendor)
{
	switch(vendor) {
	case SVEC_META_VENDOR_ID:
		fputs("CERN", stdout);
		break;
	default:
		fprintf(stdout, "unknown (0x%08"PRIx32")", vendor);
		break;
	}
}

static void print_meta_device(uint32_t device)
{
	switch(device) {
	case SVEC_META_DEVICE_ID:
		fputs("svec-base", stdout);
		break;
	default:
		fprintf(stdout, "unknown (0x%08"PRIx32")", device);
		break;
	}
}

static const char *capability[] = {
	"vic",
	"thermometer",
	"spi",
	"white-rabbit",
	"build-info",
	"dma-engine",
};

static void print_meta_capabilities(uint32_t cap)
{
	bool has_cap = false;
	int i;

	for (i = 0; i < 32; ++i) {
		if (i < 6) { /* known bits */
			if (cap & BIT(i)) {
				fputs(capability[i], stdout);
				fputs(", ", stdout);
				has_cap = true;
			}
		} else {
			if (cap & BIT(i))
				fprintf(stdout, "unknown BIT(%d), ", i);
		}
	}
	if (has_cap)
		fputs("\b\b  ", stdout);
}

#define SVEC_BASE_REGS_BUILDINFO 0x200UL
#define SVEC_BASE_REGS_BUILDINFO_SIZE 256
static int print_build_info(int fd)
{
	void *bld;
	int off;

	bld = mmap(NULL, SVEC_BASE_REGS_BUILDINFO + SVEC_BASE_REGS_BUILDINFO_SIZE,
		   PROT_READ, MAP_SHARED, fd, 0);
	if ((long)bld == -1) {
		fputs("Failed while reading SVEC-BASE FPGA BUILD INFO\n",
		      stderr);
		return -1;
	}

        fputs("build-info : \n  ", stdout);
	for (off = SVEC_BASE_REGS_BUILDINFO;
	     off < SVEC_BASE_REGS_BUILDINFO + SVEC_BASE_REGS_BUILDINFO_SIZE - 1;
	     off += 4) {
		uint32_t tmp = *((uint32_t *)(bld + off));
		int k;

		tmp = __builtin_bswap32(tmp);
		for (k = 0; k < 4; ++k) {
			char c = ((char *)&tmp)[k];

			if (!c)
				goto out;
			fputc(c, stdout);
			if (c == '\n')
				fputs("  ", stdout);
		}
	}
out:
	fputc('\n', stdout);
	munmap(bld, SVEC_BASE_REGS_BUILDINFO + SVEC_BASE_REGS_BUILDINFO_SIZE);
	return 0;
}

static void print_meta_id(struct svec_meta_id *rom)
{
	fputc('\n', stdout);

        fprintf(stdout, "  vendor       : ");
	print_meta_vendor(__builtin_bswap32(rom->vendor));
	fputc('\n', stdout);

        fprintf(stdout, "  device       : ");
        print_meta_device(__builtin_bswap32(rom->device));
	fputc('\n', stdout);

        fprintf(stdout, "  version      : %u.%u.%u\n",
		SVEC_META_VERSION_MAJ(__builtin_bswap32(rom->version)),
		SVEC_META_VERSION_MIN(__builtin_bswap32(rom->version)),
		SVEC_META_VERSION_PATCH(__builtin_bswap32(rom->version)));

        fprintf(stdout, "  capabilities : ");
	print_meta_capabilities(__builtin_bswap32(rom->cap));
	fputc('\n', stdout);

        if (verbose > 0) {
		fprintf(stdout, "  byte-order   : %s\n",
			bom_to_str(__builtin_bswap32(rom->bom)));
		fprintf(stdout, "  sources      : %08x%08x%08x%08x\n",
			__builtin_bswap32(rom->src[0]),
			__builtin_bswap32(rom->src[1]),
			__builtin_bswap32(rom->src[2]),
			__builtin_bswap32(rom->src[3]));
		fprintf(stdout, "  UUID         : %08x%08x%08x%08x\n",
			__builtin_bswap32(rom->uuid[0]),
			__builtin_bswap32(rom->uuid[1]),
			__builtin_bswap32(rom->uuid[2]),
			__builtin_bswap32(rom->uuid[3]));
	}
}

static int print_base_meta_id(int fd)
{
	struct svec_meta_id *rom;

	rom = mmap(NULL, sizeof(*rom), PROT_READ, MAP_SHARED, fd,
		   SVEC_BASE_REGS_METADATA);
	if ((long)rom == -1) {
		fputs("Failed while reading SVEC-BASE FPGA ROM\n", stderr);
		return -1;
	}
	fputs("base: ", stdout);
	if (singleline)
		print_meta_id_one(rom);
	else
		print_meta_id(rom);
	munmap(rom, sizeof(*rom));

        return 0;
}

static off_t app_meta_id_offset(int fd)
{
	off_t offset;
	void *regs;

	regs = mmap(NULL, 0x100, PROT_READ, MAP_SHARED, fd, 0);
	if ((long)regs == -1)
		return -1;
	offset = *((uint32_t *)((char *)regs + SVEC_BASE_REGS_CSR_APP_OFFSET));
	munmap(regs, 0x100);

	return offset;
}

static int print_app_meta_id(int fd)
{
	struct svec_meta_id *rom;
	off_t offset;

	offset = app_meta_id_offset(fd);
	if (offset < 0) {
		fputs("Can't get svec-app offset\n", stderr);
		return -1;
	}

	if (offset == 0) {
		fputs("svec-application:\n  None\n", stderr);
		return 0;
	}
	rom = mmap(NULL, sizeof(*rom), PROT_READ, MAP_SHARED, fd, offset);
	if ((long)rom == -1) {
		fputs("Failed while reading SVEC-APP FPGA ROM\n", stderr);
		return -1;
	}
	fputs("application: ", stdout);
	if (singleline)
		print_meta_id_one(rom);
	else
		print_meta_id(rom);
	munmap(rom, sizeof(*rom));

        return 0;
}

int main(int argc, char *argv[])
{
	bool base = false, app = false, buildinfo = false;
	int err;
	int fd;
	int slot =  0;
	char path[128];
	char opt;

        name = strndup(basename(argv[0]), 64);
	if (!name)
		exit(EXIT_FAILURE);
	err = atexit(cleanup);
	if (err)
		exit(EXIT_FAILURE);

        while ((opt = getopt(argc, argv, "h?Vvs:ba1B")) != -1) {
		switch (opt) {
		case 'h':
		case '?':
			help();
			exit(EXIT_SUCCESS);
		case 'V':
			print_version();
			exit(EXIT_SUCCESS);
		case 's':
			sscanf(optarg, "%d", &slot);
			break;
		case 'a':
			app = true;
			break;
		case 'b':
			base = true;
			break;
		case 'v':
			verbose++;
			break;
		case '1':
			singleline = true;
			break;
		case 'B':
			buildinfo = true;
			break;
		}
	}
	if (!slot) {
		fputs("VME slot is mandatory\n", stderr);
		help();
		exit(EXIT_FAILURE);
	}
	snprintf(path, 128, "/sys/bus/vme/devices/slot.%02d/vme.%d/resource%d",
		 slot, slot, SVEC_FUNC_NR);
	fd = open(path, O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "Can't open \"%s\": %s\n",
			path, strerror(errno));
		exit(EXIT_FAILURE);
	}
	if (base)
		err = print_base_meta_id(fd);
	if (app)
		err = print_app_meta_id(fd);
	if (buildinfo)
		err = print_build_info(fd);
	close(fd);

	exit(err ? EXIT_FAILURE : EXIT_SUCCESS);

 }
