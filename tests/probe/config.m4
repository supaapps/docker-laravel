PHP_ARG_ENABLE([base_probe], [whether to enable base_probe], [AS_HELP_STRING([--enable-base_probe], [Enable test probe])], [yes])
PHP_NEW_EXTENSION([base_probe], [base_probe.c], [$ext_shared])
