#!/usr/bin/env python3
"""Check the current user's password against PAM (exit 0 = ok, 1 = wrong).

Talks to libpam through ctypes, so it works on Debian/Arch alike with no python-pam
package (Debian's python3-pam ships a different module than Arch's python-pam).
Reads the password from argv[1] or stdin.
"""
import sys

sys.dont_write_bytecode = True

import ctypes
import ctypes.util
import getpass

PAM_PROMPT_ECHO_OFF = 1
PAM_PROMPT_ECHO_ON = 2
PAM_SUCCESS = 0


class PamMessage(ctypes.Structure):
    _fields_ = [("msg_style", ctypes.c_int), ("msg", ctypes.c_char_p)]


class PamResponse(ctypes.Structure):
    _fields_ = [("resp", ctypes.c_void_p), ("resp_retcode", ctypes.c_int)]


CONV_FUNC = ctypes.CFUNCTYPE(
    ctypes.c_int,
    ctypes.c_int,
    ctypes.POINTER(ctypes.POINTER(PamMessage)),
    ctypes.POINTER(ctypes.POINTER(PamResponse)),
    ctypes.c_void_p,
)


class PamConv(ctypes.Structure):
    _fields_ = [("conv", CONV_FUNC), ("appdata_ptr", ctypes.c_void_p)]


def authenticate(password, service="login"):
    libpam = ctypes.CDLL(ctypes.util.find_library("pam") or "libpam.so.0")
    libc = ctypes.CDLL(ctypes.util.find_library("c") or "libc.so.6")
    libc.calloc.restype = ctypes.c_void_p
    libc.calloc.argtypes = [ctypes.c_size_t, ctypes.c_size_t]
    libc.strdup.restype = ctypes.c_void_p
    libc.strdup.argtypes = [ctypes.c_char_p]
    libpam.pam_start.argtypes = [
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.POINTER(PamConv),
        ctypes.POINTER(ctypes.c_void_p),
    ]
    libpam.pam_start.restype = ctypes.c_int
    libpam.pam_authenticate.argtypes = [ctypes.c_void_p, ctypes.c_int]
    libpam.pam_authenticate.restype = ctypes.c_int
    libpam.pam_end.argtypes = [ctypes.c_void_p, ctypes.c_int]
    libpam.pam_end.restype = ctypes.c_int

    pw = password.encode()

    def conv(n_messages, messages, p_response, _app):
        array = libc.calloc(n_messages, ctypes.sizeof(PamResponse))
        p_response[0] = ctypes.cast(array, ctypes.POINTER(PamResponse))
        for i in range(n_messages):
            if messages[i].contents.msg_style in (PAM_PROMPT_ECHO_OFF, PAM_PROMPT_ECHO_ON):
                p_response[0][i].resp = libc.strdup(pw)
                p_response[0][i].resp_retcode = 0
        return PAM_SUCCESS

    conv_cb = CONV_FUNC(conv)  # keep a reference alive for the whole call
    handle = ctypes.c_void_p()
    user = getpass.getuser().encode()
    rc = libpam.pam_start(service.encode(), user, ctypes.byref(PamConv(conv_cb, None)), ctypes.byref(handle))
    if rc != PAM_SUCCESS:
        return False
    rc = libpam.pam_authenticate(handle, 0)
    libpam.pam_end(handle, rc)
    return rc == PAM_SUCCESS


if __name__ == "__main__":
    password = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.readline().rstrip("\r\n")
    sys.exit(0 if authenticate(password) else 1)
