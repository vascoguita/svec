/*
* Copyright (C) 2017 CERN (www.cern.ch)
* Author: Federico Vaga <federico.vaga@cern.ch>
*
* Based on the SVEC version of:
* Author: Juan David Gonzalez Cobas <dcobas@cern.ch>
* Author: Luis Fernando Ruiz Gago <lfruiz@cern.ch>
* Author: Tomasz Wlostowski <tomasz.wlostowski@cern.ch>
*
* Released according to the GNU GPL, version 2 or any later version
*
* Driver for SVEC (Simple VME FMC carrier) board.
*/

#include <linux/module.h>


static int __init svec_init(void)
{
	return 0;
}

static void __exit svec_exit(void)
{

}

module_init(svec_init);
module_exit(svec_exit);

MODULE_AUTHOR("Federico Vaga <federico.vaga@cern.ch>");
MODULE_AUTHOR("Juan David Gonzalez Cobas <dcobas@cern.ch>");
MODULE_LICENSE("GPLv2");
MODULE_VERSION(GIT_VERSION);
MODULE_DESCRIPTION("svec driver");

ADDITIONAL_VERSIONS;
