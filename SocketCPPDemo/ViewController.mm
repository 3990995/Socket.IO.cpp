//
//  ViewController.m
//  SocketCPPDemo
//
//  Created by XueliangZhu on 16/06/2017.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

#import "ViewController.h"
#include "sio_client.h"

using namespace std;
using namespace sio;

@interface ViewController () {
    sio::client *_io;
    std::map<string, string> _query;
}

-(void)onConnected;
-(void)onDisconnected;

@end

void OnConnected(CFTypeRef ctrl,std::string nsp) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [((__bridge ViewController*)ctrl) onConnected];
    });
}

void OnlineUserCount(CFTypeRef ctrl,string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp) {
    if(data->get_flag() == message::flag_integer) {
        printf("%lld\n", data->get_int());
    }
}


void OnNewMessage(CFTypeRef ctrl,string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp) {
    
    if(data->get_flag() == message::flag_object) {
        NSString *userName = [NSString stringWithUTF8String:data->get_map()["userName"]->get_string().data()];
        NSString *message = [NSString stringWithUTF8String:data->get_map()["message"]->get_string().data()];
        long createdDate = data->get_map()["createdDate"]->get_int();
        
        NSLog(@"%@, %@, %ld", userName, message, createdDate);
    }
}

void PlanStateChanged(CFTypeRef ctrl,string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp) {
    if(data->get_flag() == message::flag_object) {
        NSString *streamStatus = [NSString stringWithUTF8String:data->get_map()["streamStatus"]->get_string().data()];
        NSString *status = [NSString stringWithUTF8String:data->get_map()["status"]->get_string().data()];
        NSLog(@"%@, %@", streamStatus, status);
    }
}

void ErrorMessage(CFTypeRef ctrl,string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp) {
    if(data->get_flag() == message::flag_object) {
        NSString *errorMessage = [NSString stringWithUTF8String:data->get_map()["message"]->get_string().data()];
        NSLog(@"%@", errorMessage);
    }
}

void OnClose(CFTypeRef ctrl,sio::client::close_reason const& reason) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [((__bridge ViewController*)ctrl) onDisconnected];
    });
}

void OnFailed(CFTypeRef ctrl) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [((__bridge ViewController*)ctrl) onDisconnected];
    });
}

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    using std::placeholders::_1;
    using std::placeholders::_2;
    using std::placeholders::_3;
    using std::placeholders::_4;
    
    _io = new sio::client();
    _io->set_socket_open_listener(std::bind(&OnConnected, (__bridge CFTypeRef)self,std::placeholders::_1));
    _io->set_close_listener(std::bind(&OnClose, (__bridge CFTypeRef)self, std::placeholders::_1));
    _io->set_fail_listener(std::bind(&OnFailed, (__bridge CFTypeRef)self));
    _io->socket()->on("online_user_count", std::bind(&OnlineUserCount, (__bridge CFTypeRef)self, _1,_2,_3,_4));
    _io->socket()->on("new_message", std::bind(&OnNewMessage, (__bridge CFTypeRef)self, _1,_2,_3,_4));
    _io->socket()->on("error_message", std::bind(&ErrorMessage, (__bridge CFTypeRef)self, _1,_2,_3,_4));
    _io->socket()->on("plan_state_changed", std::bind(&OnNewMessage, (__bridge CFTypeRef)self, _1,_2,_3,_4));
    _query = {
        {"planId", "5947881a46e0fb00060dcc6f"},
        {"ticket", "usBla8B37XPMj5TJaXtRs9EB5DbG9FuPYIUC%2Ft0uTSS6rxFbeGC6PLGtkJQlkKRzZV%2B6C4qAf1eVKVgK1j165Q%3D%3D"}
    };
    _io->connect("ws://hwworks-live-sit.test.huawei.com", _query);
}

-(void)viewDidDisappear:(BOOL)animated {
    _io->socket()->off_all();
    _io->set_open_listener(nullptr);
    _io->set_close_listener(nullptr);
    _io->close();
}

- (IBAction)send:(id)sender {
    message::ptr ptr = object_message::create();
    std::map<string, message::ptr> msg = {
        {"message", string_message::create("123")}
    };
    ptr->get_map() = msg;
    message::list li(ptr);
    _io->socket()->emit("send_message", li);
}

-(void)onConnected {
    NSLog(@"success");
}

-(void)onDisconnected {
    NSLog(@"Disconnect");
}

@end
