
# JMCache 
JMCache is a key/value store designed for persisting temporary objects fully based on GCD.
It is composed of a cache disk and a memory cache (JMCacheMemory).

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

