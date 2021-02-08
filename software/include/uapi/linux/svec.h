// Copyright (C) 2020 CERN (www.cern.ch)
// SPDX-FileCopyrightText: 2020 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later
// Author: Federico Vaga <federico.vaga@cern.ch>

#ifndef __LINUX_UAPI_SVEC_H
#define __LINUX_UAPI_SVEC_H
#ifndef __KERNEL__
#include <stdint.h>
#endif

#define SVEC_FMC_SLOTS 2
#define SVEC_FUNC_NR 1

#define PCI_VENDOR_ID_CERN      (0x10DC)

#define SVEC_META_VENDOR_ID PCI_VENDOR_ID_CERN
#define SVEC_META_DEVICE_ID 0x53564543
#define SVEC_META_BOM_BE 0xFFFE0000
#define SVEC_META_BOM_END_MASK 0xFFFF0000
#define SVEC_META_BOM_VER_MASK 0x0000FFFF
#define SVEC_META_VERSION_MASK 0xFFFF0000

#ifndef BIT
#define BIT(_b) (1 << _b)
#endif
#define SVEC_META_CAP_VIC BIT(0)
#define SVEC_META_CAP_THERM BIT(1)
#define SVEC_META_CAP_SPI BIT(2)
#define SVEC_META_CAP_WR BIT(3)
#define SVEC_META_CAP_BLD BIT(4)

/**
 * struct svec_meta_id Metadata
 */
struct svec_meta_id {
	uint32_t vendor;
	uint32_t device;
	uint32_t version;
	uint32_t bom;
	uint32_t src[4];
	uint32_t cap;
	uint32_t uuid[4];
};

#define SVEC_META_VERSION_MAJ(_v) ((_v >> 24) & 0xFF)
#define SVEC_META_VERSION_MIN(_v) ((_v >> 16) & 0xFF)
#define SVEC_META_VERSION_PATCH(_v) (_v & 0xFFFF)

#endif /* __LINUX_UAPI_SVEC_H */
