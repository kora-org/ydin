/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Copyright © 2022 Leap of Azzam
 *
 * This file is part of FaruOS.
 *
 * FaruOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FaruOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FaruOS.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once
#include <stdint.h>

#define CPUID_VENDOR_INTEL         "GenuineIntel"
#define CPUID_VENDOR_AMD           "AuthenticAMD"
#define CPUID_VENDOR_OLDAMD        "AMDisbetter!" // Early engineering samples of AMD K5 processor
#define CPUID_VENDOR_VIA           "VIA VIA VIA "
#define CPUID_VENDOR_TRANSMETA     "GenuineTMx86"
#define CPUID_VENDOR_OLDTRANSMETA  "TransmetaCPU"
#define CPUID_VENDOR_CYRIX         "CyrixInstead"
#define CPUID_VENDOR_CENTAUR       "CentaurHauls"
#define CPUID_VENDOR_NEXGEN        "NexGenDriven"
#define CPUID_VENDOR_UMC           "UMC UMC UMC "
#define CPUID_VENDOR_SIS           "SiS SiS SiS "
#define CPUID_VENDOR_NSC           "Geode by NSC"
#define CPUID_VENDOR_RISE          "RiseRiseRise"
#define CPUID_VENDOR_VORTEX        "Vortex86 SoC"
#define CPUID_VENDOR_OLDAO486      "GenuineAO486"
#define CPUID_VENDOR_AO486         "MiSTer AO486"
#define CPUID_VENDOR_ZHAOXIN       "  Shanghai  "
#define CPUID_VENDOR_HYGON         "HygonGenuine"
#define CPUID_VENDOR_ELBRUS        "E2K MACHINE "
 
// Vendor strings from hypervisors.
#define CPUID_VENDOR_QEMU          "TCGTCGTCGTCG"
#define CPUID_VENDOR_KVM           " KVMKVMKVM  "
#define CPUID_VENDOR_VMWARE        "VMwareVMware"
#define CPUID_VENDOR_VIRTUALBOX    "VBoxVBoxVBox"
#define CPUID_VENDOR_XEN           "XenVMMXenVMM"
#define CPUID_VENDOR_HYPERV        "Microsoft Hv"
#define CPUID_VENDOR_PARALLELS     " prl hyperv "
#define CPUID_VENDOR_PARALLELS_ALT " lrpepyh vr " // Sometimes Parallels incorrectly encodes "prl hyperv" as "lrpepyh vr" due to an endianness mismatch.
#define CPUID_VENDOR_BHYVE         "bhyve bhyve "
#define CPUID_VENDOR_QNX           " QNXQVMBSQG "

enum {
    CPUID_ECX_SSE3               = 1 << 0,
    CPUID_ECX_PCLMUL             = 1 << 1,
    CPUID_ECX_DTES64             = 1 << 2,
    CPUID_ECX_MONITOR            = 1 << 3,
    CPUID_ECX_DS_CPL             = 1 << 4,
    CPUID_ECX_VMX                = 1 << 5,
    CPUID_ECX_SMX                = 1 << 6,
    CPUID_ECX_EST                = 1 << 7,
    CPUID_ECX_TM2                = 1 << 8,
    CPUID_ECX_SSSE3              = 1 << 9,
    CPUID_ECX_CID                = 1 << 10,
    CPUID_ECX_SDBG               = 1 << 11,
    CPUID_ECX_FMA                = 1 << 12,
    CPUID_ECX_CX16               = 1 << 13,
    CPUID_ECX_XTPR               = 1 << 14,
    CPUID_ECX_PDCM               = 1 << 15,
    CPUID_ECX_PCID               = 1 << 17,
    CPUID_ECX_DCA                = 1 << 18,
    CPUID_ECX_SSE4_1             = 1 << 19,
    CPUID_ECX_SSE4_2             = 1 << 20,
    CPUID_ECX_X2APIC             = 1 << 21,
    CPUID_ECX_MOVBE              = 1 << 22,
    CPUID_ECX_POPCNT             = 1 << 23,
    CPUID_ECX_TSC                = 1 << 24,
    CPUID_ECX_AES                = 1 << 25,
    CPUID_ECX_XSAVE              = 1 << 26,
    CPUID_ECX_OSXSAVE            = 1 << 27,
    CPUID_ECX_AVX                = 1 << 28,
    CPUID_ECX_F16C               = 1 << 29,
    CPUID_ECX_RDRAND             = 1 << 30,
    CPUID_ECX_HYPERVISOR         = 1 << 31
} cpuid_ecx;

enum {
    CPUID_EDX_FPU                = 1 << 0,
    CPUID_EDX_VME                = 1 << 1,
    CPUID_EDX_DE                 = 1 << 2,
    CPUID_EDX_PSE                = 1 << 3,
    CPUID_EDX_TSC                = 1 << 4,
    CPUID_EDX_MSR                = 1 << 5,
    CPUID_EDX_PAE                = 1 << 6,
    CPUID_EDX_MCE                = 1 << 7,
    CPUID_EDX_CX8                = 1 << 8,
    CPUID_EDX_APIC               = 1 << 9,
    CPUID_EDX_SEP                = 1 << 11,
    CPUID_EDX_MTRR               = 1 << 12,
    CPUID_EDX_PGE                = 1 << 13,
    CPUID_EDX_MCA                = 1 << 14,
    CPUID_EDX_CMOV               = 1 << 15,
    CPUID_EDX_PAT                = 1 << 16,
    CPUID_EDX_PSE36              = 1 << 17,
    CPUID_EDX_PSN                = 1 << 18,
    CPUID_EDX_CLFLUSH            = 1 << 19,
    CPUID_EDX_DS                 = 1 << 21,
    CPUID_EDX_ACPI               = 1 << 22,
    CPUID_EDX_MMX                = 1 << 23,
    CPUID_EDX_FXSR               = 1 << 24,
    CPUID_EDX_SSE                = 1 << 25,
    CPUID_EDX_SSE2               = 1 << 26,
    CPUID_EDX_SS                 = 1 << 27,
    CPUID_EDX_HTT                = 1 << 28,
    CPUID_EDX_TM                 = 1 << 29,
    CPUID_EDX_IA64               = 1 << 30,
    CPUID_EDX_PBE                = 1 << 31
} cpuid_edx;

enum {
    CPUID_ECX_LAHF_LONG_MODE     = 1 << 0,
    CPUID_ECX_INVALID_HT         = 1 << 1,
    CPUID_ECX_SVM                = 1 << 2,
    CPUID_ECX_EXTENDED_APIC      = 1 << 3,
    CPUID_ECX_CR8_PROTECTED_MODE = 1 << 4,
    CPUID_ECX_ABM                = 1 << 5,
    CPUID_ECX_SSE4               = 1 << 6,
    CPUID_ECX_MISALIGNED_SSE     = 1 << 7,
    CPUID_ECX_PREFETCH           = 1 << 8,
    CPUID_ECX_OSVW               = 1 << 9,
    CPUID_ECX_IBS                = 1 << 10,
    CPUID_ECX_XOP                = 1 << 11,
    CPUID_ECX_SKINIT             = 1 << 12,
    CPUID_ECX_WDT                = 1 << 13,
    CPUID_ECX_LWP                = 1 << 15,
    CPUID_ECX_FMA4               = 1 << 16,
    CPUID_ECX_TCE                = 1 << 17,
    CPUID_ECX_NODEID_MSR         = 1 << 19,
    CPUID_ECX_TBM                = 1 << 21,
    CPUID_ECX_PERFCTR_CORE       = 1 << 23,
    CPUID_ECX_PERFCTR_NB         = 1 << 24,
    CPUID_ECX_DBX                = 1 << 26,
    CPUID_ECX_PERFTSC            = 1 << 27,
    CPUID_ECX_PCX_L2I            = 1 << 28
} cpuid_extended_ecx;

enum {
    CPUID_EDX_SYSCALL            = 1 << 11,
    CPUID_EDX_MP                 = 1 << 19,
    CPUID_EDX_NX                 = 1 << 20,
    CPUID_EDX_MMX_EXTENDED       = 1 << 22,
    CPUID_EDX_FXSR_OPTIMIZATIONS = 1 << 25,
    CPUID_EDX_PDPE1GB            = 1 << 26,
    CPUID_EDX_RDTSCP             = 1 << 27,
    CPUID_EDX_LONG_MODE          = 1 << 29,
    CPUID_EDX_3DNOW_EXTENDED     = 1 << 30,
    CPUID_EDX_3DNOW              = 1 << 31
} cpuid_extended_edx;

static inline void cpuid(uint32_t code, uint32_t *eax, uint32_t *ebx, uint32_t *ecx, uint32_t *edx) {
    asm volatile("cpuid" : "=a"(*eax), "=b"(*ebx), "=c"(*ecx), "=d"(*edx) : "a"(code));
}

static char string[13];
static inline char *cpuid_string(uint32_t code) {
    uint32_t eax, ebx, ecx, edx;

    cpuid(code, &eax, &ebx, &ecx, &edx);
    *(uint32_t *)&string[0] = ebx;
    *(uint32_t *)&string[4] = edx;
    *(uint32_t *)&string[8] = ecx;
    string[12] = '\0';

    return string;
}
