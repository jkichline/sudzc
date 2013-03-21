/*
 SoapArray.m
 Implementation of the SoapArray base object
 Authors:	Jason Kichline, andCulture - Harrisburg, Pennsylvania USA
*/
#import "SoapArray.h"

@implementation SoapArray

@synthesize items;

- (id) init {
	if(self = [super init]) {
		self.items = [NSMutableArray array];
	}
	return self;
}

+(SoapArray*)createWithNode: (CXMLNode*) node {
	return [[[self alloc] initWithNode:node] autorelease];
}

-(id)initWithNode:(CXMLNode*)node {
	if(self = [self init]) {
		for(CXMLNode* child in [node children]) {
			[self addObject:[Soap deserialize:child]];
		}
	}
	return self;
}

+ (NSMutableString*) serialize: (NSArray*) array {
	return [NSMutableString stringWithString:[Soap serialize:array]];
}

- (id) object {
	return self.items;
}

- (NSUInteger)count {
	return [self.items count];
}

- (id)objectAtIndex:(NSUInteger)index {
	return [self.items objectAtIndex:index];
}

- (NSArray *)arrayByAddingObject:(id)anObject {
	return [self.items arrayByAddingObject:anObject];
}
- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)otherArray {
	return [self.items arrayByAddingObjectsFromArray:otherArray];
}
- (NSString *)componentsJoinedByString:(NSString *)separator {
	return [self.items componentsJoinedByString: separator]; 
}
- (BOOL)containsObject:(id)anObject {
	return [self.items containsObject:anObject];
}

- (NSString *)description {
	return [self.items description];
}

- (NSString *)descriptionWithLocale:(id)locale {
	return [self.items descriptionWithLocale:locale];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
	return [self.items descriptionWithLocale:locale indent:level];
}

- (id)firstObjectCommonWithArray:(NSArray *)otherArray {
	return [self.items firstObjectCommonWithArray:otherArray];
}

- (void)getObjects:(id *)objects {
	return [self.items getObjects:objects];
}

- (void)getObjects:(id *)objects range:(NSRange)range {
	return [self.items getObjects:objects range:range];
}

- (NSUInteger)indexOfObject:(id)anObject {
	return [self.items indexOfObject:anObject];
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range {
	return [self.items indexOfObject:anObject inRange:range];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject {
	return [self.items indexOfObjectIdenticalTo:anObject];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range {
	return [self.items indexOfObjectIdenticalTo:anObject inRange:range];
}

- (BOOL)isEqualToArray:(NSArray *)otherArray {
	return [self.items isEqualToArray:otherArray];
}

- (id)lastObject {
	return [self.items lastObject];
}

- (NSEnumerator *)objectEnumerator {
	return [self.items objectEnumerator];
}

- (NSEnumerator *)reverseObjectEnumerator {
	return [self.items reverseObjectEnumerator];
}

- (NSData *)sortedArrayHint {
	return [self.items sortedArrayHint];
}

- (NSArray *)sortedArrayUsingSelector:(SEL)comparator {
	return [self.items sortedArrayUsingSelector:comparator];
}

- (NSArray *)subarrayWithRange:(NSRange)range {
	return [self.items subarrayWithRange:range];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile{
	return [self.items writeToFile:path atomically:useAuxiliaryFile];
}

- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically {
	return [self.items writeToURL:url atomically:atomically];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector {
	return [self.items makeObjectsPerformSelector:aSelector];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)argument {
	return [self.items makeObjectsPerformSelector:aSelector withObject:argument];
}

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
	return [self.items objectsAtIndexes:indexes];
}

- (void)addObject:(id)anObject {
	return [self.items addObject:anObject];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index {
	return [self.items insertObject:anObject atIndex:index];
}

- (void)removeLastObject {
	return [self.items removeLastObject];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
	return [self.items removeObjectAtIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
	return [self.items replaceObjectAtIndex:index withObject:anObject];
}

- (void)addObjectsFromArray:(NSArray *)otherArray {
	return [self.items addObjectsFromArray:otherArray];
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2 {
	return [self.items exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

- (void)removeAllObjects {
	return [self.items removeAllObjects];
}

- (void)removeObject:(id)anObject inRange:(NSRange)range {
	return [self.items removeObject:anObject inRange:range];
}

- (void)removeObject:(id)anObject {
	return [self.items removeObject:anObject];
}

- (void)removeObjectIdenticalTo:(id)anObject inRange:(NSRange)range {
	return [self.items removeObjectIdenticalTo:anObject inRange:range];
}

- (void)removeObjectIdenticalTo:(id)anObject {
	return [self.items removeObjectIdenticalTo:anObject];
}

- (void)removeObjectsInArray:(NSArray *)otherArray {
	return [self.items removeObjectsInArray:otherArray];
}

- (void)removeObjectsInRange:(NSRange)range {
	return [self.items removeObjectsInRange:range];
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray range:(NSRange)otherRange {
	return [self.items replaceObjectsInRange:range withObjectsFromArray:otherArray range:otherRange];
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray {
	return [self.items replaceObjectsInRange:range withObjectsFromArray:otherArray];
}

- (void)setArray:(NSArray *)otherArray {
	return [self.items setArray:otherArray];
}

- (void)sortUsingSelector:(SEL)comparator {
	return [self.items sortUsingSelector:comparator];
}

- (void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes {
	return [self.items insertObjects:objects atIndexes:indexes];
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
	return [self.items removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects {
	return [self.items replaceObjectsAtIndexes:indexes withObjects:objects];
}

- (id)initWithCapacity:(NSUInteger)numItems {
	self = [self init];
	if(self) {
		self.items = [[[NSMutableArray alloc] initWithCapacity:numItems] autorelease];
	}
	return self;
}

+ (id)array {
	return [[[SoapArray alloc] init] autorelease];
}

+ (id)arrayWithObject:(id)anObject {
	return [[[SoapArray alloc] initWithObjects:anObject, nil] autorelease];
}

+ (id)arrayWithObjects:(const id *)objects count:(NSUInteger)cnt {
	return [[[SoapArray alloc] initWithObjects:objects count:cnt] autorelease];
}

+ (id)arrayWithObjects:(id)firstObj, ... {
	SoapArray* a = [SoapArray array];
	id eachObject;
	va_list argumentList;
	if (firstObj) {
		[a.items addObject: firstObj];
		va_start(argumentList, firstObj);
		while ((eachObject = va_arg(argumentList, id))) {
			[a.items addObject: eachObject];
		}
		va_end(argumentList);
	}
	return a;
}

- (id)initWithObjects:(id)firstObj, ... {
	if(self = [self init]) {
		id eachObject;
		va_list argumentList;
		if (firstObj) {
			[self.items addObject: firstObj];
			va_start(argumentList, firstObj);
			while ((eachObject = va_arg(argumentList, id))) {
				[self.items addObject: eachObject];
			}
			va_end(argumentList);
		}
	}
	return self;
}

+ (id)arrayWithArray:(NSArray *)array {
	return [[[SoapArray alloc] initWithArray:array] autorelease];
}

+ (id)arrayWithContentsOfFile:(NSString *)path {
	return [[[SoapArray alloc] initWithContentsOfFile:path] autorelease];
}

+ (id)arrayWithContentsOfURL:(NSURL *)url {
	return [[[SoapArray alloc] initWithContentsOfURL:url] autorelease];
}

+ (id)arrayWithCapacity:(NSUInteger)numItems {
	return [[[SoapArray alloc] initWithCapacity:numItems] autorelease];
}

- (id)initWithObjects:(const id *)objects count:(NSUInteger)cnt {
	self = [self init];
	if(self) {
		self.items = [[[NSMutableArray alloc] initWithObjects:objects count:cnt] autorelease];
	}
	return self;
}

- (id)initWithArray:(NSArray *)array {
	self = [self init];
	if(self) {
		self.items = [[[NSMutableArray alloc] initWithArray:array] autorelease];
	}
	return self;
}

- (id)initWithArray:(NSArray *)array copyItems:(BOOL)flag {
	self = [self init];
	if(self) {
		self.items = [[[NSMutableArray alloc] initWithArray:array copyItems:flag] autorelease];
	}
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path {
	self = [self init];
	if(self) {
		self.items = [[[NSMutableArray alloc] initWithContentsOfFile:path] autorelease];
	}
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)url {
	self = [self init];
	if(self) {
		self.items = [[[NSMutableArray alloc] initWithContentsOfURL:url] autorelease];
	}
	return self;
}

- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator context:(void *)context {
	return [self.items sortedArrayUsingFunction:comparator context:context];
}

- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator context:(void *)context hint:(NSData *)hint {
	return [self.items sortedArrayUsingFunction:comparator context:context hint:hint];
}

- (void)sortUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context {
	return [self.items sortUsingFunction:compare context:context];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
	return [self.items countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[self.items encodeWithCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [self init];
	if(self) {
		self.items = [[[NSMutableArray alloc] initWithCoder:aDecoder] autorelease];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	return [self.items copyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
	return [self.items mutableCopyWithZone:zone];
}

-(void)dealloc{
	[items release];
	[super dealloc];
}

@end