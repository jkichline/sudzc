@interface NSData (Base64) 

+ (NSData *)dataWithBase64EncodedString:(NSString *)string;
- (id)initWithBase64EncodedString:(NSString *)string;

- (NSString *)base64Encodeing;
- (NSString *)base64EncodeingWithLineLength:(unsigned int) lineLength;

@end