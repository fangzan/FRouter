//
//  FFRouter.m
//  FFMainProject
//
//  Created by imlifengfeng on 2018/9/18.
//  Copyright © 2018 imlifengfeng. All rights reserved.
//

#import <objc/runtime.h>

#import "FFRouter.h"
#import "FFRouterLogger.h"

static NSString *const FFRouterWildcard = @"*";
static NSString *FFSpecialCharacters = @"/?&.";

static NSString *const FFRouterCoreKey = @"FFRouterCore";
static NSString *const FFRouterCoreBlockKey = @"FFRouterCoreBlock";
static NSString *const FFRouterCoreTypeKey = @"FFRouterCoreType";

NSString *const FFRouterParameterURLKey = @"FFRouterParameterURL";

typedef NS_ENUM(NSInteger,FFRouterType) {
    FFRouterTypeDefault = 0,
    FFRouterTypeObject = 1,
    FFRouterTypeCallback = 2,
};

@interface FFRouter()

@property (nonatomic,strong) NSCache *classMapCache;

@property (nonatomic,strong) NSMutableDictionary *moduleMapCache;

@property (nonatomic,strong) NSMutableDictionary *routes;

@property (nonatomic,strong) FFRouterUnregisterURLHandler routerUnregisterURLHandler;

@end

@implementation FFRouter

static FFRouter *_instance;
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.classMapCache = [[NSCache alloc] init];
        self.moduleMapCache = [[NSMutableDictionary alloc]initWithCapacity:0];
        self.classMapCache.countLimit = 50;//限制缓存的数据数目,目的是控制内存占用
        [self loadClassesConfirmToProtocol:@protocol(FFRouterProtocol)];
    }
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [super allocWithZone:zone];
        }
    });
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

#pragma mark - Public Methods
+ (id)interfaceForProtocol:(Protocol *)protocol
{
    FFRouterLog(@"interfaceForProtocol:%@",NSStringFromProtocol(protocol));
    Class class = [[self sharedInstance] findClassForProtocol:protocol];
    return [[class alloc]init];
}

+ (id)interfaceCacheModuleForProtocol:(Protocol *)protocol
{
    FFRouterLog(@"interfaceCacheModule:%@",NSStringFromProtocol(protocol));
    NSString *key = NSStringFromProtocol(protocol);
    id instance = [[[self sharedInstance] moduleMapCache] objectForKey:key];
    if (instance) {
        return instance;
    }
    Class class = [[self sharedInstance] findClassForProtocol:protocol];
    instance = [[class alloc]init];
    [[[self sharedInstance] moduleMapCache] setObject:instance forKey:key];
    return instance;
}

+ (void)registerRouteURL:(NSString *)routeURL handler:(FFRouterHandler)handlerBlock {
    FFRouterLog(@"registerRouteURL:%@",routeURL);
    [[self sharedInstance] addRouteURL:routeURL handler:handlerBlock];
}

+ (void)registerObjectRouteURL:(NSString *)routeURL handler:(FFObjectRouterHandler)handlerBlock {
    FFRouterLog(@"registerObjectRouteURL:%@",routeURL);
    [[self sharedInstance] addObjectRouteURL:routeURL handler:handlerBlock];
}

+ (void)registerCallbackRouteURL:(NSString *)routeURL handler:(FFCallbackRouterHandler)handlerBlock {
    FFRouterLog(@"registerCallbackRouteURL:%@",routeURL);
    [[self sharedInstance] addCallbackRouteURL:routeURL handler:handlerBlock];
}

+ (BOOL)canRouteURL:(NSString *)URL {
    NSString *rewriteURL = [FFRouterRewrite rewriteURL:URL];
    return [[self sharedInstance] achieveParametersFromURL:rewriteURL] ? YES : NO;
}

+ (void)routeURL:(NSString *)URL {
    [self routeURL:URL withParameters:nil];
}

+ (void)routeURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters {
    FFRouterLog(@"Route to URL:%@\nwithParameters:%@",URL,parameters);
    NSString *rewriteURL = [FFRouterRewrite rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        FFRouterErrorLog(@"Route unregistered URL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return;
    }
    
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    
    if (routerParameters) {
        NSDictionary *coreDic = routerParameters[FFRouterCoreKey];
        FFRouterHandler handler = coreDic[FFRouterCoreBlockKey];
        FFRouterType type = [coreDic[FFRouterCoreTypeKey] integerValue];
        if (type != FFRouterTypeDefault) {
            [self routeTypeCheckLogWithCorrectType:type url:URL];
            return;
        }
        
        if (handler) {
            if (parameters) {
                [routerParameters addEntriesFromDictionary:parameters];
            }
            [routerParameters removeObjectForKey:FFRouterCoreKey];
            handler(routerParameters);
        }
    }
}

+ (id)routeObjectURL:(NSString *)URL {
    return [self routeObjectURL:URL withParameters:nil];
}

+ (id)routeObjectURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters {
    FFRouterLog(@"Route to ObjectURL:%@\nwithParameters:%@",URL,parameters);
    NSString *rewriteURL = [FFRouterRewrite rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        FFRouterErrorLog(@"Route unregistered ObjectURL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return nil;
    }
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    NSDictionary *coreDic = routerParameters[FFRouterCoreKey];
    FFObjectRouterHandler handler = coreDic[FFRouterCoreBlockKey];
    FFRouterType type = [coreDic[FFRouterCoreTypeKey] integerValue];
    if (type != FFRouterTypeObject) {
        [self routeTypeCheckLogWithCorrectType:type url:URL];
        return nil;
    }
    if (handler) {
        if (parameters) {
            [routerParameters addEntriesFromDictionary:parameters];
        }
        [routerParameters removeObjectForKey:FFRouterCoreKey];
        return handler(routerParameters);
    }
    return nil;
}

+ (void)routeCallbackURL:(NSString *)URL targetCallback:(FFRouterCallback)targetCallback {
    [self routeCallbackURL:URL withParameters:nil targetCallback:targetCallback];
}

+ (void)routeCallbackURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters targetCallback:(FFRouterCallback)targetCallback {
    FFRouterLog(@"Route to URL:%@\nwithParameters:%@",URL,parameters);
    NSString *rewriteURL = [FFRouterRewrite rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        FFRouterErrorLog(@"Route unregistered URL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return;
    }
    
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    
    if (routerParameters) {
        NSDictionary *coreDic = routerParameters[FFRouterCoreKey];
        FFCallbackRouterHandler handler = coreDic[FFRouterCoreBlockKey];
        FFRouterType type = [coreDic[FFRouterCoreTypeKey] integerValue];
        if (type != FFRouterTypeCallback) {
            [self routeTypeCheckLogWithCorrectType:type url:URL];
            return;
        }
        if (parameters) {
            [routerParameters addEntriesFromDictionary:parameters];
        }
        
        if (handler) {
            [routerParameters removeObjectForKey:FFRouterCoreKey];
            handler(routerParameters,^(id callbackObjc){
                if (targetCallback) {
                    targetCallback(callbackObjc);
                }
            });
        }
    }
}


+ (void)routeUnregisterURLHandler:(FFRouterUnregisterURLHandler)handler {
    [[self sharedInstance] setRouterUnregisterURLHandler:handler];
}

+ (void)unregisterRouteURL:(NSString *)URL {
    [[self sharedInstance] removeRouteURL:URL];
    FFRouterLog(@"Unregister URL:%@\nroutes:%@",URL,[[self sharedInstance] routes]);
}

+ (void)unregisterAllRoutes {
    [[self sharedInstance] removeAllRouteURL];
    FFRouterLog(@"Unregister All URL\nroutes:%@",[[self sharedInstance] routes]);
}

+ (void)setLogEnabled:(BOOL)enable {
    [FFRouterLogger enableLog:enable];
}

#pragma mark - Private Methods
// moudle
- (Class<FFRouterProtocol>)findClassForProtocol:(Protocol*)protocol {
    
    NSString *key = NSStringFromProtocol(protocol);
    Class cacheClass = [self.classMapCache objectForKey:key];
    if (cacheClass) {
        //已经缓存的协议实现类
        return cacheClass;
    } else {
        //未缓存的协议实现类
        Class<FFRouterProtocol> responseClass = [self assertForMoudleWithProtocol:protocol];
        return responseClass;
    }
    return nil;
}

- (Class)classForProtocol:(Protocol *)protocol {
    
    unsigned int classCount;
    Class* classList = objc_copyClassList(&classCount);
    int i;
    Class thisClass = nil;
    for (i=0; i<classCount; i++) {
        const char *className = class_getName(classList[i]);
        Class tempClass = objc_getClass(className);
        if (class_conformsToProtocol(tempClass, protocol)) {
            thisClass = tempClass;
            break;
        }
    }
    free(classList);
    return thisClass;
}

- (Class)assertForMoudleWithProtocol:(Protocol *)p {
    
    Class thisClass = [self classForProtocol:p];
    if (!thisClass) {
        NSString *protocolName = NSStringFromProtocol(p);
        NSString *reason = [NSString stringWithFormat: @"找不到协议 %@ 对应的接口实现类", protocolName];
        NSLog(@"组件异常⚠️:%@",reason);
        return nil;
    }
    return thisClass;
}

- (void)loadClassesConfirmToProtocol:(Protocol *)protocol {
    unsigned int classCount;
    Class* classList = objc_copyClassList(&classCount);
    int i;
    for (i=0; i<classCount; i++) {
        const char *className = class_getName(classList[i]);
        Class thisClass = objc_getClass(className);
        if (class_conformsToProtocol(thisClass, protocol)) {
            const char *protocolName = protocol_getName([self protroclForClass:thisClass]);
            NSString *pn = [NSString stringWithUTF8String:protocolName];
            [self.classMapCache setObject:thisClass forKey:pn];
        }
    }
    free(classList);
}
//取实现类的协议列表的第一个协议为路由协议
- (Protocol*)protroclForClass:(Class)cs
{
    unsigned int protocalCount;
    //获取协议列表
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList(cs, &protocalCount);
    Protocol *myProtocal = protocolList[0];
    free(protocolList);
    return myProtocal;
}

// MARK:- router
- (void)addRouteURL:(NSString *)routeUrl handler:(FFRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeUrl];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{FFRouterCoreBlockKey:[handlerBlock copy],FFRouterCoreTypeKey:@(FFRouterTypeDefault)};
        subRoutes[FFRouterCoreKey] = coreDic;
    }
}

- (void)addObjectRouteURL:(NSString *)routeUrl handler:(FFObjectRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeUrl];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{FFRouterCoreBlockKey:[handlerBlock copy],FFRouterCoreTypeKey:@(FFRouterTypeObject)};
        subRoutes[FFRouterCoreKey] = coreDic;
    }
}

- (void)addCallbackRouteURL:(NSString *)routeUrl handler:(FFCallbackRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeUrl];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{FFRouterCoreBlockKey:[handlerBlock copy],FFRouterCoreTypeKey:@(FFRouterTypeCallback)};
        subRoutes[FFRouterCoreKey] = coreDic;
    }
}

- (NSMutableDictionary *)addURLPattern:(NSString *)URLPattern {
    NSArray *pathComponents = [self pathComponentsFromURL:URLPattern];
    
    NSMutableDictionary* subRoutes = self.routes;
    
    for (NSString* pathComponent in pathComponents) {
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
    }
    return subRoutes;
}

- (void)unregisterURLBeRouterWithURL:(NSString *)URL {
    if (self.routerUnregisterURLHandler) {
        self.routerUnregisterURLHandler(URL);
    }
}

- (void)removeRouteURL:(NSString *)routeUrl{
    if (self.routes.count <= 0) {
        return;
    }
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[self pathComponentsFromURL:routeUrl]];
    BOOL firstPoll = YES;
    
    while(pathComponents.count > 0){
        NSString *componentKey = [pathComponents componentsJoinedByString:@"."];
        NSMutableDictionary *route = [self.routes valueForKeyPath:componentKey];
        
        if (route.count > 1 && firstPoll) {
            [route removeObjectForKey:FFRouterCoreKey];
            break;
        }
        if (route.count <= 1 && firstPoll){
            NSString *lastComponent = [pathComponents lastObject];
            [pathComponents removeLastObject];
            NSString *parentComponent = [pathComponents componentsJoinedByString:@"."];
            route = [self.routes valueForKeyPath:parentComponent];
            [route removeObjectForKey:lastComponent];
            firstPoll = NO;
            continue;
        }
        if (route.count > 0 && !firstPoll){
            break;
        }
    }
}

- (void)removeAllRouteURL {
    [self.routes removeAllObjects];
}

- (NSArray*)pathComponentsFromURL:(NSString*)URL {
    
    NSMutableArray *pathComponents = [NSMutableArray array];
    if ([URL rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [URL componentsSeparatedByString:@"://"];
        [pathComponents addObject:pathSegments[0]];
        for (NSInteger idx = 1; idx < pathSegments.count; idx ++) {
            if (idx == 1) {
                URL = [pathSegments objectAtIndex:idx];
            }else{
                URL = [NSString stringWithFormat:@"%@://%@",URL,[pathSegments objectAtIndex:idx]];
            }
        }
    }
    
    if ([URL hasPrefix:@":"]) {
        if ([URL rangeOfString:@"/"].location != NSNotFound) {
            NSArray *pathSegments = [URL componentsSeparatedByString:@"/"];
            [pathComponents addObject:pathSegments[0]];
        }else{
            [pathComponents addObject:URL];
        }
    }else{
        for (NSString *pathComponent in [[NSURL URLWithString:URL] pathComponents]) {
            if ([pathComponent isEqualToString:@"/"]) continue;
            if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
            [pathComponents addObject:pathComponent];
        }
    }
    return [pathComponents copy];
}

- (NSMutableDictionary *)achieveParametersFromURL:(NSString *)url{
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[FFRouterParameterURLKey] = [url stringByRemovingPercentEncoding];
    
    NSMutableDictionary* subRoutes = self.routes;
    NSArray* pathComponents = [self pathComponentsFromURL:url];
    
    NSInteger pathComponentsSurplus = [pathComponents count];
    BOOL wildcardMatched = NO;
    
    for (NSString* pathComponent in pathComponents) {
        NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch;
        NSArray *subRoutesKeys =[subRoutes.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj2 compare:obj1 options:comparisonOptions];
        }];
        
        for (NSString* key in subRoutesKeys) {
            
            if([pathComponent isEqualToString:key]){
                pathComponentsSurplus --;
                subRoutes = subRoutes[key];
                break;
            }else if([key hasPrefix:@":"] && pathComponentsSurplus == 1){
                subRoutes = subRoutes[key];
                NSString *newKey = [key substringFromIndex:1];
                NSString *newPathComponent = pathComponent;
                
                NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:FFSpecialCharacters];
                NSRange range = [key rangeOfCharacterFromSet:specialCharacterSet];
                
                if (range.location != NSNotFound) {
                    newKey = [newKey substringToIndex:range.location - 1];
                    NSString *suffixToStrip = [key substringFromIndex:range.location];
                    newPathComponent = [newPathComponent stringByReplacingOccurrencesOfString:suffixToStrip withString:@""];
                }
                parameters[newKey] = newPathComponent;
                break;
            }else if([key isEqualToString:FFRouterWildcard] && !wildcardMatched){
                subRoutes = subRoutes[key];
                wildcardMatched = YES;
                break;
            }
        }
    }
    
    if (!subRoutes[FFRouterCoreKey]) {
        return nil;
    }
    
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:[[NSURL alloc] initWithString:url] resolvingAgainstBaseURL:false].queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        parameters[item.name] = item.value;
    }
    
    parameters[FFRouterCoreKey] = [subRoutes[FFRouterCoreKey] copy];
    return parameters;
}

+ (void)routeTypeCheckLogWithCorrectType:(FFRouterType)correctType url:(NSString *)URL{
    if (correctType == FFRouterTypeDefault) {
        FFRouterErrorLog(@"You must use [routeURL:] or [routeURL: withParameters:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }else if (correctType == FFRouterTypeObject) {
        FFRouterErrorLog(@"You must use [routeObjectURL:] or [routeObjectURL: withParameters:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }else if (correctType == FFRouterTypeCallback) {
        FFRouterErrorLog(@"You must use [routeCallbackURL: targetCallback:] or [routeCallbackURL: withParameters: targetCallback:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }
}

#pragma mark - getter/setter
- (NSMutableDictionary *)routes {
    if (!_routes) {
        _routes = [[NSMutableDictionary alloc] init];
    }
    return _routes;
}

@end
