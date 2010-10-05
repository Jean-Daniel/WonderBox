/*
 *  WBMachDispatch.c
 *  Amethyst
 *
 *  Created by Jean-Daniel Dupas on 06/08/10.
 *  Copyright 2010 Ninsight. All rights reserved.
 *
 */

#include WBHEADER(WBMachDispatch.h)

/* Copy from XNU sources */
mach_msg_return_t
WBMachMessageServer(boolean_t (*demux)(mach_msg_header_t *, mach_msg_header_t *, void *ctxt),
                    mach_msg_size_t max_size, mach_port_t rcv_name, mach_msg_options_t options, void *ctxt)
{
	mig_reply_error_t *bufRequest, *bufReply;
	mach_msg_size_t request_size;
	mach_msg_size_t new_request_alloc;
	mach_msg_size_t request_alloc;
	mach_msg_size_t trailer_alloc;
	mach_msg_size_t reply_alloc;
	mach_msg_return_t mr;
	kern_return_t kr;
	mach_port_t self = mach_task_self();

	options &= ~(MACH_SEND_MSG|MACH_RCV_MSG|MACH_RCV_OVERWRITE);

	reply_alloc = round_page((options & MACH_SEND_TRAILER) ?
                           (max_size + MAX_TRAILER_SIZE) : max_size);

	kr = vm_allocate(self,
                   (vm_address_t *)&bufReply,
                   reply_alloc,
                   VM_MAKE_TAG(VM_MEMORY_MACH_MSG)|TRUE);
	if (kr != KERN_SUCCESS)
		return kr;

	request_alloc = 0;
	trailer_alloc = REQUESTED_TRAILER_SIZE(options);
	new_request_alloc = round_page(max_size + trailer_alloc);

	request_size = (options & MACH_RCV_LARGE) ?
  new_request_alloc : max_size + trailer_alloc;

	for (;;) {
		if (request_alloc < new_request_alloc) {
			request_alloc = new_request_alloc;
			kr = vm_allocate(self,
                       (vm_address_t *)&bufRequest,
                       request_alloc,
                       VM_MAKE_TAG(VM_MEMORY_MACH_MSG)|TRUE);
			if (kr != KERN_SUCCESS) {
				vm_deallocate(self,
                      (vm_address_t)bufReply,
                      reply_alloc);
				return kr;
			}
		}

		mr = mach_msg(&bufRequest->Head, MACH_RCV_MSG|options,
                  0, request_size, rcv_name,
                  MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);

		while (mr == MACH_MSG_SUCCESS) {
			/* we have another request message */

			(void) (*demux)(&bufRequest->Head, &bufReply->Head, ctxt);

			if (!(bufReply->Head.msgh_bits & MACH_MSGH_BITS_COMPLEX)) {
				if (bufReply->RetCode == MIG_NO_REPLY)
					bufReply->Head.msgh_remote_port = MACH_PORT_NULL;
				else if ((bufReply->RetCode != KERN_SUCCESS) &&
                 (bufRequest->Head.msgh_bits & MACH_MSGH_BITS_COMPLEX)) {
					/* destroy the request - but not the reply port */
					bufRequest->Head.msgh_remote_port = MACH_PORT_NULL;
					mach_msg_destroy(&bufRequest->Head);
				}
			}

			/*
			 * We don't want to block indefinitely because the client
			 * isn't receiving messages from the reply port.
			 * If we have a send-once right for the reply port, then
			 * this isn't a concern because the send won't block.
			 * If we have a send right, we need to use MACH_SEND_TIMEOUT.
			 * To avoid falling off the kernel's fast RPC path,
			 * we only supply MACH_SEND_TIMEOUT when absolutely necessary.
			 */
			if (bufReply->Head.msgh_remote_port != MACH_PORT_NULL) {
				if (request_alloc == reply_alloc) {
					mig_reply_error_t *bufTemp;

					mr = mach_msg(
                        &bufReply->Head,
                        (MACH_MSGH_BITS_REMOTE(bufReply->Head.msgh_bits) ==
                         MACH_MSG_TYPE_MOVE_SEND_ONCE) ?
                        MACH_SEND_MSG|MACH_RCV_MSG|options :
                        MACH_SEND_MSG|MACH_RCV_MSG|MACH_SEND_TIMEOUT|options,
                        bufReply->Head.msgh_size, request_size, rcv_name,
                        MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);

					/* swap request and reply */
					bufTemp = bufRequest;
					bufRequest = bufReply;
					bufReply = bufTemp;

				} else {
					mr = mach_msg_overwrite(
                                  &bufReply->Head,
                                  (MACH_MSGH_BITS_REMOTE(bufReply->Head.msgh_bits) ==
                                   MACH_MSG_TYPE_MOVE_SEND_ONCE) ?
                                  MACH_SEND_MSG|MACH_RCV_MSG|options :
                                  MACH_SEND_MSG|MACH_RCV_MSG|MACH_SEND_TIMEOUT|options,
                                  bufReply->Head.msgh_size, request_size, rcv_name,
                                  MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL,
                                  &bufRequest->Head, 0);
				}

				if ((mr != MACH_SEND_INVALID_DEST) &&
            (mr != MACH_SEND_TIMED_OUT))
					continue;
			}
			if (bufReply->Head.msgh_bits & MACH_MSGH_BITS_COMPLEX)
				mach_msg_destroy(&bufReply->Head);

			mr = mach_msg(&bufRequest->Head, MACH_RCV_MSG|options,
                    0, request_size, rcv_name,
                    MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);

		} /* while (mr == MACH_MSG_SUCCESS) */

		if ((mr == MACH_RCV_TOO_LARGE) && (options & MACH_RCV_LARGE)) {
			new_request_alloc = round_page(bufRequest->Head.msgh_size +
                                     trailer_alloc);
			request_size = new_request_alloc;
			vm_deallocate(self,
                    (vm_address_t) bufRequest,
                    request_alloc);
			continue;
		}

		break;

  } /* for(;;) */

  (void)vm_deallocate(self,
                      (vm_address_t) bufRequest,
                      request_alloc);
  (void)vm_deallocate(self,
                      (vm_address_t) bufReply,
                      reply_alloc);
  return mr;
}

