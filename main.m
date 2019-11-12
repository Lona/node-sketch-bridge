#include <node_api.h>
#include <string.h>

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AppKit/AppKit.h>

napi_value nsobject_to_napi_value(napi_env env, NSObject *object) {
    if ([object isKindOfClass:[NSString class]]) {
        NSString *nsString = (NSString *)object;
        napi_value result;

        const char *cString = [nsString cStringUsingEncoding: NSUTF8StringEncoding];
        napi_create_string_utf8(env, cString, strnlen(cString, 128), &result);

        return result;
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *nsArray = (NSArray *)object;
        NSUInteger count = [nsArray count];
        napi_value result;

        napi_create_array_with_length(env, count, &result);

        for (NSUInteger i = 0; i < count; i++) {
            napi_value element = nsobject_to_napi_value(env, [nsArray objectAtIndex:i]);
            napi_set_element(env, result, i, element);
        }

        return result;
    }

    return NULL;
}

NSArray<NSString *> * font_names_for_family_impl(NSString *familyName) {
    NSFontManager *manager = [NSFontManager sharedFontManager];
    NSArray<NSArray *> *members = [manager availableMembersOfFontFamily: familyName];
    NSUInteger count = [members count];

    NSMutableArray *results = [NSMutableArray array];

    for (NSUInteger i = 0; i < count; i++) {
        [results addObject:[[members objectAtIndex:i] objectAtIndex:0]];
    }

    return results;
}

napi_value font_names_for_family(napi_env env, napi_callback_info info)
{
    napi_value argv[1];
    size_t argc = 1;

    napi_get_cb_info(env, info, &argc, argv, NULL, NULL);

    if (argc < 1) {
        napi_throw_error(env, "EINVAL", "Too few arguments");
        return NULL;
    }

    char cString[1024];
    size_t cStringLength;

    if (napi_get_value_string_utf8(env, argv[0], (char *)&cString, 1024, &cStringLength) != napi_ok) {
        napi_throw_error(env, "EINVAL", "Expected string");
        return NULL;
    }

    cString[cStringLength] = '\0';
    NSString *nsString = [NSString stringWithUTF8String:cString];

    return nsobject_to_napi_value(env, font_names_for_family_impl(nsString));
}

napi_value init_all(napi_env env, napi_value exports)
{
    napi_value font_names_for_family_func;
    napi_create_function(env, NULL, 0, font_names_for_family, NULL, &font_names_for_family_func);
    napi_set_named_property(env, exports, "fontNamesForFamily", font_names_for_family_func);
    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, init_all)
