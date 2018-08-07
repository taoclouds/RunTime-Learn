# RunTime消息与方法
## 基础数据类型
### SEL 选择器
`SEL` 表示一个方法的 selector 指针，定义如下：
```
typedef struct objc_selector *SEL;
```
方法的`selector`用于表示运行时方法的名字。`Objective-C`在编译时，会依据每一个方法的名字、参数序列，生成一个唯一的整型标识(`Int`类型的地址)，这个标识就是`SEL`。

两个类之间，不管它们之间有没有继承关系，只要方法名相同，那么方法的`SEL`就是一样的。每一个方法都对应着一个`SEL`。所以在`Objective-C`同一个类(及类的继承体系)中，不能存在2个同名的方法，即使参数类型不同也不行。相同的方法只能对应一个`SEL`。这也就导致`Objective-C`在处理相同方法名且参数个数相同但类型不同的方法方面的能力很差。

不同的类可以拥有相同的`selector`，这个没有问题。不同类的实例对象执行相同的selector时，会在各自的方法列表中去根据selector去寻找自己对应的IMP。

工程中的所有的SEL组成一个Set集合，Set的特点就是唯一，因此SEL是唯一的。因此，如果我们想去这个方法集合中查找某个方法时，只需要去找到这个方法对应的SEL就行了，SEL实际上就是根据方法名hash化了的一个字符串，而对于字符串的比较仅仅需要比较他们的地址就可以了，可以说速度上无语伦比！！但是，有一个问题，就是数量增多会增大hash冲突而导致的性能下降（或是没有冲突，因为也可能用的是`perfect hash`）。但是不管使用什么样的方法加速，如果能够将总量减少（多个方法可能对应同一个SEL），那将是最犀利的方法。那么，我们就不难理解，为什么SEL仅仅是函数名了。

SEL只是一个指向方法的指针（准确的说，只是一个根据方法名hash化了的KEY值，能唯一代表一个方法），它的存在只是为了加快方法的查询速度。

对于 `selector`，可以在运行时添加新的`selector`，也可以在运行时获取已存在的`selector`，我们可以通过下面三种方法来获取SEL:

* `sel_registerName`函数
* `Objective-C`编译器提供的`@selector()`
* `NSSelectorFromString()`方法

### IMP函数指针-指向方法实现的首地址

前面介绍过的`SEL`就是为了查找方法的最终实现`IMP`的。由于每个方法对应唯一的`SEL`，因此我们可以通过`SEL`方便快速准确地获得它所对应的IMP，取得IMP后，我们就获得了执行这个方法代码的入口点，此时，我们就可以像调用普通的C语言函数一样来使用这个函数指针了。

通过取得IMP，我们可以跳过Runtime的消息传递机制，直接执行IMP指向的函数实现，这样省去了Runtime消息传递过程中所做的一系列查找操作，会比直接向对象发送消息高效一些。

### Method-代表方法的数据结构
`method` 表示类中方法的定义：
```
typedef struct objc_method *Method;
struct objc_method {
    SEL method_name                	OBJC2_UNAVAILABLE;	// 方法名
    char *method_types                	OBJC2_UNAVAILABLE;
    IMP method_imp             			OBJC2_UNAVAILABLE;	// 方法实现
}
```
该结构中`method_name`是一个 `SEL`，它与`method_imp`是一一对应的。通过 `SEL` 可以找到`method_imp`的执行入口在哪里。

### 操作方法的相关函数
这些函数如下：
```
// 调用指定方法的实现
id method_invoke ( id receiver, Method m, ... );
// 调用返回一个数据结构的方法的实现
void method_invoke_stret ( id receiver, Method m, ... );
// 获取方法名
SEL method_getName ( Method m );
// 返回方法的实现
IMP method_getImplementation ( Method m );
// 获取描述方法参数和返回值类型的字符串
const char * method_getTypeEncoding ( Method m );
// 获取方法的返回值类型的字符串
char * method_copyReturnType ( Method m );
// 获取方法的指定位置参数的类型字符串
char * method_copyArgumentType ( Method m, unsigned int index );
// 通过引用返回方法的返回值类型字符串
void method_getReturnType ( Method m, char *dst, size_t dst_len );
// 返回方法的参数的个数
unsigned int method_getNumberOfArguments ( Method m );
// 通过引用返回方法指定位置参数的类型字符串
void method_getArgumentType ( Method m, unsigned int index, char *dst, size_t dst_len );
// 返回指定方法的方法描述结构体
struct objc_method_description * method_getDescription ( Method m );
// 设置方法的实现
IMP method_setImplementation ( Method m, IMP imp );
// 交换两个方法的实现
void method_exchangeImplementations ( Method m1, Method m2 );
```

操作选择器的函数如下：

```
// 返回给定选择器指定的方法的名称
const char * sel_getName ( SEL sel );
// 在Objective-C Runtime系统中注册一个方法，将方法名映射到一个选择器，并返回这个选择器
SEL sel_registerName ( const char *str );
// 在Objective-C Runtime系统中注册一个方法
SEL sel_getUid ( const char *str );
// 比较两个选择器
BOOL sel_isEqual ( SEL lhs, SEL rhs );
```

以上就是对于方法操作的函数。下面要描述的是在一次方法调用过程中，到底经过哪些流程。

### 方法调用流程
通常向一个对象`obj`发送一条消息`message`：`[obj message]`。编译器将这个语句转化为一个消息函数的调用：`objc_msgSend`。这个函数将消息接受者(`obj`)和方法名`message`作为其基础参数：`objc_msgSend(obj, message)`。如果消息包含参数，那么它应该是这个样子：
```
objc_msgSend(obj,message,arg1,arg2......);
```
`objc_msgSend`这个函数所做的事情如下：
* 首先它根据 `obj` 对象找到selector对应的方法实现。因为同一个方法可能在不同的类中有不同的实现，所以我们需要依赖于`obj`来找到确切的实现。
* 然后调用方法实现，传入 `obj` 和参数。
* 最后，方法实现的返回值用作为它自己的返回值返回去。

当消息发送给一个对象时，`objc_msgSend`通过对象的`isa`指针获取到类的结构体，然后在`cache` 和 `methodLists`里面查找有没有方法的`selector`。如果没有找到`selector`，则通过`objc_msgSend`结构体中的`superClass`指针找到其父类，并在父类的`cache` 和 `methodLists`里面查找方法的`selector`。依次沿着类的继承体系到达`NSObject`类（或者其它基类）。一旦找到`selector`，函数获取到了实现的入口点，并传入相应的参数来执行方法的具体实现。如果最后没有定位到`selector`，则会走消息转发流程。

消息转发流程如下：
* 如果是以`[object message]`的方式调用方法，如果`object`无法响应`message`消息时，编译器会报错。
* 如果是以`perform...`的形式来调用，则需要等到运行时才能确定`object`是否能接收`message`消息。如果不能，则程序崩溃。
* 动态方法解析：在运行时期，如果对象收到一个自己没法处理的消息，首先会调用所属类的类方法`+resolveInstanceMethod:`(实例方法)或者`+resolveClassMethod:`(类方法)。在这个方法中，我们有机会为该未知消息新增一个处理方法。不过使用该方法的前提是我们已经实现了该处理方法，只需要在运行时通过`class_addMethod`函数动态添加到类里面就可以了。
* 在经过了上一步后还是无法处理消息，则 RunTime 会继续走这个方法：`- (id)forwardingTargetForSelector:(SEL)aSelector`。任何一个对象如果实现了这个方法，并且返回的结果不为空，则这个对象会成为消息的新的接受者。 这一步完成的是对于消息的转发。
* 如果上一步也没处理，那么还有一次机会，会调用`- (void)forwardInvocation:(NSInvocation *)anInvocation`这个方法。这是最后一次机会将消息转发给其它对象。对象将会创建一个表示消息的`NSInvocation`对象，尚未处理的消息有关的全部细节都封装在这个对象里面。可以在`forwardInvocation`方法中选择将消息转发给其它对象。

在上面最后一个方法中，可以对消息的内容进行修改，比如增加一个参数等，然后再去触发消息。另外，若发现某个消息不应由本类处理，则应调用父类的同名方法，以便继承体系中的每个类都有机会处理此调用请求。不过如果想要方法生效，需要重写这个方法：
```
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
```
Demo 可以在仓库中找到。
### 应用示例
场景：在`RTFirstDemo`下有一个方法`firstMethod`。在`RTMethodDemo`下没有该方法。现在给`RTMethodDemo`的实例发送`firstMethod`消息，希望通过消息转发使得`RTMethodDemo`的实例响应该方法。
`RTFirstDemo`：
```
- (void)firstMethod {
    NSLog(@"该方法为：firstMethod");
}
```

`RTMethodDemo`内做消息转发的处理，将 performSelector 传入的 `firstMethod` 方法转发给`RTFirstDemo`去处理：

第一种消息处理：动态解析
```
//动态解析

void methodFunction(id self, SEL _cmd) {
    NSLog(@"动态运行时添加的方法");
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *selectorString = NSStringFromSelector(sel);
    if ([selectorString isEqualToString:@"firstMethod"]) {
        class_addMethod(self, @selector(firstMethod), (IMP)methodFunction, "@:");
    }
    return [super resolveInstanceMethod:sel];
}
```

第二种方法：
```
// 消息转发的接收者
- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSString *selectorString = NSStringFromSelector(aSelector);
    if ([selectorString isEqualToString:@"firstMethod"]) {
        return self.firstDemo;
    }
    return [super forwardingTargetForSelector:aSelector];

}
```

第三种方法：
```
// 消息转发的最后一环

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        if ([RTFirstDemo instancesRespondToSelector:aSelector]) {
            signature = [RTFirstDemo instanceMethodSignatureForSelector:aSelector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([RTFirstDemo instancesRespondToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.firstDemo];
    }
}
```

## 消息转发与多继承
通过以上的消息转发机制，可以使得类内部处理某些未知的消息。但是在外部看仍然是该对象在处理该未知消息。通过这种机制，可以模拟多重继承的某些特性。给类添加它原来不能响应的方法。

## 总结
Runtime的强大之处主要在于消息发送和转发的基本机制。通过它，我们可以为程序增加很多动态的行为，了解它们有助于更多地理解底层的实现。在实际的编码过程中，我们也可以灵活地使用这些机制，去实现一些特殊的功能，如hook某个消息等。
