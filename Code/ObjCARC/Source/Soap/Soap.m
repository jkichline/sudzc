//
//  Soap.m
//
//  Provides method for serializing and deserializing values to and from the web service.
//  Authors: Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
//           Karl Schulenburg, UMAI Development - Shoreditch, London UK
//

#import <objc/runtime.h>
#import "Soap.h"
#import "NSData+Base64.h"
#import "NSMutableArray+Soap.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Soap

// Creates the XML request for the SOAP envelope.
+ (NSString *)createEnvelope:(NSString *)method forNamespace:(NSString *)ns forParameters:(NSString *)params
{
    return [self createEnvelope:method forNamespace:ns forParameters:params withHeaders:nil];
}

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString *)createEnvelope:(NSString *)method forNamespace:(NSString *)ns
               forParameters:(NSString *)params withHeaders:(NSDictionary *)headers
{
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
    [s appendFormat:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\"%@\">",
                    ns];

    // Create header
    if (headers != nil && headers.count > 0) {
        [s appendString:@"<soap:Header>"];
        for (id key in [headers allKeys]) {
            if ([[headers objectForKey:key] isMemberOfClass:[SoapNil class]]) {
                [s appendFormat:@"<%@ xsi:nil=\"true\"/>", key];
            } else {
                [s appendString:[Soap serializeHeader:headers forKey:key]];
            }
        }
        [s appendString:@"</soap:Header>"];
    }

    // Create body
    [s appendString:@"<soap:Body>"];

    if ([params isEqualToString:@""]) {
        [s appendFormat:@"<%@ xmlns=\"%@\"/>", method, ns];
    } else {
        [s appendFormat:@"<%@ xmlns=\"%@\">%@</%@>", method, ns,
                        [params stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"], method];
    }

    [s appendString:@"</soap:Body>"];
    [s appendString:@"</soap:Envelope>"];

    return s;
}

+ (NSString *)serializeHeader:(NSDictionary *)headers forKey:(NSString *)key
{
    id headerValue = [headers objectForKey:key];

    // If its a literal, just output it
    if ([headerValue isKindOfClass:[SoapLiteral class]]) {
        SoapLiteral *literal = (SoapLiteral *) headerValue;
        return [literal value];
    }

    // If it's a dictionary, then serialize and look for attributes
    if ([headerValue isKindOfClass:[NSDictionary class]]) {
        NSMutableString *attributes = [NSMutableString string];
        NSMutableString *elements = [NSMutableString string];
        for (id subkey in [headerValue allKeys]) {
            if ([subkey hasPrefix:@"@"]) {
                [attributes appendFormat:@" %@=\"%@\"",
                                         [subkey substringFromIndex:1],
                                         [headerValue objectForKey:subkey]];
            } else {
                [elements appendFormat:@"%@%@%@", subkey, [Soap serialize:[headerValue objectForKey:subkey]], subkey];
            }
        }
        return [NSString stringWithFormat:@"<%@%@>%@</%@>", key, attributes, elements, key];
    }

    // Otherwise, just use regular serialization
    return [NSString stringWithFormat:@"<%@>%@</%@>", key, [Soap serialize:[headerValue objectForKey:key]], key];
}

// Creates the XML request for the SOAP envelope.
+ (NSString *)createEnvelope:(NSString *)method forNamespace:(NSString *)ns containing:(NSDictionary *)containing
{
    return [self createEnvelope:method forNamespace:ns containing:containing withHeaders:nil];
}

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString *)createEnvelope:(NSString *)method
                forNamespace:(NSString *)ns
                  containing:(NSDictionary *)containing
                 withHeaders:(NSDictionary *)headers
{
    NSMutableString *s = [NSMutableString string];
    for (id key in containing) {
        if ([[containing objectForKey:key] isMemberOfClass:[SoapNil class]]) {
            [s appendFormat:@"<%@ xsi:nil=\"true\"/>", key];
        } else {
            [s appendFormat:@"<%@>%@</%@>", key, [Soap serialize:[containing objectForKey:key]], key];
        }
    }
    NSString *envelope = [Soap createEnvelope:method forNamespace:ns forParameters:s withHeaders:headers];
    return envelope;
}

// Creates the XML request for the SOAP envelope.
+ (NSString *)createEnvelope:(NSString *)method forNamespace:(NSString *)ns withParameters:(NSArray *)params
{
    return [self createEnvelope:method forNamespace:ns withParameters:params withHeaders:nil];
}

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString *)createEnvelope:(NSString *)method
                forNamespace:(NSString *)ns
              withParameters:(NSArray *)params
                 withHeaders:(NSDictionary *)headers
{
    NSMutableString *s = [NSMutableString string];
    for (SoapParameter *p in params) {
        [s appendString:p.xml];
    }
    NSString *envelope = [Soap createEnvelope:method forNamespace:ns forParameters:s withHeaders:headers];
    return envelope;
}

// Creates the XML request for the SOAP envelope with optional SOAP headers.
+ (NSString *)createEnvelope:(NSString *)method
                    ofAction:(NSString *)action
                forNamespace:(NSString *)ns
                  containing:(SoapObject *)containing
                 withHeaders:(NSDictionary *)headers
{
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"<%@>%@</%@>", method, [containing serialize], method];
    NSString *envelope = [Soap createEnvelope:action forNamespace:ns forParameters:s withHeaders:headers];
    return envelope;
}

// Serializes an object to a string, XML representation with a specific node name.
+ (NSString *)serialize:(id)object withName:(NSString *)nodeName
{
    if ([object respondsToSelector:@selector(serialize:)]) {
        return [object performSelector:@selector(serialize:) withObject:nodeName];
    }
    return [NSString stringWithFormat:@"<%@>%@</%@>", nodeName, [Soap serialize:object], nodeName];
}

// Serializes an object to a string, XML representation.
+ (NSString *)serialize:(id)object
{
    if ([object respondsToSelector:@selector(serialize)]) {
        return [object serialize];
    }

    // If it's not an object, just return it as a string.
    if ([Soap isObject:object] == NO) {
        @try {
            if ([object isKindOfClass:[NSDate class]]) {
                return [Soap getDateString:object];
            }
            if ([object isKindOfClass:[NSData class]]) {
                return [Soap getBase64String:object];
            }
        } @catch (NSError *error) {
            return (NSString *) object;
        }
        return (NSString *) object;
    }

    // If it s an array, then serialize it as an array.
    if ([Soap isArray:object]) {
        // VARIAN@AM: Also serialize SoapArrays, implementation below
        return [object serialize];
    }

    // Otherwise we need to serialize the object as XML.
    unsigned int outCount, i;
    NSMutableString *s = [NSMutableString string];
    NSMutableDictionary *keys = [NSMutableDictionary dictionary];

    Class currentClass = [object class];
    while (currentClass != nil) {
        objc_property_t *properties = class_copyPropertyList([object class], &outCount);
        if (outCount > 0) {
            for (i = 0; i < outCount; i++) {
                NSString *name = @(property_getName(properties[i]));
                [s appendFormat:@"<%@>%@</%@>", name, [Soap serialize:(__bridge id) properties[i]], name];
                [keys setValue:name forKey:name];
            }
        }
        free(properties);
    }
    return s;
}

// Calls an HTTP service.
+ (NSMutableData *)callService:(NSString *)urlString
                          data:(NSString *)data
                        action:(NSString *)action
                      delegate:(SEL)handler
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    if (action != nil) {
        [request addValue:action forHTTPHeaderField:@"SOAPAction"];
    }
    if (data != nil) {
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
        [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    }

    [NSURLConnection connectionWithRequest:request delegate:self];

    NSError *error;
    NSURLResponse *response;

    return (NSMutableData *) [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
}

// Gets the node from another node by name.
+ (CXMLNode *)getNode:(CXMLNode *)element withName:(NSString *)name
{
    // Check if the direct children respond to the name
    for (CXMLNode *child in [element children]) {
        // VARIAN@AM: Must compare localName here instead of prefixed name, because the SOAP
        //            code and the generated code use non-prefixed names for comparison here...
        // VARIAN@AM: TODO: repondsToSelector always true... does this do anything useful?
        if ([child respondsToSelector:@selector(name)] && [[child localName] isEqualToString:name]) {
            return child;
        }
    }

    // Recursivly traverse through the children
    for (CXMLNode *child in [element children]) {
        CXMLNode *el = [Soap getNode:(CXMLElement *) child withName:name];
        if (el != nil) {
            return el;
        }
    }

    return nil;
}

// Finds nodes in a parent with a given XPath query.
+ (NSArray *)findNodes:(CXMLNode *)node xpath:(NSString *)xpath
{
    NSError *error;
    return [node nodesForXPath:xpath error:&error];
}

// Finds a single node with the given XPath query.
+ (CXMLNode *)findNode:(CXMLNode *)node xpath:(NSString *)xpath
{
    NSArray *a = [Soap findNodes:node xpath:xpath];
    if (a != nil && [a count] > 0) {
        return (CXMLNode *) [a objectAtIndex:0];
    }
    return nil;
}

// Deserialize an object as a generic object
+ (id)deserialize:(CXMLNode *)element
{
    // Get the type
    NSString *type = [Soap getNodeValue:element withName:@"type"];
    if (type == nil || type.length == 0) {
        if ([element children].count < 1) {
            return [element stringValue];

            // Render as a complex object
        } else {
            return [Soap deserializeAsDictionary:element];
        }
    } else {
        NSString *value = [element stringValue];
        if ([type rangeOfString:@":"].length > 0) {
            type = [[type substringFromIndex:[type rangeOfString:@":"].location + 1] lowercaseString];
        }

        // Return as string
        if ([type isEqualToString:@"string"] || [type isEqualToString:@"token"] || [type isEqualToString:@"normalizedstring"]) {
            return value;
        }

        // Return as integer
        if ([type isEqualToString:@"int"] ||
                [type isEqualToString:@"integer"] ||
                [type isEqualToString:@"positiveinteger"] ||
                [type isEqualToString:@"negativeinteger"] ||
                [type isEqualToString:@"nonpositiveinteger"] ||
                [type isEqualToString:@"nonnegativeinteger"]) {
            return @([value intValue]);
        }

        // Return as long
        if ([type isEqualToString:@"long"] || [type isEqualToString:@"unsignedlong"]) {
            return [NSNumber numberWithLongLong:[value longLongValue]];
        }

        // Return as short
        if ([type isEqualToString:@"short"] || [type isEqualToString:@"unsignedshort"]) {
            return @((short) [value intValue]);
        }

        // Return as float
        if ([type isEqualToString:@"float"]) {
            return @([value floatValue]);
        }

        // Return as double
        if ([type isEqualToString:@"double"]) {
            return @([value doubleValue]);
        }

        // Return as byte
        if ([type isEqualToString:@"byte"] || [type isEqualToString:@"unsignedbyte"]) {
            return @((short) [value intValue]);
        }

        // Return as decimal
        if ([type isEqualToString:@"decimal"]) {
            return [NSDecimalNumber numberWithFloat:[value floatValue]];
        }

        // Return as boolean
        if ([type isEqualToString:@"boolean"]) {
            return @([value boolValue]);
        }

        // Return as a date
        if ([type isEqualToString:@"date"] || [type isEqualToString:@"time"] || [type isEqualToString:@"datetime"]) {
            return [Soap dateFromString:value];
        }

        // Return as data
        if ([type isEqualToString:@"base64binary"]) {
            return [Soap dataFromString:value];
        }

        // Return as a dictionary
        if (value == nil) {
            NSString *prefix = @"";
            if ([Soap respondsToSelector:@selector(prefix)]) {
                prefix = [Soap performSelector:@selector(prefix)];
            }
            Class cls = NSClassFromString([NSString stringWithFormat:@"%@%@", prefix, type]);
            if (cls != nil) {
                return [cls createWithNode:element];
            } else {
                return [Soap deserializeAsDictionary:element];
            }
        }

                // Return as string
        else {
            return value;
        }
    }
}

// Deserializes the element in a dictionary.
+ (id)deserializeAsDictionary:(CXMLNode *)element
{
    if ([element childCount] == 1) {
        CXMLNode *child = [[element children] objectAtIndex:0];
        if ([child kind] == CXMLTextKind) {
            return [[[element children] objectAtIndex:0] stringValue];
        }
    }

    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    for (CXMLNode *child in [element children]) {
        id v = [Soap deserialize:child];
        if (v == nil) {
            v = [NSNull null];
        }
        [d setObject:v forKey:[child name]];
    }
    return d;
}

// Determines if an object is an array.
+ (BOOL)isArray:(NSObject *)value
{
    return [value isKindOfClass:[NSArray class]];
}

// Determines if an object is an object with properties.
+ (BOOL)isObject:(NSObject *)value
{
    return [value isKindOfClass:[SoapObject class]];
}

// Gets the value of a named node from a parent node.
+ (NSString *)getNodeValue:(CXMLNode *)node withName:(NSString *)name
{
    // Set up the variables
    if (node == nil || name == nil) {
        return nil;
    }
    CXMLNode *child = nil;

    // If it's an attribute get it
    if ([node isKindOfClass:[CXMLElement class]]) {
        child = [(CXMLElement *) node attributeForName:name];
        if (child != nil) {
            return [child stringValue];
        }
    }

    // Otherwise get the first element
    child = [Soap getNode:node withName:name];
    if (child != nil) {
        return [child stringValue];
    }
    return nil;
}

+ (id)convert:(NSString *)value toType:(NSString *)toType
{
    if (toType == nil || value == nil) {
        return value;
    }

    toType = [toType lowercaseString];
    if ([toType isEqualToString:@"nsstring*"]) {
        return value;
    }
    if ([toType isEqualToString:@"nsplaceholderstring*"]) {
        return value;
    }
    if ([toType isEqualToString:@"bool"]) {
        return [NSNumber numberWithBool:(([[value lowercaseString] isEqualToString:@"true"]) ? YES : NO)];
    }
    if ([toType isEqualToString:@"int"]) {
        return @([value intValue]);
    }
    if ([toType isEqualToString:@"long"]) {
        return [NSNumber numberWithLong:[value longLongValue]];
    }
    if ([toType isEqualToString:@"double"]) {
        return @([value doubleValue]);
    }
    if ([toType isEqualToString:@"float"]) {
        return @([value floatValue]);
    }
    if ([toType isEqualToString:@"nsdecimalnumber*"]) {
        return [NSDecimalNumber decimalNumberWithString:value];
    }
    if ([toType isEqualToString:@"nsdate*"]) {
        return [Soap dateFromString:value];
    }
    if ([toType isEqualToString:@"nsdata*"]) {
        return [Soap dataFromString:value];
    }
    return value;
}

+ (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:enUS];
    [formatter setLenient:YES];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];

    return formatter;
}

// Converts a string to a date.
+ (NSDate *)dateFromString:(NSString *)value
{
    if ([value rangeOfString:@"T"].length != 1) {
        value = [NSString stringWithFormat:@"%@T00:00:00.000", value];
    }
    if ([value rangeOfString:@"."].length != 1) {
        value = [NSString stringWithFormat:@"%@.000", value];
    }
    if (value == nil || [value isEqualToString:@""]) {
        return nil;
    }
    NSDate *outputDate = [[Soap dateFormatter] dateFromString:value];
    return outputDate;
}

+ (NSString *)getDateString:(NSDate *)value
{
    return [[Soap dateFormatter] stringFromDate:value];
}

+ (NSData *)dataFromString:(NSString *)value
{
    return [[NSData alloc] initWithBase64EncodedString:value];
}

+ (NSString *)getBase64String:(NSData *)value
{
    return [value base64Encoding];
}

+ (NSString *)md5:(NSString *)value
{
    const char *cStr = [value UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5((void *)cStr, strlen(cStr), result);
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                                      result[0],
                                      result[1],
                                      result[2],
                                      result[3],
                                      result[4],
                                      result[5],
                                      result[6],
                                      result[7],
                                      result[8],
                                      result[9],
                                      result[10],
                                      result[11],
                                      result[12],
                                      result[13],
                                      result[14],
                                      result[15]
    ];
}

// Creates a unique hash for the object's contents.
+ (NSUInteger)generateHash:(SoapObject *)value
{
    NSString *md5 = [Soap md5:[value serialize]];
    return [[md5 dataUsingEncoding:NSUTF8StringEncoding] hash];
}

// Creates dictionary of string values from the XML document.
+ (id)objectFromXMLString:(NSString *)xmlString
{
    CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:nil];
    return [Soap objectFromNode:doc];
}

// Creates dictionary of string values from the node.
+ (id)objectFromNode:(CXMLNode *)node
{
    NSMutableArray *children = [NSMutableArray arrayWithArray:[node children]];
    if ([node isKindOfClass:[CXMLElement class]]) {
        [children addObjectsFromArray:[(CXMLElement *) node attributes]];
    }
    if ([children count] > 0) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (CXMLNode *child in children) {
            id childValue = [Soap objectFromNode:child];
            id value = [dictionary objectForKey:[child name]];
            if (value != nil) {
                if ([value isKindOfClass:[NSMutableArray class]] == NO) {
                    value = [NSMutableArray arrayWithObject:value];
                }
                if (childValue != nil) {
                    [(NSMutableArray *) value addObject:childValue];
                }
            } else {
                if (childValue != nil) {
                    [dictionary setObject:childValue forKey:[child name]];
                }
            }
        }
        if ([[dictionary allKeys] count] == 1) {
            return [dictionary objectForKey:[[dictionary allKeys] objectAtIndex:0]];
        } else {
            return dictionary;
        }
    } else {
        return [node stringValue];
    }
}

@end
