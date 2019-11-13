#include <node_api.h>
#include <string.h>

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AppKit/AppKit.h>

// https://github.com/djmadcat/NSNumber-CGFloat
@implementation NSNumber (CGFloat)

- (CGFloat)CGFloatValue
{
#if (CGFLOAT_IS_DOUBLE == 1)
    CGFloat result = [self doubleValue];
#else
    CGFloat result = [self floatValue];
#endif
    return result;
}

- (id)initWithCGFloat:(CGFloat)value
{
#if (CGFLOAT_IS_DOUBLE == 1)
    self = [self initWithDouble:value];
#else
    self = [self initWithFloat:value];
#endif
    return self;
}

+ (NSNumber *)numberWithCGFloat:(CGFloat)value
{
    NSNumber *result = [[self alloc] initWithCGFloat:value];
    return result;
}

@end

typedef struct TextStyle {
    CGFloat fontSize;
    NSString *fontFamily;
    NSFontWeight fontWeight;
    CGFloat lineHeight;
    NSTextAlignment textAlign;
    NSUnderlineStyle underlineStyle;
    CGFloat letterSpacing;
    bool hasStrikethrough;
    bool isItalic;

    bool includesFontWeight;
    bool includesFontStyle;
    bool includesLineHeight;
    bool includesTextAlign;
    bool includesLetterSpacing;
} TextStyle;

NSDictionary *FONT_WEIGHTS;
NSDictionary *FONT_STYLES;
NSDictionary *TEXT_ALIGN;
NSDictionary *TEXT_DECORATION_UNDERLINE;
NSDictionary *TEXT_DECORATION_LINETHROUGH;
NSString *DEFAULT_FONT_FAMILY;

NSString *APPLE_BROKEN_SYSTEM_FONT = @".AppleSystemUIFont";

NSParagraphStyle *make_paragraph_style(TextStyle *textStyle) {
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];

    if (textStyle->includesLineHeight) {
        [pStyle setMinimumLineHeight:textStyle->lineHeight];
        [pStyle setLineHeightMultiple:1.0];
        [pStyle setMaximumLineHeight:textStyle->lineHeight];
    }

    if (textStyle->includesTextAlign) {
        [pStyle setAlignment: textStyle->textAlign];
    }

    return pStyle;
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

bool is_italic_font(NSFont *font) {
    NSFontTraitMask traits = [[NSFontManager sharedFontManager] traitsOfFont:font];

    return traits & NSFontItalicTrait;
}

bool is_condensed_font(NSFont *font) {
    NSFontTraitMask traits = [[NSFontManager sharedFontManager] traitsOfFont:font];

    return traits & NSFontCondensedTrait;
}

NSFontWeight weight_of_font(NSFont *font) {
    NSDictionary *traits = [[font fontDescriptor] objectForKey:NSFontTraitsAttribute];
    id fontWeightNumber = traits[@"NSCTFontWeightTrait"];

    if (fontWeightNumber == 0) {
        NSArray *weights = [FONT_WEIGHTS allKeys];

        NSString *fontName = [[font fontName] lowercaseString];

        for (NSString *weight in weights) {
            if ([fontName hasSuffix:weight]) {
                return [FONT_WEIGHTS[weight] CGFloatValue];
            }
        }
    }

    return [fontWeightNumber CGFloatValue];
}

NSFont *find_font(TextStyle *textStyle) {
    NSFont *font = NULL;

    NSString *fontFamily = textStyle->fontFamily;
    NSFontWeight fontWeight = textStyle->fontWeight;
    bool isItalic = textStyle->isItalic;

    // Handle system font as special case. This ensures that we preserve
    // the specific metrics of the standard system font as closely as possible.
    if ([fontFamily isEqualToString:DEFAULT_FONT_FAMILY] ||
        [fontFamily isEqualToString:@"System"]) {

        font = [NSFont systemFontOfSize:textStyle->fontSize weight:fontWeight];

        if (font && isItalic) {
            font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontItalicTrait];
        }
    }

    bool isCondensed = false;
    NSArray<NSString *> * fontNames = font_names_for_family_impl(fontFamily);

    // Gracefully handle being given a font name rather than font family, for
    // example: "Helvetica Light Oblique" rather than just "Helvetica".
    if (!font && [fontNames count] == 0) {
        font = [NSFont fontWithName:fontFamily size:textStyle->fontSize];

        if (font) {
            // It's actually a font name, not a font family name,
            // but we'll do what was meant, not what was said.
            fontFamily = [font familyName];
            fontWeight = textStyle->includesFontWeight ? fontWeight : weight_of_font(font);
            isItalic = textStyle->includesFontStyle ? isItalic : is_italic_font(font);
            isCondensed = is_condensed_font(font);
        } else {
            NSLog(@"Unrecognized font family %@", fontFamily);
            font = [NSFont systemFontOfSize:textStyle->fontSize weight:fontWeight];
        }
    }

    NSFontWeight closestWeight = CGFLOAT_MAX;

    // Get the closest font that matches the given weight for the fontFamily
    for (NSString *fontName in fontNames) {
        NSFont *match = [NSFont fontWithName:fontName size:textStyle->fontSize];

        if (isItalic == is_italic_font(match) && isCondensed == is_condensed_font(match)) {
            NSFontWeight testWeight = weight_of_font(match);

            if (fabs(testWeight - fontWeight) < fabs(closestWeight - fontWeight)) {
                font = match;
                closestWeight = testWeight;
            }
        }
    }

    // If we still don't have a match at least return the first font in the fontFamily
    // This is to support built-in font Zapfino and other custom single font families like Impact
    if (!font) {
      if ([fontNames count] > 0) {
        font = [NSFont fontWithName:[fontNames objectAtIndex:0] size:textStyle->fontSize];
      }
    }

    return font;
}

napi_value nsobject_to_napi_value(napi_env env, NSObject *object) {
    napi_value result = NULL;

    if ([object isKindOfClass:[NSNumber class]]) {
        NSNumber *nsNumber = (NSNumber *)object;

        napi_create_double(env, [nsNumber doubleValue], &result);
    } else if ([object isKindOfClass:[NSString class]]) {
        NSString *nsString = (NSString *)object;

        const char *cString = [nsString cStringUsingEncoding: NSUTF8StringEncoding];
        napi_create_string_utf8(env, cString, strnlen(cString, 128), &result);
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *nsArray = (NSArray *)object;
        NSUInteger count = [nsArray count];

        napi_create_array_with_length(env, count, &result);

        for (NSUInteger i = 0; i < count; i++) {
            napi_value element = nsobject_to_napi_value(env, [nsArray objectAtIndex:i]);
            napi_set_element(env, result, i, element);
        }
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;

        napi_create_object(env, &result);

        for (NSString *key in dict) {
            const char *cString = [key cStringUsingEncoding: NSUTF8StringEncoding];
            napi_set_named_property(env, result, cString, nsobject_to_napi_value(env, dict[key]));
        }
    }

    return result;
}

NSDictionary<NSAttributedStringKey, id> *create_string_attributes(TextStyle *textStyle) {
    NSFont *font = find_font(textStyle);

    if (!font) { return NULL; };

    NSDictionary<NSAttributedStringKey, id> *attribs = [[NSMutableDictionary alloc] init];

    [attribs setValue:font forKey:@"NSFont"];
    [attribs setValue:make_paragraph_style(textStyle) forKey:@"NSParagraphStyle"];
    [attribs setValue:[NSNumber numberWithInt:textStyle->underlineStyle] forKey:@"NSUnderline"];
    [attribs setValue:[NSNumber numberWithBool:textStyle->hasStrikethrough] forKey:@"NSStrikethrough"];

    if (textStyle->includesLetterSpacing) {
        [attribs setValue:[NSNumber numberWithCGFloat:textStyle->letterSpacing] forKey:@"NSKern"];
    }

    // TODO: Implement text transform
    // MSAttributedStringTextTransformAttribute is a Sketch-specific key

    return attribs;
}

NSAttributedString *create_attributed_string(NSString *content, TextStyle *textStyle) {
    NSDictionary<NSAttributedStringKey, id> *attribs = create_string_attributes(textStyle);
    return [[NSAttributedString alloc] initWithString:content attributes:attribs];
}

NSString *ns_string_from_napi_value(napi_env env, napi_value value) {
    size_t cStringLength;

    if (napi_get_value_string_utf8(env, value, NULL, 0, &cStringLength) != napi_ok) {
        napi_throw_error(env, "EINVAL", "Could not get string length");
        return NULL;
    }

    char *cString = (char *)malloc(cStringLength + 1);

    if (napi_get_value_string_utf8(env, value, cString, cStringLength + 1, &cStringLength) != napi_ok) {
        napi_throw_error(env, "EINVAL", "Expected string");
        return NULL;
    }

    NSString *nsString = [NSString stringWithUTF8String:cString];

    free(cString);

    return nsString;
}

bool has_named_property(napi_env env, napi_value object, const char *name) {
    bool hasValue;

    if (napi_has_named_property(env, object, name, &hasValue) != napi_ok) {
        napi_throw_error(env, "EINVAL", "Failed to find named property");
        return false;
    }

    return hasValue;
}


TextStyle *make_text_style(napi_env env, napi_value object) {
    TextStyle *textStyle = (TextStyle *)malloc(sizeof(TextStyle));

    if (has_named_property(env, object, "fontSize")) {
        napi_value fontSizeValue;
        napi_get_named_property(env, object, "fontSize", &fontSizeValue);
        napi_get_value_double(env, fontSizeValue, &textStyle->fontSize);
    } else {
        textStyle->fontSize = 14.0;
    }

    if (has_named_property(env, object, "letterSpacing")) {
        napi_value letterSpacingValue;
        napi_get_named_property(env, object, "letterSpacing", &letterSpacingValue);
        napi_get_value_double(env, letterSpacingValue, &textStyle->letterSpacing);
        textStyle->includesLetterSpacing = true;
    } else {
        textStyle->letterSpacing = 0;
        textStyle->includesLetterSpacing = false;
    }

    if (has_named_property(env, object, "lineHeight")) {
        napi_value lineHeightValue;
        napi_get_named_property(env, object, "lineHeight", &lineHeightValue);
        napi_get_value_double(env, lineHeightValue, &textStyle->lineHeight);
        textStyle->includesLineHeight = true;
    } else {
        textStyle->lineHeight = 0;
        textStyle->includesLineHeight = false;
    }

    if (has_named_property(env, object, "textAlign")) {
        napi_value textAlignValue;
        napi_get_named_property(env, object, "textAlign", &textAlignValue);
        NSString *textAlignString = ns_string_from_napi_value(env, textAlignValue);
        NSNumber *textAlignNumber = TEXT_ALIGN[textAlignString];
        if (textAlignNumber) {
            textStyle->textAlign = [textAlignNumber intValue];
            textStyle->includesTextAlign = true;
        } else {
            textStyle->textAlign = NSTextAlignmentLeft;
            textStyle->includesTextAlign = false;
        }
    } else {
        textStyle->textAlign = NSTextAlignmentLeft;
        textStyle->includesTextAlign = false;
    }

    if (has_named_property(env, object, "fontWeight")) {
        napi_value fontWeightValue;
        napi_get_named_property(env, object, "fontWeight", &fontWeightValue);
        NSString *fontWeightString = ns_string_from_napi_value(env, fontWeightValue);
        NSNumber *fontWeightNumber = FONT_WEIGHTS[fontWeightString] ?: [NSNumber numberWithCGFloat:NSFontWeightRegular];
        textStyle->fontWeight = [fontWeightNumber CGFloatValue];
        textStyle->includesFontWeight = true;
    } else {
        textStyle->fontWeight = NSFontWeightRegular;
        textStyle->includesFontWeight = false;
    }

    if (has_named_property(env, object, "fontStyle")) {
        napi_value fontStyleValue;
        napi_get_named_property(env, object, "fontStyle", &fontStyleValue);
        NSString *fontStyleString = ns_string_from_napi_value(env, fontStyleValue);
        NSNumber *fontStyleNumber = FONT_STYLES[fontStyleString] ?: @NO;
        textStyle->isItalic = [fontStyleNumber boolValue];
        textStyle->includesFontStyle = true;
    } else {
        textStyle->isItalic = false;
        textStyle->includesFontStyle = false;
    }

    if (has_named_property(env, object, "fontFamily")) {
        napi_value fontFamilyValue;
        napi_get_named_property(env, object, "fontFamily", &fontFamilyValue);
        NSString *fontFamilyString = ns_string_from_napi_value(env, fontFamilyValue);
        textStyle->fontFamily = fontFamilyString;
    // Default to Helvetica if fonts are missing
    } else if ([DEFAULT_FONT_FAMILY isEqualToString:APPLE_BROKEN_SYSTEM_FONT]) {
        textStyle->fontFamily = @"Helvetica";
    } else {
        textStyle->fontFamily = DEFAULT_FONT_FAMILY;
    }

    if (has_named_property(env, object, "textDecoration")) {
        napi_value textDecorationValue;
        napi_get_named_property(env, object, "textDecoration", &textDecorationValue);
        NSString *textDecorationString = ns_string_from_napi_value(env, textDecorationValue);
        NSNumber *strikeThroughNumber = TEXT_DECORATION_LINETHROUGH[textDecorationString] ?: @NO;
        NSNumber *underlineNumber = TEXT_DECORATION_UNDERLINE[textDecorationString] ?: [NSNumber numberWithInt:NSUnderlineStyleNone];
        textStyle->hasStrikethrough = [strikeThroughNumber boolValue];
        textStyle->underlineStyle = [underlineNumber intValue];
    } else {
        textStyle->underlineStyle = NSUnderlineStyleNone;
        textStyle->hasStrikethrough = false;
    }

    return textStyle;
};

void free_text_style(TextStyle *textStyle) {
    free(textStyle);
};

NSString *get_postscript_name(TextStyle *textStyle) {
    NSFont *font = find_font(textStyle);

    if (!font) { return [NSString init]; }

    return [[font fontDescriptor] postscriptName];
}

napi_value find_font_name(napi_env env, napi_callback_info info)
{
    napi_value argv[1];
    size_t argc = 1;

    napi_get_cb_info(env, info, &argc, argv, NULL, NULL);

    if (argc < 1) {
        napi_throw_error(env, "EINVAL", "Too few arguments");
        return NULL;
    }

    napi_value result;

    @autoreleasepool {
        TextStyle *textStyle = make_text_style(env, argv[0]);

        NSString *fontName = get_postscript_name(textStyle);

        free_text_style(textStyle);

        result = nsobject_to_napi_value(env, fontName);
    }

    return result;
}

napi_value create_string_measurer(napi_env env, napi_callback_info info)
{
    napi_value argv[2];
    size_t argc = 2;

    napi_get_cb_info(env, info, &argc, argv, NULL, NULL);

    if (argc < 2) {
        napi_throw_error(env, "EINVAL", "Too few arguments");
        return NULL;
    }

    napi_value result;

    @autoreleasepool {
        NSMutableAttributedString *fullStr = [[NSMutableAttributedString alloc] init];

        CGFloat width;
        napi_get_value_double(env, argv[1], &width);

        uint32_t textNodeCount;
        napi_get_array_length(env, argv[0], &textNodeCount);

        for (size_t i = 0; i < textNodeCount; i++) {
            napi_value textNodeValue;
            napi_value contentValue;
            napi_value textStylesValue;
            napi_get_element(env, argv[0], i, &textNodeValue);
            napi_get_named_property(env, textNodeValue, "content", &contentValue);
            napi_get_named_property(env, textNodeValue, "textStyles", &textStylesValue);

            TextStyle *textStyle = make_text_style(env, textStylesValue);
            NSString *content = ns_string_from_napi_value(env, contentValue);

            NSAttributedString *newString = create_attributed_string(content, textStyle);

            if (newString) {
                [fullStr appendAttributedString:newString];
            }

            free_text_style(textStyle);
        }

        CGRect rect = [fullStr boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin];
        NSDictionary *dict = @{
            @"width": [NSNumber numberWithCGFloat:rect.size.width],
            @"height": [NSNumber numberWithCGFloat:rect.size.height],
        };

        result = nsobject_to_napi_value(env, dict);
    }

    return result;
}

napi_value make_image_data_from_url(napi_env env, napi_callback_info info)
{
    napi_value argv[1];
    size_t argc = 1;

    napi_get_cb_info(env, info, &argc, argv, NULL, NULL);

    napi_value result;

    @autoreleasepool {
        NSData* fetchedData = nil;

        if (argc >= 1) {
            NSURL* url = [NSURL URLWithString:ns_string_from_napi_value(env, argv[0])];
            fetchedData = [NSData dataWithContentsOfURL:url];
        }

        if (fetchedData != nil) {
            NSString* firstByte = [[fetchedData subdataWithRange:NSMakeRange(0, 1)] description];

            // Check for first byte. Must use non-type-exact matching (!=).
            // 0xFF = JPEG, 0x89 = PNG, 0x47 = GIF, 0x49 = TIFF, 0x4D = TIFF
            if (
                ![firstByte isEqual: @"<ff>"] &&
                ![firstByte isEqual: @"<89>"] &&
                ![firstByte isEqual: @"<47>"] &&
                ![firstByte isEqual: @"<49>"] &&
                ![firstByte isEqual: @"<4d>"]
            ) {
              fetchedData = nil;
            }
        }

        if (fetchedData == nil) {
            // load a red image instead
            fetchedData = [[NSData alloc] initWithBase64EncodedString:@"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mM8w8DwHwAEOQHNmnaaOAAAAABJRU5ErkJggg==" options: NSDataBase64DecodingIgnoreUnknownCharacters];
        }

        NSImage* image = [[NSImage alloc] initWithData:fetchedData];

        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        imageRep.size = image.size;

        NSString* base64 = [[imageRep representationUsingType:NSPNGFileType properties: @{}] base64EncodedStringWithOptions: NSDataBase64EncodingEndLineWithCarriageReturn];

        result = nsobject_to_napi_value(env, base64);
    }

    return result;
}

napi_value init_all(napi_env env, napi_value exports)
{
    FONT_WEIGHTS = @{
        @"normal": [NSNumber numberWithCGFloat:NSFontWeightRegular],
        @"bold" : [NSNumber numberWithCGFloat:NSFontWeightBold],
        @"100" : [NSNumber numberWithCGFloat:NSFontWeightUltraLight],
        @"200" : [NSNumber numberWithCGFloat:NSFontWeightThin],
        @"300" : [NSNumber numberWithCGFloat:NSFontWeightLight],
        @"400" : [NSNumber numberWithCGFloat:NSFontWeightRegular],
        @"500" : [NSNumber numberWithCGFloat:NSFontWeightMedium],
        @"600" : [NSNumber numberWithCGFloat:NSFontWeightSemibold],
        @"700" : [NSNumber numberWithCGFloat:NSFontWeightBold],
        @"800" : [NSNumber numberWithCGFloat:NSFontWeightHeavy],
        @"900" : [NSNumber numberWithCGFloat:NSFontWeightBlack],
    };

    FONT_STYLES = @{
        @"normal": @NO,
        @"italic" : @YES,
        @"oblique" : @YES,
    };

    TEXT_ALIGN = @{
        @"auto": [NSNumber numberWithInt:NSTextAlignmentLeft],
        @"left": [NSNumber numberWithInt:NSTextAlignmentLeft],
        @"right": [NSNumber numberWithInt:NSTextAlignmentRight],
        @"center": [NSNumber numberWithInt:NSTextAlignmentCenter],
        @"justify": [NSNumber numberWithInt:NSTextAlignmentJustified],
    };

    TEXT_DECORATION_UNDERLINE = @{
        @"none": [NSNumber numberWithInt:NSUnderlineStyleNone],
        @"underline": [NSNumber numberWithInt:NSUnderlineStyleSingle],
        @"double": [NSNumber numberWithInt:NSUnderlineStyleDouble],
    };

    TEXT_DECORATION_LINETHROUGH = @{
        @"none": @NO,
        @"line-through": @YES,
    };

    NSFont *defaultFont = [NSFont systemFontOfSize:14.0];
    DEFAULT_FONT_FAMILY = [defaultFont familyName];

    napi_value find_font_name_func;
    napi_create_function(env, NULL, 0, find_font_name, NULL, &find_font_name_func);
    napi_set_named_property(env, exports, "findFontName", find_font_name_func);

    napi_value create_string_measurer_func;
    napi_create_function(env, NULL, 0, create_string_measurer, NULL, &create_string_measurer_func);
    napi_set_named_property(env, exports, "createStringMeasurer", create_string_measurer_func);

    napi_value make_image_data_from_url_func;
    napi_create_function(env, NULL, 0, make_image_data_from_url, NULL, &make_image_data_from_url_func);
    napi_set_named_property(env, exports, "makeImageDataFromURL", make_image_data_from_url_func);

    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, init_all)
