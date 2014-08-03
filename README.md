
# JMCache 
JMCache is a key/value store designed for persisting temporary objects fully based on GCD.
It is composed of a cache disk and a memory cache (JMCacheMemory).

JMCache is cool because :
* it can store object not compliant with NSCoding protocols, you can implement JMcoding protocol or use [FastCoding implementation](https://github.com/nicklockwood/FastCoding),
* you can configure the cache to be "memory then disk", "only memory", "only disk",
* you can use a ValueTransformer to increase security of your encoded object, you can zip it, crypt it with your own algorithms.


## Cache parameters
### Cache path type -> auto path to the save directory

```objective-c
typedef NS_ENUM(NSUInteger, JMCacheType) {
    JMCacheTypePublic,
    JMCacheTypePrivate,
    JMCacheTypeOffline
};
```

### Cache type -> memory, disk 

```objective-c
typedef NS_OPTIONS(NSUInteger, JMCacheType) {
    JMCacheTypeInMemory = 1,
    JMCacheTypeOnDisk   = 1 << 1,
    JMCacheTypeBoth     = 1 << 2
};
```

### ValueTransformer
You can write your own valueTransformer to increase security of your encoded data.
For example, see minimalist implemtation of JMCacheReverseDataValueTransformer class.
```objective-c
@property (strong, nonatomic) JMCacheValueTransformer *valueTransformer;
```

### preferredCompletionQueue
Default completion queue can be configure here.
```objective-c
@property (strong, nonatomic) dispatch_queue_t preferredCompletionQueue
```

