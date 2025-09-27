/*
   telos_proxy_internal.h - Internal helpers for Telos proxy forwarding

   This header exposes internal helper routines shared between telos_proxy.c
   and telos_proxy_forwarding.c. The functions declared here are not part of
   the public ABI and should not be consumed outside the Telos core.
*/

#ifndef TELOS_PROXY_INTERNAL_H
#define TELOS_PROXY_INTERNAL_H

#include "telos_proxy.h"

#ifdef __cplusplus
extern "C" {
#endif

PyObject* TelosProxy_DefaultForwardMessage(IoObjectHandle handle, const char *messageName, PyObject *args);
void TelosProxy_WriteUnraisable(const char *operation, const char *slot_name);
int TelosProxy_HandleForwardFailure(TelosProxyObject *self, const char *attr_name, PyObject *err_type, PyObject *err_value, PyObject *err_trace);
int TelosProxy_PropagateSlotUpdate(TelosProxyObject *self, const char *slot_name, PyObject *value);
int TelosProxy_PropagateSlotDeletion(TelosProxyObject *self, const char *slot_name);
PyObject* TelosProxy_InvokeForwardMessage(TelosProxyObject *self, const char *messageName, PyObject *args);
PyObject* TelosProxy_CopyDispatchMetrics(TelosProxyObject *self);
int TelosProxy_ResetDispatchMetrics(TelosProxyObject *self);
int TelosProxy_RecordDispatch(TelosProxyObject *self, const char *messageName, int success, double duration_ms, double timestamp_s, PyObject *error_text);

#ifdef __cplusplus
}
#endif

#endif /* TELOS_PROXY_INTERNAL_H */
