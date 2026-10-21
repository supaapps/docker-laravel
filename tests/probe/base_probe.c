#include "php.h"

PHP_FUNCTION(base_probe)
{
    ZEND_PARSE_PARAMETERS_NONE();
    RETURN_STRING("compiled");
}

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_base_probe, 0, 0, IS_STRING, 0)
ZEND_END_ARG_INFO()

static const zend_function_entry base_probe_functions[] = {
    PHP_FE(base_probe, arginfo_base_probe)
    PHP_FE_END
};

zend_module_entry base_probe_module_entry = {
    STANDARD_MODULE_HEADER,
    "base_probe",
    base_probe_functions,
    NULL, NULL, NULL, NULL, NULL,
    "1.0",
    STANDARD_MODULE_PROPERTIES
};

ZEND_GET_MODULE(base_probe)
