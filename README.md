# Atom.apex
Atom.apex is a library that tries to save you from the doom of Salesforce governor limits.

## Why Atom.apex?
Your apex code has always been working fine until someday it fails because of a huge amount of data. Usually this is because your code does not scale well. Atom.apex gives you this scalability and you only need to focus on your business logic.

## Inspirations
Usually when we reach the governor limits(heap size, cpu time, query, ...), it is because we are repeating a resource-consuming action. Everything works when there is reasonable repetition. But the unexpected data may cause the repetition count to grow out of control. By then, the governor limits are reached, exceptions are thrown, business logic is aborted and you are left in a mess(especially when you interact with external services).

What we have dreamed is that if the governor limits are reached, Salesforce does not throw exceptions directly, and instead it will schedule our remaining logic to the next available time spot to continue.

Sadly this has always been a dream and Salesforce aborts your execution brutally in this case(roll back your transaction as well, which is a good thing).

This is how we got our inspiration. We want to **split** our business logic into **steps**, so that each step can be executed sequentially and if resources are running out, we have a chance to save our progress and then continue the remaining steps.

We call the whole process an **Atom**, which means that your business logic is guaranteed to be executed even if some governor limits are reached, so that it will not be broken.

## Dependencies
Atom.apex has a dependency over [R.apex](https://github.com/Click-to-Cloud/R.apex/)

Please include it before including Atom.apex.

## Getting Started

### Big Picture
We will have an overview of what Atom.apex looks like in action.

```java
Map<String, Object> initialData = new Map<String, Object>{ ... };
new Atom(initialData)
    .then(new CustomBeforeCompute())
    .then(new Atom.ForEachStep('item', 'items', new CustomCompute()))
    .then(new CustomAfterCompute())
    .fork();
```

Here we split our business logic into `CustomBeforeCompute`, `CustomCompute` and `CustomAfterCompute`. The Atom instance is created with the initial data, then it will execute the `CustomBeforeCompute`. After that, it will do a 'for-each' loop of `CustomCompute` over the data indexed by 'items', and the looping item will be saved under the key of 'item'. Finally it will do the `CustomAfterCompute`.

All is not set off until the `fork` is invoked. During any step, if governor limits are reached, a new queueable job will be created to continue to run the remaining logic.

### Compute
A **compute** is a single unsplittable unit of business logic that can be executed within a transaction. In Atom.apex, all steps are running in the queueable job context, so the Async Apex Limits apply here.

Here is how we create a `CustomCompute`.

```java
public class CustomCompute extends Atom.Compute {
    public override void execute(Atom.State s) {
        Integer count = (Integer)s.getData('count');
        count += 1;
        s.setData('count', count);
    }
}
```

### Step
A **step** is the basic component of an **Atom**. Here is how we chain the steps into an Atom.

```java
new Atom()
    .then(step1)
    .then(step2)
    .fork();
```

We have different kinds of steps in Atom.apex.

- Simple Step
A simple step is one that contains a compute. The only job for a simple step is to execute that compute.

```java
new Atom()
    .then(new Atom.SimpleStep(new CustomCompute()))
    .then(new CustomCompute()) // equivalent to above
    .fork();
```

- Composite Step
A composite step is one that can contain multiple steps. It executes the children steps one by one.

```java
new Atom()
    .then(
        new Atom.CompositeStep()
            .then(...)
    )
    .fork();
```

- ForEach Step
A ForEachStep is one that executes the 'for-each' loop with the given step. It looks up for the collection data with the given name from the Atom state, and creates a new looping item before invoking the looping step.

```java
Map<String, Object> initialData = new Map<String, Object>{ 'items' => new List<Object>{ ... } };
new Atom(initialData)
    .then(new Atom.ForEachStep('item', 'items', new CustomStep()))
    .fork();
```

- Range Step
A RangeStep is one that executes the given step with a range of numbers.

```java
new Atom()
    .then(new Atom.RangeStep('n', 1, 10, new CustomStep()))
    .fork();
```

- Repeat Step
A RepeatStep is one that repeats the given step until N times.

```java
new Atom()
    .then(new Atom.RepeatStep(10, new CustomStep()))
    .fork();
```

### State
An Atom holds a state, which is then shared by all of its steps. You can access data with the state.

```java
public class CustomCompute extends Atom.Compute {
    public override void execute(Atom.State s) {
        Integer count = (Integer)s.getData('count');
        count += 1;
        s.setData('count', count);
    }
}
```

And this is the only way to communicate with other steps in Atom.apex

### Interruptions
In Atom.apex, when the governor limits are reached, we try to create a new queueable job to execute the remaining logic. The attempt to switch to a new queueable job is called an interruption.

Most of the time, we do not need to request for interruptions. But if we do, we can use this.

```java
public class CustomCompute extends Atom.Compute {
    public override void execute(Atom.State s) {
        s.setInterrupted(true);
    }
}
```

Also notice that new queueable jobs will not fix all the governor limit issues. So we have a limit for the interruptions. When an Atom tries the limit number of interruptions and still fails to resolve the resource issue, an exception will be thrown to indicate that.

You can set the interruption limit.

```java
new Atom()
    .setMaxInterruptions(20)
    .then(...)
    .fork();
```

### Functional Support
Atom.apex embraces functional style programming. You can pass in a Func to be used as a Compute or a Step.

```java
new Atom()
    .then(R.debug.apply('Running'))
    .fork();
```

Atom.apex has a helper Func to get values from the state, provide them to the given Func and apply the computed value back to the state.

```java
new Atom()
    .then(Atom.F.compute.apply('count', R.inc, 'count'))
    .fork();
```

The code above will get the number indexed by `count`, increment it and set it back to `count`.

If a Func returns `true` without being set to the state, the interrupted flag will be marked.

```java
new Atom()
    .then(Atom.F.compute.apply(R.equals.apply(1), 'count'))
    .fork();
```

This code will request an interruption if the `count` equals with 1.

### Monitor
When the governor limits are reached is determined by monitors.

Atom.apex has the following built-in monitors.

| Name | Description |
| ---- | ----------- |
| AggregateQueriesMonitor | Aggregate query limit |
| CalloutsMonitor | Call out limit |
| CpuTimeMonitor | Cpu time limit |
| DMLRowsMonitor | DML rows limit |
| DMLStatementsMonitor | DML statement limit |
| EmailInvocationsMonitor | Email invocation limit |
| FutureCallsMonitor | Future call limit |
| HeapSizeMonitor | Heap size limit |
| MobilePushApexCallsMonitor | Mobile push apex call limit |
| QueriesMonitor | Query limit |
| QueryLocatorRowsMonitor | Query locator row limit |
| QueryRowsMonitor | Query row limit |
| QueueableJobsMonitor | Queueable job limit |
| SoslQueriesMonitor | SOSL query limit |

Most of the time, you don't need to care about monitors. However, you could still provide your own monitor.

```java
public class CustomMonitor extends Atom.DefaultMonitor {
    public CustomMonitor() {
        super('Custom limit is reached');
    }

    public override Integer getCurrentValue(Atom.State s) {
        return (Integer)s.getData('count');
    }

    public override Integer getMaxValue(Atom.State s) {
        return 1000;
    }
}

Atom.registerMonitor(new CustomMonitor());
```

