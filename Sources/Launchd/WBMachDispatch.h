/*
 *  WBMachDispatch.h
 *  Amethyst
 *
 *  Created by Jean-Daniel Dupas on 06/08/10.
 *  Copyright 2010 Ninsight. All rights reserved.
 *
 */

#if !defined(__WB_MACH_MESSAGE_SERVER_H)
#define __WB_MACH_MESSAGE_SERVER_H 1

#include <WonderBox/WBBase.h>

#include <mach/mach.h>

WB_EXPORT
mach_msg_return_t WBMachMessageServer(boolean_t (*demux)(mach_msg_header_t *, mach_msg_header_t *, void *ctxt),
                                      mach_msg_size_t max_size, mach_port_t rcv_name, mach_msg_options_t options, void *ctxt);


#endif /* __WB_MACH_MESSAGE_SERVER_H */
