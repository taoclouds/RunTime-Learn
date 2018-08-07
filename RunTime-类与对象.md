# RunTime-类与对象
此篇主要介绍 RunTime 机制中类与对象在底层是如何表示的，以及 OC 中向对象发消息是如何做的。最后介绍一些操作类和对象的方法。
## RunTime 机制
OC 是一门动态语言，将一些原本在编译和链接阶段要做的任务推迟到了运行时。因此，我们可以利用这个特性实现一些特殊的功能。
为了实现这个动态的机制，OC 有一个 RunTime 库，用于支持这种运行机制。这个 RunTime 库是基于 C语言的，正是由于 RunTime 库，它赋予了 C 面向对象的能力。
RunTime 将类和对象使用结构体封装起来，而向对象和类发送的消息是用 C 函数来实现。
当向类/对象发送一条消息时，RunTime 决定了该怎样响应这条消息。

## 类与对象的基础结构
### 类（Class）与对象
在 `Objective-C` 中，类是由 Class 类型来表示的，它是一个指向 `objc_class` 的指针。这点在objc.h 文件中可以看到：
```
typedef struct objc_class *Class;
```
而 `objc_class` 这个结构体的定义在 `objc/runtime.h` 这个文件里：
```
struct objc_class {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;

#if !__OBJC2__
    Class _Nullable super_class                              OBJC2_UNAVAILABLE;
    const char * _Nonnull name                               OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
#endif
} OBJC2_UNAVAILABLE;
```
以下几个字段比较重要：
* `super_class` 指向该类的父类，如果该类是顶层的类，则指向 null。
* `isa` 也是指向一个`Class`，在 OC 中，类本身也是一个对象，这个特殊的对象里有一个 `isa` 指针，指向`metaClass`。
* `methodLists` 该类的方法列表
* `cache` 缓存的方法列表。用于缓存最近使用的方法，对于收到的一个消息，一开始在`methodLists`方法中查找，找到之后会顺便放到`cache`中，这样下次直接到缓存方法列表中去取即可。
* `ivars` 类的属性列表，保存着类的所有属性
* `protocols` 类的遵循的协议接口

当我们在向一个 Objective-C 对象发送消息时，RunTime 库会根据实例对象的 isa 指针找到这个实例对象所属的类，RunTime 会在类的方法列表以及父类的方法列表中去查找可以响应消息的方法。
在创建一个特定的实例对象时，分配的内存是一个 objc_object 数据结构，然后是类的实例变量。NSObject类的`alloc`和`allocWithZone:`方法使用函数`class_createInstance`来创建`objc_object`数据结构。

#### Meta class
所有的类自身也是一个对象，我们可以向这个对象发送消息(即调用类方法)。既然这个类也是一个对象，那么它也是一个 `objc_object` 指针，它包含一个指向其类的一个 `isa` 指针，而这个 `isa` 指针指向的就是 `metaClass`。这个`metaclass`的作用其实和对象对应的类是一样的，即：

** 向一个对象发送消息时，RunTime 会在这个对象所属的类(`isa`指针的指向)的方法列表中查找方法；**
** 而向一个类发送消息时，则会在这个类的 `metaClass`(`isa`指针的指向)的方法列表中查找。**

`metaClass` 存储着一个类的所有类方法，每个类都有一个单独的`metaClass`。但是 `metaClass` 也是一个 `Class` 类型，那它的 `isa` 指针应该指向哪里呢？`metaClass`的 `isa` 指针指向当前类的基类的`metaClass`，而基类的 `metaClass`则指向它自己。
![一个简单的 Class 指向]()

## 类与对象操作函数
runtime提供了大量的函数来操作类与对象。类的操作方法大部分是以`class_`为前缀的，而对象的操作方法大部分是以`objc_`或`object_`为前缀。下面根据这些方法的用途来分类讨论这些方法的使用。
### 操作类
下面是操作类相关的函数
```
// 获取类的类名 返回字符串
const char * class_getName ( Class cls );
// 获取类的父类，返回 Class 类型
Class class_getSuperclass ( Class cls );
// 判断给定的Class是否是一个元类， 是返回 yes,否返回 No
BOOL class_isMetaClass ( Class cls );
```
### 操作类的实例变量，成员变量与属性
在`objc_class`中，所有的成员变量、属性的信息是放在链表`ivars`中的。`ivars`是一个数组，数组中每个元素是指向`Ivar`(变量信息)的指针。runtime提供了丰富的函数来操作这一字段。下面是相关的一些函数:
操作成员变量的：
```
// 获取实例大小
size_t class_getInstanceSize ( Class cls );
// 获取类中指定名称实例成员变量的信息
Ivar class_getInstanceVariable ( Class cls, const char *name );
// 获取类成员变量的信息
Ivar class_getClassVariable ( Class cls, const char *name );
// 添加成员变量
BOOL class_addIvar ( Class cls, const char *name, size_t size, uint8_t alignment, const char *types );
// 获取整个成员变量列表
Ivar * class_copyIvarList ( Class cls, unsigned int *outCount );

```
* `class_getInstanceVariable`函数，根据传入的 `Class` 和成员变量名称，返回该成员变量信息的`objc_ivar`结构体的指针(`Ivar`类型)。

* `class_getClassVariable`函数，一般认为Objective-C不支持类变量。注意，返回的列表不包含父类的成员变量和属性。

* Objective-C不支持往已存在的类中添加实例变量，注意是实例变量，不是属性。无法动态添加成员变量。如果通过运行时来创建一个类的话，就可以使用`class_addIvar`函数来添加实例变量。不过需要注意的是，这个方法只能在`objc_allocateClassPair`函数与`objc_registerClassPair`之间调用。另外，这个类也不能是元类。成员变量的按字节最小对齐量是`1<<alignment`。这取决于`ivar`的类型和机器的架构。如果变量的类型是指针类型，则传递`log2(sizeof(pointer_type))`。

* `class_copyIvarList`函数，它返回一个指向成员变量信息的数组，数组中每个元素是指向该成员变量信息的`objc_ivar`结构体的指针。这个数组不包含在父类中声明的变量。`outCount`指针返回数组的大小。需要注意的是，我们必须使用`free()`来释放这个数组。

属性操作函数：
```
// 获取指定的属性
objc_property_t class_getProperty ( Class cls, const char *name );
// 获取属性列表
objc_property_t * class_copyPropertyList ( Class cls, unsigned int *outCount );
// 为类添加属性
BOOL class_addProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );
// 替换类的属性
void class_replaceProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );
```

### 操作方法的函数
操作方法的函数如下：
```
// 添加方法
BOOL class_addMethod ( Class cls, SEL name, IMP imp, const char *types );
// 获取实例方法
Method class_getInstanceMethod ( Class cls, SEL name );
// 获取类方法
Method class_getClassMethod ( Class cls, SEL name );
// 获取所有方法的数组
Method * class_copyMethodList ( Class cls, unsigned int *outCount );
// 替代方法的实现
IMP class_replaceMethod ( Class cls, SEL name, IMP imp, const char *types );
// 返回方法的具体实现
IMP class_getMethodImplementation ( Class cls, SEL name );
IMP class_getMethodImplementation_stret ( Class cls, SEL name );
// 类实例是否响应指定的selector
BOOL class_respondsToSelector ( Class cls, SEL sel );
```
* `class_addMethod`的实现会覆盖父类的方法实现，但不会取代本类中已存在的实现，如果本类中包含一个同名的实现，则函数会返回NO。如果要修改已存在实现，可以使用`method_setImplementation`。一个Objective-C方法是一个简单的C函数，它至少包含两个参数`–self`和`_cmd`。所以，我们的实现函数(IMP参数指向的函数)至少需要两个参数，如下所示：
```
void myMethodIMP(id self, SEL _cmd)
{
    // implementation ....
}
```
* `class_getInstanceMethod`、`class_getClassMethod`函数，与`class_copyMethodList`不同的是，这两个函数都会去搜索父类的实现。
* `class_copyMethodList`函数，返回包含所有实例方法的数组，如果需要获取类方法，则可以使用`class_copyMethodList(object_getClass(cls), &count)`(一个类的实例方法是定义在元类里面)。该列表不包含父类实现的方法。`outCount`参数返回方法的个数。在获取到列表后，我们需要使用`free()`方法来释放它。
* `class_replaceMethod`函数，该函数的行为可以分为两种：如果类中不存在name指定的方法，则类似于class_addMethod函数一样会添加方法；如果类中已存在name指定的方法，则类似于`method_setImplementation`一样替代原方法的实现。
* `class_getMethodImplementation`函数，该函数在向类实例发送消息时会被调用，并返回一个指向方法实现函数的指针。这个函数会比`method_getImplementation(class_getInstanceMethod(cls, name))`更快。返回的函数指针可能是一个指向runtime内部的函数，而不一定是方法的实际实现。例如，如果类实例无法响应selector，则返回的函数指针将是运行时消息转发机制的一部分。
* `class_respondsToSelector`函数，判断某个 `class` 是否响应某个方法。我们通常使用NSObject类的`respondsToSelector:`或`instancesRespondToSelector:`方法来达到相同目的。

### 操作协议的方法
操作协议的函数如下：
```
// 添加协议
BOOL class_addProtocol ( Class cls, Protocol *protocol );
// 返回类是否实现指定的协议
BOOL class_conformsToProtocol ( Class cls, Protocol *protocol );
// 返回类实现的协议列表
Protocol * class_copyProtocolList ( Class cls, unsigned int *outCount );
```
操作协议的方法很清晰，不过多解释。

### RunTime 实例演示
[Demo实例在 GitHub]()

## 动态创建类与对象
RunTime机制可以实现动态运行时创建类与对象：

### 动态创建类
动态创建类用到的函数如下：

```
// 创建一个新类和元类
Class objc_allocateClassPair ( Class superclass, const char *name, size_t extraBytes );
// 销毁一个类及其相关联的类
void objc_disposeClassPair ( Class cls );
// 在应用中注册由objc_allocateClassPair创建的类
void objc_registerClassPair ( Class cls );
```

* `objc_allocateClassPair`函数：如果我们要创建一个根类，则`superclass`指定为Nil。`extraBytes`通常指定为0，该参数是分配给类和元类对象尾部的索引`ivars`的字节数。

通过调用`objc_allocateClassPair`创建新类，然后使用一些函数`class_addMethod`，`class_addIvar`为新创建的类添加方法、实例变量和属性等。之后需要将创建的类注册一下，使用`objc_registerClassPair`函数。这样，新创建出来的类就可以使用了。

实例方法和实例变量应该添加到类自身上，而类方法应该添加到类的元类上。

`objc_disposeClassPair`函数用于销毁一个类，不过需要注意的是，如果程序运行中还存在类或其子类的实例，则不能调用针对类调用该方法。

### 动态创建对象
动态创建对象的函数如下：
```
// 创建类实例
id class_createInstance ( Class cls, size_t extraBytes );
// 在指定位置创建类实例
id objc_constructInstance ( Class cls, void *bytes );
// 销毁类实例
void * objc_destructInstance ( id obj );
```
* class_createInstance函数：创建实例时，会在默认的内存区域为类分配内存。extraBytes参数表示分配的额外字节数。这些额外的字节可用于存储在类定义中所定义的实例变量之外的实例变量。该函数在ARC环境下无法使用。

### 实例操作函数

** 针对对象进行操作的函数 **

```
// 返回指定对象的一份拷贝
id object_copy ( id obj, size_t size );
// 释放指定对象占用的内存
id object_dispose ( id obj );
```
** 针对对象实例变量操作的函数 **

```
// 修改类实例的实例变量的值
Ivar object_setInstanceVariable ( id obj, const char *name, void *value );
// 获取对象实例变量的值
Ivar object_getInstanceVariable ( id obj, const char *name, void **outValue );
// 返回指向给定对象分配的任何额外字节的指针
void * object_getIndexedIvars ( id obj );
// 返回对象中实例变量的值
id object_getIvar ( id obj, Ivar ivar );
// 设置对象中实例变量的值
void object_setIvar ( id obj, Ivar ivar, id value );
```
如果实例变量的Ivar已经知道，那么调用object_getIvar会比object_getInstanceVariable函数快，相同情况下，object_setIvar也比object_setInstanceVariable快。

** 针对对象的类进行操作的函数 **
```
// 返回给定对象的类名
const char * object_getClassName ( id obj );
// 返回对象的类
Class object_getClass ( id obj );
// 设置对象的类
Class object_setClass ( id obj, Class cls );
```

### 获取类定义的函数
```
// 获取已注册的类定义的列表
int objc_getClassList ( Class *buffer, int bufferCount );
// 创建并返回一个指向所有已注册类的指针列表
Class * objc_copyClassList ( unsigned int *outCount );
// 返回指定类的类定义
Class objc_lookUpClass ( const char *name );
Class objc_getClass ( const char *name );
Class objc_getRequiredClass ( const char *name );
// 返回指定类的元类
Class objc_getMetaClass ( const char *name );
```
