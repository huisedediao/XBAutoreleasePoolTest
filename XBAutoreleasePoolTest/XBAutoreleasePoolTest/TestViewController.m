//
//  TestViewController.m
//  XBAutoreleasePoolTest
//
//  Created by 谢贤彬 on 2019/1/3.
//  Copyright © 2019年 谢贤彬. All rights reserved.
//

#import "TestViewController.h"
#import <objc/runtime.h>

extern uintptr_t _objc_rootRetainCount(id obj);
extern void _objc_autoreleasePoolPrint(void);

@interface TestClass : NSObject
{
    id _obj;
}
- (void)setObj:(id)obj;
+ (id)obj;
@end

@implementation TestClass
- (void)setObj:(id)obj
{
    _obj = obj;
}
+ (id)obj
{
    return [[TestClass alloc] init];
}
+ (id)obj_2
{
    id obj = [[TestClass alloc] init];
    return obj;
}
+ (id)allocObj
{
    return [[TestClass alloc] init];
}
@end

@interface TestViewController ()
{
    id __weak _obj_1;
}
@property (nonatomic,weak) id obj;
@property (nonatomic,weak) id obj2;
@end

@implementation TestViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
 总结：在打印weak指针的时候，打印出来的retainCount为真实的retainCount加1,但是这里有个例外，就是如果weak指针作为一个对象的属性时，只要这个指针指向了一个对象，那么每调用一次这个属性，对象的retainCount就会加1，这样就搞不清楚真实的retainCount是多少了。补充：只有属性会，作为成员变量不会有上述问题
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [UILabel new];
    [self.view addSubview:label];
    label.frame = CGRectMake(10, 100, 200, 100);
    label.text = @"点击屏幕返回上一页面";
    int index = 1;
    
    switch (index)
    {
        case -2:
        {
            id __weak obj_1 = nil;
            id __weak obj_2 = nil;
            id __strong obj_10 = nil;
            id __strong obj_11 = nil;
            {
                //新指针：指被赋值的指针，以下所有指针指向同一个对象
                id __strong obj1 = [TestClass obj];
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj1));//2
                
                //-->>1.用一个strong指针给weak指针赋值，对象的retainCount不变
                obj_1 = obj1;
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj1));//2
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_1));//3
                obj_2 = obj1;
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj1));//2
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_2));//3
                
                //-->>2.用一个strong指针给strong指针赋值，对象的retainCount加1
                obj_10 = obj1;
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj1));//3
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_1));//4
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_10));//3
                
                //-->>3.用一个weak指针给strong指针赋值,对象的retainCount加1
                obj_11 = obj_1;
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj1));//4
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_1));//5
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_10));//4
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_11));//4
                
                //--->>4.用一个weak指针给weak指针赋值，原来的weak指针的retainCount不变，新指针的retainCount和原来的指针一致
                obj_2 = obj_1;
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj1));//4
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_2));//5
                NSLog(@"retainCount :%ld",_objc_rootRetainCount(obj_10));//4
            }
        }
            break;
        case -1:
        {
            id __weak obj_1 = nil;
            id __weak obj_2 = nil;
            id __weak obj_3 = nil;
            {
                id __strong obj1 = [TestClass obj];
                id obj2 = [TestClass obj];
                NSLog(@"obj1 retainCount :%ld",_objc_rootRetainCount(obj1));//2
                NSLog(@"obj2 retainCount :%ld",_objc_rootRetainCount(obj2));//2
                
                [obj1 setObj:obj2];
                [obj2 setObj:obj1];
                NSLog(@"obj1 retainCount :%ld",_objc_rootRetainCount(obj1));//3
                NSLog(@"obj2 retainCount :%ld",_objc_rootRetainCount(obj2));//3
                
                obj_1 = obj1;
                obj_2 = obj2;
                obj_3 = obj1;
                NSLog(@"%ld",_objc_rootRetainCount(obj_1));//4
                NSLog(@"%ld",_objc_rootRetainCount(obj_2));//4
                NSLog(@"%ld",_objc_rootRetainCount(obj_3));//4
                NSLog(@"%ld",_objc_rootRetainCount(obj1));//3
                NSLog(@"%ld",_objc_rootRetainCount(obj2));//3
            }
            
            NSLog(@"%ld",_objc_rootRetainCount(obj_1));//3
            NSLog(@"%ld",_objc_rootRetainCount(obj_2));//3
            NSLog(@"%@",obj_1);///<TestClass: 0x600001450a90>
            NSLog(@"%@",obj_2);///<TestClass: 0x60000145dcd0>
            /*
             打断点查看
             2019-01-04 21:55:44.797127+0800 XBAutoreleasePoolTest[34463:3004907] obj1 retainCount :2
             2019-01-04 21:55:45.350422+0800 XBAutoreleasePoolTest[34463:3004907] obj2 retainCount :2
             2019-01-04 21:55:47.607886+0800 XBAutoreleasePoolTest[34463:3004907] obj1 retainCount :3
             2019-01-04 21:55:48.210101+0800 XBAutoreleasePoolTest[34463:3004907] obj2 retainCount :3
             */
            /*
             没打断点查看
             2019-01-04 00:09:16.872071+0800 UnitTestTest[33395:2895165] obj1 retainCount :1
             2019-01-04 00:09:16.872191+0800 UnitTestTest[33395:2895165] obj2 retainCount :1
             2019-01-04 00:09:16.872264+0800 UnitTestTest[33395:2895165] obj1 retainCount :2
             2019-01-04 00:09:16.872335+0800 UnitTestTest[33395:2895165] obj2 retainCount :2
             */
        }
            break;
        case 0:
        {
            id __weak obj_0 = nil;
            {
                id obj = nil;
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//1,只有obj持有对象
                obj = [NSObject new];
                NSLog(@"-----%@",obj);//-----<NSObject: 0x600000efd970>
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//1,只有obj持有对象
                obj_0 = obj;
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//1,只有obj持有对象
                NSLog(@"-----%ld",_objc_rootRetainCount(obj_0));//2
                _objc_autoreleasePoolPrint();//autoReleasePool中没有对象
            }
            NSLog(@"viewDidLoad:%@",obj_0);//(null)
            //结论：alloc/new/copy/mutableCopy开头的方法，取得的对象（自己创建并持有），并没有加入到autoReleasePool，
            //obj出了作用域就销毁了,对象的retainCount为0，所以对象销毁了
        }
            break;
        case 1:
        {
            id __weak obj_0 = nil;
            id __weak obj_1 = nil;
            self.obj = obj_0;
            {
                id obj = nil;
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//1
                obj = [TestClass obj];
                NSLog(@"-----%@",obj);
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//2,obj和autoReleasePool持有对象
                obj_0 = obj;
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//2,obj和autoReleasePool持有对象
                NSLog(@"-----%ld",_objc_rootRetainCount(obj_0));//3
                NSLog(@"-----%ld",_objc_rootRetainCount(self.obj));//1,因为这里self.obj指向的还是nil
                _objc_autoreleasePoolPrint();//0x600002ac67b0  TestClass ，autoReleasePool中有对象
            }
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_0));//2，obj出了作用域销毁，指向对象的指针减1
            self.obj = obj_0;
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj));//3,这里的retainCount3怎么理解？
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_1));//1
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_0));//3
            obj_1 = self.obj;
            NSLog(@"viewDidLoad:%@",obj_0); ///<TestClass: 0x600002ac67b0>
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj));//5,这里的retainCount5怎么理解？
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj));//6,这里的retainCount6怎么理解？
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj));//7,这里的retainCount7怎么理解？
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_1));//7
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_0));//7
            
            typeof(self) __weak weakSelf = self;
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(weakSelf.obj));//8,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(weakSelf.obj));//9,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(weakSelf.obj));//10,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_1));//10
            
            _obj_1 = obj_0;
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(_obj_1));//10,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(_obj_1));//10,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(_obj_1));//10,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_0));//10
            
            self.obj2 = obj_0;
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj2));//10,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj2));//10,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj2));//10,
            NSLog(@"retainCount:%ld",_objc_rootRetainCount(obj_0));//10
            //结论：非alloc/new/copy/mutableCopy开头的方法，取得的对象（非自己创建并持有），系统自动加入到autoReleasePool，
            //出了obj作用域，obj被销毁，对象的retainCount 减1变成1，只有等到所在autoReleasePool drain时，对象的retainCount变为0，对象才销毁
        }
            break;
        case 2:
        {
            id __weak obj_0 = nil;
            @autoreleasepool
            {
                id obj = [TestClass obj];
                NSLog(@"-----%@",obj);//0x600000866710  TestClass
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//2,obj和autoReleasePool持有对象
                obj_0 = obj;
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//2,obj和autoReleasePool持有对象
                NSLog(@"-----%ld",_objc_rootRetainCount(obj_0));//3
                _objc_autoreleasePoolPrint();//0x600000866710  TestClass ，autoReleasePool中有对象
            }
            NSLog(@"viewDidLoad:%@",obj_0);//(null)
            //符合1的结论，出了autoReleasePool，obj不再引用对象，autoReleasePool不再管理对象，对象的retainCount为0，对象销毁
        }
            break;
        case 3:
        {
            id __weak obj_0 = nil;
            @autoreleasepool
            {
                id obj = [TestClass obj_2];
                NSLog(@"-----%@",obj);//-----<TestClass: 0x600002510910>
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//2,obj和autoReleasePool持有对象
                obj_0 = obj;
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//2,obj和autoReleasePool持有对象
                NSLog(@"-----%ld",_objc_rootRetainCount(obj_0));//3
                _objc_autoreleasePoolPrint();//0x600002510910  TestClass ，autoReleasePool中有对象
            }
            NSLog(@"viewDidLoad:%@",obj_0);//(null)
            //符合1的结论，出了autoReleasePool，obj不再引用对象，autoReleasePool不再管理对象，对象的retainCount为0，对象销毁
        }
            break;
        case 4:
        {
            id __weak obj_0 = nil;
            @autoreleasepool
            {
                id obj = [TestClass allocObj];
                NSLog(@"-----%@",obj);//-----<TestClass: 0x600000a91af0>
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//1,obj持有对象
                obj_0 = obj;
                NSLog(@"-----%ld",_objc_rootRetainCount(obj));//1,obj持有对象
                NSLog(@"-----%ld",_objc_rootRetainCount(obj_0));//2
                _objc_autoreleasePoolPrint();//autoReleasePool中没有对象
            }
            NSLog(@"viewDidLoad:%@",obj_0);//(null)
            //出了作用域，obj销毁，对象的内存引用计数变为0，所以对象销毁
        }
            break;
            
        default:
            break;
    }
    NSLog(@"viewDidLoad end:%@",self.obj);
    NSLog(@"retainCount:%ld",_objc_rootRetainCount(self.obj));//3,这里的retainCount3怎么理解？
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear:%@",self.obj);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear:%@",self.obj);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear:%@",self.obj);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"viewDidDisappear:%@",self.obj);
}

- (void)dealloc
{
    NSLog(@"dealloc:%@",self.obj);
}

@end
