//
//  BWConnection.m
//  BiggerWallet
//
//  Created by Jos Kuijpers on 9/30/11.
//  Copyright 2011 Jos Kuijpers. All rights reserved.
//

#import "BWNetworking.h"
#import "JSONKit.h"

@interface BWConnection : NSObject {
    
    NSMutableData *data;
    NSURLConnection *connection;
    NSString *collection;
    NSArray *param;
    BWCompletionBlock block;
    NSURLResponse *response;
}

@property (retain, readonly) NSData *data;
@property (retain) NSURLResponse *response;

- (id)initWithCollection:(NSString *)_collection 
                   param:(NSArray *)_param 
              connection:(NSURLConnection *)_connection 
              completion:(BWCompletionBlock)_block;

- (void)addData:(NSData *)newData;

- (void)didFinish;
- (void)didFinishWithError:(NSError *)error;

@end


@implementation BWNetworking

@synthesize apiURL;

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        
        apiURL = [[NSURL alloc] initWithString:@"http://thayer-remodeling.com/bw/api/"];
        
        connections = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    self.apiURL = nil;
    [connections release];
    
    [super dealloc];
}

- (NSString *)keyForConnection:(NSURLConnection *)connection
{
    return [NSString stringWithFormat:@"%X",[connection hash]];
}

- (NSURL *)urlForCollection:(NSString *)collection
                      param:(NSArray *)param
{
    NSString *params = nil;
    if(param == nil)
        params = @"";
    else
        params = [param componentsJoinedByString:@"/"];
    
    NSString *str = [NSString stringWithFormat:@"%@/%@",collection,params];
    return [NSURL URLWithString:str
                  relativeToURL:apiURL];
}

- (void)getFromCollection:(NSString *)collection
               parameters:(NSArray *)param
               completion:(BWCompletionBlock)block
{
    NSURL *url = [self urlForCollection:collection
                                  param:param];
    
    // Create the request
    NSURLConnection *urlConnection = [NSURLConnection alloc];
    urlConnection = [urlConnection initWithRequest:[NSURLRequest requestWithURL:url]
                                          delegate:self];
    
    if(urlConnection)
    {
        BWConnection *conn = [BWConnection alloc];
        conn = [conn initWithCollection:collection 
                                  param:param 
                             connection:urlConnection 
                             completion:block];
        
        [connections setObject:conn forKey:[self keyForConnection:urlConnection]];
        [conn release];
    }
    else
    {
        if(block)
            block(collection,param,nil);
    }
}

- (void)postToCollection:(NSString *)collection
                    data:(NSData *)data
              parameters:(NSArray *)param
              completion:(BWCompletionBlock)block
{

}

- (void)putToCollection:(NSString *)collection
                   data:(NSData *)data
             parameters:(NSArray *)param
             completion:(BWCompletionBlock)block
{

}

#pragma mark - Connection delegate

- (void)connection:(NSURLConnection *)connection 
    didReceiveData:(NSData *)data
{
    BWConnection *conn = [connections objectForKey:[self keyForConnection:connection]];
    if(conn == nil)
        return;
    [conn addData:data];
}

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response
{
    BWConnection *conn = [connections objectForKey:[self keyForConnection:connection]];
    if(conn == nil)
        return;
    [conn setResponse:response];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    BWConnection *conn = [connections objectForKey:[self keyForConnection:connection]];
    if(conn == nil)
        return;
    [conn didFinish];
    [connections removeObjectForKey:[self keyForConnection:connection]];
}

- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error
{
    BWConnection *conn = [connections objectForKey:[self keyForConnection:connection]];
    if(conn == nil)
        return;
    [conn didFinishWithError:error];
    
    // Remove and release the object. This should also dealloc the object
    [connections removeObjectForKey:[self keyForConnection:connection]];
}

@end

@implementation BWConnection

@synthesize data, response;

- (id)initWithCollection:(NSString *)_collection 
                   param:(NSArray *)_param 
              connection:(NSURLConnection *)_connection 
              completion:(BWCompletionBlock)_block
{
    self = [super init];
    if (self)
    {
        data = [[NSMutableData alloc] init];
        collection = [_collection retain];
        param = [_param retain];
        connection = [_connection retain];
        block = [_block copy];
    }
    
    return self;
}

- (void)dealloc {

    [data release];
    [param release];
    [collection release];
    [block release];
    [connection release];
    
    [super dealloc];
}

- (void)addData:(NSData *)newData {
    if(newData)
    {
        [data appendData:newData];
    }
}

- (void)didFinish
{
    id jsonObj = [data objectFromJSONData];
    if(block)
        block(collection,param,jsonObj);
}

- (void)didFinishWithError:(NSError *)error
{
    if(block)
        block(collection,param,error);
}

@end
