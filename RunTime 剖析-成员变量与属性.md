# RunTime 剖析-成员变量与属性
## 类型编码(Type Encoding)
[类型编码](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1)是为了支持 RunTime 机制，编译器将方法的返回值和参数类型编码为一个字符串，再将这个字符串与方法的 `selector` 绑定在一起。使用`@encode()`指令来获取这种类型编码的形式。给定一个类型（如 NSString 、NSInteger等），`@encode()`会返回这个类型的字符串编码。

## 类的成员变量与属性

### 基础数据类型
#### 表示实例变量的类型-- Ivar
`Ivar`用来表示一个指向 `objc_ivar` 的指针，定义如下：
```
struct objc_ivar {
    char * _Nullable ivar_name                               OBJC2_UNAVAILABLE;
    char * _Nullable ivar_type                               OBJC2_UNAVAILABLE;
    int ivar_offset                                          OBJC2_UNAVAILABLE;
#ifdef __LP64__
    int space                                                OBJC2_UNAVAILABLE;
#endif
}    
```

#### 表示属性的类型-- objc_property_t

`objc_property_t`也是一个指针，它指向`objc_property` 结构体。貌似在 `runtime.h`里没找到该结构体。只有一个这个：
```
typedef struct {
    const char * _Nonnull name;           /**< The name of the attribute */
    const char * _Nonnull value;          /**< The value of the attribute (usually empty) */
} objc_property_attribute_t;
```

该结构体表示了属性具有的特性。

### 关联对象
关联对象比较实用，可以利用它实现
关联对象是在运行时添加的，类似于成员变量，通常类的成员变量是声明在头文件当中的，或者是放在实现文件`@implementation`前面。但是有一个缺点：无法在分类中给类添加成员变量。

此时，可以使用关联对象给其动态地添加成员变量。可以将关联对象看作是一个 Objective-C 对象，通过给定一个 key 链接到类的一个实例上。但是由于使用的是 C 接口，因此key 是一个 `void` 指针。同时还需要指定一个内存管理策略，告诉 `runtime` 该如何管理该对象的内存。内存管理策略如下：

```
OBJC_ASSOCIATION_ASSIGN
OBJC_ASSOCIATION_RETAIN_NONATOMIC
OBJC_ASSOCIATION_COPY_NONATOMIC
OBJC_ASSOCIATION_RETAIN
OBJC_ASSOCIATION_COPY
```
当宿主对象被释放时，会根据指定的内存管理策略来处理关联对象。
* `assign` 宿主对象释放时，关联对象不会被释放。
* `retain` / `copy` 宿主对象释放时，关联对象也会被释放。

将一个对象连接到其它对象所需要做的就是下面两行代码：
```
static char myKey;
objc_setAssociatedObject(self, &myKey, anObject, OBJC_ASSOCIATION_RETAIN);
```
在这种情况下，`self`对象将获取一个新的关联的对象`anObject`，且内存管理策略是自动`retain`关联对象，当`self`对象释放时，会自动`release`关联对象。另外，如果我们使用同一个`key`来关联另外一个对象时，也会自动释放之前关联的对象，这种情况下，先前的关联对象会被妥善地处理掉，并且新的对象会使用它的内存。

```
id anObject = objc_getAssociatedObject(self, &myKey);
```
我们可以使用`objc_removeAssociatedObjects`函数来移除一个关联对象，或者使用`objc_setAssociatedObject`函数将key指定的关联对象设置为nil。

关联对象的操作函数如下：
```
// 设置关联对象
void objc_setAssociatedObject ( id object, const void *key, id value, objc_AssociationPolicy policy );
// 获取关联对象
id objc_getAssociatedObject ( id object, const void *key );
// 移除关联对象
void objc_removeAssociatedObjects ( id object );
```

举例：在分类中给 `UITableViewCell` 添加一个属性 `currentIndex` 用于指向当前的 `cell` 的`indexPath`:
```
// 分类的.h 文件
@interface UITableViewCell (Category)

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end

//分类的.m 文件

@implementation UITableViewCell (Category)
@dynamic currentIndexPath;

- (NSIndexPath *)currentIndexPath {
    NSIndexPath *indexPath = objc_getAssociatedObject(self, @selector(currentIndexPath));
    return indexPath;
}

- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath {
    objc_setAssociatedObject(self, @selector(currentIndexPath), currentIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

```
